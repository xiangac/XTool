//
//  XNotification.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

/*
 如果在主线程（如 SwiftUI 视图、UIViewController）中调用，和以前一样直接用：NotificationCenter.default.x_postOnMainThread(name: ...)。
 如果在后台异步线程调用，编译器会逼你加上 await，确保安全切回主线程：await NotificationCenter.default.x_postOnMainThread(name: ...)。
 */
//MARK: 主线程发送通知
public extension NotificationCenter {
    
    /// 在主线程发送通知（安全刷新UI）
    /// - Note: 显式标记 `@MainActor`，由编译器自动、无损地处理线程安全切换
    @MainActor
    func x_postOnMainThread(
        name aName: NSNotification.Name,
        object anObject: Any? = nil,
        userInfo aUserInfo: [AnyHashable : Any]? = nil
    ) {
        // 既然已经隔离在 @MainActor，这里可以直接同步发送，绝对安全！
        self.post(name: aName, object: anObject, userInfo: aUserInfo)
    }
}
