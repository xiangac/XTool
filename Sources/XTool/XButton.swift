//
//  XButton.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// 💡 使用效果：
// 在 AppDelegate / 项目初始化时执行一次：UIButton.x_enableDebounce()
// 之后全项目的 UIButton 都会自动获得“防连击”金身。想针对某个按钮改间隔改：btn.x_clickDelay = 1.0
public extension UIButton {
    /// 连击的时间间隔限制（单位：秒），默认 0.5 秒内连续点击无效
    var x_clickDelay: TimeInterval {
        get { objc_getAssociatedObject(self, &UIButton.clickDelayKey) as? TimeInterval ?? 0.5 }
        set { objc_setAssociatedObject(self, &UIButton.clickDelayKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 开启防连击机制（替换系统的 sendAction）
    static func x_enableDebounce() {
        let originalSelector = #selector(UIButton.sendAction(_:to:for:))
        let swizzledSelector = #selector(UIButton.x_sendAction(_:to:for:))
        
        guard let originalMethod = class_getInstanceMethod(UIButton.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIButton.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIButton {
    private static var lastClickTimeKey: UInt8 = 0
    private static var clickDelayKey: UInt8 = 0
        
    private var lastClickTime: TimeInterval {
        get { objc_getAssociatedObject(self, &UIButton.lastClickTimeKey) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &UIButton.lastClickTimeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
        
    @objc private func x_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastClickTime < x_clickDelay {
            // 💡 时间太短，拦截不执行
            return
        }
        lastClickTime = currentTime
        // 执行原本的方法
        x_sendAction(action, to: target, for: event)
    }
}
