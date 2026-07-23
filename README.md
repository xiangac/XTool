# XTool

面向 iOS 的 Swift Package 工具库，封装日常开发高频扩展。

- **平台**：iOS 18+
- **语言**：Swift 6.2
- **集成**：Swift Package Manager
- **约定**：公开 API 统一 `x_` 前缀（类型用 `X` 前缀）

---

## 安装

```swift
dependencies: [
    .package(url: "你的仓库地址", from: "1.0.0")
]
```

```swift
import XTool
```

## 启动建议

```swift
UIButton.x_enableDebounce()
// 可选：全局系统字体工厂缩放（影响面大，更推荐 UIFont.x_scaledSystemFont）
// UIFont.x_enableDynamicFontRules()
```

---

## 模块结构

| 文件 | 职责 |
|------|------|
| `XAppInfo` | App 名称 / 版本 / Bundle ID |
| `XDevice` | 屏幕、安全区、触觉、越狱、灵动岛 |
| `XLayout` | 设计稿基准宽度、等比缩放 |
| `XJSON` | JSON ↔ Model / Dictionary |
| `XCodable` | 解码容错默认值 |
| `XArray` | 数组安全下标 |
| `XDate` | 日期格式化、北京时间、时长 |
| `XString` | 校验、哈希、本地化、剪贴板 |
| `XColor` | Hex 颜色、`@XColor` |
| `XView` | 圆角 / 边框 / 渐变 / 手势 / Frame |
| `XGraphics` | 渐变层工厂、缩放动画 |
| `XImage` | 图片缩放压缩、渲染体检 |
| `XButton` | 按钮防连击 |
| `XFont` | 全局字体动态缩放 |
| `XApplication` | Key Window / 根 VC / 顶层 VC |
| `XViewController` | `XNavigationBarConfigurable` |
| `XConcurrency` | 主线程通知、Task 防抖 |
| `XKeychain` | Keychain 读写 |
| `XURLRequest` | 幂等令牌、Body MD5 |
| `XBundle` | Debug / TestFlight / App Store |

---

## 常用示例

### 字符串 / JSON

```swift
"demo@mail.com".x_isValidEmail
"13800138000".x_isValidChinesePhoneNumber
"123".x_isDigitsOnly
"hello".x_md5
"title_key".x_localized
"内容".x_copyToClipboard()           // 默认带震动
"内容".x_copyToClipboard(haptic: false)

jsonStr.x_toModel(User.self)
jsonStr.x_toDictionary                 // 失败为 nil，可与 {} 区分
model.x_toJSONString
list[x_safe: 3]
```

### 颜色 / 布局

```swift
UIColor(hexString: "#07073C")
Color(hex: 0xFF5733, alpha: 0.8)

label.x_width = 120.x_scaled
CGFloat(3.14159).x_roundTo(places: 2)
```

### 日期时间

```swift
Date().x_toString(format: "yyyy-MM-dd HH:mm:ss")
Date().x_toRelativeString
Date.x_currentBeijingTimeString()
Date.x_dateString(fromTimestamp: 1_700_000_000)
Date.x_formatVideoDuration(95)      // "01:35"
Date.x_microsecondTimestampString()
```

### UI

```swift
view.x_applyCornerRadius(12)
view.x_roundCorners([.topLeft, .topRight], radius: 12)
view.x_applyCapsuleStyle()
view.x_applyGradient(colors: [.red, .blue], direction: .leftToRight)
view.x_addTapGesture { }

let layer = CAGradientLayer.x_gradient(colors: [.red, .blue])
view.x_frameX = 16
```

### 设备 / App

```swift
XAppInfo.fullVersion
UIDevice.x_screenWidth
UIDevice.x_safeAreaBottom
UIDevice.x_systemVersion
UIDevice.x_triggerHaptic(.success)
UIDevice.x_isJailbroken
Bundle.x_currentEnvironment          // debug / testFlight / nonAppStore / appStore

// push/pop 或显隐 Nav/Tab 后刷新栏高度缓存
UIDevice.x_invalidateChromeMetrics()
```

### 窗口 / 导航

```swift
UIApplication.x_keyWindow()
UIApplication.x_rootViewController()
UIApplication.x_topViewController()

class HomeVC: UIViewController, XNavigationBarConfigurable {
    override func viewDidLoad() {
        super.viewDidLoad()
        x_setupNavigationBarTheme()
        x_setNavRightTitle("完成") { }
        x_setNavLeftTitle("首页")
    }
}
```

### JSON 容错

```swift
// 推荐：整个 struct 容错（缺失 / null / 类型不符 → 默认值；Optional → nil）
@XResilientCodable
struct Product: Codable {
    var price: Int
    var name: String
    var tags: [String]
    var note: String?
}

// 或单字段：
struct Product: Codable {
    @XDefault var price: Int
    @XDefault var name: String
    @XDecodableDefault<XDefaults.True> var enabled: Bool
}
```

### 网络 / 防抖 / Keychain

```swift
var request = URLRequest(url: url)
request.x_addIdempotencyToken()

searchTask?.cancel()
searchTask = Task.x_debounce(seconds: 0.3) {
    await search(keyword)
}

XKeychain.save("token", forKey: "auth")
```

---

## 测试

```bash
xcodebuild -scheme XTool -destination 'generic/platform=iOS' build
```
