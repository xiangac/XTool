//
//  XDeviceInfo.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// MARK: - 应用信息 (不依赖 UI，理论上可 nonisolated)
public struct XDeviceInfo {
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

// MARK: - 核心窗口捕获
public extension UIDevice {
    /// 获取当前活跃的 Key Window
    @MainActor
    static var keyWindow: UIWindow? {
        // 1. 先尝试获取活跃的 Scene
        let activeScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        
        // 2. 如果拿不到活跃的（可能在启动初期），就拿任意一个连接着的 Scene
        let anyScene = activeScene ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene)
        
        // 3. 优先找 keyWindow，找不到就保底拿第一个 window
        return anyScene?.windows.first(where: { $0.isKeyWindow }) ?? anyScene?.windows.first
    }

}

// MARK: - 屏幕与安全区域尺寸
@MainActor
public extension UIDevice {
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
@MainActor
public extension UIDevice {
    /// 内容视图的默认 Frame（扣除顶部导航栏和底部 TabBar 后的可视区域）
    static var defaultContentFrame: CGRect {
        let contentHeight = screenHeight - navBarTotalHeight - tabBarHeight
        return CGRect(x: 0, y: navBarTotalHeight, width: screenWidth, height: contentHeight)
    }
}

// MARK: - 设备硬件信息
@MainActor
public extension UIDevice {
    /// 设备型号 (e.g., "iPhone", "iPad")
    static var deviceModel: String {
        return UIDevice.current.model
    }
    
    /// 系统版本 (e.g., "17.0")
    static var version: String {
        return UIDevice.current.systemVersion
    }
    
    /// 用户自定义的设备名称 (e.g., "张三的 iPhone")
    static var deviceName: String {
        return UIDevice.current.name
    }
    
    /// 厂商唯一标识符 (UUID)
    static var uuid: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}


// 💡 使用效果：
// 支付成功时：UIDevice.x_triggerHaptic(.success)
// 列表滚动撞墙时：UIDevice.x_triggerHaptic(.lightImpact)
//MARK: 系统马达震动
public extension UIDevice {
    
    enum x_FeedbackType {
        case success
        case warning
        case error
        case lightImpact
        case heavyImpact
    }
    
    /// 触发系统马达反馈
    @MainActor
    static func x_triggerHaptic(_ type: x_FeedbackType) {
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .lightImpact:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .heavyImpact:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}

//MARK: 越狱、模拟器与灵动岛判断
public extension UIDevice {
    
    /// 1. 判断当前设备是否是模拟器（常用于屏蔽某些模拟器不支持的硬件功能）
    static var x_isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// 2. 检查当前设备是否被越狱（工业级 App 基础安全风控必备）
    static var x_isJailbroken: Bool {
        if x_isSimulator { return false }
        
        // 常见越狱文件路径检查
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
        
        // 尝试写入系统私有目录，看是否有高权限操作权限
        let testString = "Jailbreak Test"
        do {
            try testString.write(toFile: "/private/jailbreak_test.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak_test.txt")
            return true // 写入成功说明系统权限已被破解
        } catch {
            return false
        }
    }
    
    /// 3. 精准判断当前设备是否具备“灵动岛 (Dynamic Island)”
    @MainActor
    static var x_hasDynamicIsland: Bool {
        // 灵动岛机型的状态栏高度通常为 54.0pt，且底部有安全区
        // 联动我们之前的 XDeviceInfo 工具类
        let keyWindow = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        let statusBarHeight = keyWindow?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 0
        
        // 经过机型精确测算，状态栏高度在 50 到 55 之间的基本上都是灵动岛机型（如 iPhone 14 Pro, 15, 16 等）
        return statusBarHeight >= 50.0 && statusBarHeight <= 55.0
    }
}
