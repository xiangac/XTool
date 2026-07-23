//
//  XDevice.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// MARK: - Key Window
public extension UIDevice {
    /// 当前活跃的 Key Window（委托 `UIApplication.x_keyWindow()`）
    @MainActor
    static var x_keyWindow: UIWindow? {
        UIApplication.x_keyWindow()
    }
}

// MARK: - 屏幕与安全区域
@MainActor
public extension UIDevice {
    /// 清空全部布局度量缓存（旋转 / Scene 变化会自动清；换 root 后建议手动调用）
    static func x_invalidateLayoutMetrics() {
        XLayoutMetricsCache.invalidate()
    }
    
    /// 仅清空 Nav/Tab 高度缓存（push/pop、`setNavigationBarHidden`、`hidesBottomBarWhenPushed` 后调用）
    /// - Note: 比 `x_invalidateLayoutMetrics()` 更轻；可在 `viewWillAppear` 里调用
    static func x_invalidateChromeMetrics() {
        XLayoutMetricsCache.invalidateChrome()
    }
    
    /// 屏幕宽度
    static var x_screenWidth: CGFloat {
        XLayoutMetricsCache.screenWidth()
    }
    
    /// 屏幕高度
    static var x_screenHeight: CGFloat {
        XLayoutMetricsCache.screenHeight()
    }
    
    /// 顶部安全区高度（含状态栏 / 刘海 / 灵动岛）
    /// - Note: 刘海与灵动岛机型数值不同（常见约 44/47 vs 59），优先读 window 的 `safeAreaInsets.top`
    static var x_statusBarHeight: CGFloat {
        XLayoutMetricsCache.statusBarHeightValue()
    }
    
    /// 底部安全区高度（Home Indicator）
    static var x_safeAreaBottom: CGFloat {
        XLayoutMetricsCache.resolvedSafeAreaInsets()?.bottom ?? 0
    }
    
    /// 是否是全面屏（任一边缘存在安全区，兼容横屏：刘海/岛在 left/right）
    static var x_isFullScreenDevice: Bool {
        guard let insets = XLayoutMetricsCache.resolvedSafeAreaInsets() else { return false }
        return insets.top > 20 || insets.bottom > 0 || insets.left > 0 || insets.right > 0
    }
    
    /// 导航栏内容区高度（不含状态栏）；导航栏隐藏时为 `0`
    static var x_navigationBarContentHeight: CGFloat {
        XLayoutMetricsCache.navigationBarContentHeightValue()
    }
    
    /// 导航栏总高度（从屏幕顶部到导航栏底边）；隐藏时为 `0`
    /// - Note: push/pop 或显隐栏后如数值异常，调用 `x_invalidateChromeMetrics()`
    static var x_navBarTotalHeight: CGFloat {
        XLayoutMetricsCache.navBarTotalHeightValue()
    }
    
    /// TabBar 总高度（含底部安全区）；无 TabBar 或已隐藏时返回 `0`
    /// - Note: `hidesBottomBarWhenPushed` 后请调用 `x_invalidateChromeMetrics()`
    static var x_tabBarHeight: CGFloat {
        XLayoutMetricsCache.tabBarHeightValue()
    }
    
    /// 扣除当前可见导航栏与 TabBar 后的默认内容区域（隐藏的栏不扣除）
    static var x_defaultContentFrame: CGRect {
        let top = XLayoutMetricsCache.isNavigationBarVisible() ? x_navBarTotalHeight : 0
        let bottom = x_tabBarHeight
        let contentHeight = max(0, x_screenHeight - top - bottom)
        return CGRect(x: 0, y: top, width: x_screenWidth, height: contentHeight)
    }
    
    /// 是否具备灵动岛（按竖屏顶部安全区估算，常见约 59pt；刘海多为 44/47）
    /// - Note: 横屏时优先取 left/right 较大边作为「刘海侧」高度
    static var x_hasDynamicIsland: Bool {
        guard let insets = XLayoutMetricsCache.resolvedSafeAreaInsets() else {
            return x_statusBarHeight >= 54.0
        }
        let notchSide = max(insets.top, insets.left, insets.right)
        return notchSide >= 54.0
    }
}

// MARK: - 安全区 / 栏高度解析（内部，已迁至 XLayoutMetricsCache）
@MainActor
private extension UIDevice {
    static var x_resolvedSafeAreaInsets: UIEdgeInsets? {
        XLayoutMetricsCache.resolvedSafeAreaInsets()
    }
}

// MARK: - 硬件信息
@MainActor
public extension UIDevice {
    /// 设备型号（例如 `"iPhone"`）
    static var x_deviceModel: String {
        UIDevice.current.model
    }
    
    /// 系统版本（例如 `"17.0"`）
    static var x_systemVersion: String {
        UIDevice.current.systemVersion
    }
    
    /// 用户自定义设备名称
    static var x_deviceName: String {
        UIDevice.current.name
    }
    
    /// 厂商唯一标识符（UUID）
    static var x_uuid: String {
        UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}

// MARK: - 触觉反馈
/// 系统触觉反馈类型
public enum XHapticFeedback {
    /// 成功
    case success
    /// 警告
    case warning
    /// 错误
    case error
    /// 轻触
    case lightImpact
    /// 重触
    case heavyImpact
}

public extension UIDevice {
    /// 触发系统触觉反馈（复用 Generator，避免每次分配导致延迟）
    /// - Parameter type: 反馈类型
    @MainActor
    static func x_triggerHaptic(_ type: XHapticFeedback) {
        switch type {
        case .success:
            XHapticStore.notification.notificationOccurred(.success)
        case .warning:
            XHapticStore.notification.notificationOccurred(.warning)
        case .error:
            XHapticStore.notification.notificationOccurred(.error)
        case .lightImpact:
            XHapticStore.lightImpact.impactOccurred()
        case .heavyImpact:
            XHapticStore.heavyImpact.impactOccurred()
        }
    }
}

@MainActor
private enum XHapticStore {
    static let notification = UINotificationFeedbackGenerator()
    static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
}

// MARK: - 模拟器 / 越狱 / 灵动岛
public extension UIDevice {
    /// 是否运行在模拟器
    static var x_isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
    
    /// 是否越狱设备（基础检测）
    static var x_isJailbroken: Bool {
        if x_isSimulator { return false }
        
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) { return true }
        }
        
        let testString = "Jailbreak Test"
        do {
            try testString.write(toFile: "/private/jailbreak_test.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak_test.txt")
            return true
        } catch {
            return false
        }
    }
    
}
