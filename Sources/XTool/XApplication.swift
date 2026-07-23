//
//  XApplication.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

public extension UIApplication {
    /// 当前 Key Window（优先前台活跃 Scene，找不到则回退）
    @MainActor
    static func x_keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive }
        let scene = activeScene ?? scenes.first
        
        guard let scene else { return nil }
        return scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
    }
    
    /// Key Window 的根视图控制器
    @MainActor
    static func x_rootViewController() -> UIViewController? {
        x_keyWindow()?.rootViewController
    }
    
    /// 当前最上层可见视图控制器（处理 present / Nav / Tab）
    @MainActor
    static func x_topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {
        let base = base ?? x_rootViewController()
        guard let base else { return nil }
        
        if let nav = base as? UINavigationController {
            // visible 为 nil 时返回容器自身，避免 base:nil 再次回落到 root 造成死循环
            guard let visible = nav.visibleViewController else { return nav }
            return x_topViewController(base: visible)
        }
        if let tab = base as? UITabBarController {
            guard let selected = tab.selectedViewController else { return tab }
            return x_topViewController(base: selected)
        }
        if let presented = base.presentedViewController {
            return x_topViewController(base: presented)
        }
        return base
    }
}
