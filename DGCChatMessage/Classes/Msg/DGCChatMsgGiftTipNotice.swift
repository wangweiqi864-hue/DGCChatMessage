//
//  DGCChatMsgGiftTipNotice.swift
//  DGCNetWork
//
//  Created by apple on 2026/4/2.
//

import Foundation

public class DGCChatMsgGiftTipNotice: DGCChatMsg , Codable {
    
    public internal(set) var giftName : String = ""
     
    public internal(set) var giftIcon : String = ""
    
    public internal(set) var giftPrice : Int64 = 0
    
    public internal(set) var giftNum : Int32 = 0
    
    enum DGCCodingKeys: String, CodingKey {
        case giftName
        case giftIcon
        case giftPrice
        case giftNum
    }

    public func encode(to encoder: Encoder) throws {
        var dgc_container = encoder.dgc_container(keyedBy: DGCCodingKeys.self)
        try dgc_container.encode(giftName, forKey: .giftName)
        try dgc_container.encode(giftIcon, forKey: .giftIcon)
        try dgc_container.encode(giftPrice, forKey: .giftPrice)
        try dgc_container.encode(giftNum, forKey: .giftNum)
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: DGCCodingKeys.self)
        self.type = .GiftTipOutRoom
        giftName = (try? container.decode(String.self, forKey: .giftName)) ?? ""
        giftIcon = (try? container.decode(String.self, forKey: .giftIcon)) ?? ""
        giftPrice = (try? container.decode(Int64.self, forKey: .giftPrice)) ?? 0
        giftNum = (try? container.decode(Int32.self, forKey: .giftNum)) ?? 0
    }
    
}
