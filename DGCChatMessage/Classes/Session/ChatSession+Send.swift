//
//  DGCChatSession+Send.swift
//  Pods
//
//  Created by mango on 2024/3/8.
//

import Foundation

// 消息发送
extension DGCChatSession {
    
    /// 发送消息
    /// msg 消息
    /// isNeedVail 是否需要校验
    public func sendMsg(_ msg : DGCChatMsg,isNeedVail : Bool = true, success : ChatEmptyBlock? = nil,fail : ChatFailBlock? = nil) {
        if isNeedVail {
            //验证消息是否能发送
            let dgc_isVail = delegate?.chatSessionVailCanSendMsg() ?? true
            if dgc_isVail == false{return}
        }
        manager.callInQueue {[weak self] in
            self?.dgc__sendMsg(msg, success: success, fail: fail)
        }
    }
    
    ///重新发送消息
    public func reSendMsg(_ msg: DGCChatMsg, isNeedVail : Bool = true, success : ChatEmptyBlock? = nil,fail : ChatFailBlock? = nil) {
        if isNeedVail {
            //验证消息是否能发送
            let dgc_isVail = delegate?.chatSessionVailCanSendMsg() ?? true
            if dgc_isVail == false{return}
        }
        //将消息先移除在发送
        msgArr.removeAll(where: {$0.mID == msg.mID})
        manager.dgc_handler.deleteMsg(session: self, msgId: msg.mID, success: {}, fail: {_,_ in })
        manager.callInQueue {[weak self] in
            self?.dgc__sendMsg(msg, success: success, fail: fail)
        }
    }
    
    ///发送提示消息 tipText 内容
    public func sendTipMsg(_ tipText:String, success : ChatEmptyBlock? = nil,fail : ChatFailBlock? = nil) {
        DGCChatManager.share.delegate?.chatManagerShowTipMsg(tipText: tipText, session: self,success: { [weak self] in
            guard let self = self else { return }
            self.callOnRefreshMsgList()
        }, fail: nil)
    }
    
    /// 发送消息
    private func dgc__sendMsg(_ msg : DGCChatMsg, success : ChatEmptyBlock? = nil,fail : ChatFailBlock? = nil) {
        //发送前的检测
//        beforeChecke(msg: msg)
        msg.sendState = .Sending
        //先将消息插入列表
        sendBeforeInsertMsgToList(msg: msg)
        dgc__innerSendMsg(msg,success: success,fail: fail)
        sendEndNotiRefresh(msg: msg)
    }
    
    // 内部发送消息
    private func dgc__innerSendMsg(_ msg : DGCChatMsg, success : ChatEmptyBlock? = nil,fail : ChatFailBlock? = nil) {
        manager.sendMsg(session: self, msg: msg) {[weak self] in
            msg.sendState = .OK
            success?()
            self?.dgc__innerSendHandleSuccess(msg: msg)
            self?.callOnRefreshMsgList()
        } fail: {[weak self] code, err in
            msg.sendState = .Fail
            self?.dgc__innerSendHandleFail(msg: msg, code: code, errString: err)
            self?.callOnRefreshMsgList()
            fail?(code,err)
        }
    }
    
//    private func dgc__sendGiftMsg(_ msg: DGCChatMsg) {
//        guard let msg = msg as? DGCChatMsgGift else { return }
//        manager.delegate?.chatManagerSendGift(msg: msg, success: { [weak self] in
//            msg.sendState = .OK
//            self?.callOnRefreshMsgList()
//        }, fail: { [weak self] code, errMsg in
//            msg.sendState = .Fail
//            self?.dgc__innerSendHandleFail(msg: msg, code: code, errString: errMsg)
//            self?.callOnRefreshMsgList()
//        })
//    }
    
    private func dgc__innerSendHandleFail(msg: DGCChatMsg, code: Int32, errString: String?) {
        DGCChatManager.share.delegate?.chatManagerMsgGlobalSendFail(session: self, msg: msg, code: code, errString: errString)
    }
    
    
    private func dgc__innerSendHandleSuccess(msg: DGCChatMsg) {
        DGCChatManager.share.delegate?.chatManagerMsgGlobalSendSuccess(session: self, msg: msg)
    }
}
