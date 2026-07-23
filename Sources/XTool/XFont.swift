//
//  XFont.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit
import ObjectiveC

// 启动时调用：UIFont.x_enableDynamicFontRules()
// 更推荐显式：UIFont.x_scaledSystemFont(ofSize: 16, weight: .medium)
@MainActor
public extension UIFont {
    
    /// 按设计稿宽度缩放 + Dynamic Type 的系统字体（不依赖 swizzle，推荐业务直接使用）
    static func x_scaledSystemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let scaledSize = XLayout.scaled(fontSize)
        let font = x_rawSystemFont(ofSize: scaledSize, weight: weight)
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    /// 开启系统字体工厂缩放（覆盖 `systemFont(ofSize:)` / `systemFont(ofSize:weight:)` / `boldSystemFont(ofSize:)`）
    /// - Note: 不影响 `preferredFont(forTextStyle:)`、自定义字体、Storyboard 字号；会作用于所有调用上述工厂的代码（含系统/三方），请谨慎开启
    /// - Note: 若已用 `x_scaledSystemFont`，无需再开 swizzle，避免语义重叠
    static func x_enableDynamicFontRules() {
        swizzleLock.lock()
        defer { swizzleLock.unlock() }
        guard !hasSwizzled else { return }
        
        x_exchangeClassMethod(
            original: #selector(UIFont.systemFont(ofSize:)),
            swizzled: #selector(UIFont.x_swizzled_systemFont(ofSize:))
        )
        x_exchangeClassMethod(
            original: #selector(UIFont.systemFont(ofSize:weight:)),
            swizzled: #selector(UIFont.x_swizzled_systemFont(ofSize:weight:))
        )
        x_exchangeClassMethod(
            original: #selector(UIFont.boldSystemFont(ofSize:)),
            swizzled: #selector(UIFont.x_swizzled_boldSystemFont(ofSize:))
        )
        hasSwizzled = true
    }
    
    private static var hasSwizzled = false
    private static let swizzleLock = NSLock()
    
    private static func x_exchangeClassMethod(original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getClassMethod(UIFont.self, original),
              let swizzledMethod = class_getClassMethod(UIFont.self, swizzled) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    /// 不经过 swizzle 的系统字体（供缩放 API 与 swizzle 实现复用）
    private static func x_rawSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if hasSwizzled {
            // 交换后 x_swizzled_* 实际指向原实现
            if weight == .bold {
                return x_swizzled_boldSystemFont(ofSize: size)
            }
            return x_swizzled_systemFont(ofSize: size, weight: weight)
        }
        if weight == .bold {
            return boldSystemFont(ofSize: size)
        }
        return systemFont(ofSize: size, weight: weight)
    }
    
    @objc private static func x_swizzled_systemFont(ofSize fontSize: CGFloat) -> UIFont {
        let scaledSize = XLayout.scaled(fontSize)
        let font = UIFont.x_swizzled_systemFont(ofSize: scaledSize)
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    @objc private static func x_swizzled_systemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        let scaledSize = XLayout.scaled(fontSize)
        let font = UIFont.x_swizzled_systemFont(ofSize: scaledSize, weight: weight)
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    @objc private static func x_swizzled_boldSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        let scaledSize = XLayout.scaled(fontSize)
        let font = UIFont.x_swizzled_boldSystemFont(ofSize: scaledSize)
        return UIFontMetrics.default.scaledFont(for: font)
    }
}
