//
//  XView.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

public extension UIView {
    
    /// 快速指定部分圆角 (例如：仅左上和右上)
    /// - Parameters:
    ///   - corners: 需要裁剪的角 (如：[.topLeft, .topRight])
    ///   - radius: 圆角半径
    func clipSpecifiedCorners(
        _ corners: UIRectCorner,
        withRadius radius: CGFloat
    ) {
        let path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    
    /// 2. 绘制线性渐变背景
    func applyLinearGradient(
        colors: [CGColor],
        locations: [NSNumber]?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = self.bounds
        
        // 插入到最底层
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// 3. 基础圆角配置
    func applyCornerRadius(_ radius: CGFloat) {
        self.renderSurface(radius: radius, borderWidth: 0, borderColor: nil)
    }
    
    /// 4. 自定义遮罩切角
    func setupMaskLayout(
        corners: UIRectCorner,
        radius: CGFloat
    ) {
        var finalRadius = radius
        if finalRadius == -1 {
            finalRadius = self.bounds.height / 2.0 // 统一使用 bounds 比 frame 更安全
        }
        
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: finalRadius, height: finalRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
    
    /// 5. 完整边框与圆角设置
    func renderSurface(
        radius: CGFloat,
        borderWidth: CGFloat,
        borderColor: UIColor?
    ) {
        self.layer.cornerRadius = radius
        self.layer.borderWidth = borderWidth
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        } else {
            self.layer.borderColor = nil
        }
        self.layer.masksToBounds = true
    }
    
    /// 6. 快速实现半圆角效果（胶囊风格）
    func configCapsuleStyle() {
        let halfHeight = self.bounds.height / 2.0
        self.renderSurface(radius: halfHeight, borderWidth: 0, borderColor: nil)
    }
}

public extension UIView {
    /// 临时限制视图的交互能力（默认防刷时间为 0.5 秒）
    /// - Parameter targetView: 需要限制交互的视图
    @MainActor
    static func restrictInteraction(for targetView: UIView,seconds:Double = 0.5) {
        // 1. 禁用交互
        targetView.isUserInteractionEnabled = false
        
        // 2. 开启一个现代化的异步任务来处理延迟恢复
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            // 3. 恢复交互
            targetView.isUserInteractionEnabled = true
        }
    }
}

//MARK: 手势扩展
public extension UIView {
    /// 内部使用的闭包包装器
    private class ClosureWrapper: NSObject {
        let closure: () -> Void
        init(_ closure: @escaping () -> Void) {
            self.closure = closure
        }
        @objc func invoke() { closure() }
    }
    
    /// 关联属性的 Key
    private static var closureKey: UInt8 = 0
    
    /// 一行代码快速添加点击手势 (带闭包回调)
    /// - Parameter action: 点击后的回调事件
    func x_addTapGesture(action: @escaping () -> Void) {
        self.isUserInteractionEnabled = true
        let target = ClosureWrapper(action)
        
        let tap = UITapGestureRecognizer(target: target, action: #selector(ClosureWrapper.invoke))
        self.addGestureRecognizer(tap)
        
        // 动态绑定将 target 留在内存中
        objc_setAssociatedObject(self, &UIView.closureKey, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

//MARK: UI 布局快捷读写
public extension UIView {
    var x_x: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }
    
    var x_y: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }
    
    var x_width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }
    
    var x_height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }
    
    var x_size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }
    
}
