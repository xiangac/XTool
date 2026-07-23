//
//  XCodable.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import CoreGraphics

// MARK: - 用法
//
// 1) 推荐：struct 级容错（缺失 / null / 类型不符 → 类型默认值；支持 "100"→Int 等弱转）
//
//    @XResilientCodable
//    struct Product: Codable {
//        var price: Int
//        var name: String
//        var tags: [String]
//        var onSale: Bool?
//    }
//
// 2) 单字段：@XDefault（按类型自动选默认值）
//
//    struct Product: Codable {
//        @XDefault var price: Int
//        @XDefault var name: String
//    }
//
// 3) 自定义默认值：@XDecodableDefault<Provider>
//
//    struct Product: Codable {
//        @XDecodableDefault<XDefaults.True> var enabled: Bool
//    }

/// 可为类型提供解码失败时的默认值
public protocol XDefaultable {
    static var x_defaultValue: Self { get }
}

/// 为 `XDecodableDefault` 提供默认值的协议
public protocol XDefaultValueProvider {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

/// 常用显式默认值 Provider（配合 `@XDecodableDefault`）
public enum XDefaults {
    public enum EmptyString: XDefaultValueProvider { public static var defaultValue: String { "" } }
    public enum EmptyArray<T: Codable>: XDefaultValueProvider { public static var defaultValue: [T] { [] } }
    public enum EmptyDictionary<K: Codable & Hashable, V: Codable>: XDefaultValueProvider {
        public static var defaultValue: [K: V] { [:] }
    }
    public enum EmptyData: XDefaultValueProvider { public static var defaultValue: Data { Data() } }
    public enum False: XDefaultValueProvider { public static var defaultValue: Bool { false } }
    public enum True: XDefaultValueProvider { public static var defaultValue: Bool { true } }
    public enum Zero: XDefaultValueProvider { public static var defaultValue: Int { 0 } }
    public enum ZeroInt64: XDefaultValueProvider { public static var defaultValue: Int64 { 0 } }
    public enum ZeroDouble: XDefaultValueProvider { public static var defaultValue: Double { 0 } }
    public enum ZeroFloat: XDefaultValueProvider { public static var defaultValue: Float { 0 } }
    public enum ZeroCGFloat: XDefaultValueProvider { public static var defaultValue: CGFloat { 0 } }
    public enum ZeroDecimal: XDefaultValueProvider { public static var defaultValue: Decimal { 0 } }
    public enum Epoch: XDefaultValueProvider {
        public static var defaultValue: Date { Date(timeIntervalSince1970: 0) }
    }
}

// MARK: - @XDefault（按类型自动默认值）

/// 解码容错属性包装器：缺失 / null / 类型错误时使用 `T.x_defaultValue`（含弱类型转换）
@propertyWrapper
public struct XDefault<T: Codable & XDefaultable>: Codable {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    /// 单值上下文：nil / 精确类型 / 弱转 / 默认值
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = T.x_defaultValue
            return
        }
        if let val = try? container.decode(T.self) {
            wrappedValue = val
            return
        }
        if let coerced: T = XTypeCoercion.decodeLossy(from: container) {
            wrappedValue = coerced
            return
        }
        wrappedValue = T.x_defaultValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

nonisolated public extension KeyedDecodingContainer {
    /// 不走 `XDefault.init(from:)` 的「先成功再兜底」，避免类型错误被吞成默认值后跳过弱转
    func decode<T: Codable & XDefaultable>(
        _ type: XDefault<T>.Type,
        forKey key: Key
    ) throws -> XDefault<T> {
        XDefault(wrappedValue: x_decode(forKey: key))
    }
}

// MARK: - @XDecodableDefault（自定义 Provider）

/// 解码容错属性包装器：解析失败时回退到 `Provider.defaultValue`（含弱类型转换）
@propertyWrapper
public struct XDecodableDefault<Provider: XDefaultValueProvider>: Codable {
    public var wrappedValue: Provider.Value

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = Provider.defaultValue
            return
        }
        if let val = try? container.decode(Provider.Value.self) {
            wrappedValue = val
            return
        }
        if let coerced: Provider.Value = XTypeCoercion.decodeLossy(from: container) {
            wrappedValue = coerced
            return
        }
        wrappedValue = Provider.defaultValue
    }

    public init(wrappedValue: Provider.Value) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

nonisolated public extension KeyedDecodingContainer {
    func decode<Provider: XDefaultValueProvider>(
        _ type: XDecodableDefault<Provider>.Type,
        forKey key: Key
    ) throws -> XDecodableDefault<Provider> {
        let value: Provider.Value = x_decodeValue(forKey: key, fallback: Provider.defaultValue)
        return XDecodableDefault(wrappedValue: value)
    }
    
    /// 解码失败时回退到类型默认值（供 `@XResilientCodable` 宏生成的代码调用）
    func x_decode<T: Decodable & XDefaultable>(forKey key: Key) -> T {
        x_decodeValue(forKey: key, fallback: T.x_defaultValue)
    }
    
    /// Optional 字段：缺失 / null / 无法转换 → `nil`
    func x_decodeIfPresent<T: Decodable>(forKey key: Key) -> T? {
        // 1. 尝试直接解码（Happy Path）
        if let val = try? decodeIfPresent(T.self, forKey: key) {
            return val
        }
        // 2. 字段不存在或显式 null 时返回 nil
        guard contains(key), (try? decodeNil(forKey: key)) == false else { return nil }
        
        // 3. 类型不匹配，尝试弱类型转换
        return XTypeCoercion.decodeLossy(from: self, forKey: key)
    }
    
    /// 非 Defaultable 字段：严格解码，失败则抛出错误
    func x_decodeStrict<T: Decodable>(forKey key: Key) throws -> T {
        try decode(T.self, forKey: key)
    }
    
    /// 统一：精确解码 → 弱转 → fallback
    fileprivate func x_decodeValue<T: Decodable>(forKey key: Key, fallback: T) -> T {
        // 1. 极速路径：类型完全匹配
        if let val = try? decodeIfPresent(T.self, forKey: key) {
            return val
        }
        // 2. 缺失或 null，直接返回 fallback
        guard contains(key), (try? decodeNil(forKey: key)) == false else {
            return fallback
        }
        // 3. 类型不符合，走弱类型转换
        if let coerced: T = XTypeCoercion.decodeLossy(from: self, forKey: key) {
            return coerced
        }
        return fallback
    }
}

// MARK: - 内建默认可解码类型

extension String: XDefaultable { public static var x_defaultValue: String { "" } }
extension Bool: XDefaultable { public static var x_defaultValue: Bool { false } }
extension Int: XDefaultable { public static var x_defaultValue: Int { 0 } }
extension Int8: XDefaultable { public static var x_defaultValue: Int8 { 0 } }
extension Int16: XDefaultable { public static var x_defaultValue: Int16 { 0 } }
extension Int32: XDefaultable { public static var x_defaultValue: Int32 { 0 } }
extension Int64: XDefaultable { public static var x_defaultValue: Int64 { 0 } }
extension UInt: XDefaultable { public static var x_defaultValue: UInt { 0 } }
extension UInt8: XDefaultable { public static var x_defaultValue: UInt8 { 0 } }
extension UInt16: XDefaultable { public static var x_defaultValue: UInt16 { 0 } }
extension UInt32: XDefaultable { public static var x_defaultValue: UInt32 { 0 } }
extension UInt64: XDefaultable { public static var x_defaultValue: UInt64 { 0 } }
extension Float: XDefaultable { public static var x_defaultValue: Float { 0 } }
extension Double: XDefaultable { public static var x_defaultValue: Double { 0 } }
extension CGFloat: XDefaultable { public static var x_defaultValue: CGFloat { 0 } }
extension Data: XDefaultable { public static var x_defaultValue: Data { Data() } }
extension Decimal: XDefaultable { public static var x_defaultValue: Decimal { 0 } }
extension URL: XDefaultable {
    /// 解码失败时的占位 URL（非业务有效地址）
    public static var x_defaultValue: URL { URL(string: "about:blank")! }
}
extension Date: XDefaultable {
    public static var x_defaultValue: Date { Date(timeIntervalSince1970: 0) }
}
extension Array: XDefaultable where Element: Codable {
    public static var x_defaultValue: [Element] { [] }
}
extension Dictionary: XDefaultable where Key: Codable, Value: Codable {
    public static var x_defaultValue: [Key: Value] { [:] }
}
extension Set: XDefaultable where Element: Codable & Hashable {
    public static var x_defaultValue: Set<Element> { [] }
}

// MARK: - 弱类型转换

private enum XTypeCoercion {
    
    static func decodeLossy<T: Decodable, K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> T? {
        // 使用 decodeIfPresent 防范递归并提升效率
        if let str = try? container.decodeIfPresent(String.self, forKey: key) {
            return coerce(str)
        }
        if let int64 = try? container.decodeIfPresent(Int64.self, forKey: key) {
            return coerce(int64)
        }
        if let uint64 = try? container.decodeIfPresent(UInt64.self, forKey: key) {
            if T.self == UInt64.self { return uint64 as? T }
            if T.self == String.self { return String(uint64) as? T }
        }
        if let double = try? container.decodeIfPresent(Double.self, forKey: key) {
            return coerce(double)
        }
        if let bool = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return coerce(bool)
        }
        return nil
    }
    
    static func decodeLossy<T: Decodable>(from container: SingleValueDecodingContainer) -> T? {
        if let str = try? container.decode(String.self) {
            return coerce(str)
        }
        if let int64 = try? container.decode(Int64.self) {
            return coerce(int64)
        }
        if let uint64 = try? container.decode(UInt64.self) {
            if T.self == UInt64.self { return uint64 as? T }
            if T.self == String.self { return String(uint64) as? T }
        }
        if let double = try? container.decode(Double.self) {
            return coerce(double)
        }
        if let bool = try? container.decode(Bool.self) {
            return coerce(bool)
        }
        return nil
    }
    
    // MARK: String → T
    
    private static func coerce<T: Decodable>(_ string: String) -> T? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if T.self == String.self { return trimmed as? T }
        
        if T.self == Bool.self {
            switch trimmed.lowercased() {
            case "true", "1", "yes", "y": return true as? T
            case "false", "0", "no", "n": return false as? T
            default: break
            }
        }
        
        if let number = parseNumber(trimmed) {
            if let value: T = coerceNumber(number) { return value }
        }
        
        if T.self == Decimal.self, let d = Decimal(string: trimmed) {
            return d as? T
        }
        
        if T.self == URL.self, !trimmed.isEmpty {
            if let url = URL(string: trimmed) {
                return url as? T
            }
            // 容错：中文 / 未 Percent Encoding 的 URL 补救
            if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encoded) {
                return url as? T
            }
        }
        
        return nil
    }
    
    // MARK: Int64 / Double / Bool → T
    
    private static func coerce<T: Decodable>(_ int64: Int64) -> T? {
        if T.self == String.self { return String(int64) as? T }
        if T.self == Bool.self { return (int64 != 0) as? T }
        return coerceNumber(NumberBox(int64: int64))
    }
    
    private static func coerce<T: Decodable>(_ double: Double) -> T? {
        if T.self == String.self {
            if double.rounded() == double, let i = Int64(exactly: double.rounded()) {
                return String(i) as? T
            }
            return String(double) as? T
        }
        if T.self == Bool.self { return (double != 0) as? T }
        return coerceNumber(NumberBox(double: double))
    }
    
    private static func coerce<T: Decodable>(_ bool: Bool) -> T? {
        if T.self == String.self { return (bool ? "true" : "false") as? T }
        if T.self == Bool.self { return bool as? T }
        return coerceNumber(NumberBox(int64: bool ? 1 : 0))
    }
    
    // MARK: Number → numeric T
    
    private struct NumberBox {
        var int64: Int64?
        var double: Double?
        
        init(int64: Int64) {
            self.int64 = int64
            self.double = Double(int64)
        }
        
        init(double: Double) {
            self.double = double
            if double.rounded(.towardZero) == double,
               let i = Int64(exactly: double.rounded(.towardZero)) {
                self.int64 = i
            } else {
                self.int64 = Int64(double)
            }
        }
    }
    
    private static func parseNumber(_ string: String) -> NumberBox? {
        if let i = Int64(string) { return NumberBox(int64: i) }
        if let d = Double(string) { return NumberBox(double: d) }
        return nil
    }
    
    private static func coerceNumber<T: Decodable>(_ box: NumberBox) -> T? {
        if T.self == Int.self, let v = box.int64 { return Int(v) as? T }
        if T.self == Int8.self, let v = box.int64, let r = Int8(exactly: v) { return r as? T }
        if T.self == Int16.self, let v = box.int64, let r = Int16(exactly: v) { return r as? T }
        if T.self == Int32.self, let v = box.int64, let r = Int32(exactly: v) { return r as? T }
        if T.self == Int64.self, let v = box.int64 { return v as? T }
        
        if T.self == UInt.self, let v = box.int64, v >= 0 { return UInt(v) as? T }
        if T.self == UInt8.self, let v = box.int64, let r = UInt8(exactly: v) { return r as? T }
        if T.self == UInt16.self, let v = box.int64, let r = UInt16(exactly: v) { return r as? T }
        if T.self == UInt32.self, let v = box.int64, let r = UInt32(exactly: v) { return r as? T }
        if T.self == UInt64.self, let v = box.int64, v >= 0 { return UInt64(v) as? T }
        
        if T.self == Float.self, let d = box.double { return Float(d) as? T }
        if T.self == Double.self, let d = box.double { return d as? T }
        if T.self == CGFloat.self, let d = box.double { return CGFloat(d) as? T }
        if T.self == Decimal.self {
            if let i = box.int64 { return Decimal(i) as? T }
            if let d = box.double { return Decimal(d) as? T }
        }
        return nil
    }
}

// MARK: - Struct 级宏

/// 为 struct 生成容错 `Codable` 实现：字段缺失 / null / 类型不符时使用默认值；`Optional` 失败则为 `nil`
///
/// ```swift
/// @XResilientCodable
/// struct Product: Codable {
///     var id: Int
///     var name: String
///     var tags: [String]
///     var note: String?
/// }
/// ```
@attached(member, names: named(init(from:)), named(encode(to:)), named(CodingKeys))
public macro XResilientCodable() = #externalMacro(module: "XToolMacros", type: "XResilientCodableMacro")
