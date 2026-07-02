//
//  XView.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

public extension UIView {
    
    /// 1. 指定位置的切角处理
    func clipSpecifiedCorners(
        _ corners: UIRectCorner,
        withRadius radius: CGFloat
    ) {
        let path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    
    /// 2. 绘制线性渐变背景
    func applyLinearGradient(
        colors: [CGColor],
        locations: [NSNumber]?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = self.bounds
        
        // 插入到最底层
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// 3. 基础圆角配置
    func applyCornerRadius(_ radius: CGFloat) {
        self.renderSurface(radius: radius, borderWidth: 0, borderColor: nil)
    }
    
    /// 4. 自定义遮罩切角
    func setupMaskLayout(
        corners: UIRectCorner,
        radius: CGFloat
    ) {
        var finalRadius = radius
        if finalRadius == -1 {
            finalRadius = self.bounds.height / 2.0 // 统一使用 bounds 比 frame 更安全
        }
        
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: finalRadius, height: finalRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
    
    /// 5. 完整边框与圆角设置
    func renderSurface(
        radius: CGFloat,
        borderWidth: CGFloat,
        borderColor: UIColor?
    ) {
        self.layer.cornerRadius = radius
        self.layer.borderWidth = borderWidth
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        } else {
            self.layer.borderColor = nil
        }
        self.layer.masksToBounds = true
    }
    
    /// 6. 快速实现半圆角效果（胶囊风格）
    func configCapsuleStyle() {
        let halfHeight = self.bounds.height / 2.0
        self.renderSurface(radius: halfHeight, borderWidth: 0, borderColor: nil)
    }
}

public extension UIView {
    /// 临时限制视图的交互能力（默认防刷时间为 0.5 秒）
    /// - Parameter targetView: 需要限制交互的视图
    @MainActor
    static func restrictInteraction(for targetView: UIView,seconds:Double = 0.5) {
        // 1. 禁用交互
        targetView.isUserInteractionEnabled = false
        
        // 2. 开启一个现代化的异步任务来处理延迟恢复
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            // 3. 恢复交互
            targetView.isUserInteractionEnabled = true
        }
    }
}
