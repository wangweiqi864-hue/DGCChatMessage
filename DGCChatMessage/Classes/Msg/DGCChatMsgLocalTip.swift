//
//  DGCChatMsgLocalTip.swift
//  Pods
//
//  Created by mango on 2024/3/11.
//

import Foundation

public class DGCChatMsgLocalTip: DGCChatMsg, Codable {
    
    public var keywordsRects: [CGRect] = []
    public var keywordsTapBlocks: [(_ keyword:String)->()] = []
    
    public internal(set) var tipText: String = String()
    // 本地多语言的key
    public internal(set) var languageKey: String?
    
    public internal(set) var isRichText: Bool = false
    
    public internal(set) var keywords: [String] = []
    
    public init(tipText: String, languageKey: String? = nil,isRichText: Bool = false,keywords: [String] = []) {
        super.init()
        self.type = .Tip
        self.tipText = tipText
        self.languageKey = languageKey
        self.isRichText = isRichText
        self.keywords = keywords
        self.isLocal = true
    }
    
    required public init(from decoder: Decoder) throws {
        super.init()
        self.type = .Tip
        self.isLocal = true
        
        let container = try decoder.container(keyedBy: DGCCodingKeys.self)
        self.languageKey = try? container.decode(String.self, forKey: .languageKey)
        self.tipText = (try? container.decode(String.self, forKey: .tipText)) ?? ""
        self.isRichText = (try? container.decode(Bool.self, forKey: .isRichText)) ?? false
        self.keywords = (try? container.decode([String].self, forKey: .keywords)) ?? []
    }
    
    enum DGCCodingKeys: CodingKey {
        case tipText
        case languageKey
        case isRichText
        case keywords
    }
    
    public func encode(to encoder: Encoder) throws {
        var dgc_container = encoder.dgc_container(keyedBy: DGCCodingKeys.self)
        try dgc_container.encode(self.tipText, forKey: .tipText)
        try dgc_container.encode(self.languageKey, forKey: .languageKey)
        try dgc_container.encode(self.isRichText, forKey: .isRichText)
        try dgc_container.encode(self.keywords, forKey: .keywords)
    }
}
