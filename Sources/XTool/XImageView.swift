//
//  File.swift
//  XTool
//
//  Created by zjwx01 on 2026/7/2.
//

import Foundation
import UIKit
//MARK: (图形渲染天花板：自动检测并报警“离屏渲染”与“不透明度隐患”
/*
 💡 场景 1：在 Cell 初始化时，直接丢给工具类进行隐患体检
 avatarImageView.x_debugPerformanceCheck()
 contentImageView.x_debugPerformanceCheck()
 
 💡 场景 2：在常规的 UIViewController 视图初始化中使用
 // 1. 设置图片属性
 headerImageView.frame = CGRect(x: 20, y: 100, width: 100, height: 100)
 headerImageView.image = UIImage(named: "avatar")
 headerImageView.layer.cornerRadius = 50
 headerImageView.layer.masksToBounds = true // ⚠️ 隐患：开启了裁剪
 
 view.addSubview(headerImageView)
 
 // 2. 执行性能体检
 headerImageView.x_debugPerformanceCheck()
 
 当你运行 App 并在屏幕上查看时：

 🟢 没有任何边框：说明这个 UIImageView 渲染配置非常完美，不会拖累 GPU，可以放心上线。

 🔴 出现红色边框：说明触发了单项隐患（要么是图片带透明通道且未设置不透明度导致像素混合；要么是开了圆角裁剪但没开启异步绘制）。

 🟣 出现紫色边框：说明两项隐患全部重叠！这个 ImageView 在滚动列表里几乎一定会触发 GPU 离屏渲染，是导致掉帧卡顿的“罪魁祸首”。
 
 看到红/紫边框后，该怎么修复代码？
 // 优化方案：
 imageView.backgroundColor = .white // 1. 给它一个明确的背景色
 imageView.isOpaque = true          // 2. 告诉 GPU 它是完全不透明的，拒绝像素混合
 // 3. 如果需要圆角，尽量让设计图直接给带圆角的图，或者使用复合图层，避免在代码里无脑使用 masksToBounds
 
 */
public extension UIImageView {
    /// 在开发阶段，对性能不合格（可能引发离屏渲染或像素混合）的 ImageView 进行高亮警告
    func x_debugPerformanceCheck() {
        #if DEBUG
        // 异步等布局完成后检查
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 隐患 1：图片带有透明通道且未设置不透明度（引发 GPU 像素混合，极其耗费性能）
            let hasAlphaRisk = self.backgroundColor == nil && !self.isOpaque
            
            // 隐患 2：设置了圆角裁剪但没有开启异步绘制，极易引发离屏渲染
            let hasCornerRisk = self.layer.cornerRadius > 0 && self.layer.masksToBounds
            
            if hasAlphaRisk && hasCornerRisk {
                // 🚨 触发最高级别性能危险警告：边框变紫色
                self.layer.borderColor = UIColor.purple.cgColor
                self.layer.borderWidth = 2.0
            } else if hasAlphaRisk || hasCornerRisk {
                // ⚠️ 触发性能隐患警告：边框变红
                self.layer.borderColor = UIColor.red.cgColor
                self.layer.borderWidth = 1.5
            }
        }
        #endif
    }
}
