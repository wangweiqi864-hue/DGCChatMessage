//
//  DGCChatUserSession.swift
//  Pods
//
//  Created by mango on 2024/3/7.
//

import Foundation

// 私聊会话
public class DGCChatUserSession: DGCChatSession {
    
    public internal(set) var sendID = String() // 发送者ID
    public var sendName = String() // 名称
    public var sendIcon = String() // 头像
    
    public internal(set) var friendID = String() // 对方ID
    public var friendName = String() // 对方昵称
    public var friendIcon = String() // 对方头像
    
    override init(sessionID: String) {
        super.init(sessionID: sessionID)
        type = .User
        //单聊消息 组成c2c_xxx
        friendID = sessionID.replacingOccurrences(of: "c2c_", with: "")
        sendID = manager.getUserId()
    }
    
    override func sendBeforeInsertMsgToList(msg: DGCChatMsg) {
        msg.sendID = sendID
        msg.friendID = friendID
        super.sendBeforeInsertMsgToList(msg: msg)
    }
}
