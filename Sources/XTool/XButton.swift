//
//  XButton.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// 启动时调用一次：UIButton.x_enableDebounce()
// 单独调整：btn.x_debounceInterval = 1.0
public extension UIButton {
    /// 防抖间隔（秒），默认 0.5；间隔内的「新一次点击」无效
    /// - Note: 同一次点击触发的多个 target/action 都会放行，不会互掐
    var x_debounceInterval: TimeInterval {
        get { objc_getAssociatedObject(self, &UIButton.debounceIntervalKey) as? TimeInterval ?? 0.5 }
        set { objc_setAssociatedObject(self, &UIButton.debounceIntervalKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 开启全局按钮防连击（Method Swizzling，仅生效一次）
    /// - Note: 建议 App 启动时调用一次；重复调用会被忽略
    static func x_enableDebounce() {
        swizzleLock.lock()
        defer { swizzleLock.unlock() }
        guard !hasSwizzled else { return }
        
        let originalSelector = #selector(UIControl.sendAction(_:to:for:))
        let swizzledSelector = #selector(UIButton.x_sendAction(_:to:for:))
        
        guard let originalMethod = class_getInstanceMethod(UIButton.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIButton.self, swizzledSelector) else { return }
        
        // 若 sendAction 来自父类 UIControl，先把实现加到 UIButton，避免污染 UISwitch 等控件
        let didAdd = class_addMethod(
            UIButton.self,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        if didAdd {
            class_replaceMethod(
                UIButton.self,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        hasSwizzled = true
    }
}

extension UIButton {
    private static var lastAcceptedClickTimeKey: UInt8 = 0
    private static var allowedEventTimestampKey: UInt8 = 0
    private static var debounceIntervalKey: UInt8 = 0
    private static var hasSwizzled = false
    private static let swizzleLock = NSLock()
    
    /// 同一代码触发批次的时间窗（秒）：多个 target 同步 sendAction 时共用
    private static let programmaticBatchWindow: TimeInterval = 0.05
    
    /// 上次「接受」的新点击时间
    private var lastAcceptedClickTime: TimeInterval {
        get { objc_getAssociatedObject(self, &UIButton.lastAcceptedClickTimeKey) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &UIButton.lastAcceptedClickTimeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前已放行手势对应的 `UIEvent.timestamp`；同 event 的多次 sendAction 都放行
    private var allowedEventTimestamp: TimeInterval {
        get { objc_getAssociatedObject(self, &UIButton.allowedEventTimestampKey) as? TimeInterval ?? -.greatestFiniteMagnitude }
        set { objc_setAssociatedObject(self, &UIButton.allowedEventTimestampKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 是否为需要防抖的「点击完成」事件（touch ended / 无 event 的代码触发）
    private func x_isClickComplete(_ event: UIEvent?) -> Bool {
        guard let event else { return true }
        guard event.type == .touches else { return false }
        return event.allTouches?.contains { $0.phase == .ended } == true
    }
    
    /// 是否应拦截本次 sendAction
    private func x_shouldBlockAction(for event: UIEvent?) -> Bool {
        guard x_isClickComplete(event) else { return false }
        
        let now = Date().timeIntervalSince1970
        
        if let event {
            let timestamp = event.timestamp
            // 同一次点击（同一 UIEvent）的多个 target：全部放行
            if timestamp == allowedEventTimestamp {
                return false
            }
            // 新的一次点击，仍在防抖间隔内：拦截
            if now - lastAcceptedClickTime < x_debounceInterval {
                return true
            }
            lastAcceptedClickTime = now
            allowedEventTimestamp = timestamp
            return false
        }
        
        // 代码触发（event == nil）：同步多 target 视为同一批次
        if now - lastAcceptedClickTime < x_debounceInterval {
            if now - lastAcceptedClickTime <= Self.programmaticBatchWindow {
                return false
            }
            return true
        }
        lastAcceptedClickTime = now
        allowedEventTimestamp = -.greatestFiniteMagnitude
        return false
    }
    
    @objc private func x_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if x_shouldBlockAction(for: event) {
            return
        }
        x_sendAction(action, to: target, for: event)
    }
}
