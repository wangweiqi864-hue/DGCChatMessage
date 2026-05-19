//
//  DGCChatMsgLiveInvite.swift
//  DGCChatMessage
//
//  Created by Macxx on 2024/11/14.
//

import Foundation

public class DGCChatMsgLiveInvite: DGCChatMsg , Codable {
    
    public internal(set) var roomId : Int64 = 0
    public internal(set) var name = ""
    public internal(set) var icon = ""
    public internal(set) var patternType: Int = 0 // 房间模式
    public internal(set) var roomId2: Int64 = 0 // 房间靓号
    public internal(set) var roomId2Eid: Int64 = 0 // 房间靓号
//
//    //是玩法或者生日派对这些的话
//    public var gameName = ""
//    public var gameIcon = ""
    
    public init(roomId: Int64, name: String, icon: String, patternType: Int,roomId2 : Int64,roomId2Eid : Int64) {
        super.init()
        self.roomId = roomId
        self.name = name
        self.icon = icon
        self.patternType = patternType
        self.roomId2 = roomId2
        self.roomId2Eid = roomId2Eid
        type = .LiveInvite
    }
    
    enum DGCCodingKeys: String, CodingKey {
        case roomId
        case name
        case icon
        case patternType
        case roomId2
        case roomId2Eid
//        case gameName
//        case gameIcon
    }

    public func encode(to encoder: Encoder) throws {
        var dgc_container = encoder.dgc_container(keyedBy: DGCCodingKeys.self)
        try dgc_container.encode(roomId, forKey: .roomId)
        try dgc_container.encode(roomId2, forKey: .roomId2)
        try dgc_container.encode(roomId2Eid, forKey: .roomId2Eid)
        try dgc_container.encode(name, forKey: .name)
        try dgc_container.encode(icon, forKey: .icon)
        try dgc_container.encode(patternType, forKey: .patternType)
//        try dgc_container.encode(gameName, forKey: .gameName)
//        try dgc_container.encode(gameIcon, forKey: .gameIcon)
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: DGCCodingKeys.self)
        self.type = .LiveInvite
        roomId = (try? container.decode(Int64.self, forKey: .roomId)) ?? 0
        roomId2 = (try? container.decode(Int64.self, forKey: .roomId2)) ?? 0
        roomId2Eid = (try? container.decode(Int64.self, forKey: .roomId2Eid)) ?? 0
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        icon = (try? container.decode(String.self, forKey: .icon)) ?? ""
        patternType = (try? container.decode(Int.self, forKey: .patternType)) ?? 0
//        gameIcon = (try? container.decode(String.self, forKey: .gameIcon)) ?? ""
//        gameName = (try? container.decode(String.self, forKey: .gameName)) ?? ""
    }
}
