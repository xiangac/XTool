//
//  XDeviceInfo.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

/// 设备与应用信息工具类
/// - Note: 涉及 UI 元素（屏幕、状态栏等）的方法和属性已绑定至 `@MainActor`，确保线程安全。

// MARK: - 核心窗口捕获 (替代已弃用的 UIScreen.main)
@MainActor
public struct XDeviceInfo {
    /// 获取当前活跃的 Key Window
    public static var keyWindow: UIWindow? {
        let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow })
    }

}

// MARK: - 屏幕与安全区域尺寸
public extension XDeviceInfo {
    /// 屏幕宽度
    static var screenWidth: CGFloat {
        return keyWindow?.bounds.width ?? UIScreen.main.bounds.width
    }
    
    /// 屏幕高度
    static var screenHeight: CGFloat {
        return keyWindow?.bounds.height ?? UIScreen.main.bounds.height
    }
    
    /// 顶部安全区高度（状态栏/刘海/灵动岛高度）
    static var statusBarHeight: CGFloat {
        let topInset = keyWindow?.safeAreaInsets.top ?? 0
        // 如果获取不到安全区，非全面屏手机默认状态栏为 20.0
        return topInset > 0 ? topInset : 20.0
    }
    
    /// 底部安全区高度（Home Indicator 占用高度）
    static var bottomPadding: CGFloat {
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }
    
    /// 是否是全面屏/有刘海的设备
    static var isFullScreenDevice: Bool {
        return bottomPadding > 0
    }
    
    /// 导航栏总高度（状态栏 + 导航栏容器 44.0）
    static var navBarTotalHeight: CGFloat {
        return statusBarHeight + 44.0
    }
    
    /// 标签栏总高度（标准 49.0 + 底部安全区）
    static var tabBarHeight: CGFloat {
        return 49.0 + bottomPadding
    }
}

// MARK: - 内容区域
public extension XDeviceInfo {
    /// 内容视图的默认 Frame（扣除顶部导航栏和底部 TabBar 后的可视区域）
    static var defaultContentFrame: CGRect {
        let contentHeight = screenHeight - navBarTotalHeight - tabBarHeight
        return CGRect(x: 0, y: navBarTotalHeight, width: screenWidth, height: contentHeight)
    }
}

// MARK: - 应用信息 (不依赖 UI，理论上可 nonisolated)
public extension XDeviceInfo {
    /// 获取 App 名称
    static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }
    
    /// 获取 App 发布版本号 (e.g., "1.0.0")
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// 获取 App 构建版本号 (e.g., "123")
    static var appBuildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    /// 获取 App 的 Bundle Identifier
    static var bundleID: String {
        return Bundle.main.bundleIdentifier ?? ""
    }
    
    /// 获取完整版本信息（格式：版本号(Build号)）
    static var fullVersion: String {
        return "\(appVersion)(\(appBuildVersion))"
    }
}

// MARK: - 设备硬件信息
public extension XDeviceInfo {
    /// 设备型号 (e.g., "iPhone", "iPad")
    static var deviceModel: String {
        return UIDevice.current.model
    }
    
    /// 系统版本 (e.g., "17.0")
    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    /// 用户自定义的设备名称 (e.g., "张三的 iPhone")
    static var deviceName: String {
        return UIDevice.current.name
    }
    
    /// 厂商唯一标识符 (UUID)
    static var deviceUUID: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}
