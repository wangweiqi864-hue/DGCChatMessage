//
//  DGCChatMsgImage.swift
//  Pods
//
//  Created by mango-linwieyan on 2024/4/16.
//

import Foundation
import ImSDK_Plus

public class DGCChatMsgImage : DGCChatMsg {
    
    public var path : String = ""
    
    public var Url : String = ""
    
    public internal(set) var originalModel = DGCChatMsgImageItem()
    public internal(set) var thumbModel = DGCChatMsgImageItem()
    
    public override init() {
        super.init()
        type = .Image
    }
        
    public func handleImage(image : UIImage) {
        
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
        thumbModel = DGCChatMsgImageItem(width: dgc_picThumbWidth,height: dgc_picThumbHeight,url: dgc_thumbPath)

        let dgc_origalPath = DGCChatFileTool.share.saveImageToPath(data: UIImageJPEGRepresentation(image, 1), sID: sendID)
        originalModel = DGCChatMsgImageItem(width: dgc_picWidth,height: dgc_picHeight,url: dgc_origalPath)
        Url = dgc_origalPath
    }
    
    public func handleGif(imageSize: CGSize, data: Data) {
        
//        let dgc_maxHeight : CGFloat = 150
//        let dgc_maxWidth : CGFloat = 150
//        var dgc_scale : CGFloat = 1
//        dgc_scale = min(dgc_maxHeight/imageSize.height, dgc_maxWidth/imageSize.width)
//        
//        let dgc_picHeight = imageSize.height;
//        let dgc_picWidth = imageSize.width;
//        
//        let dgc_picThumbHeight = dgc_picHeight * dgc_scale
//        let dgc_picThumbWidth = dgc_picWidth * dgc_scale
//
//        thumbModel = DGCChatMsgImageItem(width: dgc_picWidth,height: dgc_picHeight,url: imageUlr)
//        originalModel = DGCChatMsgImageItem(width: dgc_picWidth,height: dgc_picHeight,url: imageUlr)
//        Url = imageUlr
        
        let dgc_maxHeight : CGFloat = 150
        let dgc_maxWidth : CGFloat = 150
//
        var dgc_scale : CGFloat = 1
        dgc_scale = min(dgc_maxHeight/imageSize.height, dgc_maxWidth/imageSize.width)
        
        let dgc_picHeight = imageSize.height;
        let dgc_picWidth = imageSize.width;
        
        let dgc_picThumbHeight = dgc_picHeight * dgc_scale
        let dgc_picThumbWidth = dgc_picWidth * dgc_scale

        //创建缩略图
//        let dgc_thumbImage = image.scaleWithImage(size: CGSize(width: dgc_picThumbWidth, height: dgc_picThumbHeight))
        let dgc_imagePath = DGCChatFileTool.share.saveImageToPath(data: data, sID: sendID, pathExtension: "gif")
        thumbModel = DGCChatMsgImageItem(width: dgc_picThumbWidth,height: dgc_picThumbHeight,url: dgc_imagePath)
        originalModel = DGCChatMsgImageItem(width: dgc_picWidth,height: dgc_picHeight,url: dgc_imagePath)
        Url = dgc_imagePath
    }
}

public class DGCChatMsgImageItem : Codable {
    //宽
    public internal(set) var width : CGFloat = 0
    //高
    public internal(set) var height : CGFloat = 0
    //图片地址
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

extension UIImage{
    
    //缩小图片到指定大小
    func scaleWithImage(size : CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let dgc_nImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if dgc_nImage != nil{
            return dgc_nImage!
        }
        return self
    }
}

