//
//  XViewController.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// MARK: - 导航与路由配置协议
public protocol NavigationBarConfigurable where Self: UIViewController {
    /// 基础导航栏样式设置
    func setupNavigationBarTheme()
    /// 配置返回按钮
    func setNavBackButton(imageName: String?, action: (() -> Void)?)
    /// 配置右侧导航图片按钮
    func setNavRightIcon(_ iconName: String, action: @escaping () -> Void)
    /// 配置右侧导航文字按钮
    func setNavRightTitle(_ title: String, action: @escaping () -> Void)
    /// 配置导航栏标题标签（左侧大标题）
    func setLeftLargeTitleLabel(_ title: String)
    /// 自定义模态跳转（全屏样式）
    func presentWithFullStyle(_ controller: UIViewController, style: UIModalPresentationStyle, animated: Bool, completion: (() -> Void)?)
}

// 导航协议默认实现
public extension NavigationBarConfigurable {
    /// 基础导航栏样式设置
    func setupNavigationBarTheme() {
        guard let navBar = navigationController?.navigationBar else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        navBar.titleTextAttributes = attributes
        navBar.isTranslucent = true
        navBar.shadowImage = UIImage()
        
        if let navController = navigationController, navController.viewControllers.count > 1 {
            setNavBackButton()
        }
    }
    
    /// 配置返回按钮
    func setNavBackButton(imageName: String? = nil, action: (() -> Void)? = nil) {
        let finalImage = imageName ?? ""
        let backAction = UIAction { [weak self] _ in
            guard let self = self else { return }
            action?()
            if let navController = self.navigationController, navController.viewControllers.count > 1 {
                navController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
        
        let btn = UIButton(type: .custom, primaryAction: backAction)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.setImage(finalImage.count > 0 ? UIImage(named: finalImage) : UIImage(systemName: "chevron.backward"), for: .normal)
        btn.contentHorizontalAlignment = .left
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 配置右侧导航图片按钮
    func setNavRightIcon(_ iconName: String, action: @escaping () -> Void) {
        let btnAction = UIAction { _ in action() }
        let btn = UIButton(type: .custom, primaryAction: btnAction)
        btn.frame = CGRect(x: 0, y: 0, width: 35, height: 40)
        btn.setImage(UIImage(named: iconName), for: .normal)
        btn.contentHorizontalAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 配置右侧导航文字按钮
    func setNavRightTitle(_ title: String, action: @escaping () -> Void) {
        let btnAction = UIAction { _ in action() }
        let btn = UIButton(type: .system, primaryAction: btnAction)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(title, for: .normal)
        
        btn.sizeToFit()
        let width = max(35, btn.frame.width + 10)
        btn.frame = CGRect(x: 0, y: 0, width: width, height: 40)
        btn.contentHorizontalAlignment = .right
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 配置导航栏标题标签（左侧大标题）
    func setLeftLargeTitleLabel(_ title: String) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 44))
        label.textColor = .white
        label.text = title
        label.font = .systemFont(ofSize: 20, weight: .heavy)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
    
    /// 自定义模态跳转（全屏样式）
    func presentWithFullStyle(
        _ controller: UIViewController,
        style: UIModalPresentationStyle = .fullScreen,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        controller.modalPresentationStyle = style
        present(controller, animated: animated, completion: completion)
    }
}
