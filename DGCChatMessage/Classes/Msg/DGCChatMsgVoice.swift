//
//  DGCChatMsgVoice.swift
//  Pods
//
//  Created by mango2333 on 2024/6/5.
//

import Foundation

public class DGCChatMsgVoice: DGCChatMsg {
    
    private override init() {
        super.init()
        type = .Voice
    }
    
    // 音频文件路径本地
    public var voicePath: String = ""
    // 总时间
    public var duration : CGFloat = 0
    
    public convenience init(voicePath : String, duration: CGFloat) {
        self.init()
        self.voicePath = voicePath
        self.duration = duration
    }
    
    
    
    private var dgc_isDownloading: Bool = false
    
    // 下载音频文件链接
    public func downloadVoice(progressBlock :@escaping (_ progress : CGFloat)->Void, complete :@escaping ((_ isOk : Bool, _ dgc_path: String?)->Void)) {
        if self.voicePath.isEmpty == false {
            complete(true, voicePath)
            return
        }
        if dgc_isDownloading {
            return
        }
        dgc_isDownloading = true
        
        self._downLoadVoice { progress in
            progressBlock(progress)
        } complete: {[weak self] isOk, dgc_path in
            self?.dgc_isDownloading = false
            if isOk , let dgc_path = dgc_path{
                self?.voicePath = dgc_path
                complete(true,dgc_path)
            }else{
                complete(false,nil)
            }
        }
    }
}

