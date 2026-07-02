//
//  XCAGradientLayer.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// 💡 使用效果：
// let bgLayer = CAGradientLayer.x_gradient(colors: [.red, .blue], direction: .leftToRight)
// bgLayer.frame = myView.bounds
// myView.layer.insertSublayer(bgLayer, at: 0)
public extension CAGradientLayer {
    
    /// 渐变方向枚举
    enum x_Direction {
        case topToBottom
        case bottomToTop
        case leftToRight
        case rightToLeft
        case topLeftToBottomRight
    }
    
    /// 快速创建渐变图层
    /// - Parameters:
    ///   - colors: 颜色数组 (UIColor)
    ///   - direction: 渐变方向
    /// - Returns: 配置好的 CAGradientLayer
    static func x_gradient(colors: [UIColor], direction: x_Direction = .leftToRight) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        
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
