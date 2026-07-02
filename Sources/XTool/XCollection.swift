//
//  XCollection.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

public extension Data {
    /// Data转字典
    public var toDictionary: [String: Any]? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            return jsonObject as? [String: Any]
        } catch {
            print("Data 转字典失败: \(error)")
            return nil
        }
    }
}

public extension String {
    /// 将 JSON 字符串解析为字典
    public func toDictionary() -> [String: Any] {
        // 1. 将字符串转为 Data
        guard let data = self.data(using: .utf8) else {
            return [:]
        }
        
        do {
            // 2. 解析 JSON 数据
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            // 3. 类型转换为字典并返回
            if let dictionary = json as? [String: Any] {
                return dictionary
            }
        } catch {
            print("[String Extension] JSON 解析失败: \(error)")
        }
        
        // 4. 失败时返回空字典
        return [:]
    }
}
