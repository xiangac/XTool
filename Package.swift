// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XTool",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "XTool",
            targets: ["XTool"]
        ),
    ],
    targets: [
        .target(
            name: "XTool"
        ),
        .testTarget(
            name: "XToolTests",
            dependencies: ["XTool"]
        ),
    ]
)
