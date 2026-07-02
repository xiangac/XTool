//
//  XFont.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

//MARK: 无感全局字体动态缩放
// 💡 使用效果：
// 在工程启动（main / AppDelegate）时执行：UIFont.x_enableDynamicFontRules()
// 之后你全项目写 `UIFont.systemFont(ofSize: 16)`，在所有屏幕和系统大字模式下，都会完美自动等比缩放！
@MainActor
public extension UIFont {
    /// 一键开启全局字体自动化等比例动态缩放
    static func x_enableDynamicFontRules() {
        let originalSelector = #selector(UIFont.systemFont(ofSize:))
        let swizzledSelector = #selector(UIFont.x_systemFont(ofSize:))
        
        guard let originalMethod = class_getClassMethod(UIFont.self, originalSelector),
              let swizzledMethod = class_getClassMethod(UIFont.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc private static func x_systemFont(ofSize fontSize: CGFloat) -> UIFont {
        // 1. 联动我们之前的物理像素缩放逻辑，计算出当前屏幕的最佳磅数
        let baseWidth: CGFloat = 393.0
        let currentWidth = UIScreen.main.bounds.width
        let scaledSize = (fontSize * currentWidth) / baseWidth
        
        // 2. 联动系统的 UIFontMetrics，让字体自动支持 iOS 系统设置里的“显示与亮度 -> 字体大小”
        let font = UIFont.x_systemFont(ofSize: scaledSize) // 因为 Method Swizzling，这行实际调用的是原生的 systemFont
        return UIFontMetrics.default.scaledFont(for: font)
    }
}


