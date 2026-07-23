//
//  XUserDefaults.swift
//  XTool
//
//  Created by xac on 2026/7/23.
//

import Foundation

public extension UserDefaults {
    
    /// 写入 `Codable` 值（JSON）；传 `nil` 则删除该 key
    /// - Returns: 编码并写入是否成功；`nil` 删除时恒为 `true`
    @discardableResult
    func x_setCodable<T: Encodable>(_ value: T?, forKey key: String) -> Bool {
        guard let value else {
            removeObject(forKey: key)
            return true
        }
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
            return true
        } catch {
            return false
        }
    }
    
    /// 读取 `Codable` 值；不存在或解码失败返回 `nil`
    func x_codable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    /// 删除指定 key
    func x_remove(forKey key: String) {
        removeObject(forKey: key)
    }
    
    /// 是否包含该 key（含显式写入的 `nil`/`false`/`0` 等）
    func x_contains(key: String) -> Bool {
        object(forKey: key) != nil
    }
}
