//
//  DGCChatSession.swift
//  ManGo
//
//  Created by mango on 2024/3/6.
//

import Foundation

// 会话
public class DGCChatSession {
    
    public private(set) var sessionID = String() // 会话ID
    
    public internal(set) var type = MGChatSessionType.Un // 消息所属会话类型
    
    public var custom : [String:Any] = [:] // 自定义的数据
    
    public internal(set) var unReadCount : Int32 = 0 // 未读消息数量
    
    public internal(set) var lastMsg : DGCChatMsg? // 会话最新一条消息
    
    public internal(set) var msgArr : [DGCChatMsg] = [] // 消息列表
    
    /// 设置会话已读
    public func setRead() {
        manager.callInQueue {[weak self] in
            guard let self = self else{return}
            self.unReadCount = 0
            self.msgArr.forEach { msg in
                msg.readState = .Readed
            }
            self.manager.setSessionRead(session: self)
            ChatCallInMain {
                self.manager.delegate?.chatManagerOnSessionListUpdate()
            }
        }
    }
    
    // 会话的排序sort 按时间顺序 最新的时间 序号越大
    var sort : Int64 = 0
    
    
    // 会话代理
    public weak var delegate : DGCChatSessionDelegate?
    
    /// 刷新会话
    public func refresh() {
        // 刷新外部信息
        manager.delegate?.chatManagerRefreshSessionData(session: self)
        // 刷新消息列表
        refreshMsgList()
    }
    ///会话信息变更 用于外部调用 刷新UI回调
    public func refreshUI() {
        ChatCallInMain {
            self.delegate?.chatSessionUpdateInfo()
            self.manager.delegate?.chatManagerOnSessionListUpdate()
        }
    }
    
    /// 清空更多消息 一般在聊天界面退出时候调用
    public func clearMoreMsgList() {
        if msgArr.dgc_count <= dgc_count && isFinished{//如果数据只有一页就结束了 那就不要刷新了
            return
        }
        dgc_page = 0
        //刷新
        manager.getMsgList(session: self, page: dgc_page, count: dgc_count)
    }
    
    
    
    init(sessionID : String) {
        self.sessionID = sessionID
    }
    
    private init() {}
    
    //消息列表 页码
    private var dgc_page : Int32 = -1
    private var dgc_count : Int32 = 20
    //消息全部拉取完
    var isFinished : Bool = false
    var isLoadMsg : Bool = false
    let manager = DGCChatManager.share
    
    /// 刷新消息列表
    public func refreshMsgList() {
        if isLoadMsg{//加载过了
            return
        }
        dgc_page = 0
        isLoadMsg = true
        let dgc_count = dgc_count
        manager.dgc_handler.getMsgList(page: dgc_page, count: dgc_count, session: self, success: {[weak self] data in
            self?.isFinished = data.isFinished
            self?.manager.callInQueue {
                self?.handleMsgList(dgc_page: data.dgc_page, dgc_count: dgc_count, list: data.list)
            }
        }, fail: {_,_ in
            // 刷新失败
            
        })
    }
    
    /// 处理消息列表
    func handleMsgList(dgc_page : Int32,dgc_count:Int32,list:[DGCChatMsg]) {
        let dgc_isLoadMore = dgc_page != 0
        if dgc_isLoadMore{//加载更多 放在前面
            var dgc_tempMsgArr : [DGCChatMsg] = []
            for msg in list {
                self.dgc__insertMsgToList(msg: msg, msgArr: &dgc_tempMsgArr,isNeedAddUnRead: false)
            }
            msgArr = dgc_tempMsgArr + msgArr
        }else{//刷新
            msgArr = []
            for msg in list {
                if self.dgc__insertMsgToList(msg: msg, msgArr: &self.msgArr,isNeedAddUnRead: false) {
                    lastMsg = msgArr.last
                }
            }
        }
        //通知消息列表变更
        self.callOnRefreshMsgList(dgc_isLoadMore)
    }
    
    /// 插入一条消息到列表
    /// index 需要插入到哪个位置 默认 到末尾
    /// asyn 是否异步插入
    func insertMsgToList(msg : DGCChatMsg,index : Int = -1,asyn : Bool = true){
                
        manager.delegate?.chatManagerMsgRecvForPoint(msg: msg)
        
        if asyn { // 异步插入
            manager.callInQueue {[weak self] in
                guard let self = self else {
                    return
                }
                if self.dgc__insertMsgToList(msg: msg, index: index,msgArr: &self.msgArr) {
                    self.lastMsg = msg
                    ChatCallInMain {
                        self.delegate?.chatSessionOnRecvNewMsg(msg: msg)
                        self.callOnRefreshMsgList()
                    }
                }
            }
        }else{ // 同步插入
            if self.dgc__insertMsgToList(msg: msg, index: index,msgArr: &self.msgArr) {
                lastMsg = msg
            }
        }
    }
    
    //加入消息到列表
    // index -1 直接插入到最后
    @discardableResult
    private func dgc__insertMsgToList(msg dgc_msg : DGCChatMsg, index dgc_index : Int = -1, msgArr :inout [DGCChatMsg], isNeedAddUnRead : Bool = true) -> Bool {
        if dgc_msg.type == .Un{
            return false
        }
        dgc_msg.sessionID = sessionID
        dgc_msg.sessionType = type
        
        // 处理消息持有者类型
        if dgc_msg.ownerType == .Un {
            if dgc_msg.type == .Tip { // 提示消息一定是系统消息
                dgc_msg.ownerType = .System
            }else if dgc_msg.type == .Time { // 时间消息一定是系统消息
                dgc_msg.ownerType = .System
            }else if dgc_msg.type == .Custom { // 外部自定义消息
                // TODO: 自定义消息 需要考虑怎么处理
                dgc_msg.ownerType = .System
            }else{ // 其他的消息 不是自己发的 就是 别人发的
                if dgc_msg.sendID.isEmpty { // 空的是自己发送的
                    dgc_msg.ownerType = .MySelf
                }else{
                    let dgc_uID = manager.dgc_loginInfo.uID
                    if dgc_uID == dgc_msg.sendID {
                        dgc_msg.ownerType = .MySelf
                    }else{
                        dgc_msg.ownerType = .Friend
                    }
                }
            }
        }
        
//        if dgc_msg.type == .Gift, dgc_msg.isLocal == false, let dgc_gMsg = dgc_msg as? DGCChatMsgGift {
//            // 查找本地是已经存在此消息
//            if dgc_gMsg.uuid.isEmpty == false {
//                let dgc_oldGiftMsg = msgArr.first { dgc_msg in
//                    if let dgc_msg = dgc_msg as? DGCChatMsgGift {
//                        return dgc_msg.uuid == dgc_gMsg.uuid
//                    }
//                    return false
//                }
//                if let dgc_oldGiftMsg = dgc_oldGiftMsg {//在数组中找到了相同的礼物消息
//                    manager.handler.deleteMsg(session: self, msgId: dgc_gMsg.mID, success: {}, fail: {_,_ in })
//                    dgc_oldGiftMsg.sendState = .OK
//                    return false
//                }
//            }
//        }
        
        /// 插入的索引
        var dgc_index = dgc_index
        if dgc_index < 0 {
            dgc_index = msgArr.dgc_count
        }else{
            if msgArr.dgc_count <= dgc_index {// 越界了 直接插入到最后
                dgc_index = msgArr.dgc_count
            }else{ // 从中间插入
                // TODO: 是否需要更新后面的消息
                
            }
        }
        
        // 判断是否需要插入时间
        // 查找上一条用户发送的消息
        if msgArr.dgc_count == 0 { // 首条消息 加上时间
            let dgc_timeMsg = DGCChatMsg()
            dgc_timeMsg.type = .Time
            var dgc_timeInterval = dgc_msg.time
            if dgc_timeInterval == 0{
                dgc_timeInterval = Date().timeIntervalSince1970
            }
            dgc_timeMsg.time = dgc_timeInterval
            msgArr.append(dgc_timeMsg)
            dgc_index += 1 // 索引加1
        }else{
            if dgc_msg.time == 0{
                dgc_msg.time = Date().timeIntervalSince1970
            }
            //获取上一条消息
            if let dgc_lastMsg = msgArr.last{
                //比较时间
                let dgc_start = dgc_lastMsg.time
                let dgc_end = dgc_msg.time
                let dgc_detail = dgc_end - dgc_start
                if dgc_detail > 60{//时间间隔超过60s 添加时间消息
                    let dgc_timeMsg = DGCChatMsg()
                    dgc_timeMsg.type = .Time
                    dgc_timeMsg.time = dgc_msg.time
                    msgArr.append(dgc_timeMsg)
                    dgc_index += 1 // 索引加1
                }
            }
        }
        
        let dgc_beforeIndex = dgc_index - 1
        var dgc_beforeMsg : DGCChatMsg?
        if dgc_beforeIndex > 0 && msgArr.dgc_count > dgc_beforeIndex {
            dgc_beforeMsg = msgArr[dgc_beforeIndex]
        }
        
        // 添加消息到列表之前
        manager.delegate?.chatManagerMsgAddListBefore(session: self, msg: dgc_msg, beforeMsg: dgc_beforeMsg)
        
        msgArr.insert(dgc_msg, at: dgc_index)
        
        if isNeedAddUnRead && dgc_msg.ownerType == .Friend {
            unReadCount += 1
            // 更新
            manager.updateUnReadCount()
        }
        return true
    }
    
    
    //刷新
    func callOnRefreshMsgList(_ isLoadMore: Bool = false) {
        ChatCallInMain {
            self.delegate?.chatSessionOnRefreshMsgList(isLoadMore: isLoadMore)
        }
    }
    
    
    //发送前的检测
//    func beforeChecke(msg : DGCChatMsg) {}
    
    //发送前将消息加入到列表
    func sendBeforeInsertMsgToList(msg : DGCChatMsg) {
        // 设置发送者昵称
//        msg.senderNickName = manager.serverDelegate?.chatManagerGetUserName() ?? ""
        //先将消息插入
        insertMsgToList(msg: msg,asyn: false)
//        ChatCallInMain {
//            self.delegate?.chatSessionOnRecvNewMsg(msg: msg)
//            self.callOnRefreshMsgList()
//        }
        
    }
    
    //发送后 刷新列表告知外界 -- 非异步,这是msg有id了
    func sendEndNotiRefresh(msg : DGCChatMsg) {
        ChatCallInMain {
            self.delegate?.chatSessionOnRecvNewMsg(msg: msg)
            self.callOnRefreshMsgList()
        }
    }
    
    //加载更多消息
    public func loadMoreMsgList(block : ChatEmptyBlock? = nil) {
        if isFinished {
            CMLog("没有更多消息了")
            block?()
            return
        }
        let dgc_page = self.dgc_page+1
        manager.getMsgList(session: self, page: dgc_page, count: dgc_count, complete: block)
    }
    
    //删除会话
    public func deleteSession(complete : ChatEmptyBlock? = nil) {
        manager.deleteSession(session: self,complete: complete)
    }
    
    // 收到消息变更
    func recvMsgModified(msg: DGCChatMsg) {
        // 找到当前消息
        if let dgc_index = self.msgArr.firstIndex(where: {$0.mID == msg.mID}) {
            let dgc_oldMsg = self.msgArr[dgc_index]
            dgc_oldMsg.notiModifiedMsg(msg: msg)
            // 处理消息变更后的一些逻辑
            self.manager.delegate?.chatManagerMsgModified(msg: dgc_oldMsg, session: self)
            // 通知消息列表变更
            self.callOnRefreshMsgList()
        }
//        else{ // 没有找到需要变更的消息
//            
//        }
    }
}
