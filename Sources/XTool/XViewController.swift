//
//  XViewController.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit
import ObjectiveC

/// 导航栏样式与常用导航操作协议
public protocol XNavigationBarConfigurable where Self: UIViewController {
    /// 配置导航栏基础主题
    func x_setupNavigationBarTheme()
    /// 配置返回按钮
    func x_setNavBackButton(imageName: String?, action: (() -> Void)?)
    /// 配置右侧图片按钮
    func x_setNavRightIcon(_ iconName: String, action: @escaping () -> Void)
    /// 配置右侧文字按钮
    func x_setNavRightTitle(_ title: String, action: @escaping () -> Void)
    /// 配置左侧标题
    func x_setNavLeftTitle(_ title: String)
    /// 全屏模态弹出
    func x_presentFullScreen(_ controller: UIViewController, style: UIModalPresentationStyle, animated: Bool, completion: (() -> Void)?)
}

public extension XNavigationBarConfigurable {
    /// 配置导航栏基础主题（白标题、透明栏、自动返回按钮）
    func x_setupNavigationBarTheme() {
        guard let navBar = navigationController?.navigationBar else { return }
        
        navBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        navBar.isTranslucent = true
        navBar.shadowImage = UIImage()
        
        if let navController = navigationController, navController.viewControllers.count > 1 {
            x_setNavBackButton()
        }
    }
    
    /// 配置返回按钮；点击后先执行自定义回调，再 pop / dismiss
    /// - Note: 会安装侧滑返回手势代理，保证自定义 `leftBarButtonItem` 后仍可右滑返回
    func x_setNavBackButton(imageName: String? = nil, action: (() -> Void)? = nil) {
        let finalImage = imageName ?? ""
        let backAction = UIAction { [weak self] _ in
            guard let self else { return }
            action?()
            if let navController = navigationController, navController.viewControllers.count > 1 {
                navController.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
        
        let btn = UIButton(type: .custom, primaryAction: backAction)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.setImage(
            finalImage.isEmpty ? UIImage(systemName: "chevron.backward") : UIImage(named: finalImage),
            for: .normal
        )
        btn.contentHorizontalAlignment = .left
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
        x_enableInteractivePopGestureIfNeeded()
    }
    
    /// 配置右侧图片按钮
    func x_setNavRightIcon(_ iconName: String, action: @escaping () -> Void) {
        let btn = UIButton(type: .custom, primaryAction: UIAction { _ in action() })
        btn.frame = CGRect(x: 0, y: 0, width: 35, height: 40)
        btn.setImage(UIImage(named: iconName), for: .normal)
        btn.contentHorizontalAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 配置右侧文字按钮
    func x_setNavRightTitle(_ title: String, action: @escaping () -> Void) {
        let btn = UIButton(type: .system, primaryAction: UIAction { _ in action() })
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(title, for: .normal)
        btn.sizeToFit()
        let width = max(35, btn.frame.width + 10)
        btn.frame = CGRect(x: 0, y: 0, width: width, height: 40)
        btn.contentHorizontalAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 配置左侧标题 Label
    func x_setNavLeftTitle(_ title: String) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 44))
        label.textColor = .white
        label.text = title
        label.font = .systemFont(ofSize: 20, weight: .heavy)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
    
    /// 全屏（或指定样式）模态弹出
    func x_presentFullScreen(
        _ controller: UIViewController,
        style: UIModalPresentationStyle = .fullScreen,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        controller.modalPresentationStyle = style
        present(controller, animated: animated, completion: completion)
    }
    
    /// 自定义返回按钮后恢复侧滑返回
    private func x_enableInteractivePopGestureIfNeeded() {
        guard let nav = navigationController,
              let gesture = nav.interactivePopGestureRecognizer else { return }
        
        let proxy: XInteractivePopGestureProxy
        if let existing = objc_getAssociatedObject(nav, &XInteractivePopGestureProxy.assocKey) as? XInteractivePopGestureProxy {
            proxy = existing
        } else {
            proxy = XInteractivePopGestureProxy()
            objc_setAssociatedObject(nav, &XInteractivePopGestureProxy.assocKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        proxy.navigationController = nav
        gesture.delegate = proxy
        gesture.isEnabled = true
    }
}

/// 保证栈深 > 1 时才允许侧滑返回（自定义 leftBarButtonItem 后系统默认代理常失效）
private final class XInteractivePopGestureProxy: NSObject, UIGestureRecognizerDelegate {
    static var assocKey: UInt8 = 0
    weak var navigationController: UINavigationController?
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
