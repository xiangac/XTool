//
//  XApplication.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

public extension UIApplication {
    /// 获取最顶层view
    public static func topView() -> UIView? {
        return UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// 获取最顶层controller
    public static func topController() -> UIViewController? {
        let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        return rootVC
    }
    
    /// 获取当前屏幕最上层可见视图控制器
    public static func presentedViewController() -> UIViewController? {
        guard let rootVC = topController() else {
            return nil
        }
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        return topVC
    }
}
