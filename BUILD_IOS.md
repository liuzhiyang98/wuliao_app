# 吾俩 App · 生成 iOS 可安装包（.ipa）指南

> 本工程在 Windows 沙箱里无法编译（无 Flutter / Xcode / 外网），以下是在**你自己的机器**上拿到真机可装包的两种方式。
> 任选其一。两种方式都假设你已完成：Supabase 建库（`supabase/schema.sql`）+ 建 public bucket `memories` + 填好 `lib/core/supabase.dart` 的 key。

---

## 路径 A：用自己的 Mac + iPhone 直接装（推荐，免费）

> 需要：一台 Mac（macOS）、Xcode（App Store 免费装）、一根数据线、一部 iPhone、一个**免费** Apple ID。
> 限制：个人签名（Personal Team）装的 App **每 7 天需重新连 Mac 跑一次**。介意就走路径 B。

### 步骤
1. **装 Flutter（macOS）**
   ```bash
   # 用官方安装包或 asdf/fvm，确保 flutter doctor 全绿（尤其 Xcode 与 CocoaPods）
   flutter doctor
   ```
2. **准备工程**
   ```bash
   cd wuliao_app
   flutter create --org com.example.wuliao .   # 生成 ios/ 等原生目录（只跑一次）
   flutter pub get
   ```
3. **补原生配置**（详见 `NATIVE_SETUP.md`）
   - `ios/Runner/Info.plist` 加：定位 `NSLocationWhenInUseUsageDescription` / `NSLocationAlwaysAndWhenInUseUsageDescription`、相机 `NSCameraUsageDescription`、后台 `UIBackgroundModes: location`、推送能力。
   - 想要「被杀也能收报备」：接 Firebase（放 `GoogleService-Info.plist` + 开 Push 能力 + 上传 APNs `.p8`，部署 `notify-checkin` Edge Function）。不接也能用，只是伴侣杀进程后收不到推送。
4. **打开 iOS 工程并连手机**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - 用数据线把 iPhone 连上 Mac，Xcode 顶部设备选你的 iPhone。
   - 左侧选中 `Runner` → Signing & Capabilities → Team 选 **你的 Apple ID（Personal Team）**；Bundle Identifier 改成你独有的（如 `com.yourname.wuliao`，避免和别人撞）。
   - 如果提示「无法启动」或位置权限相关，按 Xcode 提示 `Trust` 设备并在 iPhone 上「设置 → 通用 → VPN与设备管理」信任开发者。
5. **运行 / 安装**
   - 直接点 Xcode 的 ▶ Run（⌘R）即可装到手机并启动。
   - 或产出 IPA 后续用 Apple Configurator / 隔空投送安装：
     ```bash
     flutter build ipa --no-codesign   # 仅验证编译；真机安装用 Xcode Run 最稳
     ```
6. **验收**：打开 App → 登录/绑定 → 地图能看到双方 → 设「家」围栏回家弹报备 → 足迹/回忆/我们 Tab 都正常。

---

## 路径 B：Codemagic 云端打正式 IPA（走 TestFlight，需付费账号）

> 需要：付费 Apple Developer 账号（$99/年）、App Store Connect 钥匙、Distribution 证书 + 描述文件。
> 好处：出正式 `.ipa`，经 TestFlight 安装，**长期有效、可发给对方手机**。本仓库已配 `codemagic.yaml`，连接仓库即可自动构建。

### 步骤
1. 注册 [Codemagic](https://codemagic.io)（用 GitHub 登录），导入本仓库。
2. 在 Codemagic 项目 **Environment variables** 里填：
   - `SUPABASE_URL`、`SUPABASE_ANON_KEY`（构建时自动注入 `lib/core/supabase.dart`）
   - `APP_STORE_CONNECT_ISSUER_ID`、`APP_STORE_CONNECT_KEY_IDENTIFIER`、`APP_STORE_CONNECT_PRIVATE_KEY`
   - `CERTIFICATE_PRIVATE_KEY`、`APP_STORE_CONN_DIST_CERT`（p12）、`APP_STORE_CONN_PROFILE`（mobileprovision）
   - 这些变量建议设为 **Encrypted**（Codemagic 会加密存储）。
3. 在 Apple Developer / App Store Connect 准备好：
   - App 记录（Bundle ID 与 `codemagic.yaml` 里的 `BUNDLE_ID` 一致）
   - 一个 **App Store Connect API Key**（取 issuer/key id/p8）
   - 一个 **Distribution 证书** 和对应的 **Provisioning Profile**（App Store 类型，若走 ad-hoc 则需登记对方设备 UDID）
4. 触发构建：Start new build → 选 `ios-release` workflow。
5. 构建完在 Artifacts 下载 `.ipa`：
   - **App Store 方式**：Codemagic 可直接传 TestFlight（在 `codemagic.yaml` 的 `publishing.app_store_connect` 配置好），你去 App Store Connect 选版本发 TestFlight，对方邮箱接受即可装。
   - **Ad-hoc 方式**：把 `.ipa` + 设备 UDID 用 Apple Configurator 或第三方工具侧载。

---

## 常见问题
- **`flutter build ipa` 报签名错**：99% 是 Bundle ID / 描述文件 / 证书三者不匹配，或没开对应 Capability。路径 A 用 Personal Team 最省心。
- **iOS 收不到报备推送**：必须在 Apple 开发者后台上传 **APNs Auth Key (.p8)** 并在 Firebase 控制台配置，且 App 已开启 Push Notification 能力。
- **后台定位不更新**：iOS 必须选「始终允许」，且 `UIBackgroundModes` 含 `location`；否则系统会杀后台定位。
- **本工程未经真机编译验证**：请 `flutter analyze` 跑一遍，有任何报错贴给我，我立刻修。
