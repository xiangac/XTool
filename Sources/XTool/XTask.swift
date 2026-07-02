//
//  XTask.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

// 💡 业务层防抖的使用极其震撼：
// class SearchViewModel {
//     private var searchTask: Task<Void, Error>?
//
//     func userDidType(keyword: String) {
//         searchTask?.cancel() // 🌟 只要用户在输入，就狂点取消上一次的
//         searchTask = Task.x_debounce(seconds: 0.3) {
//             await self.executeWebSearch(key: keyword) // 用户停手 0.3 秒后才会真正发网络请求
//         }
//     }
// }
public extension Task where Success == Never, Failure == Never {
    
    /// 现代防抖包装器：在指定秒数内，如果再次调用，则自动取消上一次的任务
    /// - Parameters:
    ///   - seconds: 延迟执行的时间（秒）
    ///   - operation: 要执行的异步任务
    /// - Returns: 返回当前的 Task 实例，方便后续控制
    @discardableResult
    static func x_debounce(
        seconds: Double,
        operation: @escaping @Sendable () async -> Void
    ) -> Task<Void, Error> {
        return Task<Void, Error> {
            // 1. 先进行纳秒级睡眠
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            // 2. 如果在睡眠期间该任务被标记为 cancelled，系统会自动抛出 CancellationError，下面这行就不会执行
            await operation()
        }
    }
}


