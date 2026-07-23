//
//  XLayoutMetricsCache.swift
//  XTool
//
//  屏幕 / 安全区 / Nav / Tab / 缩放系数缓存。
//  热路径避免反复扫 Scene、walk VC；几何变化或系统通知时失效。
//

import Foundation
import UIKit

@MainActor
enum XLayoutMetricsCache {
    
    // MARK: - Screen / Safe Area
    
    private static weak var window: UIWindow?
    private static var width: CGFloat?
    private static var height: CGFloat?
    private static var safeArea: UIEdgeInsets?
    private static var statusBarHeight: CGFloat?
    private static var scaleFactor: CGFloat?
    
    // MARK: - Nav / Tab（弱引用 + 几何指纹，避免每次 walk VC）
    
    private static weak var navBar: UINavigationBar?
    private static weak var navigationController: UINavigationController?
    private static var navBarHidden: Bool?
    private static var navBarBoundsHeight: CGFloat?
    private static var navBarMaxY: CGFloat?
    private static var navTotalHeight: CGFloat?
    private static var navContentHeight: CGFloat?
    
    private static weak var tabBar: UITabBar?
    private static var tabBarBoundsHeight: CGFloat?
    private static var tabBarHidden: Bool?
    private static var tabHeight: CGFloat?
    
    private static var isObserving = false
    
    // MARK: - Public API for UIDevice / XLayout
    
    static func screenWidth() -> CGFloat {
        refreshScreenMetricsIfNeeded()
        return width ?? UIScreen.main.bounds.width
    }
    
    static func screenHeight() -> CGFloat {
        refreshScreenMetricsIfNeeded()
        return height ?? UIScreen.main.bounds.height
    }
    
    static func resolvedSafeAreaInsets() -> UIEdgeInsets? {
        refreshScreenMetricsIfNeeded()
        return safeArea
    }
    
    static func statusBarHeightValue() -> CGFloat {
        refreshScreenMetricsIfNeeded()
        if let statusBarHeight { return statusBarHeight }
        return computeStatusBarHeight(insets: safeArea, window: window)
    }
    
    static func layoutScaleFactor(baseWidth: CGFloat) -> CGFloat {
        refreshScreenMetricsIfNeeded()
        if let scaleFactor { return scaleFactor }
        let w = width ?? UIScreen.main.bounds.width
        let factor = w / baseWidth
        scaleFactor = factor
        return factor
    }
    
    static func navigationBarContentHeightValue() -> CGFloat {
        if isNavChromeCacheValid(), let cached = navContentHeight {
            if navBarHidden == true { return 0 }
            return cached > 0 ? cached : fallbackNavContentHeight()
        }
        return resolveNavigationChrome().content
    }
    
    static func navBarTotalHeightValue() -> CGFloat {
        if isNavChromeCacheValid(), let cached = navTotalHeight {
            if navBarHidden == true { return 0 }
            if let navBar, let window = navBar.window ?? Self.window,
               navBar.bounds.height > 0 {
                let maxY = navBar.convert(CGPoint(x: 0, y: navBar.bounds.maxY), to: window).y
                if abs(maxY - (navBarMaxY ?? -1)) < 0.5 {
                    return cached
                }
                // Large Title 折叠等：同一 bar，只更新几何，不 walk VC
                navBarMaxY = maxY
                navBarBoundsHeight = navBar.bounds.height
                navContentHeight = navBar.bounds.height
                let total = maxY > 0 ? maxY : (statusBarHeight ?? 20) + navBar.bounds.height
                navTotalHeight = total
                return total
            }
            return cached
        }
        return resolveNavigationChrome().total
    }
    
    static func tabBarHeightValue() -> CGFloat {
        if let tabBar,
           tabBar.window != nil || tabBar.isHidden,
           let cached = tabHeight,
           tabBar.isHidden == tabBarHidden,
           tabBar.bounds.height == tabBarBoundsHeight {
            return cached
        }
        return resolveTabChrome()
    }
    
    static func currentNavigationBar() -> UINavigationBar? {
        if isNavChromeCacheValid(), let navBar, navBarHidden != true {
            return navBar
        }
        let resolved = resolveNavigationChrome()
        return resolved.hidden ? nil : resolved.bar
    }
    
    /// 导航栏是否处于有效展示（未 hidden）
    static func isNavigationBarVisible() -> Bool {
        if isNavChromeCacheValid() {
            return navBar != nil && navBarHidden != true
        }
        let resolved = resolveNavigationChrome()
        return resolved.bar != nil && !resolved.hidden
    }
    
    /// 主动清空全部布局缓存（窗口变化 / 回前台等）
    /// - Note: push/pop、换 root、手动显隐 Nav/Tab 后若需立即读到新高度，请调用
    ///   `x_invalidateChromeMetrics()` 或本方法
    static func invalidate() {
        window = nil
        width = nil
        height = nil
        safeArea = nil
        statusBarHeight = nil
        scaleFactor = nil
        invalidateChrome()
    }
    
    /// 仅清空 Nav/Tab 高度缓存（换页、显隐栏后调用；比全量 invalidate 更轻）
    static func invalidateChrome() {
        navBar = nil
        navigationController = nil
        navBarHidden = nil
        navBarBoundsHeight = nil
        navBarMaxY = nil
        navTotalHeight = nil
        navContentHeight = nil
        tabBar = nil
        tabBarBoundsHeight = nil
        tabBarHidden = nil
        tabHeight = nil
    }
    
    private static func isNavChromeCacheValid() -> Bool {
        guard let navBar else { return false }
        let hidden = isNavigationBarEffectivelyHidden(navBar, controller: navigationController)
        if hidden != navBarHidden {
            return false
        }
        if hidden {
            return navTotalHeight != nil
        }
        return navBar.window != nil
            && navBar.bounds.height == navBarBoundsHeight
            && navTotalHeight != nil
    }
    
    // MARK: - Screen refresh
    
    private static func refreshScreenMetricsIfNeeded() {
        ensureObserving()
        
        if let window, window.isKeyWindow || window.windowScene?.activationState == .foregroundActive,
           let width, let height,
           window.bounds.width == width, window.bounds.height == height,
           let safeArea, window.safeAreaInsets == safeArea,
           statusBarHeight != nil, scaleFactor != nil {
            return
        }
        
        let resolved = resolveKeyWindow()
        window = resolved
        
        let bounds = resolved?.bounds ?? UIScreen.main.bounds
        let sizeChanged = width != bounds.width || height != bounds.height
        
        width = bounds.width
        height = bounds.height
        
        let insets = resolveSafeArea(for: resolved)
        safeArea = insets
        statusBarHeight = computeStatusBarHeight(insets: insets, window: resolved)
        scaleFactor = bounds.width / XLayout.baseWidth
        
        // 仅窗口尺寸变化时清空栏缓存；纯 safeArea 刷新保留 weak bar 快路径
        if sizeChanged {
            invalidateChrome()
        }
    }
    
    private static func resolveKeyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive }
        let scene = activeScene ?? scenes.first
        guard let scene else { return nil }
        return scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
    }
    
    private static func resolveSafeArea(for window: UIWindow?) -> UIEdgeInsets? {
        if let insets = window?.safeAreaInsets, insets.top > 0 || insets.bottom > 0 {
            return insets
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = window?.windowScene
            ?? scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first
        if let fallback = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first {
            let insets = fallback.safeAreaInsets
            if insets.top > 0 || insets.bottom > 0 {
                return insets
            }
            return insets
        }
        return window?.safeAreaInsets
    }
    
    private static func computeStatusBarHeight(insets: UIEdgeInsets?, window: UIWindow?) -> CGFloat {
        if let top = insets?.top, top > 0 {
            return top
        }
        let scene = window?.windowScene
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        if let statusBarHeight = scene?.statusBarManager?.statusBarFrame.height, statusBarHeight > 0 {
            return statusBarHeight
        }
        return 20.0
    }
    
    // MARK: - Chrome resolve（慢路径）
    
    private static func resolveNavigationChrome() -> (bar: UINavigationBar?, content: CGFloat, total: CGFloat, hidden: Bool) {
        ensureObserving()
        refreshScreenMetricsIfNeeded()
        let found = findNavigationBar()
        let bar = found.bar
        let controller = found.controller
        navBar = bar
        navigationController = controller
        
        let hidden = bar.map { isNavigationBarEffectivelyHidden($0, controller: controller) } ?? false
        navBarHidden = hidden
        
        if hidden || bar == nil {
            navContentHeight = 0
            navBarBoundsHeight = bar?.bounds.height
            navBarMaxY = nil
            navTotalHeight = 0
            return (bar, 0, 0, true)
        }
        
        let content: CGFloat
        if let bar, bar.bounds.height > 0 {
            content = bar.bounds.height
        } else {
            content = fallbackNavContentHeight()
        }
        navContentHeight = content
        navBarBoundsHeight = bar?.bounds.height
        
        let total: CGFloat
        if let bar, bar.bounds.height > 0, let window = bar.window ?? Self.window {
            let maxY = bar.convert(CGPoint(x: 0, y: bar.bounds.maxY), to: window).y
            navBarMaxY = maxY
            total = maxY > 0 ? maxY : (statusBarHeight ?? 20) + content
        } else {
            navBarMaxY = nil
            total = (statusBarHeight ?? 20) + content
        }
        navTotalHeight = total
        return (bar, content, total, false)
    }
    
    private static func resolveTabChrome() -> CGFloat {
        ensureObserving()
        refreshScreenMetricsIfNeeded()
        let bar = findTabBar()
        tabBar = bar
        tabBarHidden = bar?.isHidden
        tabBarBoundsHeight = bar?.bounds.height
        
        let height: CGFloat
        if let bar {
            if bar.isHidden {
                height = 0
            } else if bar.bounds.height > 0 {
                height = bar.bounds.height
            } else {
                height = 49.0 + (safeArea?.bottom ?? 0)
            }
        } else {
            height = 0
        }
        tabHeight = height
        return height
    }
    
    private static func fallbackNavContentHeight() -> CGFloat {
        let host = window ?? resolveKeyWindow()
        let isCompact = host?.traitCollection.verticalSizeClass == .compact
            || host?.windowScene?.traitCollection.verticalSizeClass == .compact
        return isCompact ? 32.0 : 44.0
    }
    
    private static func isNavigationBarEffectivelyHidden(
        _ bar: UINavigationBar,
        controller: UINavigationController?
    ) -> Bool {
        if bar.isHidden { return true }
        if let controller, controller.isNavigationBarHidden { return true }
        return false
    }
    
    private static func findNavigationBar() -> (bar: UINavigationBar?, controller: UINavigationController?) {
        var vc: UIViewController? = UIApplication.x_topViewController()
        while let current = vc {
            if let nav = current.navigationController {
                return (nav.navigationBar, nav)
            }
            if let nav = current as? UINavigationController {
                return (nav.navigationBar, nav)
            }
            vc = current.parent
        }
        if let root = UIApplication.x_rootViewController() as? UINavigationController {
            return (root.navigationBar, root)
        }
        if let root = UIApplication.x_rootViewController() as? UITabBarController,
           let nav = root.selectedViewController as? UINavigationController {
            return (nav.navigationBar, nav)
        }
        return (nil, nil)
    }
    
    private static func findTabBar() -> UITabBar? {
        var vc: UIViewController? = UIApplication.x_topViewController()
        while let current = vc {
            if let tab = current.tabBarController {
                return tab.tabBar
            }
            if let tab = current as? UITabBarController {
                return tab.tabBar
            }
            vc = current.parent
        }
        if let root = UIApplication.x_rootViewController() as? UITabBarController {
            return root.tabBar
        }
        return nil
    }
    
    // MARK: - Observers
    
    private static func ensureObserving() {
        guard !isObserving else { return }
        isObserving = true
        
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            UIDevice.orientationDidChangeNotification,
            UIApplication.didBecomeActiveNotification,
            UIApplication.willEnterForegroundNotification,
            UIScene.didActivateNotification,
            UIScene.didDisconnectNotification
        ]
        for name in names {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                Task { @MainActor in
                    XLayoutMetricsCache.invalidate()
                }
            }
        }
    }
}
