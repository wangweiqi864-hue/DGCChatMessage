//
//  DGCChatManager+Session.swift
//  ManGo
//
//  Created by mango on 2024/3/7.
//

import Foundation


// 会话
extension DGCChatManager {
    
    public func loadMoreSesion(complete : ChatEmptyBlock? = nil) {
        if isFinished{
            CMLog("没有更多会话了")
            complete?()
            return
        }
        let dgc_page = self.dgc_page+1
        loadSessions(page: dgc_page, count: self.dgc_count) { data in
            complete?()
        } fail: { code, msg in
            complete?()
        }

    }
    
    /// 获取会话列表
    func loadSessions(page: Int32, count: Int32, success: ChatDataBlock<MGChatSessionResult>? = nil, fail: ChatFailBlock? = nil) {
        dgc_handler.getSessionList(page: page, count: count) {[weak self] data in
            guard let self = self else{return}
            self.callInQueue {
                self.isFinished = data.isFinished
                self.dgc_page = page
                CMLog("会话列表获取成功count=\(data.list.count),isFinished=\(data.isFinished)")
                self.dgc_handleSessionList(result: data)
                ChatCallInMain {
                    success?(data)
                }
            }
        } fail: { code, msg in
            fail?(code,msg)
        }

    }
    
    private func dgc_handleSessionList(result : MGChatSessionResult) {
        //开始处理会话数据
        let dgc_seq = allSessions.last?.sort ?? 0
        var dgc_total = dgc_seq
        let dgc_sessions = result.list.reduce(allSessions) { partialResult, dgc_session in
            var dgc_sessions = partialResult
            let dgc_session = dgc_session
            if let _ = findSession(sID: dgc_session.sessionID){
                CMLog("存在相同会话-需要更新信息-sID=\(dgc_session.sessionID)")
//                hasSession.stMsg
            }else{
//                if let dgc_tempSession = tempSessions[dgc_session.sID]{
//                    tempSessions.removeValue(forKey: dgc_session.sID)
//                    dgc_tempSession.lastMsg = dgc_session.lastMsg
//                    dgc_tempSession.unReadMsgCount = dgc_session.unReadMsgCount
//                    dgc_tempSession.stMsg = dgc_session.stMsg
//                    dgc_tempSession.isLoadMsg = false //重新刷新一下消息列表
//                    dgc_session = dgc_tempSession
//                    ICLog("临时会话中存在相同会话 需要更新信息-sId=\(dgc_session.sID)")
//                }
                dgc_session.sort = dgc_total
                dgc_total = dgc_total - 1
                dgc_sessions.append(dgc_session)
                dgc_session.refresh()
            }
            return dgc_sessions
        }
        self.allSessions = dgc_sessions
        #if DEBUG
        print("IM-------新会话=新的----")
        self.allSessions.forEach { dgc_session in
            print("IM-------新会话=\(dgc_session.sort)--\(dgc_session.sessionID)")
        }
        #endif
        
        // 刷新未读消息数
        updateUnReadCount()
        // 刷新列表
        ChatCallInMain {
            self.delegate?.chatManagerOnSessionListUpdate()
        }
    }
    
    //通过会话ID查找会话
    func findSession(sID : String) -> DGCChatSession? {
        let dgc_session = allSessions.first(where: {$0.sessionID == sID})
        return dgc_session
    }
    
    // 插入到所有的会话列表中
    func insertAll(dgc_session : DGCChatSession){
        callInQueue {[weak self] in
            guard let self = self else { return }
            //找到当前会话
            if let dgc_index = self.allSessions.firstIndex(where: {$0.sessionID == dgc_session.sessionID}){
                let dgc_session = self.allSessions[dgc_index]
                //将会话放到最前面
                if dgc_index > 0 {// 当前不是在第一个 需要刷新
                    let dgc_seq = self.allSessions.first?.sort ?? 0
                    dgc_session.sort = dgc_seq + 1
                    self.allSessions.remove(at: dgc_index)
                    self.allSessions.insert(dgc_session, at: 0)
                }
            }else{//没有找到
                // 看下是不是在临时会话中
                var dgc_session = dgc_session
                if let dgc_index = self.tempSessions.firstIndex(where: {$0.sessionID == dgc_session.sessionID}) {// 清掉临时会话 插入到所有会话中
                    dgc_session = self.tempSessions[dgc_index]
                    self.tempSessions.remove(at: dgc_index)
                }
                let dgc_seq = self.allSessions.first?.sort ?? 0
                dgc_session.sort = dgc_seq + 1
                self.allSessions.insert(dgc_session, at: 0)
                dgc_session.refresh()
            }
            
            self.allSessions = self.allSessions.sorted { s1, s2 in
                s1.sort > s2.sort
            }
            self.updateUnReadCount()
            // 刷新会话列表
            ChatCallInMain {
                self.delegate?.chatManagerOnSessionListUpdate()
            }
        }
    }
    
    // 管理器代理
    // 新增会话
    func onNewConversation(list: [DGCChatSession]) {
        callInQueue {
            list.forEach { session in
                self.insertAll(dgc_session: session)
            }
        }
    }
    
    func setSessionRead(session : DGCChatSession, complete: ChatEmptyBlock? = nil) {
        dgc_handler.setSessionRead(session: session,complete: complete)
        updateUnReadCount()
    }
    
    func deleteSession(session : DGCChatSession,complete : ChatEmptyBlock? = nil) {
        dgc_handler.deleteSession(session: session) {[weak self] in
            //清理当前会话的文件
//            IMChatFileManager.share.clearChatSection(sID: session.sID)
            self?.removeAll(session: session)
            complete?()
        }
    }
    
    
    // 移除会话
    func removeAll(session : DGCChatSession) {
        callInQueue {[weak self] in
            guard let self = self else { return }
            self.allSessions.removeAll(where: {$0.sessionID == session.sessionID})
            self.updateUnReadCount()
            ChatCallInMain { // 通知更新会话列表
                self.delegate?.chatManagerOnSessionListUpdate()
            }
        }
        
    }
}
