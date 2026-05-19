//
//  DGCChatMsgGuildInvite.swift
//  Pods
//
//  Created by mango2333 on 2024/11/8.
//

import Foundation

public class DGCChatMsgGuildInvite: DGCChatMsg , Codable {
    
    public internal(set) var guildId : Int64 = 0
    public internal(set) var name = ""
    public internal(set) var icon = ""
    
    public init(guildId : Int64,name : String,icon : String) {
        super.init()
        self.guildId = guildId
        self.name = name
        self.icon = icon
        type = .GuildInvite
    }
    
    enum DGCCodingKeys: String, CodingKey {
        case guildId
        case name
        case icon
    }

    public func encode(to encoder: Encoder) throws {
        var dgc_container = encoder.dgc_container(keyedBy: DGCCodingKeys.self)
        try dgc_container.encode(guildId, forKey: .guildId)
        try dgc_container.encode(name, forKey: .name)
        try dgc_container.encode(icon, forKey: .icon)
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: DGCCodingKeys.self)
        self.type = .GuildInvite
        guildId = (try? container.decode(Int64.self, forKey: .guildId)) ?? 0
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        icon = (try? container.decode(String.self, forKey: .icon)) ?? ""
    }
}
