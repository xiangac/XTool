//
//  XFloat.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

public extension CGFloat {
    
    /// 屏幕适配：以指定设计图宽度（默认 393.0pt，即 iPhone 14/15 宽度）为基准，等比例缩放当前数值
    /// - Usage: `view.frame.size.width = 100.x_scaled` -> 在不同屏幕下自动放大或缩小
    @MainActor
    var x_scaled: CGFloat {
        let baseWidth: CGFloat = 393.0
        let currentWidth = UIDevice.screenWidth
        return self * (currentWidth / baseWidth)
    }
}

// 顺便让 Double 和 Int 也支持无缝调用缩放
public extension Double {
    @MainActor
    var x_scaled: CGFloat { CGFloat(self).x_scaled }
}

public extension Int {
    @MainActor
    var x_scaled: CGFloat { CGFloat(self).x_scaled }
}

public extension CGFloat {
    /// 价格资产等数据保留指定位数的小数（四舍五入）
    func x_roundTo(places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return (self * divisor).rounded() / divisor
    }
}
