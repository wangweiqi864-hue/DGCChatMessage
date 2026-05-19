//
//  DGCChatTencentHandler+Session.swift
//  Pods
//
//  Created by mango on 2024/3/8.
//

import Foundation
import ImSDK_Plus

extension DGCChatTencentHandler {
    
    func getSessionList(page: Int32, count: Int32, success: @escaping ChatDataBlock<MGChatSessionResult>, fail: @escaping ChatFailBlock) {
        if page == 0{//重新获取
            nextSeq = 0
        }//加载更多
        let dgc_currNextSeq = nextSeq
        manger.getConversationList(dgc_currNextSeq, count: count) {[weak self] dgc_list, nextSeq, isFinished in
            if let self = self{
                DispatchQueue.global().async {
                    self.nextSeq = nextSeq
                    let dgc_list = dgc_list?.map({DGCChatSession.map($0)}) ?? []
                    success(MGChatSessionResult(dgc_list: dgc_list,page: page,isFinished: isFinished))
                }
            }
        } fail: { code, msg in
            CMLog("获取会话列表失败--\(code)---\(msg ?? "")")
            fail(code,msg ?? "")
        }
    }
    
}


extension DGCChatSession{
    
    static func map(_ conversation : V2TIMConversation) -> DGCChatSession {
        let dgc_session : DGCChatSession!
        let dgc_cID = conversation.conversationID ?? ""
        
        if conversation.type == .C2C{
            let dgc_newSession = DGCChatUserSession(sessionID: dgc_cID)
            dgc_newSession.friendID = conversation.userID ?? ""
            dgc_session = dgc_newSession
        }else{
            dgc_session = DGCChatSession(sessionID: dgc_cID)
        }
        dgc_session.unReadCount = conversation.unreadCount
        if let dgc_lastMsg = conversation.lastMessage{//存在最后一条消息
            dgc_session.tencentLastMsg = dgc_lastMsg
            dgc_session.lastMsg = DGCChatMsg.map(message: dgc_lastMsg) // 可能会导致 最后一条消息没有 会话id
        }
        return dgc_session
        
    }
    
    /// 保存会话最后一条消息  获取消息列表时需要用到
    var tencentLastMsg : V2TIMMessage? {
        get{
            self.custom["TencentLastMsgKey"] as? V2TIMMessage
        }
        set{
            self.custom["TencentLastMsgKey"] = newValue
        }
    }
    
}
