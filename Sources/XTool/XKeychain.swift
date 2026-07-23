//
//  XKeychain.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import Security

/// Keychain 轻量封装，提供字符串的安全读写与删除
public struct XKeychain {
    /// 默认 Service，隔离不同 App / Target 的同名 Account
    private static var service: String {
        Bundle.main.bundleIdentifier ?? "XTool.Keychain"
    }
    
    private static func baseQuery(forKey key: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
    }
}

public extension XKeychain {
    /// 存储字符串到 Keychain（同 key 会覆盖旧值）
    /// - Parameters:
    ///   - value: 要保存的字符串
    ///   - key: 存储键名（Account）
    /// - Returns: 是否写入成功
    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let updateQuery = baseQuery(forKey: key)
        let updateAttrs: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttrs as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return true
        }
        if updateStatus != errSecItemNotFound {
            return false
        }
        
        var addQuery = baseQuery(forKey: key)
        addQuery[kSecValueData] = data
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
    
    /// 从 Keychain 读取字符串
    /// - Parameter key: 存储键名
    /// - Returns: 对应字符串；不存在或读取失败时返回 `nil`
    static func load(forKey key: String) -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    /// 从 Keychain 删除指定键值
    /// - Parameter key: 要删除的存储键名
    /// - Returns: 是否删除成功（键不存在也视为成功）
    @discardableResult
    static func remove(forKey key: String) -> Bool {
        let status = SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
