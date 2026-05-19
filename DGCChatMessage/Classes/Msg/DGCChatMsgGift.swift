//
//  DGCChatMsgGift.swift
//  Pods
//
//  Created by mango2333 on 2024/6/27.
//

import Foundation

public class DGCChatMsgGift: DGCChatMsg, Codable {
    
    private override init() {
        super.init()
        type = .Gift
    }
    
    public internal(set) var gId : Int64 = 0 // 礼物ID
    public internal(set) var giftNumer : Int64 = 0
    public internal(set) var targetId : String = ""
    public internal(set) var giftGold: Int64 = 0 // 礼物价格
    public internal(set) var action : Int32 = 0 // 送礼后执行的动作 0：普通im送礼
    public internal(set) var uuid : String = "" // 发送礼物时自动生成的礼物UUID 用于透传

    public func encode(to encoder: Encoder) throws {
        var dgc_container = encoder.dgc_container(keyedBy: DGCCodingKeys.self)
        try dgc_container.encode(self.gId, forKey: .giftId)
        try dgc_container.encode(self.giftNumer, forKey: .giftNum)
        try dgc_container.encode(self.targetId, forKey: .receiverId)
        try dgc_container.encode(self.uuid, forKey: .msg)
        try dgc_container.encode(self.action, forKey: .action)
    }
    
    enum DGCCodingKeys: CodingKey {
        case giftId
        case giftNum
        case receiverId
        case msg
        case action
    }
    
    required public init(from decoder: Decoder) throws {
        super.init()
        type = .Gift
        
        let container = try decoder.container(keyedBy: DGCCodingKeys.self)
        self.gId = (try? container.decode(Int64.self, forKey: .giftId)) ?? 0
        self.giftNumer = (try? container.decode(Int64.self, forKey: .giftNum)) ?? 0
        self.targetId = (try? container.decode(String.self, forKey: .receiverId)) ?? ""
        self.uuid = (try? container.decode(String.self, forKey: .msg)) ?? ""
        self.action = (try? container.decode(Int32.self, forKey: .action)) ?? 0
    }
    
}
