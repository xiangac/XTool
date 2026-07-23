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

// MARK: - 去重 / 分块 / 分组
public extension Sequence where Element: Hashable {
    /// 去重并保持首次出现顺序
    var x_unique: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public extension Collection {
    /// 按固定大小切块；最后一块可能不足 `size`
    /// - Parameter size: 每块元素个数；`<= 0` 时返回空数组
    func x_chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        
        var result: [[Element]] = []
        result.reserveCapacity((count + size - 1) / size)
        
        var index = startIndex
        while index != endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<next]))
            index = next
        }
        return result
    }
}

public extension Sequence {
    /// 按闭包结果分组
    func x_grouped<Key: Hashable>(by keyForValue: (Element) throws -> Key) rethrows -> [Key: [Element]] {
        try Dictionary(grouping: self, by: keyForValue)
    }
    
    /// 按 `KeyPath` 分组
    func x_grouped<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
        Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
    }
}

public extension Dictionary {
    /// 对 value 做变换并丢弃 `nil`（与标准库 `compactMapValues` 等价，统一 `x_` 前缀）
    func x_compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        try compactMapValues(transform)
    }
}
