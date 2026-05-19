//
//  DGCChatHandlerProtocol.swift
//  ManGo
//
//  Created by mango on 2024/3/7.
//

import Foundation

protocol DGCChatHandlerProtocol {
    var delegate : DGCChatHandlerDelegate?{get set}
    
    //是否登录
    var isLogin : Bool{get}
    
    //安装SDK
    func initSDK(config : MGChatSDKConfig)
    
    //登录
    func login(login:MGChatLoginData)
    //退出登录
    func logout()
    
    /// 更新自己的个人信息
    func updateMineInfo(nickName: String?, faceUrl: String?, succ: ChatEmptyBlock?, fail: ChatFailBlock?)
    
    //获取会话列表
    func getSessionList(page : Int32 , count : Int32,success :@escaping ChatDataBlock<MGChatSessionResult>,fail :@escaping ChatFailBlock)
    
    //获取消息列表
    func getMsgList(page : Int32 , count : Int32,session : DGCChatSession,success :@escaping ChatDataBlock<MGChatMsgResult>,fail :@escaping ChatFailBlock)
    
    /// 发送一条消息
    /// - Parameters:
    ///   - session: 当前的会话
    ///   - msg: 当前需要发送的消息
    ///   - success: <#success description#>
    ///   - fail: <#fail description#>
    func sendMsg(session : DGCChatSession,msg : DGCChatMsg,success :@escaping ChatEmptyBlock,fail :@escaping ChatFailBlock)
    
    /// 删除一条消息
    func deleteMsg(session : DGCChatSession,msgId : String,success :@escaping ChatEmptyBlock,fail :@escaping ChatFailBlock)
    
    ///设置会话消息为已读
    func setSessionRead(session : DGCChatSession, complete: ChatEmptyBlock?)
    ///删除会话
    func deleteSession(session : DGCChatSession,complete : ChatEmptyBlock?)
    
    /// 设置消息已播放
    func setMsgPlayStatus(mId: String, success: ((_ msg : DGCChatMsg)->Void)?, fail: ChatFailBlock?)
    
    /// 变更消息
    func modifyMessage(msg: DGCChatMsg, success: @escaping ChatEmptyBlock, fail: ChatFailBlock?)
    
    /// 查找消息 通过msgID
    func findMessage(msgID : String,success: @escaping ChatDataBlock<DGCChatMsg>, fail: ChatFailBlock?)
}


protocol DGCChatHandlerDelegate {
    
    //刷新会话列表
    //初始化成功 / 同步服务器完成回调
    func onRefreshSession()
    
    //收到新消息
    func onRecvNewMsg(msg : DGCChatMsg,sessionID : String,sessionType : MGChatSessionType,sender:String)
    
    //消息修改
    func onRecvMsgModified(msg : DGCChatMsg,sessionID : String,sessionType : MGChatSessionType, sender:String)
    
    //获取用户ID
    func getUserId() -> String
    
    // 收到新会话
    func onNewConversation(list : [DGCChatSession])
}


public protocol DGCChatSessionDelegate : NSObjectProtocol {
    //刷新消息列表
    func chatSessionOnRefreshMsgList(isLoadMore : Bool)
    
    //校验是否能发送消息
    func chatSessionVailCanSendMsg() -> Bool
    
    //发送之前的检测
    func chatSessionbeforeChecke(msg : DGCChatMsg) -> Bool
    
    //会话信息更新
    func chatSessionUpdateInfo()
    
    //收到新消息回调
    func chatSessionOnRecvNewMsg(msg : DGCChatMsg)
}
