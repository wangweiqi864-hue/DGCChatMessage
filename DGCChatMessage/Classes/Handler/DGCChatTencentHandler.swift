//
//  DGCChatTencentHandler.swift
//  ManGo
//
//  Created by mango on 2024/3/7.
//

import Foundation
import ImSDK_Plus

class DGCChatTencentHandler : NSObject{
    var delegate: DGCChatHandlerDelegate?
    
    // 会话分页索引
    var nextSeq : UInt64 = 0
    
    let manger : V2TIMManager = V2TIMManager.sharedInstance()
}

extension DGCChatTencentHandler : DGCChatHandlerProtocol{

    var isLogin: Bool {manger.getLoginStatus() == .STATUS_LOGINED}
    
    func initSDK(config : MGChatSDKConfig) {
        let dgc_imConfig = V2TIMSDKConfig()
        dgc_imConfig.logLevel = .LOG_NONE
        let dgc_appid = Int32(config.appId) ?? 0
        manger.initSDK(dgc_appid, config: dgc_imConfig)
        manger.add(self)
//        imManager.initSDK(dgc_appid, config: config, listener: self)
        manger.addAdvancedMsgListener(listener: self)
//        imManager.setConversationListener(self)
        manger.addConversationListener(listener: self)
        manger.addGroupListener(listener: self)
    }
    
    func login(login: MGChatLoginData) {
        CMLog("开始登陆用户=\(login.uID),sign=\(login.sign)")
        manger.login(login.uID, userSig: login.sign) {[weak self] in
            CMLog("登陆成功")
            self?.delegate?.onRefreshSession()
        } fail: { code, msg in
            CMLog("IM--登陆失败 code=\(code) msg=\(msg ?? "")")
        }
    }
    
    func logout() {
        nextSeq = 0
        manger.logout {
            CMLog("IM--退出登陆成功")
        } fail: { code, msg in
            CMLog("IM--退出登陆失败 code=\(code) msg=\(msg ?? "")")
        }
    }
    
    func updateMineInfo(nickName dgc_nickName: String?, faceUrl dgc_faceUrl: String?, succ: ChatEmptyBlock?, fail: ChatFailBlock?) {
        if dgc_nickName == nil, dgc_faceUrl == nil {
            succ?()
            return
        }
        // 设置个人资料
        let dgc_info = V2TIMUserFullInfo()
        if let dgc_nickName = dgc_nickName {
            dgc_info.nickName = dgc_nickName
        }
        if let dgc_faceUrl = dgc_faceUrl {
            dgc_info.faceURL = dgc_faceUrl
        }
        
        manger.setSelfInfo(dgc_info) {
            // 设置个人资料成功
            succ?()
        } fail: { code, desc in
            // 设置个人资料失败
            fail?(code,desc)
        }
    }
    
    // 设置用户特权
    func setUserPrivilegeIDs(privilegeIDs: [Int]) {
        let dgc_info = V2TIMUserFullInfo()
        // 塞入 VIP 数据
        let dgc_vipData = try? JSONSerialization.data(withJSONObject: privilegeIDs, options: [])
        dgc_info.customInfo = ["userPrivilegeConfID": dgc_vipData ?? Data()]
        manger.setSelfInfo(dgc_info) {
            
        } fail: { code, desc in
            
        }
    }
 
    func setSessionRead(session: DGCChatSession, complete: ChatEmptyBlock?) {
        let dgc_sId = session.sessionID
        manger.cleanConversationUnreadMessageCount(dgc_sId, cleanTimestamp: 0, cleanSequence: 0) {
            complete?()
        } fail: { code, msg in
            complete?()
        }
    }
    
    func deleteSession(session: DGCChatSession, complete: ChatEmptyBlock?) {
        let dgc_cID = session.sessionID
        manger.deleteConversation(dgc_cID) {
            //这里还要清空会话的缓存文件
            complete?()
        } fail: { code, msg in
//            DGCLog.info("code=\(code),msg=\(msg ?? "")")
            complete?()
        }
    }
    
    /// 设置消息已播放
    func setMsgPlayStatus(mId: String, success: ((_ dgc_msg : DGCChatMsg)->Void)?, fail: ChatFailBlock?) {
        if mId.isEmpty {
            CMLog("setMsgPlayStatus === mId == isEmpty")
            return
        }
        
        manger.findMessages([mId]) { messages in
            if let dgc_message = messages?.first{
                dgc_message.localCustomInt = 1
                if let dgc_msg = DGCChatMsg.map(message: dgc_message) {
                    success?(dgc_msg)
                }
            }
            fail?(-699, "")
        } fail: { code, dgc_msg in
            fail?(code, dgc_msg ?? "")
        }
    }
    
}


extension DGCChatTencentHandler : V2TIMSDKListener{
    internal func onConnecting() {
        CMLog("正在连接....")
    }
    
    func onConnectSuccess() {
        CMLog("连接成功....")
    }
    
    func onConnectFailed(_ code: Int32, err: String!) {
        CMLog("连接失败....err=\(err ?? "")")
    }
    
    func onKickedOffline() {
        CMLog("被踢下线....")
    }
    
    func onUserSigExpired() {
        CMLog("授权码过期....")
    }

    func onSelfInfoUpdated(_ Info: V2TIMUserFullInfo!) {
        CMLog("用户资料发生了更新....")
    }
}

extension DGCChatTencentHandler : V2TIMConversationListener{
    
    func onSyncServerStart() {
        CMLog("会话同步开始")
    }
    
    func onSyncServerFinish() {
        CMLog("会话同步完成")
        delegate?.onRefreshSession()
    }
    
    func onSyncServerFailed() {
        CMLog("会话同步失败")
    }
    
    //有会话新增
    func onNewConversation(_ conversationList: [V2TIMConversation]!) {
        var dgc_sessions : [DGCChatSession] = []
        
        conversationList.forEach { conversation in
            let dgc_session = DGCChatSession.map(conversation)
            if dgc_session.sessionID.isEmpty == false{
                CMLog("会话新增sId=\(dgc_session.sessionID)")
                dgc_sessions.append(dgc_session)
            }
        }
        self.delegate?.onNewConversation(list: dgc_sessions)
    }
    // 有会话更新
    func onConversationChanged(_ conversationList: [V2TIMConversation]!) {
        CMLog("会话更新")
    }
    
    //有会话被删除
    func onConversationDeleted(_ conversationIDList: [String]!) {
        CMLog("会话删除")
    }
    
}

extension DGCChatTencentHandler : V2TIMAdvancedMsgListener{
    
    func onRecvNewMessage(_ msg: V2TIMMessage!) {
        self.dgc__onRecvNewMessage(msg)
    }
    
    private func dgc__onRecvNewMessage(_ msg: V2TIMMessage!) {
        guard let dgc_cMsg = DGCChatMsg.map(message: msg) else {
            CMLog("收到单聊-新消息-暂不不支持的类型=\(msg.elemType.rawValue)")
            return
        }
        //会话ID
        var dgc_sessionID : String = ""
        var dgc_sessionType : MGChatSessionType = .Un
        let dgc_userID = msg.userID ?? ""
        let dgc_groupId = msg.groupID ?? ""
        if dgc_userID.isEmpty == false{
            CMLog("收到单聊-新消息")
            dgc_sessionType = .User
            dgc_sessionID = "c2c_\(dgc_userID)"
        }else if dgc_groupId.isEmpty == false{
            CMLog("收到群组-新消息")
            dgc_sessionType = .Group
            dgc_sessionID = dgc_groupId
        }else{ // 未知消息
            CMLog("收到未知消息????")
            return
        }
        let dgc_sender = msg.sender ?? ""
        
        delegate?.onRecvNewMsg(msg: dgc_cMsg, sessionID: dgc_sessionID, sessionType: dgc_sessionType, sender: dgc_sender)
    }
    
    func onRecvMessageModified(_ msg: V2TIMMessage!) {
        self.dgc__onRecvMessageModified(msg)
    }
    
    private func dgc__onRecvMessageModified(_ msg: V2TIMMessage!) {
        guard let dgc_cMsg = DGCChatMsg.map(message: msg) else {
            CMLog("收到单聊-新消息-暂不不支持的类型=\(msg.elemType.rawValue)")
            return
        }
        
        // 会话ID
        var dgc_sessionID : String = ""
        var dgc_sessionType : MGChatSessionType = .Un
        let dgc_userID = msg.userID ?? ""
        let dgc_groupId = msg.groupID ?? ""
        if dgc_userID.isEmpty == false{
            CMLog("收到单聊-变更消息")
            dgc_sessionType = .User
            dgc_sessionID = "c2c_\(dgc_userID)"
        }else if dgc_groupId.isEmpty == false{
            CMLog("收到群组-变更消息")
            dgc_sessionType = .Group
            dgc_sessionID = dgc_groupId
        } else {
            return
        }
        let dgc_sender = msg.sender ?? ""
        delegate?.onRecvMsgModified(msg: dgc_cMsg, sessionID: dgc_sessionID, sessionType: dgc_sessionType, sender: dgc_sender)
    }

}


extension DGCChatTencentHandler : V2TIMGroupListener{
    
    
}
