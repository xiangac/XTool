@_exported import XTool

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
public macro XResilientCodable() = #externalMacro(
    module: "XToolCodableMacrosImpl",
    type: "XResilientCodableMacro"
)
