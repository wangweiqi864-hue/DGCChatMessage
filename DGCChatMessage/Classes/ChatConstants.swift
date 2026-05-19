//
//  ChatConstants.swift
//  ManGo
//
//  Created by mango on 2024/3/7.
//

import Foundation
import DGCLog

// 会话类型
public enum MGChatSessionType {
    case Un
    case User // 用户对用户
    case Group // 群聊
}

@available(*, deprecated, renamed: "MGChatSessionType")
public typealias DGCChatSessionType = MGChatSessionType


// 消息类型
public enum MGChatMsgType {
    case Un
    case Text // 文本
    case Image // 图片
    case Expression // 表情
    case Voice // 语音
    case Video // 视频
    case Tip // 提示消息
    case Time // 时间消息 
    case Custom // 外部自定义的消息
    case Gift // 礼物
    case GuildInvite // 公会邀请
    case LiveInvite // 房间邀请
    case GiftBag // 活动礼包
    case RelationshipInvite // 关系邀请
    case RelationshipUnbind // 关系解绑相关
    case GiftTipOutRoom //不在房送礼
}

@available(*, deprecated, renamed: "MGChatMsgType")
public typealias DGCChatMsgType = MGChatMsgType
/// 消息拥有者
public enum MGChatMsgOwnerType {
    case Un
    case System // 系统消息  如: tip
    case MySelf // 自己发送的消息
    case Friend // 他人的消息
}

@available(*, deprecated, renamed: "MGChatMsgOwnerType")
public typealias DGCChatMsgOwnerType = MGChatMsgOwnerType

/// 消息发送状态
public enum MGChatMsgSendState {
    case Sending // 发送中
    case OK // 失败
    case Fail // 成功
    case Revoked // 撤回
}

@available(*, deprecated, renamed: "MGChatMsgSendState")
public typealias DGCChatMsgSendState = MGChatMsgSendState

// 消息读取状态
public enum MGChatMsgReadState {
    case UnRead // 未读
    case Readed // 已读
}

@available(*, deprecated, renamed: "MGChatMsgReadState")
public typealias DGCChatMsgReadState = MGChatMsgReadState

// 消息 播放状态
public enum MGChatMsgPlayState {
    case UnPlay // 未播放
    case Played // 已播放
}

@available(*, deprecated, renamed: "MGChatMsgPlayState")
public typealias DGCChatMsgPlayState = MGChatMsgPlayState

// 初始化SDK的配置
public struct MGChatSDKConfig {
    public var appId = String()
    public init(appId: String = String()) {
        self.appId = appId
    }
}

@available(*, deprecated, renamed: "MGChatSDKConfig")
public typealias DGCChatSDKConfig = MGChatSDKConfig


// 空回调
public typealias ChatEmptyBlock = (()->Void)

// 带数据回调
public typealias ChatDataBlock<T> = ((_ data : T)->Void)

// 错误
public typealias ChatFailBlock = ((Int32,String?)->Void)

/// 日志输出
internal func CMLog(_ msg : String, file: String = #file){
    DGCLog.log("IM--\(msg)",file: file)
}


/// 主线程回调
internal func ChatCallInMain(_ block :@escaping (()->Void)) {
    if Thread.isMainThread{
        block()
    }else{
        DispatchQueue.main.async {
            block()
        }
    }
}

extension Array {
    var dgc_count: Int {
        count
    }
}

extension Encoder {
    func dgc_container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        container(keyedBy: type)
    }
}
