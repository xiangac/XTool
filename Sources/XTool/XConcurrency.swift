//
//  XConcurrency.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

// MARK: - 主线程通知
public extension NotificationCenter {
    /// 在主线程发送通知（已在主线程则同步发送，否则异步派发到主线程）
    /// - Parameters:
    ///   - aName: 通知名
    ///   - anObject: 关联对象
    ///   - aUserInfo: 附加信息
    nonisolated func x_postOnMainThread(
        name aName: NSNotification.Name,
        object anObject: Any? = nil,
        userInfo aUserInfo: [AnyHashable: Any]? = nil
    ) {
        if Thread.isMainThread {
            post(name: aName, object: anObject, userInfo: aUserInfo)
            return
        }
        // Notification 载荷本身非 Sendable；跨队列派发时按既有 Foundation 语义传递
        nonisolated(unsafe) let object = anObject
        nonisolated(unsafe) let info = aUserInfo
        DispatchQueue.main.async { [weak self] in
            self?.post(name: aName, object: object, userInfo: info)
        }
    }
}

// MARK: - 防抖
public extension Task where Success == Never, Failure == Never {
    /// 延迟指定秒数后执行；期间若被取消则不会执行
    /// - Parameters:
    ///   - seconds: 延迟秒数（负数按 0 处理）
    ///   - operation: 异步任务
    /// - Returns: 可取消的 `Task`
    /// - Note: 典型用法：先 `cancel` 上一次任务，再创建新的 debounce Task
    @discardableResult
    static func x_debounce(
        seconds: Double,
        operation: @escaping @Sendable () async -> Void
    ) -> Task<Void, Error> {
        let delay = max(0, seconds)
        return Task<Void, Error> {
            try await Task.sleep(for: .seconds(delay))
            try Task.checkCancellation()
            await operation()
        }
    }
}
