//
//  XLayout.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

/// 布局与屏幕适配相关常量 / 工具
public enum XLayout {
    /// 设计稿基准宽度（iPhone 14/15 逻辑宽度）
    public static let baseWidth: CGFloat = 393.0
    
    /// 当前用于适配的宽度（与 `UIDevice.x_screenWidth` 同源：优先 Key Window）
    @MainActor
    public static var currentWidth: CGFloat {
        UIDevice.x_screenWidth
    }
    
    /// 将设计稿数值按当前宽度等比缩放（内部缓存缩放系数，热路径可安全频繁调用）
    @MainActor
    public static func scaled(_ value: CGFloat) -> CGFloat {
        value * XLayoutMetricsCache.layoutScaleFactor(baseWidth: baseWidth)
    }
}

public extension CGFloat {
    
    /// 以 `XLayout.baseWidth` 为基准，将当前数值等比缩放到当前屏幕宽度
    /// - Usage: `view.frame.size.width = 100.x_scaled`
    @MainActor
    var x_scaled: CGFloat {
        XLayout.scaled(self)
    }
    
    /// 将数值四舍五入到指定小数位
    /// - Parameter places: 保留的小数位数
    /// - Returns: 四舍五入后的结果
    func x_roundTo(places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return (self * divisor).rounded() / divisor
    }
}

public extension Double {
    /// 将 `Double` 按设计稿宽度等比缩放
    @MainActor
    var x_scaled: CGFloat { CGFloat(self).x_scaled }
}

public extension Int {
    /// 将 `Int` 按设计稿宽度等比缩放
    @MainActor
    var x_scaled: CGFloat { CGFloat(self).x_scaled }
}
