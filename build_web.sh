#!/usr/bin/env bash
# 本地一键构建 Flutter Web（PWA）产物到 build/web。
# 前提是本机已装好 Flutter 且 `flutter doctor` 通过。
set -e

flutter pub get
# 首次构建 web 需要先生成 web 目录（已存在会自动跳过）
flutter create --platforms=web . || true
flutter build web --release

echo ""
echo "✅ 构建完成：build/web"
echo "把它部署到任意静态托管（Netlify 拖拽 / GitHub Pages / Firebase Hosting / Cloudflare Pages）即可。"
echo "在 iPhone 的 Safari 打开该地址 → 分享按钮 → 『添加到主屏幕』，桌面就会出现『吾俩』图标。"
