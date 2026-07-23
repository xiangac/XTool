//
//  XView.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

// MARK: - 圆角 / 边框 / 渐变
public extension UIView {
    
    /// 为指定角设置圆角遮罩
    /// - Parameters:
    ///   - corners: 需要圆角的角，默认四角
    ///   - radius: 圆角半径；传 `-1` 时使用高度一半（半圆）
    /// - Note: 依赖当前 `bounds`，请在布局完成后再调用；尺寸变化后需重新调用
    func x_roundCorners(_ corners: UIRectCorner = .allCorners, radius: CGFloat) {
        var finalRadius = radius
        if finalRadius == -1 {
            finalRadius = bounds.height / 2.0
        }
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: finalRadius, height: finalRadius)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
    
    /// 设置圆角（无边框）
    /// - Parameter radius: 圆角半径
    func x_applyCornerRadius(_ radius: CGFloat) {
        x_applyBorderStyle(radius: radius, borderWidth: 0, borderColor: nil)
    }
    
    /// 设置圆角与边框
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色，传 `nil` 则清除
    func x_applyBorderStyle(radius: CGFloat, borderWidth: CGFloat, borderColor: UIColor?) {
        layer.cornerRadius = radius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor?.cgColor
        layer.masksToBounds = true
    }
    
    /// 应用胶囊样式（圆角 = 高度一半）
    /// - Note: 依赖当前 `bounds.height`
    func x_applyCapsuleStyle() {
        x_applyBorderStyle(radius: bounds.height / 2.0, borderWidth: 0, borderColor: nil)
    }
    
    /// 应用线性渐变背景（插入最底层；重复调用会更新已有渐变层，不叠加）
    /// - Parameters:
    ///   - colors: 渐变色
    ///   - direction: 渐变方向，默认从左到右
    /// - Note: 依赖当前 `bounds`；尺寸变化后需再次调用以刷新 frame
    func x_applyGradient(colors: [UIColor], direction: XGradientDirection = .leftToRight) {
        let gradientLayer: CAGradientLayer
        if let existing = layer.sublayers?.first(where: { $0.name == XViewGradientLayerName }) as? CAGradientLayer {
            gradientLayer = existing
        } else {
            gradientLayer = CAGradientLayer()
            gradientLayer.name = XViewGradientLayerName
            layer.insertSublayer(gradientLayer, at: 0)
        }
        
        let configured = CAGradientLayer.x_gradient(colors: colors, direction: direction)
        gradientLayer.colors = configured.colors
        gradientLayer.startPoint = configured.startPoint
        gradientLayer.endPoint = configured.endPoint
        gradientLayer.frame = bounds
    }
}

private let XViewGradientLayerName = "xtool.gradient.layer"

// MARK: - 交互限制
public extension UIView {
    private static var restrictTokenKey: UInt8 = 0
    
    /// 本次限制交互的代数 token（用于取消过期的恢复任务）
    private var x_restrictToken: UInt {
        get { objc_getAssociatedObject(self, &UIView.restrictTokenKey) as? UInt ?? 0 }
        set { objc_setAssociatedObject(self, &UIView.restrictTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 临时禁用交互，防止短时间重复点击
    /// - Parameters:
    ///   - targetView: 目标视图
    ///   - seconds: 禁用时长，默认 0.5 秒（负数按 0 处理）
    /// - Note: 连续调用会作废上一次的恢复任务，避免提前重新启用
    @MainActor
    static func x_restrictInteraction(for targetView: UIView, seconds: Double = 0.5) {
        targetView.isUserInteractionEnabled = false
        targetView.x_restrictToken &+= 1
        let token = targetView.x_restrictToken
        let delay = max(0, seconds)
        
        Task { @MainActor [weak targetView] in
            try? await Task.sleep(for: .seconds(delay))
            guard let targetView, targetView.x_restrictToken == token else { return }
            targetView.isUserInteractionEnabled = true
        }
    }
}

// MARK: - 手势
public extension UIView {
    /// 闭包包装器，桥接为 Objective-C target
    private class ClosureWrapper: NSObject {
        let closure: () -> Void
        init(_ closure: @escaping () -> Void) { self.closure = closure }
        @objc func invoke() { closure() }
    }
    
    private static var tapWrappersKey: UInt8 = 0
    
    /// 已绑定的手势闭包列表（支持多次添加，避免覆盖导致野指针）
    private var x_tapWrappers: [ClosureWrapper] {
        get { objc_getAssociatedObject(self, &UIView.tapWrappersKey) as? [ClosureWrapper] ?? [] }
        set { objc_setAssociatedObject(self, &UIView.tapWrappersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 添加点击手势（闭包回调）
    /// - Parameter action: 点击回调
    /// - Note: 可多次调用；每次都会新增手势与对应 target
    func x_addTapGesture(action: @escaping () -> Void) {
        isUserInteractionEnabled = true
        let target = ClosureWrapper(action)
        let tap = UITapGestureRecognizer(target: target, action: #selector(ClosureWrapper.invoke))
        addGestureRecognizer(tap)
        
        var wrappers = x_tapWrappers
        wrappers.append(target)
        x_tapWrappers = wrappers
    }
}

// MARK: - Frame 快捷读写
public extension UIView {
    /// frame.origin.x
    var x_frameX: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }
    
    /// frame.origin.y
    var x_frameY: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }
    
    /// frame.size.width
    var x_width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }
    
    /// frame.size.height
    var x_height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }
    
    /// frame.size
    var x_size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }
}
