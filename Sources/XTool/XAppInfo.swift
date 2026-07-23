//
//  XAppInfo.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

/// App 基础信息读取（名称、版本号、Bundle ID 等）
public struct XAppInfo {
    /// App 名称（优先 `CFBundleDisplayName`，否则 `CFBundleName`）
    public static var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? ""
    }
    
    /// 发布版本号（例如 `"1.0.0"`）
    public static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// 构建版本号（例如 `"123"`）
    public static var appBuildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    /// Bundle Identifier
    public static var bundleID: String {
        Bundle.main.bundleIdentifier ?? ""
    }
    
    /// 完整版本信息（格式：`版本号(Build号)`）
    public static var fullVersion: String {
        "\(appVersion)(\(appBuildVersion))"
    }
}
