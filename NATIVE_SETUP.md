# 原生平台配置（后台定位 + 自动报备必须）

后台持续定位和地理围栏需要原生权限与配置，**Flutter 层代码已写好，但下面这些原生改动是 iOS / Android 平台强制要求的**，否则后台定位不会生效。

> 前提：先执行 `flutter create --org com.example.wuliao .` 生成 `android/` 和 `ios/` 目录，再按本文件修改。
> 包名改成你自己的（如 `com.you.wuliao`）。文中的 `com.example.wuliao` 需全局替换成你的包名。

---

## 一、Android

### 1. `android/app/src/main/AndroidManifest.xml`

在 `<manifest>` 顶层（`<application>` 之外）添加权限：

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" /> <!-- Android 14+ -->
```

在 `<application>` 内添加前台服务声明（后台定位必须）：

```xml
<service
    android:name="diozzdev.background_locator_2.BackgroundLocatorService"
    android:foregroundServiceType="location"
    android:exported="false" />
```

### 2. 通知小图标（必做）

`flutter_local_notifications` 在 `notification_service.dart` 里引用了 `ic_notification` 这个 drawable，Android 上**必须存在该资源**，否则初始化会崩溃。请放一张 24×24、纯白单色（透明底）的 `ic_notification.png` 到：

```
android/app/src/main/res/drawable/ic_notification.png
```

> 直接从 `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` 复制改名即可；Android 12+ 建议用纯白单色图标，否则小图标会显示为灰色方块。`background_locator_2` 的后台通知则用 App 启动图标（代码里 `notificationIconColor` 已染成品牌粉 `#E96A8B`）。

### 3. 注册插件 `android/app/src/main/kotlin/com/example/wuliao/MainActivity.kt`

```kotlin
package com.example.wuliao

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import diozzdev.background_locator_2.BackgroundLocatorPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BackgroundLocatorPlugin.registerWith(flutterEngine)
    }
}
```

> 提示：Android 10+ 首次会弹「始终允许」后台定位的授权；请在设置里确认「始终允许」，否则后台定位会被系统限制。

---

## 二、iOS

### 1. `ios/Runner/Info.plist` 添加定位权限与后台模式

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>吾俩需要在后台获取你的位置，才能实时看到彼此 💞</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>吾俩需要在后台获取你的位置，才能实时看到彼此 💞</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

> 用户首次会看到「使用 App 期间」和「始终」两个选项，**必须选「始终」**，后台定位才会持续。选错可在 系统设置 → 吾俩 → 位置 里改回。

### 2. `ios/Runner/AppDelegate.swift` 注册插件

```swift
import UIKit
import Flutter
import background_locator_2

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    BackgroundLocatorPlugin.register(with: self.registrar(forPlugin: "BackgroundLocatorPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

> iOS 真机调试需 macOS + Xcode；后台定位无法在模拟器完整验证，请务必用真机测试。

---

## 三、被杀也能收推送：FCM + Supabase Edge Function（必做项）

现在「自动报备」走 **系统级推送通道**：你进出围栏 → 写 `checkins` → Supabase 数据库 webhook 触发 Edge Function → 经 **FCM** 把通知下发到伴侣设备。**伴侣 App 被杀、挂后台、甚至没打开过，都能收到**（Android 走 FCM，iOS 由 FCM 桥接 APNs）。

> Firebase 有永久免费的 Spark 计划，个人两人用完全够、不花钱、不需要任何付费 Key。

### 1. 建 Firebase 项目（一次）
1. 打开 [Firebase 控制台](https://console.firebase.google.com) → 新建项目（免费）。
2. 进入项目 → **Build → Cloud Messaging**，记下 `Sender ID` / `Project ID`（后面用）。
3. 项目设置 → **服务账号** → 生成并下载 **JSON 私钥**（后面作为 `FCM_SERVICE_ACCOUNT` 给 Edge Function 用）。
4. iOS 额外：项目设置 → **Cloud Messaging → APNs 身份验证密钥**，上传苹果开发者账号的 `.p8` 推送密钥（iOS 才能收到）。

### 2. Android 接入 Firebase
1. 项目概览 → 添加 **Android 应用**，包名填你的（如 `com.you.wuliao`），下载 `google-services.json` 放到 `android/app/`。
2. 项目根 `android/build.gradle` 的 `dependencies` 加：
   ```gradle
   classpath 'com.google.gms:google-services:4.4.2'
   ```
3. `android/app/build.gradle` 顶部 `plugins` 加：
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
（FCM 推送权限由 Firebase 自动处理，无需额外 manifest 改动。）

### 3. iOS 接入 Firebase
1. 添加 **iOS 应用**，包名（Bundle ID）填你的，下载 `GoogleService-Info.plist` 放到 `ios/Runner/`（Xcode 里拖进 Runner 目标，勾选 Copy if needed）。
2. 用 Xcode 打开 `ios/Runner.xcworkspace`，**Signing & Capabilities → + Capability → Push Notifications** 和 **Background Modes → Remote notifications** 都勾上。
3. `ios/Runner/Info.plist` 不需要额外改（FlutterFire 会自动读取 plist）。

### 4. 部署 Edge Function
工程已提供 `supabase/functions/notify-checkin/index.ts`。用 Supabase CLI 部署：
```bash
# 安装 CLI：npm i -g supabase
supabase login
supabase link --project-ref <你的项目ref>
supabase functions deploy notify-checkin --no-verify-jwt
# 设置密钥（从 Firebase 第 1 步拿到）
supabase secrets set FCM_PROJECT_ID=<你的 Firebase Project ID>
supabase secrets set FCM_SERVICE_ACCOUNT="$(cat 你的服务账号.json)"
supabase secrets set SUPABASE_URL=<你的 Project URL>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<你的 service_role key>
```
> 也可用 Supabase 控制台 → Edge Functions → 新建 `notify-checkin` → 粘贴 `index.ts` → 在 Function 设置里填上面 4 个 Secrets。

### 5. 建数据库 webhook（关键）
在 Supabase 控制台 **Database → Webhooks → Create a new webhook**：
- 触发：表 `checkins`，事件 `Insert`，Schema `public`
- 目标：调用 Supabase Function → 选 `notify-checkin`
- 保存。

这样每次写入 `checkins`，服务端自动调 Edge Function 下发推送，**不依赖 App 是否存活**。

### 6. token 上报
`lib/features/location/push_service.dart` 已在登录后把设备 FCM token 写入 `profiles.fcm_token`（已加 `fcm_token` 字段）。双方都装好并登录后，互相的报备即可经系统通道送达。

---

## 四、真机验收清单

- [ ] Android / iOS 真机安装，登录并绑定彼此，双方都授权了通知权限
- [ ] Firebase 已接入、Edge Function 已部署、webhook 已建、双方 `profiles.fcm_token` 非空
- [ ] 设置里打开「后台持续定位」「自动报备」，各设一个「家」围栏
- [ ] **把伴侣 App 彻底划掉（杀进程）**，你到家 → 伴侣手机仍弹出「Ta 到家了 🏠」，自己手机弹「你到家了」
- [ ] 锁屏 / 切到别的 App 后，对方地图页仍每 ~60s 刷新你的位置
- [ ] 电量：iOS 用 Settings → 开发者 → Logging → Energy，Android 用 `adb shell dumpsys batterystats` 验证后台存活与耗电
- [ ] 爱情足迹页能画出两人轨迹折线，且回忆点 / 地点标记正确叠加
