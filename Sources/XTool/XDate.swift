//
//  XDate.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import os
import Darwin

// MARK: - 格式化
public extension Date {
    /// 将 `Date` 转为指定格式字符串
    /// - Parameter format: 日期格式，默认 `"yyyy-MM-dd"`
    func x_toString(format: String = "yyyy-MM-dd") -> String {
        Date.x_formatter(for: format).string(from: self)
    }
    
    /// 从字符串解析 `Date`
    /// - Parameters:
    ///   - string: 日期字符串
    ///   - format: 解析格式，默认 `"yyyy-MM-dd HH:mm:ss"`
    static func x_from(_ string: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        x_formatter(for: format).date(from: string)
    }
    
    /// 人性化相对时间（刚刚 / N分钟前 / 昨天 HH:mm / N天前）
    /// - Note: 未来时间直接返回具体日期字符串，避免出现负数文案
    var x_toRelativeString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if self > now {
            return x_toString(format: "yyyy-MM-dd HH:mm")
        }
        
        // 用总分钟差，避免 dateComponents 拆分后 hour/minute 互相干扰
        let totalMinutes = max(0, Int(now.timeIntervalSince(self) / 60))
        
        if calendar.isDateInToday(self) {
            if totalMinutes < 1 { return "刚刚" }
            if totalMinutes < 60 { return "\(totalMinutes)分钟前" }
            return "\(totalMinutes / 60)小时前"
        } else if calendar.isDateInYesterday(self) {
            return "昨天 " + x_toString(format: "HH:mm")
        }
        
        let day = calendar.dateComponents([.day], from: self, to: now).day ?? 0
        if day < 7 {
            return "\(max(1, day))天前"
        }
        return x_toString(format: "yyyy-MM-dd")
    }
}

// MARK: - 日历语义
public extension Date {
    /// 是否为今天（按当前日历）
    var x_isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否为昨天（按当前日历）
    var x_isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 当天 00:00:00（按当前日历）
    var x_startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 相对 `date` 的整天差（`self` − `date`，按日切分；可为负）
    /// - Example: 今天相对昨天为 `1`，昨天相对今天为 `-1`
    func x_days(from date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: self)
        ).day ?? 0
    }
}

// MARK: - 时间戳 / 北京时间 / 时长
public extension Date {
    /// 将 Unix 时间戳转为日期字符串
    /// - Parameters:
    ///   - timestamp: 自 1970 以来的秒数
    ///   - format: 输出格式，默认 `"yyyy.MM.dd"`
    static func x_dateString(fromTimestamp timestamp: TimeInterval, format: String = "yyyy.MM.dd") -> String {
        x_formatter(for: format).string(from: Date(timeIntervalSince1970: timestamp))
    }
    
    /// 当前北京时间字符串（`yyyy-MM-dd HH:mm:ss`）
    static func x_currentBeijingTimeString() -> String {
        x_beijingFormatter().string(from: Date())
    }
    
    /// 对北京时间字符串做分钟偏移
    /// - Parameters:
    ///   - timeString: 基准时间，格式 `yyyy-MM-dd HH:mm:ss`
    ///   - minutes: 偏移分钟数（可为负）
    /// - Returns: 偏移后的北京时间；解析失败返回 `nil`
    static func x_beijingTimeString(from timeString: String, offsetMinutes minutes: Int) -> String? {
        let formatter = x_beijingFormatter()
        guard let baseDate = formatter.date(from: timeString) else { return nil }
        let targetDate = baseDate.addingTimeInterval(TimeInterval(minutes * 60))
        return formatter.string(from: targetDate)
    }
    
    /// 计算两个日期字符串的秒差（`to - from`，即从 `from` 到 `to` 经过的秒数）
    /// - Note: 自动识别 `yyyy-MM-dd` / `yyyy-MM-dd HH:mm` / `yyyy-MM-dd HH:mm:ss`
    /// - Returns: 秒差；任一端解析失败返回 `nil`
    static func x_seconds(from fromDate: String, to toDate: String) -> Int? {
        guard let start = x_parseFlexibleDate(fromDate),
              let end = x_parseFlexibleDate(toDate) else {
            return nil
        }
        return Int(end.timeIntervalSince(start))
    }
    
    /// 当前微秒时间戳字符串
    /// - Note: 使用 `clock_gettime` 避免 `Double` 乘法丢失微秒精度
    static func x_microsecondTimestampString() -> String {
        var ts = timespec()
        clock_gettime(CLOCK_REALTIME, &ts)
        let microseconds = Int64(ts.tv_sec) * 1_000_000 + Int64(ts.tv_nsec) / 1_000
        return "\(microseconds)"
    }
    
    /// 将秒数格式化为视频时长（`00:15` / `05:30` / `01:15:30`）
    /// - Note: 负数按 `0` 处理
    static func x_formatVideoDuration(_ duration: Int) -> String {
        let duration = max(0, duration)
        if duration < 60 {
            return String(format: "00:%02d", duration)
        }
        if duration < 3600 {
            let min = duration / 60
            let sec = duration % 60
            return String(format: "%02d:%02d", min, sec)
        }
        let hour = duration / 3600
        let min = (duration % 3600) / 60
        let sec = duration % 60
        return String(format: "%02d:%02d:%02d", hour, min, sec)
    }
}

// MARK: - Formatter（线程安全：锁内完成格式化）
extension Date {
    private static let formatterCache = OSAllocatedUnfairLock(initialState: [String: DateFormatter]())
    
    /// 按格式安全格式化（锁内使用缓存的 Formatter）
    fileprivate static func x_formatter(for pattern: String) -> DateFormatterProxy {
        DateFormatterProxy(pattern: pattern)
    }
    
    /// 代理：每次格式化都在锁内执行，避免 DateFormatter 跨线程共享
    fileprivate struct DateFormatterProxy {
        let pattern: String
        
        func string(from date: Date) -> String {
            formatterCache.withLock { cache in
                let formatter = cachedFormatter(pattern: pattern, cache: &cache)
                return formatter.string(from: date)
            }
        }
        
        func date(from string: String) -> Date? {
            formatterCache.withLock { cache in
                let formatter = cachedFormatter(pattern: pattern, cache: &cache)
                return formatter.date(from: string)
            }
        }
        
        private func cachedFormatter(pattern: String, cache: inout [String: DateFormatter]) -> DateFormatter {
            if let cached = cache[pattern] { return cached }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = pattern
            cache[pattern] = formatter
            return formatter
        }
    }
    
    /// 北京时区 Formatter（独立缓存，不与本地时区 formatter 混用）
    private static let beijingFormatterLock = OSAllocatedUnfairLock(initialState: Optional<DateFormatter>.none)
    
    private static func x_beijingFormatter() -> BeijingFormatterProxy {
        BeijingFormatterProxy()
    }
    
    fileprivate struct BeijingFormatterProxy {
        func string(from date: Date) -> String {
            beijingFormatterLock.withLock { cached in
                formatter(&cached).string(from: date)
            }
        }
        
        func date(from string: String) -> Date? {
            beijingFormatterLock.withLock { cached in
                formatter(&cached).date(from: string)
            }
        }
        
        private func formatter(_ cached: inout DateFormatter?) -> DateFormatter {
            if let cached { return cached }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            cached = formatter
            return formatter
        }
    }
    
    /// 按长度与冒号识别常见日期格式（兼容 `T` 分隔的 ISO 片段）
    private static func x_parseFlexibleDate(_ string: String) -> Date? {
        let normalized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
        let timePart = normalized.split(separator: " ", maxSplits: 1).last.map(String.init) ?? ""
        let colonCount = timePart.filter { $0 == ":" }.count
        let format: String
        if colonCount >= 2 {
            format = "yyyy-MM-dd HH:mm:ss"
        } else if colonCount == 1 {
            format = "yyyy-MM-dd HH:mm"
        } else {
            format = "yyyy-MM-dd"
        }
        // 截断到格式对应长度，丢掉毫秒 / 时区后缀
        let trimmed: String
        switch format {
        case "yyyy-MM-dd HH:mm:ss":
            trimmed = String(normalized.prefix(19))
        case "yyyy-MM-dd HH:mm":
            trimmed = String(normalized.prefix(16))
        default:
            trimmed = String(normalized.prefix(10))
        }
        return x_formatter(for: format).date(from: trimmed)
    }
}
