//
//  XCodable.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

//MARK: 工业级容错：彻底解决因为后端返回 nil 或类型不对导致的解码崩溃
// 💡 工业级容错使用效果：
// struct UserProduct: Codable {
//     @XDecodableDefault<XDefault.Zero> var price: Int         // 后端漏传或传 null，自动变成 0
//     @XDecodableDefault<XDefault.EmptyString> var name: String // 类型不匹配时，自动变成 ""
//     @XDecodableDefault<XDefault.EmptyArray<String>> var tags: [String] // 自动变 []
// }


// 1. 定义一个用于提供默认值的协议
public protocol XDefaultValueProvider {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

// 2. 实现几种高频的默认值实现
public enum XDefault {
    public enum EmptyString: XDefaultValueProvider { public static var defaultValue: String { "" } }
    public enum EmptyArray<T: Codable>: XDefaultValueProvider { public static var defaultValue: [T] { [] } }
    public enum False: XDefaultValueProvider { public static var defaultValue: Bool { false } }
    public enum Zero: XDefaultValueProvider { public static var defaultValue: Int { 0 } }
}

// 3. 属性包装器核心逻辑
@propertyWrapper
public struct XDecodableDefault<Provider: XDefaultValueProvider>: Codable {
    public var wrappedValue: Provider.Value

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // 🌟 核心容错：如果解析失败或类型不匹配，直接降级采用默认值，绝对不抛出异常导致整个大 JSON 报废
        self.wrappedValue = (try? container.decode(Provider.Value.self)) ?? Provider.defaultValue
    }

    public init(wrappedValue: Provider.Value) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

// 4. 让 Key 不存在时也能顺利走入 init(from:)
nonisolated public extension KeyedDecodingContainer {
    func decode<Provider: XDefaultValueProvider>(_ type: XDecodableDefault<Provider>.Type, forKey key: Key) throws -> XDecodableDefault<Provider> {
        try decodeIfPresent(type, forKey: key) ?? XDecodableDefault(wrappedValue: Provider.defaultValue)
    }
}

// 5. 直接对常用类型进行扩展，不使用属性包装器也可以解析nil
nonisolated public extension KeyedDecodingContainer {
    
    // 1. 容错解析 String：遇到 null 或缺失时返回 ""
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        return try decodeIfPresent(String.self, forKey: key) ?? ""
    }
    
    // 2. 容错解析 Int：遇到 null 或缺失时返回 0
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try decodeIfPresent(Int.self, forKey: key) ?? 0
    }
    
    // 3. 容错解析 Double：遇到 null 或缺失时返回 0.0
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        return try decodeIfPresent(Double.self, forKey: key) ?? 0.0
    }
    
    // 4. 容错解析 Bool：遇到 null 或缺失时返回 false
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        return try decodeIfPresent(Bool.self, forKey: key) ?? false
    }
    
    // 5. 容错解析 数组：遇到 null 或缺失时返回空数组 []
    func decode<T: Decodable>(_ type: [T].Type, forKey key: Key) throws -> [T] {
        return try decodeIfPresent([T].self, forKey: key) ?? []
    }
    
    // 6. 容错解析字典/子模型 (可选型)：如果字段解析失败，自动转为 nil 而不崩溃
    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        // 尝试获取该键的值，如果不存在、是 null 或者解析内部出错，都安全返回 nil
        guard contains(key), try decodeNil(forKey: key) == false else {
            return nil
        }
        return try? decode(T.self, forKey: key)
    }
}
