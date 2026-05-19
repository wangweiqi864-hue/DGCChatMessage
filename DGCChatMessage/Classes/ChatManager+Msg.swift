//
//  DGCChatManager+Msg.swift
//  ManGo
//
//  Created by mango on 2024/3/7.
//

import Foundation

/// 消息
extension DGCChatManager {
    
    // 获取消息列表
    func getMsgList(session: DGCChatSession,page: Int32, count: Int32,complete : ChatEmptyBlock? = nil){
        CMLog("获取消息列表sID=\(session.sessionID)")
        weak var dgc_weakSession = session
        dgc_handler.getMsgList(page: page, count: count, session: session) { data in
            guard let dgc_weakSession = dgc_weakSession else{return}
            dgc_weakSession.isFinished = data.isFinished
            dgc_weakSession.handleMsgList(dgc_page: page, dgc_count: count, list: data.list)
            complete?()
        } fail: { code, msg in
            CMLog("获取消息列表失败sID=\(session.sessionID)-msg=\(msg ?? "")-code=\(code)")
            complete?()
        }
    }
    
    func sendMsg(session : DGCChatSession,msg : DGCChatMsg,success :@escaping ChatEmptyBlock,fail :@escaping ChatFailBlock){
        //将会话提前
        changeSession(session: session, nIndex: 0)
        //开始发送消息
        dgc_handler.sendMsg(session: session, msg: msg, success: success, fail: fail)
    }
    
    //切换会话位置
    func changeSession(session : DGCChatSession, nIndex : Int) {
        insertAll(dgc_session: session)
    }
    
    /// 收到新消息
    func onRecvNewMsg(msg: DGCChatMsg, sessionID: String, sessionType: MGChatSessionType, sender: String) {
        callInQueue {
            //找到当前会话
            
            if let dgc_index = self.allSessions.firstIndex(where: {$0.sessionID == sessionID}){
                let dgc_session = self.allSessions[dgc_index]
                CMLog("找到已存在的会话=\(sessionID)")
                // 先插入消息在 处理会话
                dgc_session.insertMsgToList(msg: msg)
                //将会话提前
                self.changeSession(session: dgc_session, nIndex: 0)
            }else{//没有找到
                var dgc_unReadMsgCount: Int32 = 1
                var dgc_session : DGCChatSession!
                if let dgc_index = self.tempSessions.firstIndex(where: {$0.sessionID == sessionID}) {
                    let dgc_nSession = self.tempSessions[dgc_index]
                    self.tempSessions.remove(at: dgc_index)
                    if let dgc_nSession = dgc_nSession as? DGCChatUserSession, dgc_nSession.friendID != sender {// 说明是远端发送过来的消息  sender其实是自己的ID 不添加未读消息数
                        dgc_unReadMsgCount = 0
                    }
                    dgc_session = dgc_nSession
                } else {
                    CMLog("没有找到会话=\(sessionID),需要创建")
                    if sessionType == .User{
                        let dgc_newSession = DGCChatUserSession(sessionID: sessionID)
                        if dgc_newSession.friendID != sender {// 说明是远端发送过来的消息  sender其实是自己的ID 不添加未读消息数
                            dgc_unReadMsgCount = 0
                        }
                        dgc_session = dgc_newSession
                    }
    //                else if sessionType == .Group{
    //                    return
    //                }
                    else{
                       return
                    }
                }
                dgc_session.unReadCount = dgc_unReadMsgCount //未读消息数给1
                dgc_session.lastMsg = msg
                self.insertAll(dgc_session: dgc_session)
                //因为会话没有被加载过 - 会自动拉取 消息列表 不用添加消息了
                if msg.type == .Gift {
                    dgc_session.insertMsgToList(msg: msg)
                }
            }
//            msg.readState = .UnRead
            //刷新会话 信息
//            self.notiDelegates { delegate in
//                delegate.chatManagerAllSeesionUpdate()
//            }
        }
        
    }
    
    // 收到了消息变更
    func onRecvMsgModified(msg: DGCChatMsg, sessionID : String,sessionType : MGChatSessionType, sender:String) {
        callInQueue {
            // 找到当前会话
            if let dgc_index = self.allSessions.firstIndex(where: {$0.sessionID == sessionID}) {
                let dgc_session = self.allSessions[dgc_index]
                dgc_session.recvMsgModified(msg: msg)
            }
        }
    }

}
