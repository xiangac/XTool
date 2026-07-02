//
//  XKeychain.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import Security

public struct XKeychain {
    
    
}

public extension XKeychain {
    /// 存储字符串到 Keychain
    static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock // 保证设备解锁后可访问
        ] as [CFString : Any]
        
        // 先删除旧值，确保新值写入成功
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain 存储失败，Status: \(status)")
        }
    }
    
    /// 从 Keychain 读取字符串
    static func load(forKey key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [CFString : Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    /// 从 Keychain 删除指定键值
    static func remove(forKey key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as [CFString : Any]
        
        SecItemDelete(query as CFDictionary)
    }
}
