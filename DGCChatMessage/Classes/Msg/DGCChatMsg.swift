//
//  DGCChatMsg.swift
//  ManGo
//
//  Created by mango on 2024/3/7.
//

import Foundation

// 消息
public class DGCChatMsg {
    
    public internal(set) var mID = String() // 消息ID
    
    public internal(set) var sendID = String() // 发送者ID
    public internal(set) var sendName = String() // 发送者昵称
    public internal(set) var sendIcon = String() // 发送者头像
    
    public internal(set) var friendID = String() // 接收者ID 单聊有值, 群聊时候为空
    
    public internal(set) var sessionID = String() // 会话ID
    
    public internal(set) var sessionType = MGChatSessionType.Un // 消息所属会话类型
    
    public internal(set) var type = MGChatMsgType.Un // 消息类型
    
    public internal(set) var ownerType = MGChatMsgOwnerType.Un // 消息发送类型
    
    public internal(set) var sendState = MGChatMsgSendState.OK // 消息发送状态
    
    public internal(set) var readState = MGChatMsgReadState.UnRead // 消息读取状态
    
    public internal(set) var isLocal : Bool = false // 是否是本地存储的消息
    
    public internal(set) var playState = MGChatMsgPlayState.UnPlay // 消息 播放状态 主要用于音频和礼物
    
    // 发送进度 发送文件时才有
    public internal(set) var progress : CGFloat = 0{
        didSet{
            if let sendProgressBlock = sendProgressBlock {
                ChatCallInMain {
                    sendProgressBlock(self.progress)
                }
            }
        }
    }
    //发送进度回调
    public var sendProgressBlock : ChatDataBlock<CGFloat>?
    
    // 时间
    public internal(set) var time : TimeInterval = 0
    
    
    public var coustom : [String:Any] = [:] // 自定义的数据 外部透传
    
    /// 自定义的数据 保存在消息中
    public var cloudCustomData : DGCChatMsgCloudCustomData? // 自定义数据 云端
    public var localCustomData : DGCChatMsgLocalCustomData? // 自定义数据 本地
    
    
    init() {}
    
    // 设置消息为已播放
    public func setMsgPlayedState() {
        self.playState = .Played
        DGCChatManager.share.dgc_handler.setMsgPlayStatus(mId: mID, success: nil, fail: nil)
    }
    
    // 变更消息
    func notiModifiedMsg(msg: DGCChatMsg) {
        self.cloudCustomData = msg.cloudCustomData
//        self.localCoustomData.isShowNeedGold = msg.localCoustomData.isShowNeedGold
    }
    
    /// 修改消息
    public func modifyMessage() {
        DGCChatManager.share.dgc_handler.modifyMessage(msg: self) {
            
        } fail: { code, str in
            
        }

    }
}

public enum MGChatCloudCustomDataType: Int, Codable {
    case CCDT_NIL = 0
    case CCDT_QUICK_MSG = 1 // 快捷发消息, customContent为快捷消息的id
    case CCDT_HIDE = 2 // 2:隐藏的图片或者视频消息标记, 模糊处理 -- 1.4.10版本去掉了
    case CCDT_SAY_HI = 3 // 3:sayhi消息
    case CCDT_PAID_MEDIA = 4  // 付费可见高清消息
}

@available(*, deprecated, renamed: "MGChatCloudCustomDataType")
public typealias DGCChatCloudCustomDataType = MGChatCloudCustomDataType

public enum MGChatSystemCloudCustomDataType: Int, Codable {
    case SCCDT_NIL = 0
    case SCCDT_HELLO = 1 // 1:自动打招呼消息
    case SCCDT_CUPID_MATCH = 2 // 2:爱神推荐消息
    case SCCDT_IM_PAYMENT = 3 // 3:im付费消息（只会标记第一条）
}

@available(*, deprecated, renamed: "MGChatSystemCloudCustomDataType")
public typealias DGCChatSystemCloudCustomDataType = MGChatSystemCloudCustomDataType


public enum MGRelationshipStatus : Int32, Codable{
    case un
    case accept = 1 // 同意
    case reject = 4 // 拒绝
    case expiration = 5 // 过期
}

@available(*, deprecated, renamed: "MGRelationshipStatus")
public typealias DGCRelationshipStatus = MGRelationshipStatus

/// 自定义云消息
public class DGCChatMsgCloudCustomData : Codable{
    /// 类型 1:快捷发消息 2:隐藏的图片或者视频
    public var custom_type: MGChatCloudCustomDataType?
    /// 内容 没有则传空
    public var custom_content: String?
    /// 特权 ID
    public var userPrivilegeConfID: [Int64]?
    /// 头像框配置文案
    public var privilegeData: String?
    /// 群聊邀请是否已经点击了
    public var isJoin : Bool?
    // IM付费信息（免费则返回空值）
//    public var payment_info : IMChatPaymentInfo?
    /// 是否是回复爱神推荐消息
    public var is_reply_cupid_match : Bool?
    // 服务端标记的消息类型
    public var sys_custom_type: MGChatSystemCloudCustomDataType?
    // 透传msg_key
    public var msg_key : String?
    
    /// 关系邀请状态
    public var relationshipStatus = MGRelationshipStatus.un
    
    // IM付费视频或者照片
//    public var paid_media_info : IMPaidMediaInfo?
    
    public init() {}
}

/// 自定义本地消息
public class DGCChatMsgLocalCustomData : Codable{
    
    public init() {}
}
