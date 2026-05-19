//
//  DGCChatSessionResult.swift
//  Pods
//
//  Created by mango on 2024/3/8.
//

import Foundation

/// 请求返回的会话数据
public struct MGChatSessionResult {
    var list = [DGCChatSession]()
    var page : Int32 = 0
    var isFinished = false

    init() {}

    init(list: [DGCChatSession], page: Int32, isFinished: Bool) {
        self.list = list
        self.page = page
        self.isFinished = isFinished
    }

    init(dgc_list: [DGCChatSession], page: Int32, isFinished: Bool) {
        self.init(list: dgc_list, page: page, isFinished: isFinished)
    }

    var dgc_list: [DGCChatSession] {
        get { list }
        set { list = newValue }
    }

    var dgc_page: Int32 {
        get { page }
        set { page = newValue }
    }

    var dgc_isFinished: Bool {
        get { isFinished }
        set { isFinished = newValue }
    }
}

@available(*, deprecated, renamed: "MGChatSessionResult")
public typealias DGCChatSessionResult = MGChatSessionResult


/// 请求返回的消息数据
public struct MGChatMsgResult {
    var list = [DGCChatMsg]()
    var page : Int32 = 0
    var isFinished = false

    init() {}

    init(list: [DGCChatMsg], page: Int32, isFinished: Bool) {
        self.list = list
        self.page = page
        self.isFinished = isFinished
    }

    init(dgc_list: [DGCChatMsg], page: Int32, isFinished: Bool) {
        self.init(list: dgc_list, page: page, isFinished: isFinished)
    }

    var dgc_list: [DGCChatMsg] {
        get { list }
        set { list = newValue }
    }

    var dgc_page: Int32 {
        get { page }
        set { page = newValue }
    }

    var dgc_isFinished: Bool {
        get { isFinished }
        set { isFinished = newValue }
    }
}

@available(*, deprecated, renamed: "MGChatMsgResult")
public typealias DGCChatMsgResult = MGChatMsgResult
