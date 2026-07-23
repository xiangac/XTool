//
//  XColor.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit
import SwiftUI

public extension UIColor {
    /// 使用十六进制字符串初始化颜色
    /// - Parameters:
    ///   - hexString: 支持 `"#FFFFFF"`、`"FFFFFF"`、`"#FFF"`、`"FFF"`、`"#FFFFFFFF"`（带 Alpha）
    ///   - alpha: 默认透明度；若 hexString 中未指定 Alpha，则使用该值
    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        // 1. 去除前后空格和换行，并转为大写
        var cleanedString = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 2. 去除前缀 #
        if cleanedString.hasPrefix("#") {
            cleanedString.remove(at: cleanedString.startIndex)
        }
        
        // 3. 处理简写格式如 "FFF" -> "FFFFFF"
        if cleanedString.count == 3 {
            cleanedString = cleanedString.map { "\($0)\($0)" }.joined()
        }
        
        // 4. 解析十六进制数值（必须完整消费字符串，避免 "FF00FFZZ" 被部分解析）
        var rgbValue: UInt64 = 0
        let scanner = Scanner(string: cleanedString)
        guard scanner.scanHexInt64(&rgbValue), scanner.isAtEnd else { return nil }
        
        let r, g, b, a: CGFloat
        
        switch cleanedString.count {
        case 6: // RGB (24-bit)
            r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgbValue & 0x0000FF) / 255.0
            a = alpha
        case 8: // RGBA (32-bit)
            r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgbValue & 0x000000FF) / 255.0
        default:
            return nil // 不合法的长度
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// 使用纯数字十六进制初始化颜色（例如：`0x07073C`）
    /// - Parameters:
    ///   - hex: RGB 十六进制整数值
    ///   - alpha: 透明度，默认 `1.0`
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

public extension Color {
    
    /// 使用十六进制字符串初始化 SwiftUI `Color`
    /// - Parameters:
    ///   - hex: 支持 `"#FFFFFF"`、`"FFFFFF"`、`"#FFF"`、`"FFF"`、`"#FFFFFFFF"`（带 Alpha）
    ///   - alpha: 默认透明度；若 hex 中未指定 Alpha，则使用该值
    init?(hex: String, alpha: Double = 1.0) {
        var cleanedString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cleanedString.hasPrefix("#") {
            cleanedString.remove(at: cleanedString.startIndex)
        }
        
        if cleanedString.count == 3 {
            cleanedString = cleanedString.map { "\($0)\($0)" }.joined()
        }
        
        var rgbValue: UInt64 = 0
        let scanner = Scanner(string: cleanedString)
        guard scanner.scanHexInt64(&rgbValue), scanner.isAtEnd else { return nil }
        
        let r, g, b, a: Double
        
        switch cleanedString.count {
        case 6: // RGB (24-bit)
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = alpha
        case 8: // RGBA (32-bit)
            r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x000000FF) / 255.0
        default:
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    /// 使用纯数字十六进制初始化 SwiftUI `Color`（例如：`Color(hex: 0x07073C)`）
    /// - Parameters:
    ///   - hex: RGB 十六进制整数值
    ///   - alpha: 透明度，默认 `1.0`
    init(hex: Int, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex & 0xFF0000) >> 16) / 255.0,
            green: Double((hex & 0x00FF00) >> 8) / 255.0,
            blue: Double(hex & 0x0000FF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - XColor 属性包装器
/// 统一颜色属性包装器，原生支持 `UIKit.UIColor` 与 `SwiftUI.Color`
/// - Note: 标记为 `Sendable`，通过内部常驻值规避 `@MainActor` 并发问题
@propertyWrapper
public struct XColor: Sendable {
    
    /// 包装值：底层保存的 `UIColor`
    public let wrappedValue: UIColor
    
    /// 投影值：通过 `$color` 直接获取 SwiftUI 的 `Color`
    public var projectedValue: Color {
        return Color(uiColor: wrappedValue)
    }
    
    /// 使用已有 `UIColor` 初始化
    /// - Parameter wrappedValue: UIKit 颜色
    public init(wrappedValue: UIColor) {
        self.wrappedValue = wrappedValue
    }
    
    /// 使用十六进制字符串初始化；非法字符串时回退为黑色
    /// - Parameters:
    ///   - hexString: 十六进制颜色字符串
    ///   - alpha: 透明度，默认 `1.0`
    public init(_ hexString: String, alpha: CGFloat = 1.0) {
        self.wrappedValue = UIColor(hexString: hexString, alpha: alpha) ?? .black
    }
    
    /// 使用十六进制整数初始化
    /// - Parameters:
    ///   - hexInt: RGB 十六进制整数值
    ///   - alpha: 透明度，默认 `1.0`
    public init(_ hexInt: Int, alpha: CGFloat = 1.0) {
        self.wrappedValue = UIColor(hex: hexInt, alpha: alpha)
    }
}

/*
 使用示例
 struct AppTheme {
     @XColor("#07073C") static var mainBackground: UIColor
     @XColor("FF5733", alpha: 0.5) static var warningTag: UIColor
     @XColor(0x2ECC71) static var successGreen: UIColor
 }

 // 业务调用极其清爽：
 view.backgroundColor = AppTheme.mainBackground
 label.textColor = AppTheme.warningTag
 
 struct MySwiftUIView: View {
     // 使用十六进制字符串
     @XColor("#FF5733") var themeColor
     // 使用十六进制数字，带透明度
     @XColor(0x07073C, alpha: 0.8) var backgroundColor

     var body: some View {
         VStack {
             Text("Hello SwiftUI!")
                 // 💡 注意：加 $ 符号直接当做 SwiftUI.Color 使用！
                 .foregroundStyle($themeColor)
         }
         .background($backgroundColor)
     }
 }
 
 */
