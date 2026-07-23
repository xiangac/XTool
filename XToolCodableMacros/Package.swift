// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "XToolCodableMacros",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "XToolCodableMacros",
            targets: ["XToolCodableMacros"]
        ),
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"603.0.0"),
    ],
    targets: [
        .macro(
            name: "XToolCodableMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "XToolCodableMacros",
            dependencies: [
                "XToolCodableMacrosImpl",
                "XTool",
            ]
        ),
    ]
)
