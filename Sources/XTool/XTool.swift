//
//  XTool.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

/// XTool：面向 iOS 的常用扩展与工具集合（Swift Package）。
///
/// - 平台：iOS 18+ / macOS 15+（部分 UIKit API 仅 iOS）
/// - 约定：公开 API 统一 `x_` 前缀；类型 / 协议 / 宏使用 `X` 前缀
/// - 引入：`import XTool`
///
/// # 文件一览（职责 + 公开 API）
///
/// ## XAppInfo.swift
/// App 基础信息读取。
/// - `XAppInfo.appName` / `appVersion` / `appBuildVersion` / `bundleID` / `fullVersion`
///
/// ## XArray.swift
/// 数组安全访问与集合高频操作。
/// - `Array.subscript(x_safe:)` — 越界返回 `nil`
/// - `Sequence.x_unique`（`Element: Hashable`）— 去重保序
/// - `Collection.x_chunked(into:)` — 按大小切块
/// - `Sequence.x_grouped(by:)` — 闭包 / KeyPath 分组
/// - `Dictionary.x_compactMapValues(_:)` — 映射并丢弃 `nil`
///
/// ## XApplication.swift
/// Scene 体系下定位窗口与顶层 VC。
/// - `UIApplication.x_keyWindow()` / `x_rootViewController()` / `x_topViewController(base:)`
///
/// ## XBundle.swift
/// 运行环境判定。
/// - `XAppEnvironment`：`.debug` / `.testFlight` / `.nonAppStore` / `.appStore`
/// - `Bundle.x_currentEnvironment`
///
/// ## XButton.swift
/// UIButton 全局防连击（Method Swizzling）。
/// - `UIButton.x_debounceInterval` — 防抖间隔，默认 0.5s
/// - `UIButton.x_enableDebounce()` — 启动时调用一次
///
/// ## XCodable.swift
/// Codable 容错解码（属性包装器 + 弱类型转换）。
/// - 协议：`XDefaultable` / `XDefaultValueProvider`
/// - `XDefaults`：`EmptyString` / `EmptyArray` / `EmptyDictionary` / `EmptyData` /
///   `False` / `True` / `Zero` / `ZeroInt64` / `ZeroDouble` / `ZeroFloat` /
///   `ZeroCGFloat` / `ZeroDecimal` / `Epoch`
/// - `@XDefault` / `@XDecodableDefault`
/// - `KeyedDecodingContainer.x_decode(forKey:)` / `x_decodeIfPresent(forKey:)` / `x_decodeStrict(forKey:)`
/// - struct 级 `@XResilientCodable` 见独立包 `XToolCodableMacros`
///
/// ## XColor.swift
/// 十六进制颜色与统一包装器。
/// - `UIColor.init?(hexString:alpha:)` / `UIColor.init(hex:alpha:)`
/// - `Color.init?(hex:alpha:)` / `Color.init(hex:alpha:)`（SwiftUI）
/// - `@XColor`：`wrappedValue` / `projectedValue` / `init(_:alpha:)`（String / Int）
///
/// ## XConcurrency.swift
/// 主线程通知与 Task 防抖。
/// - `NotificationCenter.x_postOnMainThread(name:object:userInfo:)`
/// - `Task.x_debounce(seconds:operation:)`
///
/// ## XDate.swift
/// 日期格式化、相对时间、北京时间、时长与时间戳、日历语义。
/// - `Date.x_toString(format:)` / `Date.x_from(_:format:)` / `x_toRelativeString`
/// - `x_isToday` / `x_isYesterday` / `x_startOfDay` / `x_days(from:)`
/// - `Date.x_dateString(fromTimestamp:format:)`
/// - `Date.x_currentBeijingTimeString()` / `x_beijingTimeString(from:offsetMinutes:)`
/// - `Date.x_seconds(from:to:)` / `x_microsecondTimestampString()` / `x_formatVideoDuration(_:)`
///
/// ## XDevice.swift
/// 屏幕 / 安全区 / 栏高度、硬件信息、触觉、模拟器与越狱检测。
/// - `UIDevice.x_keyWindow`
/// - `UIDevice.x_invalidateLayoutMetrics()` / `x_invalidateChromeMetrics()`
/// - `x_screenWidth` / `x_screenHeight` / `x_statusBarHeight` / `x_safeAreaBottom`
/// - `x_isFullScreenDevice` / `x_navigationBarContentHeight` / `x_navBarTotalHeight` / `x_tabBarHeight`
/// - `x_defaultContentFrame` / `x_hasDynamicIsland` / `x_resolvedSafeAreaInsets`
/// - `x_deviceModel` / `x_systemVersion` / `x_deviceName` / `x_uuid`
/// - `XHapticFeedback` + `UIDevice.x_triggerHaptic(_:)`
/// - `x_isSimulator` / `x_isJailbroken`
///
/// ## XFont.swift
/// 设计稿宽度缩放 + Dynamic Type 系统字体。
/// - `UIFont.x_scaledSystemFont(ofSize:weight:)` — 推荐显式使用
/// - `UIFont.x_enableDynamicFontRules()` — 可选全局工厂 swizzle（影响面大）
///
/// ## XGraphics.swift
/// 渐变层与缩放动画工厂。
/// - `XGradientDirection`：`.topToBottom` / `.bottomToTop` / `.leftToRight` /
///   `.rightToLeft` / `.topLeftToBottomRight`
/// - `CAGradientLayer.x_gradient(colors:direction:)`
/// - `XAnimation.x_scaleAnimation(...)` / `CABasicAnimation.x_scaleAnimation(...)`
///
/// ## XImage.swift
/// 图片缩放压缩与 ImageView 渲染体检（DEBUG）。
/// - `UIImage.x_resize(toWidth:)` / `x_compressTo(maxBytes:)`
/// - `UIImageView.x_debugPerformanceCheck()`
///
/// ## XJSON.swift
/// JSON ↔ Dictionary / Model 互转。
/// - `Data.x_toDictionary`
/// - `String.x_toDictionary` / `x_toModel(_:)`
/// - `Encodable.x_toJSONString` / `x_toDictionary`
///
/// ## XKeychain.swift
/// Keychain 字符串读写。
/// - `XKeychain.save(_:forKey:)` / `load(forKey:)` / `remove(forKey:)`
///
/// ## XLayout.swift
/// 以设计稿基准宽度做等比适配（默认 `baseWidth = 393`）。
/// - `XLayout.baseWidth` / `currentWidth` / `scaled(_:)`
/// - `CGFloat.x_scaled` / `x_roundTo(places:)`
/// - `Double.x_scaled` / `Int.x_scaled`
///
/// ## XLayoutMetricsCache.swift（internal）
/// 屏幕 / 安全区 / Nav / Tab / 缩放系数缓存，供 `UIDevice` / `XLayout` 热路径复用。
/// - 对外通过 `UIDevice.x_*` 与 `XLayout.scaled` 间接使用
/// - `UIDevice.x_invalidateLayoutMetrics()` / `x_invalidateChromeMetrics()` 触发失效
///
/// ## XString.swift
/// 字符串空白处理、校验、哈希、测高、本地化、剪贴板。
/// - `x_trimmed` / `x_isBlank` / `x_nilIfBlank`（含 `String?`）
/// - `x_isValidEmail` / `x_isValidChinesePhoneNumber` / `x_isDigitsOnly`
/// - `x_md5` / `x_sha256` / `x_base64Encoded` / `x_base64Decoded`
/// - `x_height(withWidth:font:)`
/// - `x_localized` / `x_localized(with:)`
/// - `x_copyToClipboard(haptic:)`
///
/// ## XUserDefaults.swift
/// UserDefaults 的 `Codable` 读写封装。
/// - `UserDefaults.x_setCodable(_:forKey:)` / `x_codable(_:forKey:)` /
///   `x_remove(forKey:)` / `x_contains(key:)`
///
/// ## XURLRequest.swift
/// 请求幂等令牌与 Body 校验和。
/// - `URLRequest.x_addIdempotencyToken()` — 写入头 `X-Idempotency-Key`
/// - `URLRequest.x_bodyChecksum` — Body MD5
///
/// ## XView.swift
/// UIView 圆角 / 边框 / 渐变、交互限制、点击手势、Frame 快捷属性。
/// - `x_roundCorners(_:radius:)` / `x_applyCornerRadius(_:)` /
///   `x_applyBorderStyle(radius:borderWidth:borderColor:)` /
///   `x_applyCapsuleStyle()` / `x_applyGradient(colors:direction:)`
/// - `UIView.x_restrictInteraction(for:seconds:)`
/// - `x_addTapGesture(action:)`
/// - `x_frameX` / `x_frameY` / `x_width` / `x_height` / `x_size`
///
/// ## XViewController.swift
/// 导航栏主题与常用导航操作。
/// - `XNavigationBarConfigurable`
/// - `x_setupNavigationBarTheme()` / `x_setNavBackButton(imageName:action:)`
/// - `x_setNavRightIcon(_:action:)` / `x_setNavRightTitle(_:action:)` /
///   `x_setNavLeftTitle(_:)`
/// - `x_presentFullScreen(_:style:animated:completion:)`
///
/// ## XToolCodableMacros（独立 Swift Package）
/// struct 级容错 Codable 宏，依赖 `XTool` 运行时解码能力。
/// - 对外入口：`@XResilientCodable`（`import XToolCodableMacros`）
