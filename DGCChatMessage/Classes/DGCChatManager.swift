//
//  DGCChatManager.swift
//  ManGo
//
//  Created by mango on 2024/3/6.
//

import Foundation

/// 登录的数据
public struct MGChatLoginData {
    var uID : String = "" //用户ID
    var sign : String = "" //授权码 目前tx需要
    
    public init(uID: String, sign: String) {
        self.uID = uID
        self.sign = sign
    }
    init() {}
}

@available(*, deprecated, renamed: "MGChatLoginData")
public typealias DGCChatLoginData = MGChatLoginData

/// 监听者
@objc public protocol DGCChatManagerObserver {
    
}

// 管理器代理
public protocol DGCChatManagerDelegate : NSObjectProtocol {
    
    /// 会话列表更新
    func chatManagerOnSessionListUpdate()
    
    // 未读消息数更新
    func chatManager(unReadCount count: Int32)
    
    /// 会话
    /// 外部刷新会话数据
    func chatManagerRefreshSessionData(session : DGCChatSession)
    
    /// 消息相关
    // 消息插入到会话列表前  可自定义处理一些数据
    // session 当前会话
    // msg 将要插入的消息
    // beforeMsg 上一条消息
    func chatManagerMsgAddListBefore(session : DGCChatSession,msg : DGCChatMsg,beforeMsg : DGCChatMsg?)
    
    
//    // 消息插入到会话列表后
//    func chatManagerMsgAddListAfter(session : DGCChatSession,msgList : [DGCChatMsg])
    
    // 消息发送失败错误 全局处理
    func chatManagerMsgGlobalSendFail(session: DGCChatSession, msg: DGCChatMsg, code: Int32, errString: String?)
    
    // 消息发送成功 全局处理
    func chatManagerMsgGlobalSendSuccess(session: DGCChatSession, msg: DGCChatMsg)

    //发送普通文案消息
    func chatManagerShowTipMsg(tipText: String, session: DGCChatSession,success : ChatEmptyBlock?,fail : ChatFailBlock?)
    
    // 消息被变更了
    func chatManagerMsgModified(msg: DGCChatMsg, session: DGCChatSession)
    
    /// 送礼处理
    /// 1.本地先插入一条消息
    /// 2. 向服务器发送API请求     这个回调用来实现API请求
    /// 3. 服务器主动推送IM消息
//    func chatManagerSendGift(msg: DGCChatMsgGift, success: ChatEmptyBlock?, fail: ChatFailBlock?)
    
    //用于统计
    func chatManagerMsgRecvForPoint(msg: DGCChatMsg)
    
    
    //生成业务会话 目前是 系统站内信
    func chatManagerGenerateBzSession()
}

public class DGCChatManager {
    // MARK: 公开 -- 属性、方法
    public static let share = DGCChatManager()
    
    /// 添加监听者
    public func addObserver(_ observer: DGCChatManagerObserver) {
        if !dgc_observers.contains(observer){
            dgc_observers.add(observer)
        }
    }
    
    public weak var delegate : DGCChatManagerDelegate?
    
    //安装SDK
    public func initSDK(config : MGChatSDKConfig){
        dgc_handler.initSDK(config: config)
    }
    
    
    /// 登录
    public func login(_ data : MGChatLoginData) {
        if data.uID == dgc_loginInfo.uID {
            CMLog("当前已登录uID=\(data.uID)")
            return
        }
        callInQueue {
            self.dgc_loginInfo = data
            self.dgc_handler.login(login: data)
        }
    }
    
    /// 退出
    public func logOut() {
        callInQueue {
            self.dgc_loadSessionCount = 0
            self.allSessions = []
            self.unReadCount = 0
            self.isFinished = false
            self.dgc_page = 0
            self.dgc_loginInfo = MGChatLoginData()
            self.dgc_handler.logout()
        }
        
    }
    
    /// 更新自己的个人信息
    public func updateMineInfo(faceUrl: String? = nil, nickName: String? = nil, succ: ChatEmptyBlock? = nil, fail: ChatFailBlock? = nil) {
        dgc_handler.updateMineInfo(nickName: nickName, faceUrl: faceUrl, succ: succ, fail: fail)
    }
    
    // 是否登录
    public var isLogin : Bool{dgc_handler.isLogin}
    

    
    /// 会话列表
    public internal(set) var allSessions : [DGCChatSession] = []
    
    /// 临时的会话
    public internal(set) var tempSessions : [DGCChatSession] = []
    
    //未读数量
    public internal(set) var unReadCount: Int32 = 0
    
    //通过ID查找或创一个单聊会话
    public func findUserSession(uID : Int64) -> DGCChatUserSession {
        if uID <= 0 {
            CMLog("会话创建异常 ID<=0")
        }
        //先查找本地是否存在该会话
        let dgc_c2cSessionID = "c2c_\(uID)"
        if let dgc_session = findSession(sID: dgc_c2cSessionID) as? DGCChatUserSession{
            CMLog("找到会话sID=\(dgc_session.sessionID)")
            return dgc_session
        }else if let dgc_session = tempSessions.first(where: {$0.sessionID == dgc_c2cSessionID}) as? DGCChatUserSession {
            CMLog("找到临时会话sID=\(dgc_session.sessionID)")
            return dgc_session
        } else{//不存在创建一个临时会话
            let dgc_nSession = DGCChatUserSession(sessionID: dgc_c2cSessionID)
            dgc_nSession.isLoadMsg = true // 不需要在请求消息列表了  自己刚刚发送的消息可能会被清空
            tempSessions.append(dgc_nSession)
            CMLog("没有找到会话sID=\(dgc_nSession.sessionID),创建新会话")
            return dgc_nSession
        }
    }
    
    /// 查找消息 通过msgID
    public func findMessage(msgID : String,success: @escaping ChatDataBlock<DGCChatMsg>, fail: ChatFailBlock?){
        dgc_handler.findMessage(msgID: msgID, success: success, fail: fail)
    }
    
    // MARK: 内部 -- 属性、方法
    private init() {
        dgc_queue.setSpecific(key: dgc_queueKey, value: 10)
        dgc_handler.delegate = self
    }
    
    private(set) var dgc_handler : DGCChatHandlerProtocol = DGCChatTencentHandler()
    /// 队列
    let dgc_queue = DispatchQueue(label: "DGCChatManager.dgc_queue")
    private let dgc_queueKey = DispatchSpecificKey<Int>()
    
    //会话结束
    public internal(set) var isFinished : Bool = false
    //获取会话的页码
    var dgc_page : Int32 = 0
    var dgc_count : Int32 = 15
    //刷新会话次数 限制2次 第一次登录成功  第二次 首次同步会话成功
    var dgc_loadSessionCount : Int = 0
    
    //监听者
    private let dgc_observers = NSHashTable<DGCChatManagerObserver>(options: .weakMemory)
    //登录信息
    var dgc_loginInfo = MGChatLoginData()
    
    /// 通知监听者
    func notiObservers(block :@escaping (_ observer : DGCChatManagerObserver)->Void) {
        ChatCallInMain {
            self.dgc_observers.allObjects.forEach { observer in
                block(observer)
            }
        }
    }
    
    // 在当前队列处理
    func callInQueue(block :@escaping (()->Void)) {
        if DispatchQueue.getSpecific(key: dgc_queueKey) == 10 {
            block()
        }else{
            dgc_queue.async {
                block()
            }
        }
    }
    
    ///更新未读消息数量
    func updateUnReadCount() {
        callInQueue {[weak self] in
            guard let self = self else { return }
            let dgc_oldCount = self.unReadCount
            
            self.unReadCount = self.allSessions.reduce(0) { partialResult, dgc_session in
                partialResult + dgc_session.unReadCount
            }
            if dgc_oldCount == self.unReadCount{ // 消息数一样不用刷新
                return
            }
            ChatCallInMain {
                self.delegate?.chatManager(unReadCount: self.unReadCount)
            }
        }
    }

}


extension DGCChatManager : DGCChatHandlerDelegate{
    
    func onRefreshSession() {
        if dgc_loadSessionCount >= 2{
            return //2次同步结束
        }
        dgc_loadSessionCount += 1
        //重新刷新会话
        self.loadSessions(page: 0, count: dgc_count)
    }
    
    func getUserId() -> String {
        dgc_loginInfo.uID
    }
    

}
