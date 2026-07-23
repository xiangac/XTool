//
//  XString.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import UIKit
import CryptoKit

// MARK: - 空白 / 裁剪
public extension String {
    /// 去除首尾空白与换行
    var x_trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 去空白后是否为空（含纯空格 / 换行）
    var x_isBlank: Bool {
        x_trimmed.isEmpty
    }
    
    /// 空白则返回 `nil`，否则返回去空白后的字符串
    var x_nilIfBlank: String? {
        let trimmed = x_trimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}

public extension Optional where Wrapped == String {
    /// `nil` 或空白字符串视为 blank
    var x_isBlank: Bool {
        switch self {
        case .none: true
        case .some(let value): value.x_isBlank
        }
    }
    
    /// `nil` / 空白 → `nil`；否则返回去空白后的字符串
    var x_nilIfBlank: String? {
        self?.x_nilIfBlank
    }
}

// MARK: - 校验
public extension String {
    /// 是否合法邮箱
    var x_isValidEmail: Bool {
        range(of: Self.x_emailPattern, options: .regularExpression) != nil
    }
    
    /// 是否合法中国大陆手机号
    var x_isValidChinesePhoneNumber: Bool {
        range(of: Self.x_phonePattern, options: .regularExpression) != nil
    }
    
    /// 是否仅包含数字（0-9），不含正负号与小数点
    var x_isDigitsOnly: Bool {
        !isEmpty && allSatisfy { $0.isNumber && $0.isASCII }
    }
    
    private static let x_emailPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
    private static let x_phonePattern = #"^1[3-9]\d{9}$"#
}

// MARK: - 哈希 / Base64
public extension String {
    /// MD5 十六进制字符串
    var x_md5: String {
        XDigestHex.string(from: Insecure.MD5.hash(data: Data(utf8)))
    }
    
    /// SHA256 十六进制字符串
    var x_sha256: String {
        XDigestHex.string(from: SHA256.hash(data: Data(utf8)))
    }
    
    /// Base64 编码
    var x_base64Encoded: String? {
        Data(utf8).base64EncodedString()
    }
    
    /// Base64 解码
    var x_base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - 文本高度
public extension String {
    /// 限定宽度与字体下的文本高度
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

// MARK: - 本地化
public extension String {
    /// 本地化文案
    var x_localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// 带参数的本地化文案
    func x_localized(with arguments: CVarArg...) -> String {
        String(format: x_localized, arguments: arguments)
    }
}

// MARK: - 剪贴板
public extension String {
    /// 复制到系统剪贴板
    /// - Parameter haptic: 是否触发成功震动，默认 `true`
    @MainActor
    func x_copyToClipboard(haptic: Bool = true) {
        UIPasteboard.general.string = self
        if haptic {
            UIDevice.x_triggerHaptic(.success)
        }
    }
}

// MARK: - Digest Hex
enum XDigestHex {
    private static let digits: [Character] = Array("0123456789abcdef")
    
    static func string<D: Digest>(from digest: D) -> String {
        var result = String()
        result.reserveCapacity(64)
        for byte in digest {
            result.append(digits[Int(byte >> 4)])
            result.append(digits[Int(byte & 0x0F)])
        }
        return result
    }
}
