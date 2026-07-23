//
//  XBundle.swift
//  XTool
//
//  Created by zjwx01 on 2026/7/2.
//

import Foundation

/// App 运行环境
public enum XAppEnvironment {
    /// Debug 编译
    case debug
    /// TestFlight（sandbox receipt）
    case testFlight
    /// 非 App Store 分发（Enterprise / Ad Hoc / 开发描述文件等，存在 embedded.mobileprovision）
    case nonAppStore
    /// App Store 正式包
    case appStore
}

public extension Bundle {
    /// 当前 App 运行环境
    /// - Note: Release 下：`sandboxReceipt` → TestFlight；有 embedded provision → `nonAppStore`；否则视为 App Store
    static var x_currentEnvironment: XAppEnvironment {
        #if DEBUG
        return .debug
        #else
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receiptURL.path),
           receiptURL.lastPathComponent == "sandboxReceipt" {
            return .testFlight
        }
        if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
            return .nonAppStore
        }
        return .appStore
        #endif
    }
}
