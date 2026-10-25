#!/bin/zsh
set -e

APP_NAME="CatTrash"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

echo "🔨 正在编译 ${APP_NAME}..."
SWIFT_FILES=($(find Sources/CatTrash -name "*.swift"))
swiftc -module-cache-path /tmp/swift-module-cache \
  -target arm64-apple-macosx14.0 \
  -O \
  "${SWIFT_FILES[@]}" \
  -o "${MACOS_DIR}/${APP_NAME}"

cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.cattrash.desktoppet</string>
    <key>CFBundleName</key>
    <string>Cat Trash</string>
    <key>CFBundleDisplayName</key>
    <string>Cat Trash</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Cat Trash 需要访问桌面文件以完成投喂删除与零食图标点化。</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Cat Trash 需要配合 Finder 完成文件移入废纸篓或推出桌面磁盘镜像。</string>
</dict>
</plist>
EOF

xattr -cr "${APP_BUNDLE}"
codesign --force --deep --sign - --identifier com.cattrash.desktoppet "${APP_BUNDLE}"

echo "✅ 打包并签名完成：$(pwd)/${APP_BUNDLE}"
