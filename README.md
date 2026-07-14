# 吾俩 · 双人专属情侣 App（Flutter）

只给你和女朋友两个人用：实时看到对方精确位置 + 两人共享回忆空间。无会员、无付费、无广告，所有数据仅你们俩可读。

技术栈：**Flutter（iOS + Android）+ Supabase（免费）**，地图用 OpenStreetMap（无需任何 API Key）。

---

## 一、准备环境
1. 安装 [Flutter SDK](https://flutter.dev)（3.22+）并 `flutter doctor` 通过。
2. 注册一个 [Supabase](https://supabase.com) 免费项目。

## 二、后端（一次性）
1. 打开 Supabase 控制台 **SQL Editor**，把 `supabase/schema.sql` 整段执行（建表 + 隐私行级安全 + 自动建档案）。
2. 在 **Storage** 里新建一个 bucket，名字填 `memories`，设为 **Public**（照片链接可访问）。
3. 打开 **Project Settings → API**，复制 `Project URL` 和 `anon public key`。
4. （推荐）配置「被杀也能收推送」：按 [NATIVE_SETUP.md](./NATIVE_SETUP.md) 第三节接 Firebase + 部署 `notify-checkin` Edge Function + 建数据库 webhook。这是「伴侣 App 被杀也能收到自动报备」的必需步骤。

## 三、填入密钥
编辑 `lib/core/supabase.dart`，把两个 `YOUR_...` 替换成上面的真实值。

## 四、生成平台目录并加权限
本仓库只有 `lib/` 源码，需要先生成 iOS/Android 目录：
```bash
cd wuliao_app
flutter create --org com.example.wuliao .
```

### Android：编辑 `android/app/src/main/AndroidManifest.xml`，在 `<manifest>` 内加：
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
（后台持续定位 + 自动报备已实装，完整的原生配置、iOS/Android 后台权限与「伴侣被杀后收不到推送」的说明见 [NATIVE_SETUP.md](./NATIVE_SETUP.md)。）

### iOS：编辑 `ios/Runner/Info.plist`，加：
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>想实时看到彼此的位置，给你满满安全感</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>即使后台也想默默守护你，知道你安全到家</string>
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
<key>NSCameraUsageDescription</key>
<string>想和 Ta 拍一张合照，留下我们的瞬间</string>
```

## 五、运行
```bash
flutter pub get
flutter run          # 连上手机或模拟器；iOS 需 macOS + Xcode
```
两人各装一份，用各自邮箱魔法链接登录，一人「创建情侣空间」拿到 6 位绑定码，另一人「加入」输入该码，即可开始。

---

## 已实现的核心功能
- **实时位置**：地图双人标记（你=蓝点，她=粉心）+ 实时距离；位置走 Supabase，每 5 秒刷新对方。
- **后台持续定位**：App 退到后台 / 锁屏仍每 ~60s 上报位置（需按 [NATIVE_SETUP.md](./NATIVE_SETUP.md) 配好原生权限）；前台实时已够用则可不开。
- **自动报备（被杀也能收）**：设置「家/公司」等围栏，进出时双方手机弹通知。由 **FCM + Supabase Edge Function（数据库 webhook）** 下发，伴侣 App 被杀/挂后台都能收到。
- **爱情足迹地图**：两人历史位置轨迹折线 + 回忆点 + 地点标记，按时段（7/30/90 天/全部）查看。
- **共享回忆**：文字/照片时间线，双端实时同步；弱网自动读本地缓存。
- **「我们」中心页**：在一起天数、下一个纪念日倒计时、今天早晚安/心情/每日一问总览，统一入口。
- **纪念日倒计时**：在一起天数 + 纪念日列表与下一个倒计时；可设「在一起的日子」。
- **每日一问**：按日期出题（本地题库，确定性），两人都答完才互相可见。
- **100 件小事**：两人共享打卡清单（100 条），完成进度实时同步。
- **远程早晚安 + 心情日记**：早晚安互道（双方都发才亮「互道 💞」）、当天双方心情与心情日记。
- **共同歌单 / 一起看片**：共享歌单与想看清单，看片可勾选「已看」。
- **默契测试小游戏**：每天一题，两人悄悄选 A/B，揭示是否一致。
- **AR 合照**：调用相机拍照，自动存入「回忆」（完整 AR 实时贴纸为进阶增强，见下）。
- **隐私优先**：行级安全保证只有你们俩可读；解绑即删；不收集 App 使用记录等越界数据。

## 本地编译与真机运行（一键）
> 本工程在编写环境为「纯源码 + 免费后端」脚手架。以下步骤在你的电脑上即可编译并刷到真机。

```bash
# 1) 前置：安装 Flutter SDK（3.22+），flutter doctor 通过；连上手机（USB 调试）或用模拟器
# 2) 后端：Supabase SQL Editor 执行 supabase/schema.sql；建 public bucket=memories；填 lib/core/supabase.dart
# 3) 生成平台目录
cd wuliao_app
flutter create --org com.example.wuliao .

# 4) 加权限（AndroidManifest.xml / Info.plist，见上文第四节；后台定位见 NATIVE_SETUP.md）

# 5) 取依赖 + 静态编译检查（这一步会抓出所有语法/类型错误）
flutter pub get
flutter analyze

# 6) 跑起来（连真机刷机）
flutter run            # Android：直接装到已连接手机
# iOS：必须在 macOS + Xcode 下执行，且需开发者账号签名
flutter build ios      # 仅构建；真机安装用 Xcode 打开 ios/Runner.xcworkspace 选设备 Run
```

跑通后两人各装一份：邮箱魔法链接登录 → 一人「创建情侣空间」拿 6 位码 → 另一人「加入」→ 开始。

## 进阶可继续（保持免费）
- **AR 实时贴纸 / 虚拟同框**：接 arcore(Android)/ARKit(iOS) 原生能力，做实时滤镜与同框叠加（当前 AR 合照为「拍照存入回忆」版）。
- **一起看片进度同步**、**情侣小游戏扩展**（你画我猜 / 成语接龙等）。
- 更多好想法见文末「好想法清单」。

> 说明：本工程为可直接运行的 MVP 脚手架。包名、图标、配色可自行替换；照片上传依赖 public bucket，仅两人可见的链接不会出现在别处。
