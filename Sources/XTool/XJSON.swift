//
//  XJSON.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

// MARK: - Data / String → Dictionary / Model
public extension Data {
    /// 将 JSON `Data` 解析为字典；失败返回 `nil`
    var x_toDictionary: [String: Any]? {
        (try? JSONSerialization.jsonObject(with: self, options: [])) as? [String: Any]
    }
}

public extension String {
    /// 将 JSON 字符串解析为字典；失败返回 `nil`（与空对象 `{}` 可区分）
    var x_toDictionary: [String: Any]? {
        guard let data = data(using: .utf8) else { return nil }
        return data.x_toDictionary
    }
    
    /// 将 JSON 字符串解码为指定 `Decodable` 模型
    /// - Parameter type: 目标模型类型
    /// - Returns: 解码成功返回模型，失败返回 `nil`
    func x_toModel<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Model → JSON / Dictionary
public extension Encodable {
    /// 编码为紧凑 JSON 字符串（`sortedKeys`，不含 pretty print，适合请求体）
    var x_toJSONString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 编码为字典（常用于组装网络请求参数）
    var x_toDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}
