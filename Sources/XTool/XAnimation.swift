//
//  XAnimation.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit

public struct XAnimation {
    /// 创建放大缩小的动画
    /// - Parameters:
    ///     - duration: 动画持续时间
    ///     - fromValue:开始时的缩放比例
    ///     - toValue: 结束时的缩放比例
    ///     - autoreverses: 动画完成后是否自动反向播放
    ///     - repeatCount: 重复次数
    ///     - isRemovedOnCompletion: 页面切换或切后台时动画是否被移除
    public static func scaleAnimation(
        duration:CFTimeInterval = 0.5,
        fromValue:Any = 1.0,
        toValue:Any = 1.0,
        autoreverses:Bool = true,
        repeatCount:Float = .infinity,
        isRemovedOnCompletion:Bool = false
    ) -> CABasicAnimation {
        return CABasicAnimation.x_scaleAnimation(
            duration: duration,
            fromValue: fromValue,
            toValue: toValue,
            autoreverses: autoreverses,
            repeatCount: repeatCount,
            isRemovedOnCompletion: isRemovedOnCompletion
        )
    }
}

public extension CABasicAnimation {
    /// 创建放大缩小的动画
    /// - Parameters:
    ///     - duration: 动画持续时间
    ///     - fromValue:开始时的缩放比例
    ///     - toValue: 结束时的缩放比例
    ///     - autoreverses: 动画完成后是否自动反向播放
    ///     - repeatCount: 重复次数
    ///     - isRemovedOnCompletion: 页面切换或切后台时动画是否被移除
    static func x_scaleAnimation(
        duration:CFTimeInterval = 0.5,
        fromValue:Any = 1.0,
        toValue:Any = 1.0,
        autoreverses:Bool = true,
        repeatCount:Float = .infinity,
        isRemovedOnCompletion:Bool = false
    ) -> CABasicAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = duration // 动画持续时间
        scaleAnimation.fromValue = fromValue // 开始时的缩放比例 (无需写 NSNumber)
        scaleAnimation.toValue = toValue // 结束时的缩放比例
        scaleAnimation.autoreverses = autoreverses // 动画完成后是否自动反向播放
        scaleAnimation.repeatCount = repeatCount // 重复次数设置为无限 (对应 HUGE_VALF)
        // KVC 赋值
        scaleAnimation.setValue("scaleAnimation", forKey: "scale")
        // 页面切换或切后台时动画不被移除
        scaleAnimation.isRemovedOnCompletion = isRemovedOnCompletion
        
        return scaleAnimation
    }
}
