//
//  DGCChatFileTool.swift
//  ManGo
//
//  Created by mango2333 on 2024/3/7.
//

import Foundation

public class DGCChatFileTool {
    
    public static let share = DGCChatFileTool()
    
    public enum MGPathType : String , CaseIterable {
        case db = "db/"
        case image = "image/"
        case video = "video/"
        case sound = "sound/"
    }

    @available(*, deprecated, renamed: "MGPathType")
    public typealias DGCPathType = MGPathType
    
    //每个文件夹下最大缓存个数
    private let dgc_maxCache : [MGPathType: Int] = [
        .db : 5,
        .image : 100,
        .video : 80,
        .sound : 80,
    ]
    
    private let dgc_fileManager = FileManager.default
    private var dgc_rootDirectory : String = ""

    private init() {
        createAllDirectory()
    }
    
    // 创建缓存路径
    func createAllDirectory() {
        let dgc_paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        // 根目录
        let dgc_doucmentDirectory = dgc_paths.first ?? ""
        dgc_rootDirectory = dgc_doucmentDirectory+"/DGCChatMessage/"
        // 把所有文件夹都创建好
        CMLog("createDirectory-dgc_rootDirectory=\(dgc_rootDirectory)")
        MGPathType.allCases.forEach { type in
            let dgc_dirPath = dgc_rootDirectory + type.rawValue
            dgc_createOneDirectory(dgc_dirPath)
        }
    }
    
    private func dgc_createOneDirectory(_ dir: String)  {
        let dgc_isExists = dgc_fileManager.fileExists(atPath: dir)
        if dgc_isExists == false{
            do {
                try dgc_fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
                CMLog("dgc_createOneDirectory==success==\(dir)")
            } catch let dgc_err {
                CMLog("dgc_createOneDirectory=fail=\(dir) dgc_err = \(dgc_err)")
            }
        }
    }
    
    public static func genImagePath(sID : String, imageName dgc_imageName : String? = nil, pathExtension: String = "png") -> String {
        let dgc_userID = DGCChatManager.share.getUserId()+sID
        let dgc_value = arc4random() % 1000
        let dgc_uuid = String(format: "%ld_%ld", Date().timeIntervalSince1970,dgc_value)
        
        var dgc_name : String
        if let dgc_imageName = dgc_imageName{
            dgc_name = String(format: "%@_image_%@_%@.%@", dgc_userID,dgc_uuid,dgc_imageName, pathExtension)
        }else{
            dgc_name = String(format: "%@_image_%@.%@", dgc_userID,dgc_uuid,pathExtension)
        }
        let dgc_path = Self.share.getDirPath(.image)+dgc_name
        return dgc_path
    }
    
    // 清理整个会话缓存文件
    func clearChatSection(sID : String) {
        DispatchQueue.global().async {
            self.dgc__clearChatSection(sID: sID)
        }
    }
    
    // 真正清理会话缓存
    private func dgc__clearChatSection(sID : String) {
        let dgc_userID = DGCChatManager.share.getUserId()+sID
        MGPathType.allCases.forEach { type in
            if type == .db{return} //数据库不用操作
            let dgc_dirPath = dgc_rootDirectory+type.rawValue
            do{
                let dgc_fileList = try dgc_fileManager.contentsOfDirectory(atPath: dgc_dirPath)
                dgc_fileList.forEach { path in
                    if path.contains(dgc_userID){//删除
                        let dgc_fPath = dgc_dirPath + path //拼接完整路径
                        try? dgc_fileManager.removeItem(atPath: dgc_fPath)
                    }
                }
            }catch _ {
                
            }
        }
    }
    
    public static func genAudioPath(sID : String, audioName : String? = nil) -> String {
        DGCChatFileTool.share.genAudioPath(sID: sID, audioName: audioName)
    }
    
    public static func genVideoPath(sID : String, videoName : String? = nil) -> String {
        DGCChatFileTool.share.genVideoPath(sID: sID, videoName:videoName)
    }
    
    public func genAudioPath(sID : String, audioName dgc_audioName : String? = nil) -> String {
        let dgc_userID = DGCChatManager.share.getUserId()+sID
        let dgc_value = arc4random() % 1000
        let dgc_uuid = String(format: "%ld_%ld", Date().timeIntervalSince1970,dgc_value)
        var dgc_name = "\(dgc_userID)_audio_\(dgc_uuid)"
        
        if let dgc_audioName = dgc_audioName{
            dgc_name = "\(dgc_name)_\(dgc_audioName)"
        }
        dgc_name = dgc_name.md5 // 变短一点 太长路径读取可能会失败
        dgc_name = "\(dgc_name).aac"
        let dgc_path = Self.share.getDirPath(.sound)+dgc_name
        return dgc_path
    }

    public func genVideoPath(sID : String, videoName dgc_videoName : String? = nil) -> String {
        let dgc_userID = DGCChatManager.share.getUserId()+sID
        let dgc_value = arc4random() % 1000
        let dgc_uuid = String(format: "%ld_%ld", Date().timeIntervalSince1970,dgc_value)
        
        var dgc_name = "\(dgc_userID)_video_\(dgc_uuid)"
        if let dgc_videoName = dgc_videoName{
            dgc_name = "\(dgc_name)_\(dgc_videoName)"
        }
        dgc_name = dgc_name.md5 // 变短一点 太长路径读取可能会失败
        dgc_name = "\(dgc_name).mp4"
        let dgc_path = Self.share.getDirPath(.video)+dgc_name
        if dgc_fileManager.fileExists(atPath: dgc_path){
            try? dgc_fileManager.removeItem(atPath: dgc_path)
        }
        return dgc_path
    }
    
    
    func getDirPath(_ type : MGPathType) -> String {
        dgc_rootDirectory+type.rawValue
    }
    
    func getFilePath(name : String, _ type : MGPathType) -> String {
        dgc_rootDirectory+type.rawValue+name
    }
    
    ///Documents之前的删除掉 document每次会变
    //重新生产当前Documents下的路径
    func getCurrDocumentsPath(oldPath : String) -> String {
        if let dgc_path = oldPath.components(separatedBy: "/DGCChatMessage/").last{
            return dgc_rootDirectory+dgc_path
        }
        return oldPath
    }
    
    func saveImageToPath(data : Data?, imageName : String? = nil,sID : String, pathExtension: String = "png") -> String {
        let dgc_path = DGCChatFileTool.genImagePath(sID: sID, imageName:imageName, pathExtension: pathExtension)
        
        if dgc_fileManager.fileExists(atPath: dgc_path){
            try? dgc_fileManager.removeItem(atPath: dgc_path)
        }
        dgc_fileManager.createFile(atPath: dgc_path, contents: data)
        return dgc_path
    }
    
    
    @discardableResult
    func saveDataToPath(data : Data?,path : String) -> Bool {
        if dgc_fileManager.fileExists(atPath: path){
            try? dgc_fileManager.removeItem(atPath: path)
        }
        return dgc_fileManager.createFile(atPath: path, contents: data)
    }
    
    public static func fileExists(path : String) -> Bool{
        DGCChatFileTool.share.fileExists(path: path)
    }
    
    func fileExists(path : String) -> Bool{
        dgc_fileManager.fileExists(atPath: path)
    }
    
    /// 保存新文件时 清理缓存机制 当达到设置的阀值开始进行清理操作
    /// - Parameter currSavePath: 当前需要保存文件的路径 空则全局清理
    func saveClearMaxCache(currSavePath : String? = nil) {
        CMLog("saveClearMaxCache=====清理最大目录缓存")
        if let dgc_cPath  = currSavePath {
            //把所有文件夹都创建好
            for type in MGPathType.allCases {
                let dgc_dirPath = dgc_rootDirectory+type.rawValue
                if dgc_cPath.contains(dgc_dirPath) {//包含当前目录
                    CMLog("saveClearMaxCache====找到了need清理的目录=\(type.rawValue)")
                    dgc__clearDirCache(csPath: dgc_cPath, type:type)
                    return
                }
            }
        }
        //清理全局文件
    }
    
    private func dgc__clearDirCache(csPath : String , type : MGPathType) {
        CMLog("_clearDirCache开始清理=\(type.rawValue)")
        let dgc_dirPath = dgc_rootDirectory+type.rawValue
        //只清理该目录下的文件
        let dgc_maxCacheCount = dgc_maxCache[type] ?? 0
        if dgc_maxCacheCount <= 0 {
            //没有限制
            CMLog("maxCacheCount没有限制---end")
            return
        }
        CMLog("dgc__clearDirCache---找到目录下的all文件")
        do {
            let dgc_fileList = try dgc_fileManager.contentsOfDirectory(atPath: dgc_dirPath)
            if dgc_fileList.isEmpty{
                CMLog("dgc_fileList.isEmpty---清理end")
                return
            }
            CMLog("找到了目录下的all列表=\nFM---\(dgc_fileList)")
//            dgc_fileList.removeAll { dgc_item in
//                dgc_item.hasSuffix(".DS_Store")
//            }
//            CMLog("处理后目录下的文件列表=\nFM---\(dgc_fileList)")
            if dgc_fileList.count < dgc_maxCacheCount{
                CMLog("文件数小于maxCacheCount---清理end")
                return
            }
            //转换数据
            var dgc_fileArr = dgc_fileList.map { file in
                let dgc_path = dgc_dirPath.appending(file)
                var dgc_item = DGCChatFileModel()
                dgc_item.getFileAttrInfo(dgc_path)
                return dgc_item
            }
            //按照时间排序
            dgc_fileArr = dgc_fileArr.sorted { file1, file2 in
                if let dgc_d1 = file1.date , let dgc_d2 = file2.date{
                    return dgc_d2.compare(dgc_d1) == .orderedAscending //降序 最新的在最前面
                }
                return true
            }
            //删除最后一个文件
            CMLog("开始清理, 准备删除文件")
            let dgc_start = dgc_maxCacheCount - 1
            
            for index in dgc_start..<dgc_fileArr.count {
                do {
                    let dgc_item = dgc_fileArr[index]
                    try dgc_fileManager.removeItem(atPath: dgc_item.path)
                    CMLog("delete文件success--index=\(index)")
                } catch let dgc_err {
                    CMLog("delete文件fail--index=\(index) dgc_err=\(dgc_err)")
                }
            }
            CMLog("clear--complete---清理end")
        } catch let dgc_err {
            CMLog("dgc__clearDirCache--catch-----清理end---=\(dgc_err)")
        }
    }
    
    //获取文件或目录的大小
//    public func getCacheSize(of path: String) -> UInt64 {
//        let dgc_fileManager = FileManager.default
//        var isDirectory: ObjCBool = false
//        if dgc_fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
//            if isDirectory.boolValue {
//                var totalSize: UInt64 = 0
//                if let contents = try? dgc_fileManager.contentsOfDirectory(atPath: path) {
//                    for content in contents {
//                        let contentPath = (path as NSString).appendingPathComponent(content)
//                        totalSize += getCacheSize(of: contentPath)
//                    }
//                }
//                return totalSize
//            } else {
//                do {
//                    let attributes = try dgc_fileManager.attributesOfItem(atPath: path)
//                    if let fileSize = attributes[.size] as? UInt64 {
//                        return fileSize
//                    }
//                } catch {
//                    debugDGCLog.info("Error: \(error)")
//                }
//            }
//        }
//        return 0
//    }
}
/*
/// 清除缓存功能相关
extension DGCChatFileTool {
    /// 获取 文件夹们 大小
    public func getFileSize(files: [MGPathType], block: @escaping ((UInt64) -> Void)) {
        DispatchQueue.global().async {
            var dgc_totalSize: UInt64 = 0
            for file in files {
                dgc_totalSize = dgc_totalSize + self.dgc__getFileSize(file: file)
            }
            ChatCallInMain {
                block(dgc_totalSize)
            }
        }
    }
    
    /// 获取单个文件夹的大小
    private func dgc__getFileSize(file: MGPathType) -> UInt64 {
        let dgc_folderURL = URL(fileURLWithPath: dgc_rootDirectory + file.rawValue)
        do {
            let dgc_folders = try FileManager.default.contentsOfDirectory(atPath: dgc_folderURL.path)
            var dgc_totalFolderSize: UInt64 = 0
            for folder in dgc_folders {
                let dgc_folderPath = dgc_folderURL.appendingPathComponent(folder).path
                
                let dgc_folderSize = getCacheSize(of: dgc_folderPath)
                dgc_totalFolderSize += dgc_folderSize
            }
            return dgc_totalFolderSize
        } catch {
            debugDGCLog.info("Error: \(error)")
        }
        return 0
    }
    
    /// 删除指定 文件夹们 下的文件
    public func clearFileCache(files: [MGPathType], block: @escaping (() -> Void)) {
        DispatchQueue.global().async {
            for file in files {
                self.dgc__clearFileCache(file: file)
            }
            ChatCallInMain {
                block()
            }
        }
    }
    
    /// 删除指定 文件夹 下的文件
    private func dgc__clearFileCache(file: MGPathType) {
        do {
            let dgc_folderURL = URL(fileURLWithPath: dgc_rootDirectory + file.rawValue)
            
            let dgc_folders = try FileManager.default.contentsOfDirectory(atPath: dgc_folderURL.path)
            for folder in dgc_folders {
                let dgc_folderPath = dgc_folderURL.appendingPathComponent(folder).path
                try dgc_fileManager.removeItem(atPath: dgc_folderPath)
            }
            CMLog("delete缓存成功--file=\(file.rawValue)")
        } catch let dgc_err {
            CMLog("delete缓存失败--file=\(file.rawValue) dgc_err=\(dgc_err)")
        }
    }
}
*/

struct DGCChatFileModel {
    
    var path : String = ""
    var isDir : Bool = false
    
    var date : Date?
    
    mutating func getFileAttrInfo(_ path : String) {
        self.path = path
        if let dgc_info = try? FileManager.default.attributesOfItem(atPath: path){
            date = dgc_info[FileAttributeKey.creationDate] as? Date
        }
    }
}

import CryptoKit
extension String{
    var md5: String {
        let digest = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}
