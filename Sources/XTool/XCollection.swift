//
//  XCollection.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

public extension Data {
    /// Data转字典
    var x_toDictionary: [String: Any]? {
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
    func x_toDictionary() -> [String: Any] {
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

// 💡 使用效果：
// let list = ["Apple", "Banana"]
// let item = list[x_safe: 5] // 🟢 以前这行直接挂了，现在安全返回 nil
public extension Array {
    /// 安全地获取数组元素，避免索引越界导致 Crash
    /// - Parameter index: 索引下标
    /// - Returns: 存在则返回对应元素，越界则返回 nil
    subscript(x_safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 模型转 JSON
public extension Encodable {
    
    /// 将模型转换为 JSON 字符串
    var x_toJSONString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // 如果需要紧凑型可以去掉这行
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 将模型转换为 字典 [String: Any] (转网络请求参数时极度高频)
    var x_toDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dict
    }
}
