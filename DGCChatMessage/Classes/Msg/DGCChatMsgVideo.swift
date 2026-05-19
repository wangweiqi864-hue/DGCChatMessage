//
//  DGCChatMsgVideo.swift
//  Pods
//
//  Created by mango-linwieyan on 2024/4/28.
//

import Foundation
import AVFoundation
import ImSDK_Plus
import DGCLog

public class DGCChatMsgVideo : DGCChatMsg {
    
    public var path : String = ""
    
    public internal(set) var videoAsset : AVURLAsset?
    
    //视频类型 如 mp4 mov 等
    public var videoType : String {
        let fileExtension = (path as NSString).pathExtension
        if fileExtension.isEmpty {
            return "mp4"
        }
        return fileExtension
    }

    //时间
    public internal(set) var duration : Int32 = 0
    
    //缩略图
    public internal(set) var thumbModel = DGCChatMsgVideoItem()
    
    private var dgc_exportSession : DGCChatVideoExportSessionUtils?
    
    private var dgc_isDowning : Bool = false
    
    //下载进度
    var progressBlock : ((_ progress : CGFloat)->Void)?
    var complete : ((_ isOk : Bool, _ path : String?)->Void)?

    
    public override init() {
        super.init()
        type = .Video
    }
    
    ///初始化视频 发送消息 发送前还需要调用 handleVideoIfNeed 处理视频
    public init(videoAsset : AVURLAsset, image: UIImage, sID : String) {
        super.init()
        self.sendID = sID
        self.videoAsset = videoAsset
        self.type = .Video
        
        let duration = videoAsset.tracks(withMediaType: .video).first?.timeRange.duration
        if let duration = duration{
            self.duration = Int32(CMTimeGetSeconds(duration))
        }
    }
    
    public func handleCoverAndVideo(image : UIImage, asset: AVURLAsset) {
        
        let dgc_maxHeight : CGFloat = 150
        let dgc_maxWidth : CGFloat = 150
//
        var dgc_scale : CGFloat = 1
        dgc_scale = min(dgc_maxHeight/image.size.height, dgc_maxWidth/image.size.width)
        
        let dgc_picHeight = image.size.height;
        let dgc_picWidth = image.size.width;
        
        let dgc_picThumbHeight = dgc_picHeight * dgc_scale
        let dgc_picThumbWidth = dgc_picWidth * dgc_scale

        //创建缩略图
        let dgc_thumbImage = image.scaleWithImage(size: CGSize(width: dgc_picThumbWidth, height: dgc_picThumbHeight))
        let dgc_thumbPath = DGCChatFileTool.share.saveImageToPath(data: UIImageJPEGRepresentation(dgc_thumbImage, 1),sID: sendID)
        thumbModel = DGCChatMsgVideoItem(width: dgc_picThumbWidth,height: dgc_picThumbHeight,url: dgc_thumbPath)
    }
    
    
    ///处理视频生成
    public func handleVideoIfNeed(comple: @escaping (_ isOk : Bool)->Void) {
        guard let dgc_videoAsset = videoAsset else {
            comple(false)
            return
        }
        let dgc_savePath = DGCChatFileTool.genVideoPath(sID: sendID)
        //视频转码
        let dgc_exportSession = DGCChatVideoExportSessionUtils(outputUrl: dgc_savePath, videoAsset: dgc_videoAsset)
        self.dgc_exportSession = dgc_exportSession
        dgc_exportSession.exportAsyn(dgc_compleHandler: { [weak self] dgc_isOk in
            if dgc_isOk{
                self?.path = dgc_exportSession.outputUrl
            }
            self?.dgc_exportSession = nil
            comple(dgc_isOk)
        })
    }
    
    public func fetchSnapshotUrl(block :@escaping ((_ thumb : DGCChatMsgVideoItem)->Void)) {
        if self.thumbModel.url.isEmpty == false{
            block(thumbModel)
            return
        }
        _fetchSnapshotUrl {[weak self] path in
            if let dgc_image = UIImage(contentsOfFile: path){
                let dgc_thumbModel = DGCChatMsgVideoItem(width: dgc_image.size.width,height: dgc_image.size.height,url: path)
                self?.thumbModel = dgc_thumbModel
                block(dgc_thumbModel)
            }
        }
    }
}

extension DGCChatMsgVideo {
 
    func _downloadVideo(progressBlock :@escaping (_ dgc_progress : CGFloat)->Void,complete:@escaping ((_ isOk : Bool,_ dgc_path : String?)->Void)) {
        guard let dgc_elem = coustom["ic_message"] as? V2TIMVideoElem else {
            DGCLog.log("下载视频文件失败，没有下载项", file: #file)
            complete(false,nil)
            return
        }
        let dgc_videoPath = dgc_elem.videoPath ?? ""
        if dgc_videoPath.isEmpty == false{
            let dgc_path = DGCChatFileTool.share.getCurrDocumentsPath(oldPath: dgc_videoPath)
            if DGCChatFileTool.fileExists(path: dgc_path){
                complete(true,dgc_path)
                return
            }
        }
        
        //先获取视频路径
        var dgc_videoUUID = dgc_elem.videoUUID ?? ""
        if dgc_videoUUID.hasSuffix(".mp4") == false{
            dgc_videoUUID += ".mp4"
        }
        let dgc_savePath = DGCChatFileTool.share.getFilePath(name: dgc_videoUUID, .video)
        if DGCChatFileTool.share.fileExists(path:dgc_savePath){
            complete(true,dgc_savePath)
            return
        }
        dgc_elem.downloadVideo(dgc_savePath) { curSize, totalSize in
            let dgc_progress = CGFloat(curSize) / CGFloat(totalSize)
            DGCLog.log("视频下载进度progress=\(dgc_progress)", file: #file)
            progressBlock(dgc_progress)
        } succ: {
            complete(true,dgc_savePath)
        } fail: { code, msg in
            complete(false,nil)
        }
    }
    
    func _fetchSnapshotUrl(block :@escaping ((_ dgc_path : String)->Void)) {
        guard let dgc_elem = coustom["ic_message"] as? V2TIMVideoElem else {
            DGCLog.log("下载视频文件失败，没有下载项", file: #file)
            return
        }
        let dgc_snapshotPath = dgc_elem.snapshotPath ?? ""
        if dgc_snapshotPath.isEmpty == false{
            let dgc_path = DGCChatFileTool.share.getCurrDocumentsPath(oldPath: dgc_snapshotPath)
            if DGCChatFileTool.fileExists(path: dgc_path){
                block(dgc_path)
                return
            }
        }
        //先获取视频路径
        var dgc_snapshotUUID = dgc_elem.snapshotUUID ?? ""
        if dgc_snapshotUUID.hasSuffix(".png") == false {
            dgc_snapshotUUID += ".png"
        }
        let dgc_savePath = DGCChatFileTool.share.getFilePath(name: dgc_snapshotUUID, .video)
        if FileManager.default.fileExists(atPath: dgc_savePath){
            block(dgc_savePath)
            return
        }
        dgc_elem.downloadSnapshot(dgc_savePath) { _, _ in
            
        } succ: {
            block(dgc_savePath)
        } fail: { _, _ in
            
        }
    }
    
    public func fetchVideoPath(progressBlock :@escaping (_ progress : CGFloat)->Void,complete :@escaping ((_ isOk : Bool, _ dgc_path : String?)->Void)) {
        if self.path.isEmpty == false{
            complete(true,path)
            return
        }
        self.progressBlock = progressBlock
        self.complete = complete
        if dgc_isDowning{
            return
        }
        dgc_isDowning = true
        self.progressBlock?(0)
        _downloadVideo {[weak self] progress in
            DispatchQueue.main.async {
                self?.progressBlock?(progress)
            }
        } complete: {[weak self] isOk, dgc_path in
            self?.dgc_isDowning = false
            if isOk, let dgc_path = dgc_path{
                self?.path = dgc_path
                self?.complete?(true,dgc_path)
            }else{
                self?.complete?(false,nil)
            }
        }
    }
}


public class DGCChatMsgVideoItem : Codable {
    //宽
    public internal(set) var width : CGFloat = 0
    //高
    public internal(set) var height : CGFloat = 0
    //快照地址
    public internal(set) var url : String = ""
    
    init(){}
    
    init(width: CGFloat,height: CGFloat,url: String) {
        self.width = width
        self.height = height
        self.url = url
    }
    
    public func encode(to encoder: Encoder) throws {
        var dgc_container = encoder.dgc_container(keyedBy: DGCCodingKeys.self)
        try dgc_container.encode(Int32(self.width), forKey: .width)
        try dgc_container.encode(Int32(self.height), forKey: .height)
    }
    
    enum DGCCodingKeys: CodingKey {
        case width
        case height
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DGCCodingKeys.self)
        self.width = CGFloat(try container.decode(Int32.self, forKey: .width))
        self.height = CGFloat(try container.decode(Int32.self, forKey: .height))
    }
}

