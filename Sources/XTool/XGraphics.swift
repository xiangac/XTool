//
//  XGraphics.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// MARK: - 渐变方向
/// 渐变方向
public enum XGradientDirection {
    /// 上 → 下
    case topToBottom
    /// 下 → 上
    case bottomToTop
    /// 左 → 右
    case leftToRight
    /// 右 → 左
    case rightToLeft
    /// 左上 → 右下
    case topLeftToBottomRight
}

public extension CAGradientLayer {
    /// 快速创建渐变图层
    /// - Parameters:
    ///   - colors: 颜色数组
    ///   - direction: 渐变方向，默认从左到右
    /// - Returns: 配置好的 `CAGradientLayer`
    static func x_gradient(
        colors: [UIColor],
        direction: XGradientDirection = .leftToRight
    ) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map(\.cgColor)
        
        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        case .bottomToTop:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        case .rightToLeft:
            gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.5)
        case .topLeftToBottomRight:
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        }
        return gradientLayer
    }
}

// MARK: - 缩放动画
/// 常用动画工厂
public enum XAnimation {
    /// 创建缩放动画
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - fromValue: 起始缩放
    ///   - toValue: 结束缩放
    ///   - autoreverses: 是否自动反向
    ///   - repeatCount: 重复次数
    ///   - isRemovedOnCompletion: 完成后是否移除
    public static func x_scaleAnimation(
        duration: CFTimeInterval = 0.5,
        fromValue: Any = 1.0,
        toValue: Any = 1.0,
        autoreverses: Bool = true,
        repeatCount: Float = .infinity,
        isRemovedOnCompletion: Bool = false
    ) -> CABasicAnimation {
        CABasicAnimation.x_scaleAnimation(
            duration: duration,
            fromValue: fromValue,
            toValue: toValue,
            autoreverses: autoreverses,
            repeatCount: repeatCount,
            isRemovedOnCompletion: isRemovedOnCompletion
        )
    }
}

public extension CABasicAnimation {
    /// 创建 `transform.scale` 缩放动画
    static func x_scaleAnimation(
        duration: CFTimeInterval = 0.5,
        fromValue: Any = 1.0,
        toValue: Any = 1.0,
        autoreverses: Bool = true,
        repeatCount: Float = .infinity,
        isRemovedOnCompletion: Bool = false
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = duration
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.autoreverses = autoreverses
        animation.repeatCount = repeatCount
        animation.setValue("scaleAnimation", forKey: "scale")
        animation.isRemovedOnCompletion = isRemovedOnCompletion
        return animation
    }
}
