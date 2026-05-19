//
//  DGCChatVideoExportSessionUtils.swift
//  Pods
//
//  Created by mango-linwieyan on 2024/4/28.
//

import Foundation
import AVFoundation
import DGCLog

//视频转码
class DGCChatVideoExportSessionUtils {
    
    private var dgc_compleHandler : ((_ isOk : Bool)->Void)? = nil
    
    ///本地路径输出路径
    var outputUrl : String
    //视频
    var videoAsset : AVURLAsset
    
    private var dgc_exportSession : AVAssetExportSession?

    init(outputUrl : String,videoAsset: AVURLAsset) {
        self.videoAsset = videoAsset
        self.outputUrl = outputUrl
    }
    
    ///异步导出
    func exportAsyn(dgc_compleHandler:((_ isOk : Bool)->Void)? = nil) {
        if outputUrl.isEmpty{
            dgc_callComple(false)
            return
        }
        self.dgc_compleHandler = dgc_compleHandler
        DispatchQueue.global().async {
            self.dgc__exportAsyn()
        }
    }
    
    
    private func dgc__exportAsyn() {
        DGCLog.log("导出视频开始_exportAsyn", file: #file)
        let dgc_urlExtension = videoAsset.url.pathExtension
        if dgc_urlExtension.lowercased() == "mp4"{//mp4文件
            //判断是否超过了最大分辨率
            if let dgc_track = videoAsset.tracks(withMediaType: .video).first{
                let dgc_size = dgc_track.naturalSize
                let dgc_resolution = dgc_size.width*dgc_size.height
                if dgc_resolution <= 540*960 {//不需要转码
                    DGCLog.log("导出视频不需要转码", file: #file)
                    dgc_saveVideo(url: videoAsset.url)
                    return
                }
            }
        }
        let dgc_saveUrl = URL(fileURLWithPath: outputUrl)
        DGCLog.log("导出视频转码开始", file: #file)
        //转码导出
        let dgc_exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset960x540)
        self.dgc_exportSession = dgc_exportSession
        guard let dgc_exportSession = dgc_exportSession else {
            DGCLog.log("导出视频转码失败exportSession==nil", file: #file)
            dgc_callComple(false)
            return
        }
//        let dgc_types = dgc_exportSession.supportedFileTypes
        
        dgc_exportSession.outputURL = dgc_saveUrl
        dgc_exportSession.outputFileType = .mp4
        dgc_exportSession.shouldOptimizeForNetworkUse = true
        
        dgc_exportSession.exportAsynchronously {[weak self] in
            guard let self = self else { return }
            if dgc_exportSession.status == .completed{
                DGCLog.log("导出视频转码完成", file: #file)
                self.dgc_callComple(true)
            }else if dgc_exportSession.status == .failed || dgc_exportSession.status == .cancelled {
                DGCLog.log("导出视频转码失败=====\(dgc_exportSession.error)", file: #file)
                do {
                    // 直接拷贝
                    try FileManager.default.copyItem(at: self.videoAsset.url, to: dgc_saveUrl)
                    self.dgc_callComple(true)
                } catch {
                    self.dgc_callComple(false)
                }
            }
        }
        
    }
    
    func cancleExport() {
        dgc_exportSession?.cancelExport()
    }

    private func dgc_saveVideo(url : URL) {
        guard let dgc_videoData = try? Data(contentsOf: url) else {
            return
        }
        let dgc_savePath = self.outputUrl
        let dgc_isSave = DGCChatFileTool.share.saveDataToPath(data: dgc_videoData, path: dgc_savePath)
        if dgc_isSave{
            dgc_callComple(true)
        }else{
            dgc_callComple(false)
        }
    }
    
    private func dgc_callComple(_ isOK : Bool)  {
//        if isOK{//生成缩略图
//            let dgc_url = URL(fileURLWithPath: outputUrl)
//            let dgc_asset = AVURLAsset(url: dgc_url)
//            genThumb(dgc_asset)
//            ICLog("导出视频成功缩略图")
//        }
        DispatchQueue.main.async {
            self.dgc_compleHandler?(isOK)
        }
    }
    
}
