import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@XResilientCodable`：生成容错 init(from:) / encode(to:) / CodingKeys
public struct XResilientCodableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw XMacroError.message("@XResilientCodable 仅适用于 struct")
        }

        let stored = structDecl.memberBlock.members.compactMap { member -> (name: String, type: TypeSyntax, isOptional: Bool)? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var)
                    || varDecl.bindingSpecifier.tokenKind == .keyword(.let)
            else { return nil }

            if varDecl.modifiers.contains(where: { $0.name.text == "static" || $0.name.text == "class" }) {
                return nil
            }

            guard let binding = varDecl.bindings.first,
                  binding.accessorBlock == nil,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let type = binding.typeAnnotation?.type
            else { return nil }

            let name = pattern.identifier.text
            let isOptional = isOptionalType(type)
            return (name, type, isOptional)
        }

        guard !stored.isEmpty else {
            throw XMacroError.message("@XResilientCodable 需要至少一个存储属性，且需显式类型注解")
        }

        let codingKeysCases = stored.map { "case \($0.name)" }.joined(separator: "\n        ")
        let codingKeys: DeclSyntax = """
            enum CodingKeys: String, CodingKey {
                \(raw: codingKeysCases)
            }
            """

        let decodeLines = stored.map { prop -> String in
            if prop.isOptional {
                return "self.\(prop.name) = container.x_decodeIfPresent(forKey: .\(prop.name))"
            } else {
                return "self.\(prop.name) = container.x_decode(forKey: .\(prop.name))"
            }
        }.joined(separator: "\n        ")

        let initFrom: DeclSyntax = """
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: decodeLines)
            }
            """

        let encodeLines = stored.map { prop -> String in
            if prop.isOptional {
                return "try container.encodeIfPresent(\(prop.name), forKey: .\(prop.name))"
            } else {
                return "try container.encode(\(prop.name), forKey: .\(prop.name))"
            }
        }.joined(separator: "\n        ")

        let encodeTo: DeclSyntax = """
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                \(raw: encodeLines)
            }
            """

        return [codingKeys, initFrom, encodeTo]
    }

    private static func isOptionalType(_ type: TypeSyntax) -> Bool {
        if type.is(OptionalTypeSyntax.self) { return true }
        if let ident = type.as(IdentifierTypeSyntax.self), ident.name.text == "Optional" {
            return true
        }
        return false
    }
}

private enum XMacroError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let text): return text
        }
    }
}

@main
struct XToolCodableMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        XResilientCodableMacro.self
    ]
}
