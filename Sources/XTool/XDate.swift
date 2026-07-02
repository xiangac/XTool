//
//  XDate.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import os

// MARK: - 1. 快速格式化
public extension Date {
    /// 将 Date 转换为指定格式的字符串
    /// - Parameter format: 例如 "yyyy-MM-dd HH:mm:ss"
    func x_toString(format: String = "yyyy-MM-dd") -> String {
        return Date.getFormatter(for: format).string(from: self)
    }
    
    /// 从指定格式的字符串快速生成 Date
    static func x_from(_ string: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        return getFormatter(for: format).date(from: string)
    }
    
}

// MARK: - 2. 人性化相对时间 (时间戳转换常用)
public extension Date {
    /// 转换为形如 “刚刚”、“5分钟前”、“昨天 14:20” 的人性化字符串
    var x_toRelativeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        guard let day = components.day, let hour = components.hour, let minute = components.minute else {
            return self.x_toString(format: "yyyy-MM-dd")
        }
        
        if calendar.isDateInToday(self) {
            if minute < 1 { return "刚刚" }
            if minute < 60 { return "\(minute)分钟前" }
            return "\(hour)小时前"
        } else if calendar.isDateInYesterday(self) {
            return "昨天 " + self.x_toString(format: "HH:mm")
        } else if day < 7 {
            return "\(day)天前"
        } else {
            return self.x_toString(format: "yyyy-MM-dd")
        }
    }
}

extension Date {
    /// 内部专属的 Formatter 缓存池，避免频繁创建销毁造成的性能卡顿
    private static let formatterCache = OSAllocatedUnfairLock(initialState: [String: DateFormatter]())
    
    private static func getFormatter(for pattern: String) -> DateFormatter {
        return formatterCache.withLock { cache in
            if let cached = cache[pattern] { return cached }
            let formatter = DateFormatter()
            formatter.dateFormat = pattern
            formatter.locale = Locale.current
            cache[pattern] = formatter
            return formatter
        }
    }
}
