//
//  XArray.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

public extension Array {
    /// 安全下标：越界返回 `nil`，避免 Crash
    /// - Parameter index: 索引
    /// - Returns: 元素或 `nil`
    subscript(x_safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
