//
//  XImage.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

//MARK: 图片缩放与压缩
public extension UIImage {
    
    /// 1. 缩放图片尺寸到指定的最大宽度 (等比例缩放)
    func x_resize(toWidth targetWidth: CGFloat) -> UIImage? {
        let size = self.size
        let widthRatio = targetWidth / size.width
        // 如果图片本来就很小，就不放大它了
        guard widthRatio < 1.0 else { return self }
        
        let newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// 2. 压缩图片质量，使其文件大小控制在指定的 KB 以内
    /// - Parameter maxBytes: 最大字节数，例如 500KB 传 500 * 1024
    func x_compressTo(maxBytes: Int) -> Data? {
        var compression: CGFloat = 1.0
        guard var data = self.jpegData(compressionQuality: compression) else { return nil }
        if data.count < maxBytes { return data }
        
        // 二分法快速逼近目标大小
        var max: CGFloat = 1.0
        var min: CGFloat = 0.0
        
        for _ in 0..<6 { // 迭代6次足够精准
            compression = (max + min) / 2
            if let imageData = self.jpegData(compressionQuality: compression) {
                data = imageData
                if imageData.count < Int(Double(maxBytes) * 0.9) {
                    min = compression
                } else if imageData.count > maxBytes {
                    max = compression
                } else {
                    break
                }
            }
        }
        return data
    }
}
