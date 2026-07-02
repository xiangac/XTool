//
//  XString.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit
import CryptoKit

// MARK: - 1. 高频正则校验
public extension String {
    /// 是否是合法的邮箱地址
    var x_isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 是否是合法的中国大陆手机号
    var x_isValidChinesePhoneNumber: Bool {
        let pattern = #"^1[3-9]\d{9}$"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 是否纯数字
    var x_isPureInt: Bool {
        let scan = Scanner(string: self)
        var val: Int = 0
        return scan.scanInt(&val) && scan.isAtEnd
    }
    
}

// MARK: - 2. 加密与数据处理
public extension String {
    /// 转换为 MD5 字符串（常用于文件名缓存加密、灰度校验）
    var x_md5: String {
        let data = Data(self.utf8)
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// 转换为 SHA256 字符串
    var x_sha256: String {
        let data = Data(self.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Base64 编码
    var x_base64Encoded: String? {
        return Data(self.utf8).base64EncodedString()
    }
    
    /// Base64 解码
    var x_base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - 3. UIKit 文本尺寸计算
public extension String {
    /// 计算字符串在限定宽度和字体下的动态高度 (UIKit 算高刚需)
    /// - Parameters:
    ///   - width: 限制的最大宽度
    ///   - font: 字体
    @MainActor
    func x_height(withWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}
