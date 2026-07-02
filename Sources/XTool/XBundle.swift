//
//  XBundle.swift
//  XTool
//
//  Created by zjwx01 on 2026/7/2.
//

import Foundation

// 💡 使用效果：
// if Bundle.x_currentEnvironment == .debug {
//     ShowLogConsole() // 仅测试或灰度环境下开启调试面板
// }
//MARK: 判断运行环境
public extension Bundle {
    enum x_AppEnvironment {
        case debug
        case testFlight
        case appStore
    }
    
    /// 动态获取当前 App 的运行环境
    static var x_currentEnvironment: x_AppEnvironment {
        #if DEBUG
        return .debug
        #else
        // TestFlight 导出的包会包含这个特殊的收据凭证
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           receiptURL.lastPathComponent == "sandboxReceipt" {
            return .testFlight
        }
        return .appStore
        #endif
    }
}

