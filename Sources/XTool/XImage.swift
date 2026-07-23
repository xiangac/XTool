//
//  XImage.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// MARK: - 缩放与压缩
public extension UIImage {
    /// 等比例缩放到指定最大宽度；原图更小时不放大
    /// - Parameter targetWidth: 目标最大宽度
    /// - Returns: 缩放后的图片；宽度非法时返回 `nil`
    func x_resize(toWidth targetWidth: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0, targetWidth > 0 else { return nil }
        
        let widthRatio = targetWidth / size.width
        guard widthRatio < 1.0 else { return self }
        
        let newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        return x_render(to: newSize)
    }
    
    /// 压缩 JPEG 体积到指定字节数以内：先阶梯缩小，再质量二分
    /// - Parameter maxBytes: 最大字节数，例如 `500 * 1024`
    /// - Returns: 尽量 ≤ `maxBytes` 的 JPEG Data；极端情况仍可能略超（已尽最大缩小 + 最低质量）
    func x_compressTo(maxBytes: Int) -> Data? {
        guard maxBytes > 0 else { return nil }
        guard size.width > 0, size.height > 0 else { return nil }
        
        var image: UIImage = self
        var bestUnderLimit: Data?
        var smallestOverLimit: Data?
        
        // 宽度阶梯：原图 → 0.7 → 0.5 → 0.35 → 0.25
        let scaleSteps: [CGFloat] = [1.0, 0.7, 0.5, 0.35, 0.25]
        
        for step in scaleSteps {
            if step < 1.0 {
                let targetWidth = size.width * step
                guard let resized = x_resize(toWidth: targetWidth) else { continue }
                image = resized
            }
            
            guard let qualityResult = image.x_jpegBinarySearch(maxBytes: maxBytes) else { continue }
            if let under = qualityResult.underLimit {
                if bestUnderLimit == nil || under.count > bestUnderLimit!.count {
                    bestUnderLimit = under
                }
                // 已达标且接近上限，无需继续缩小
                if under.count >= Int(Double(maxBytes) * 0.85) {
                    return under
                }
                // 已有合格结果，可提前结束后续更小尺寸
                return under
            }
            if let over = qualityResult.smallestOverLimit {
                if smallestOverLimit == nil || over.count < smallestOverLimit!.count {
                    smallestOverLimit = over
                }
            }
        }
        
        return bestUnderLimit ?? smallestOverLimit
    }
    
    /// 对当前尺寸做 JPEG 质量二分
    private func x_jpegBinarySearch(maxBytes: Int) -> (underLimit: Data?, smallestOverLimit: Data?)? {
        guard let data = jpegData(compressionQuality: 1.0) else { return nil }
        if data.count <= maxBytes {
            return (data, nil)
        }
        
        var maxQuality: CGFloat = 1.0
        var minQuality: CGFloat = 0.0
        var bestUnderLimit: Data?
        var smallestOverLimit = data
        
        for _ in 0..<8 {
            let compression = (maxQuality + minQuality) / 2
            guard let imageData = jpegData(compressionQuality: compression) else { break }
            
            if imageData.count > maxBytes {
                maxQuality = compression
                if imageData.count < smallestOverLimit.count {
                    smallestOverLimit = imageData
                }
            } else {
                minQuality = compression
                if bestUnderLimit == nil || imageData.count > bestUnderLimit!.count {
                    bestUnderLimit = imageData
                }
                if imageData.count >= Int(Double(maxBytes) * 0.9) {
                    break
                }
            }
        }
        return (bestUnderLimit, smallestOverLimit)
    }
    
    private func x_render(to newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - 渲染性能体检（DEBUG）
public extension UIImageView {
    /// DEBUG 下高亮可能引发离屏渲染 / 像素混合的 ImageView
    /// - Note: 红框 = 单项隐患；紫框 = 双重隐患
    func x_debugPerformanceCheck() {
        #if DEBUG
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let hasAlphaRisk = backgroundColor == nil && !isOpaque
            let hasCornerRisk = layer.cornerRadius > 0 && layer.masksToBounds
            
            if hasAlphaRisk && hasCornerRisk {
                layer.borderColor = UIColor.purple.cgColor
                layer.borderWidth = 2.0
            } else if hasAlphaRisk || hasCornerRisk {
                layer.borderColor = UIColor.red.cgColor
                layer.borderWidth = 1.5
            }
        }
        #endif
    }
}
