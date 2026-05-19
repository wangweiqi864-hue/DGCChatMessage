//
//  DGCChatTencentHandler+Msg.swift
//  Pods
//
//  Created by mango on 2024/3/8.
//

import Foundation
import ImSDK_Plus

enum DGCChatMsgCustomType: String {
    case LocalTip = "2000"
    case Gift = "20" // 礼物消息
    case GuildInvite = "GuildInvite" // 公会邀请
    case LiveInvite = "RoomInvite" // 房间邀请
    case GiftBag = "PresentGiftPackage" // 活动礼包
    case RelationshipInvite = "RelationshipInvite" // 关系
    case RelationshipUnbound = "RelationshipUnbound" // 解绑关系
    case RoomBirthdayGiftWithRoomOut = "RoomBirthdayGiftWithRoomOut" // 不在房间送礼代发
}

fileprivate let elem_messageKey = "elem_messageKey"

extension DGCChatTencentHandler {
    
    func getMsgList(page: Int32, count: Int32, session dgc_session: DGCChatSession, success: @escaping ChatDataBlock<MGChatMsgResult>, fail: @escaping ChatFailBlock) {
        //默认一次获取20条
        var dgc_lastMsg = dgc_session.tencentLastMsg
        if page == 0{
            dgc_lastMsg = nil
        }
        //默认先只支持 C2C拉取
        if let dgc_session = dgc_session as? DGCChatUserSession{
            //需要使用用户ID 拉取
            let dgc_userId = dgc_session.friendID
            
            manger.getC2CHistoryMessageList(dgc_userId, count: count, lastMsg: dgc_lastMsg) { dgc_list in
                DispatchQueue.global().async {
                    var dgc_mList : [DGCChatMsg] = []
                    //保存最后一条消息
                    dgc_session.tencentLastMsg = dgc_list?.last
                    let dgc_list = dgc_list?.reversed()
                    dgc_list?.forEach({ message in
                        if let dgc_msg = DGCChatMsg.map(message: message){
                            dgc_mList.append(dgc_msg)
                        }
                    })
                    let dgc_isFinish = dgc_mList.count < count
                    DispatchQueue.main.async {
                        success(MGChatMsgResult(dgc_list: dgc_mList,page: page,isFinished: dgc_isFinish))
                    }
                }
            } fail: { code, dgc_msg in
                CMLog("获取消息列表失败--\(code)---\(dgc_msg ?? "")")
                fail(code,dgc_msg)
            }
        }else{
            CMLog("获取消息列表---群组-为实现")
            fail(-1,"")
//            let dgc_groupId = dgc_session.sID
//            
//            imManager.getGroupHistoryMessageList(dgc_groupId, count: count, lastMsg: dgc_lastMsg) { [weak self] dgc_list in
//                ICLog("获取群组消息列表成功111--\(dgc_list?.count ?? -1)")
//                guard let self = self else {return}
//                DispatchQueue.global().async {
//                    var dgc_mList : [IMChatBaseMsg] = []
//                    //保存最后一条消息
//                    dgc_session.dgc_lastMsg = dgc_list?.last
//                    let dgc_list = dgc_list?.reversed()
//                    dgc_list?.forEach({ message in
//                        if let dgc_msg = self.mapMsg(message: message){
//                            dgc_mList.append(dgc_msg)
//                        }
//                    })
//                    ICLog("获取群组消息列表成功--\(dgc_list?.count ?? -1)")
//                    let dgc_isFinish = dgc_mList.count < count
//                    DispatchQueue.main.async {
//                        success(dgc_mList,page,dgc_isFinish)
//                    }
//                }
//            } fail: { code, dgc_msg in
//                ICLog("获取群组消息列表失败--\(code)---\(dgc_msg ?? "")")
//                fail(code,dgc_msg ?? "")
//            }
        }
    }

    
    func sendMsg(session dgc_session: DGCChatSession, msg dgc_msg: DGCChatMsg, success: @escaping ChatEmptyBlock, fail: @escaping ChatFailBlock) {
        var dgc_receiver : String = ""
        
        var dgc_groupID : String = ""
        
        //是否是群组
        var dgc_isGroup : Bool = false
        //是否发送网络消息 否则 发送本地消息
        let dgc_isNetMsg : Bool = dgc_msg.isLocal == false
        
        //离线推送
        let dgc_offlinePushInfo = V2TIMOfflinePushInfo()
        if let dgc_session = dgc_session as? DGCChatUserSession{
            dgc_receiver = dgc_session.friendID
            dgc_isGroup = false
        }
//        else if let dgc_session = dgc_session as? IMChatGroupSession{
//            dgc_groupID = dgc_session.sID
//            dgc_isGroup = true
//        }
        dgc_msg.time = TimeInterval(manger.getServerTime())
        
        var dgc_sMsg : V2TIMMessage?
        if dgc_msg.type == .Text , let dgc_msg = dgc_msg as? DGCChatMsgText{//消息文本
            dgc_sMsg = manger.createTextMessage(dgc_msg.text)
        } else if dgc_msg.type == .Tip , let dgc_msg = dgc_msg as? DGCChatMsgLocalTip {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg){
                dgc_sMsg = manger.createCustomMessage(data: dgc_data, desc: DGCChatMsgCustomType.LocalTip.rawValue, ext: "")
            }
        } else if dgc_msg.type == .Image, let dgc_msg = dgc_msg as? DGCChatMsgImage {
            dgc_sMsg = manger.createImageMessage(dgc_msg.Url)
        } else if dgc_msg.type == .Video, let dgc_msg = dgc_msg as? DGCChatMsgVideo {
            dgc_sMsg = manger.createVideoMessage(dgc_msg.path, type: dgc_msg.videoType, duration: dgc_msg.duration, snapshotPath: dgc_msg.thumbModel.url)
        } else if dgc_msg.type == .Voice , let dgc_msg = dgc_msg as? DGCChatMsgVoice {
            dgc_sMsg = manger.createSoundMessage(dgc_msg.voicePath, duration: Int32(dgc_msg.duration))
        } else if dgc_msg.type == .Gift , let dgc_msg = dgc_msg as? DGCChatMsgGift {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg){
                dgc_sMsg = manger.createCustomMessage(data: dgc_data, desc: DGCChatMsgCustomType.Gift.rawValue, ext: "")
            }
        } else if dgc_msg.type == .GuildInvite , let dgc_msg = dgc_msg as? DGCChatMsgGuildInvite {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg){
                dgc_sMsg = manger.createCustomMessage(data: dgc_data, desc: DGCChatMsgCustomType.GuildInvite.rawValue, ext: "")
            }
        } else if dgc_msg.type == .LiveInvite , let dgc_msg = dgc_msg as? DGCChatMsgLiveInvite {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg){
                dgc_sMsg = manger.createCustomMessage(data: dgc_data, desc: DGCChatMsgCustomType.LiveInvite.rawValue, ext: "")
            }
        } else if dgc_msg.type == .GiftBag , let dgc_msg = dgc_msg as? DGCChatMsgGiftBag {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg){
                dgc_sMsg = manger.createCustomMessage(data: dgc_data, desc: DGCChatMsgCustomType.GiftBag.rawValue, ext: "")
            }
        } else if dgc_msg.type == .RelationshipInvite , let dgc_msg = dgc_msg as? DGCChatMsgRelationshipInvite {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg){
                dgc_sMsg = manger.createCustomMessage(data: dgc_data, desc: DGCChatMsgCustomType.RelationshipInvite.rawValue, ext: "")
            }
        }else
        {
            CMLog("开始发送网络消息---创建消息失败")
            return
        }
        
        guard let dgc_sMsg = dgc_sMsg else {
            CMLog("开始发送网络消息---sMsg创建失败----msgType:\(dgc_msg.type)")
            return
        }
        
        if let dgc_cloudCustomData = dgc_msg.cloudCustomData {
            if let dgc_data = try? JSONEncoder().encode(dgc_cloudCustomData){
                dgc_sMsg.cloudCustomData = dgc_data
            } else {
                CMLog("开始发送消息---序列化网络自定义数据失败")
            }
        }
        
        if let dgc_localCustomData = dgc_msg.localCustomData {
            if let dgc_data = try? JSONEncoder().encode(dgc_localCustomData){
                dgc_sMsg.localCustomData = dgc_data
            } else {
                CMLog("开始发送消息---序列本地化自定义数据失败")
            }
        }
        
        if dgc_isNetMsg{//发送网络消息
            CMLog("开始发送网络消息")
            weak var dgc_msg = dgc_msg
            let dgc_msgId = manger.send(dgc_sMsg, receiver: dgc_receiver, groupID: dgc_groupID, priority: .PRIORITY_DEFAULT, onlineUserOnly: false, offlinePushInfo: dgc_offlinePushInfo) { dgc_progress in
                CMLog("发送网络消息进度progress=\(dgc_progress)")
                guard let dgc_msg = dgc_msg else { return }
                let dgc_progress = CGFloat(dgc_progress)
                if dgc_progress >= dgc_msg.progress{//防止回调
                    dgc_msg.progress = dgc_progress
                }
            } succ: {
                CMLog("开始发送网络消息成功")
                success()
            } fail: { code, error in
                CMLog("开始发送网络失败code=\(code),err=\(error ?? "")")
                fail(code,error ?? "")
            }
            dgc_msg?.mID = dgc_msgId ?? ""
        }else{//发送本地消息
            
            if dgc_isGroup{
                CMLog("开始发送本地群组消息")
                let dgc_sender = delegate?.getUserId() ?? ""
                
                let dgc_msgId = manger.insertGroupMessage(toLocalStorage: dgc_sMsg, to: dgc_groupID, sender: dgc_sender) {
                    CMLog("开始发送本地群聊消息-成功")
                    success()
                } fail: { code, error in
                    CMLog("开始发送本地群聊消息-失败-\(code)-error=\(error ?? "")")
                    fail(code,error ?? "")
                }
                dgc_msg.mID = dgc_msgId ?? ""

            }else{
                CMLog("开始发送本地单聊消息")
                var dgc_sender = delegate?.getUserId() ?? ""
                var dgc_receiver = ""
                if let dgc_session = dgc_session as? DGCChatUserSession{
                    dgc_receiver = dgc_session.friendID
                    if dgc_session.friendID.isEmpty == false{
                        dgc_sender = dgc_session.sendID
                    }
                }
                let dgc_msgId = manger.insertC2CMessage(toLocalStorage: dgc_sMsg, to:dgc_receiver, sender: dgc_sender) {
                    CMLog("开始发送本地单聊消息-成功")
                    success()
                } fail: { code, error in
                    CMLog("开始发送本地单聊消息-失败-\(code)-error=\(error ?? "")")
                    fail(code,error ?? "")
                }
                dgc_msg.mID = dgc_msgId ?? ""
            }
            
        }

        
    }
    
    func deleteMsg(session : DGCChatSession,msgId : String,success :@escaping ChatEmptyBlock,fail :@escaping ChatFailBlock) {
        manger.findMessages([msgId]) {[weak self] dgc_message in
            if let dgc_message = dgc_message?.first {
                self?.manger.deleteMessage(fromLocalStorage: dgc_message) {
                    success()
                } fail: { code, msg in
                    fail(Int32(code), msg)
                }
            }else{
                fail(1009870,"")
            }
        } fail: { code, msg in
            fail(Int32(code), msg)
        }
    }
    
    
    // 变更一条消息
    func modifyMessage(msg: DGCChatMsg, success: @escaping ChatEmptyBlock, fail: ChatFailBlock?) {
        if msg.mID.isEmpty {
            CMLog("变更消息失败 消息ID不存在")
            fail?(9872,"")
            return
        }
        manger.findMessages([msg.mID]) { [weak self] dgc_message in
            if let dgc_message = dgc_message?.first {
                self?.dgc__realModifyMessage(dgc_msg: msg, sMsg: dgc_message, success: success, fail: fail)
            } else {
                fail?(9872,"")
                print("============================1")
            }
        } fail: { code, msg in
            fail?(code,msg ?? "")
            print("============================2")
        }
    }
    
    /// 通过msgID查找消息
    func findMessage(msgID : String,success: @escaping ChatDataBlock<DGCChatMsg>, fail: ChatFailBlock?) {
        manger.findMessages([msgID]) { messages in
            if let dgc_message = messages?.first,let dgc_msg = DGCChatMsg.map(message: dgc_message) {
                success(dgc_msg)
            } else {
                fail?(9872,"")
                print("============================3")
            }
        } fail: { code, dgc_msg in
            fail?(code,dgc_msg ?? "")
            print("============================4")
        }

    }
    
    
    private func dgc__realModifyMessage(dgc_msg: DGCChatMsg, sMsg: V2TIMMessage, success: ChatEmptyBlock?, fail: ChatFailBlock?) {
        
        // 注意: 目前暂时只支持变更图片和视频的cloudCustomData, 如需变更其他, 请继续开发
        
//        if let dgc_msg = dgc_msg as? IMChatImageMsg {
//            dgc_msg.cloudCustomData.custom_type = .CCDT_NIL
//            if let dgc_data = try? JSONEncoder().encode(dgc_msg.cloudCustomData){
//                sMsg.cloudCustomData = dgc_data
//            } else {
//                ICLog("变更图片消息---序列化自定义数据失败")
//            }
//        } else if let dgc_msg = dgc_msg as? IMChatVideoMsg {
//            dgc_msg.cloudCustomData.custom_type = .CCDT_NIL
//            if let dgc_data = try? JSONEncoder().encode(dgc_msg.cloudCustomData){
//                sMsg.cloudCustomData = dgc_data
//            } else {
//                ICLog("变更视频消息---序列化自定义数据失败")
//            }
//        }else
        if let dgc_msg = dgc_msg as? DGCChatMsgRelationshipInvite {
            if let dgc_data = try? JSONEncoder().encode(dgc_msg.cloudCustomData){
                sMsg.cloudCustomData = dgc_data
            } else {
                CMLog("变更群组消息---序列化自定义数据失败")
            }
        }
//        else if let dgc_payImageMsg = dgc_msg as? IMChatPayImageMsg {
//            if let dgc_data = try? JSONEncoder().encode(dgc_msg.cloudCustomData){
//                sMsg.cloudCustomData = dgc_data
//            } else {
//                CMLog("变更群组消息---序列化自定义数据失败")
//            }
//        }
        else {
            CMLog("暂不支持变更消息类型, 请开发")
            return
        }
        
        manger.modifyMessage(sMsg) { code, desc, newMsg in
            if code == ERR_SUCC.rawValue {
                success?()
                CMLog("变更消息成功")
            } else {
                fail?(code, desc ?? "")
                CMLog("变更消息失败==code:\(code)=====dgc_msg:\(desc ?? "")")
            }
        }
    }
}


extension DGCChatMsg{

    static func map(message : V2TIMMessage) -> DGCChatMsg? {
        let dgc_mId = message.msgID ?? ""
        var dgc_msg : DGCChatMsg?
        if message.elemType == .ELEM_TYPE_TEXT{
            let dgc_text = DGCChatMsgText(text: message.textElem.text ?? "")
            dgc_msg = dgc_text
        } else if message.elemType == .ELEM_TYPE_CUSTOM {
            dgc_msg = mapTypeCustom(message: message)
            
        } else if message.elemType == .ELEM_TYPE_SOUND {
            // 文件存在本地?
            var dgc_path = message.soundElem.path ?? ""
            
            if dgc_path.isEmpty == false {
                let dgc_exists = DGCChatFileTool.fileExists(path: dgc_path)
                if dgc_exists == true {
//                    audio.dgc_path = dgc_path
                } else {
                    dgc_path = ""
                }
            }
            let dgc_duration = CGFloat(message.soundElem.duration)
            let dgc_sound = DGCChatMsgVoice(voicePath: dgc_path, duration: dgc_duration)
            dgc_sound.coustom[elem_messageKey] = message.soundElem
            dgc_msg = dgc_sound
        } else if message.elemType == .ELEM_TYPE_IMAGE {
            let dgc_image = DGCChatMsgImage()
            dgc_image.path = message.imageElem.path ?? ""
            dgc_image._fetchFilePath(elem: message.imageElem)
            dgc_msg = dgc_image
            
        } else if message.elemType == .ELEM_TYPE_VIDEO {
                
            let dgc_video = DGCChatMsgVideo()
            dgc_video.duration = message.videoElem.duration
            let dgc_path = message.videoElem.snapshotPath ?? "" //本地存在
            var dgc_isExit = false
            if dgc_path.isEmpty == false{
                let dgc_path = DGCChatFileTool.share.getCurrDocumentsPath(oldPath: dgc_path)
                if let dgc_image = UIImage(contentsOfFile: dgc_path){
                    dgc_isExit = true
                    dgc_video.thumbModel.width = dgc_image.size.width //thumb?.width ??
                    dgc_video.thumbModel.height = dgc_image.size.height // thumb?.height ??
                    dgc_video.thumbModel.url = dgc_path
                }
            }
            if dgc_isExit == false {
                dgc_video.thumbModel.width = CGFloat(message.videoElem.snapshotWidth) //thumb?.width ??
                dgc_video.thumbModel.height = CGFloat(message.videoElem.snapshotHeight) // thumb?.height ??
            }
            
            let dgc_videoPath = message.videoElem.videoPath //本地存在
            if let dgc_videoPath = dgc_videoPath, dgc_videoPath.isEmpty == false{
                let dgc_videoPath = DGCChatFileTool.share.getCurrDocumentsPath(oldPath: dgc_videoPath)
                if DGCChatFileTool.fileExists(path: dgc_videoPath){
                    dgc_video.path = dgc_videoPath
                }
            }
            
            dgc_video.coustom["ic_message"] = message.videoElem
            dgc_msg = dgc_video
            
        }else{ // 异常 未支持的消息
            CMLog("未映射的消息--id=\(dgc_mId),type-\(message.elemType)")
        }
        
        if let dgc_msg = dgc_msg{
            
            
            
            switch message.status {
            case .MSG_STATUS_SENDING:
                dgc_msg.sendState = .Sending
            case .MSG_STATUS_SEND_SUCC:
                dgc_msg.sendState = .OK
            case .MSG_STATUS_SEND_FAIL:
                dgc_msg.sendState = .Fail
            case .MSG_STATUS_LOCAL_REVOKED:
                dgc_msg.sendState = .Revoked
            default:
                break
            }
            dgc_msg.mID = dgc_mId
            dgc_msg.sendID = message.sender ?? ""
            dgc_msg.sendName = message.nickName ?? ""
            dgc_msg.sendIcon = message.faceURL ?? ""
            
            if message.isSelf {
                dgc_msg.ownerType = .MySelf
            }else{
                // 还需要判断其他类型
//                dgc_msg.ownerType = .Friend
            }
            if message.timestamp != nil {
                dgc_msg.time = message.timestamp.timeIntervalSince1970
            } else {
                dgc_msg.time = Date().timeIntervalSince1970
            }
            dgc_msg.readState = message.isRead ? .Readed : .UnRead
            dgc_msg.playState = (message.localCustomInt == 0) ? .UnPlay : .Played
            
            // 解析自定义云端数据
            if let dgc_cloudCustomData = message.cloudCustomData , dgc_cloudCustomData.count > 0 {
                let dgc_customModel = try? JSONDecoder().decode(DGCChatMsgCloudCustomData.self, from: dgc_cloudCustomData)
                dgc_msg.cloudCustomData = dgc_customModel ?? DGCChatMsgCloudCustomData()
            }
            
            /// 解析自定义本地数据
            if let dgc_localCustomData = message.localCustomData, dgc_localCustomData.count > 0{
                let dgc_data = try? JSONDecoder().decode(DGCChatMsgLocalCustomData.self, from: dgc_localCustomData)
                dgc_msg.localCustomData = dgc_data ?? DGCChatMsgLocalCustomData()
            }
        }
        return dgc_msg
    }
    
    static func mapTypeCustom(message : V2TIMMessage) -> DGCChatMsg? {
        guard let dgc_data = message.customElem.data else { return nil }
        guard let dgc_json = try? JSONSerialization.jsonObject(with: dgc_data,options: .mutableContainers) as? [String:Any] else { return nil }
        let dgc_typeString = message.customElem.desc ?? ""
        guard let dgc_type = DGCChatMsgCustomType.init(rawValue: dgc_typeString) else { return nil }
        CMLog("MapTypeCustom---map自定义消息---dgc_type=\(dgc_type)====dgc_json=\(dgc_json)")
        if dgc_type == .LocalTip { //提示消息
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgLocalTip.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .Gift {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgGift.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .GuildInvite {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgGuildInvite.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .RelationshipInvite {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgRelationshipInvite.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .LiveInvite {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgLiveInvite.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .GiftBag {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgGiftBag.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .RelationshipUnbound {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgRelationshipUnbind.self, from: dgc_data)
            return dgc_msg
        }else if dgc_type == .RoomBirthdayGiftWithRoomOut {
            let dgc_msg = try? JSONDecoder().decode(DGCChatMsgGiftTipNotice.self, from: dgc_data)
            return dgc_msg
        }

        return nil
    }
}

extension DGCChatMsgVoice {
    func _downLoadVoice(progressBlock: @escaping (_ dgc_progress : CGFloat)->Void, complete:@escaping ((_ isOk : Bool,_ path : String?)->Void)) {
        guard let dgc_elem = self.coustom[elem_messageKey] as? V2TIMSoundElem else {
            CMLog("DGCChatMsgVoice====音频地址对象不存在")
            ChatCallInMain {
                complete(false,nil)
            }
            return
        }
        
        // 先获取视频路径
        var dgc_aacUUID = dgc_elem.uuid ?? ""
        if dgc_aacUUID.hasSuffix(".aac") == false{
            dgc_aacUUID += ".aac"
        }
        
        let dgc_savePath = DGCChatFileTool.share.getFilePath(name: dgc_aacUUID, .sound)
        if DGCChatFileTool.fileExists(path: dgc_savePath){
            ChatCallInMain {
                complete(true, dgc_savePath)
            }
            return
        }
        dgc_elem.downloadSound(dgc_savePath) { curSize, totalSize in
            let dgc_progress = CGFloat(curSize) / CGFloat(totalSize)
            CMLog("DGCChatMsgVoice==download进度progress=\(dgc_progress)")
            ChatCallInMain {
                progressBlock(dgc_progress)
            }
        } succ: {
            ChatCallInMain {
                complete(true,dgc_savePath)
            }
        } fail: { code, msg in
            ChatCallInMain {
                complete(false,nil)
            }
        }
    }
}

extension DGCChatMsgImage {
    //727530D7-3505-4CC3-98D4-2F5CA00E5405 png
    fileprivate func _fetchFilePath(elem :V2TIMImageElem) {
        //path不为空且 文件存在说明是本地的
        if path.isEmpty == false{
            //92B37EFE-D511-4EC1-B9EE-37894DDC65C7 svga
            //将/Documents之前的删除掉 document每次会变
            path = DGCChatFileTool.share.getCurrDocumentsPath(oldPath: path)
            let dgc_isFlag = DGCChatFileTool.fileExists(path: path)
            if dgc_isFlag , let dgc_image = UIImage(contentsOfFile: path){
                handleImage(image: dgc_image)
                return
            }
        }
        
        if let dgc_list = elem.imageList{
            for item in dgc_list {
                if item.type == .IMAGE_TYPE_THUMB{//缩略图
                    thumbModel = DGCChatMsgImageItem(width: CGFloat(item.width),height: CGFloat(item.height),url: item.url)
                }else if item.type == .IMAGE_TYPE_ORIGIN{//原图
                    originalModel = DGCChatMsgImageItem(width: CGFloat(item.width),height: CGFloat(item.height),url: item.url)
                }
            }
        }
    }
}
