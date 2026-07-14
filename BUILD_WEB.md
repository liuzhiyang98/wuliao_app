# 把「吾俩」装进 iPhone（无需 Mac / 无需 $99 / 无需 App Store）

iOS 真机打包在物理上必须 macOS + Xcode + Apple 签名。如果你现在没有 Mac，
**最现实的落地方式是把 Flutter 编译成 Web（PWA）**，部署到免费静态托管，
然后在 iPhone 的 Safari 里「添加到主屏幕」——桌面上就会出现一个像原生 App 的图标，点开全屏运行。

> 这套方案**不需要 Mac、不需要付费开发者账号、不需要 App Store 审核**，
> 只要你有一台能联网的电脑（Mac/Windows/Linux 都行）跑一次构建即可。

---

## 一、它能做什么 / 不能做什么

**Web 端完全可用的功能**
- 📍 实时双人位置（打开 App 时前台定位，地图双人标记 + 距离）
- 💞 共享回忆（文字/照片时间线，双端实时同步）
- 🗺️ 爱情足迹地图（前台轨迹 + 回忆点 + 地点）
- 💍 在一起天数 + 纪念日倒计时
- 💬 每日一问、🎯 100 件小事、🌅 远程早晚安 + 心情、🎵 共同歌单、🎬 一起看片、🧩 默契测试
- 📸 AR 合照（调用浏览器相机拍照存入回忆）

**Web 端做不到的（浏览器安全限制，非代码问题）**
- ❌ 后台持续定位（App 关掉后不再更新位置）
- ❌ 自动报备推送（进出家/公司围栏时系统级弹通知）—— Web 端没有后台地理围栏
- ❌ App 被杀后仍收到推送

> 如果你**必须**要后台定位和自动报备推送，那只能走原生 iOS（见 `BUILD_IOS.md`，需要 Mac + 开发者账号）。
> 对「两人随时打开看彼此」的日常使用，Web 版已覆盖绝大部分核心价值。

---

## 二、三步部署（任选一种托管）

### 方式 A：Netlify 拖拽（最快，30 秒）
1. 本机装好 Flutter，运行：
   ```bash
   bash build_web.sh          # 生成 build/web
   # 或：flutter pub get && flutter create --platforms=web . && flutter build web --release
   ```
2. 打开 https://app.netlify.com/drop ，把 `build/web` 文件夹拖进去。
3. 立刻得到一个 `https://xxxx.netlify.app` 地址。
4. iPhone 打开该地址 → 分享 → **添加到主屏幕**。

### 方式 B：GitHub Pages（自动化，推代码即上线）
1. 在 GitHub 新建一个**公开**仓库（例如 `wuliao-app`），**不要**勾选 README / .gitignore（本工程已自带）。
2. 在本机（已装 git 且登录 GitHub）执行推送：
   ```bash
   git remote add origin https://github.com/<你的用户名>/wuliao-app.git
   git branch -M main
   git push -u origin main
   ```
   > 若提示登录，按弹窗用浏览器授权即可；或先 `gh auth login`。
3. 仓库 **Settings → Pages → Source** 选 **GitHub Actions** 并保存。
4. 到 **Actions** 标签页看构建，绿色对勾 = 发布成功。
5. iPhone 打开 `https://<你的用户名>.github.io/wuliao-app/` → 分享 → **添加到主屏幕**。

> 工作流已自动按仓库名注入 `--base-href="/wuliao-app/"`，所以页面地址必须与仓库名一致；
> 若你取名不同，把上面命令里的 `wuliao-app` 全部换成你的仓库名即可。

### 方式 C：Firebase Hosting / Cloudflare Pages
- 同样先 `flutter build web --release`，再按对应平台上传 `build/web` 目录即可（SPA 回退已在 `netlify.toml` 思路一致，平台侧开启「全部回退到 index.html」）。

---

## 三、iOS 上「添加到主屏幕」操作步骤
1. 用 **Safari**（必须是 Safari，Chrome 不行）打开你的部署地址。
2. 点底部**分享**按钮（方框带向上箭头）。
3. 下滑找到 **「添加到主屏幕」**。
4. 命名「吾俩」，点右上角**添加**。
5. 回到桌面，点新图标即可全屏打开——和原生 App 体验一致。

> 提示：iOS 的「添加到主屏幕」本质是书签 + 全屏网页，首次打开需要联网；
> 之后浏览器会缓存资源，弱网也能进（PWA 离线能力）。

---

## 四、上线前必做（和原生版一致）
1. 在 `lib/core/supabase.dart` 填入你的 Supabase `URL` 和 `anon key`。
2. Supabase 控制台执行 `supabase/schema.sql`（建表 + 行级安全）。
3. Storage 建一个名为 `memories` 的 **Public** bucket。
4. 两人各用邮箱魔法链接登录 → 一方「创建情侣空间」拿 6 位码 → 另一方「加入」。

---

## 五、想升级成真正的原生 iOS App？
Web 版满足日常使用；若要**后台定位 + 自动报备推送 + 上架 App Store**，
按 `BUILD_IOS.md` 走：自己 Mac+Xcode（免费账号，7 天重签）或 Codemagic 云端打 IPA（付费账号，走 TestFlight）。

> 本工程已通过条件导出同时支持原生与 Web：`sqflite` / `background_locator_2` / `flutter_local_notifications`
> 在 Web 下自动走占位实现，原生逻辑一行未改。一个代码库，双端可发。
