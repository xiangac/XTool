//
//  XTimeUtils.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation

public struct XTimeUtils {

}

public extension XTimeUtils {
    /// 时间戳转特定格式字符串
    static func getTime(withInterval interval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    /// 获取当前北京时间字符串
    static func getCurrentBeijingTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.string(from: Date())
    }
    
    /// 北京时间字符串进行分钟偏移计算
    static func getBeijingTime(from timeString: String, offsetMins mins: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        
        let baseDate = formatter.date(from: timeString) ?? Date()
        let targetDate = baseDate.addingTimeInterval(TimeInterval(mins * 60))
        return formatter.string(from: targetDate)
    }
    
    /// 计算两个日期字符串之间的秒数差值
    static func twoDateSecondsInterval(fromDate: String, toDate: String) -> Int {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        
        let colonCount = fromDate.components(separatedBy: ":").count - 1
        if colonCount == 2 {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        } else if colonCount == 1 {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        
        let date1 = formatter.date(from: fromDate) ?? Date()
        let date2 = formatter.date(from: toDate) ?? Date()
        let secondInterval = date1.timeIntervalSince1970 - date2.timeIntervalSince1970
        return Int(secondInterval)
    }
}

public extension XTimeUtils {
    /// 以百纳秒为单位的时间戳
    static func fetchMicrosecondTimestampString() -> String {
        let interval = Date().timeIntervalSince1970
        // 乘以一百万，真正对应 micro 的含义
        let microseconds = Int64(round(interval * 1_000_000))
        return "\(microseconds)"
    }
}

public extension XTimeUtils {
    /// 将秒数（duration）格式化为挂钟时间字符串（如 00:15、05:30 或 01:15:30）。
    static func formatVideoDuration(_ duration: Int) -> String {
        // 小于 1 分钟
        if duration < 60 {
            return String(format: "00:%02d", duration)
        }
        
        // 小于 1 小时
        if duration < 3600 {
            let min = duration / 60
            let sec = duration % 60
            return String(format: "%02d:%02d", min, sec)
        }
        
        // 大于等于 1 小时
        let hour = duration / 3600
        let min = (duration % 3600) / 60
        let sec = duration % 60
        return String(format: "%02d:%02d:%02d", hour, min, sec)
    }
}
