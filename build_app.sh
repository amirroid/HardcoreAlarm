#!/usr/bin/env bash
set -euo pipefail

# Hardcore Alarm .app Bundle Generator
echo "🚀 Building Hardcore Alarm for macOS (Apple Silicon)..."

cd "$(dirname "$0")"

# 1. Ensure AppIcon exists
if [ ! -f "Resources/AppIcon.icns" ]; then
    echo "🎨 Generating AppIcon.icns..."
    swift Scripts/generate_app_icon.swift
fi

# 2. Build Release Executable
echo "🔨 Compiling Release executable via Swift Package Manager..."
swift build -c release --target HardcoreAlarmApp

# Locate binary
BIN_PATH=$(find .build -name "HardcoreAlarm" -type f -perm +111 | grep -i "Release/HardcoreAlarm" | head -n 1)
if [ -z "$BIN_PATH" ] || [ ! -f "$BIN_PATH" ]; then
    echo "❌ Error: Could not locate compiled HardcoreAlarm release binary."
    exit 1
fi
echo "✅ Located release binary at: $BIN_PATH"

# 3. Create .app bundle structure
APP_NAME="HardcoreAlarm.app"
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

# 4. Copy files
cp "$BIN_PATH" "$APP_NAME/Contents/MacOS/HardcoreAlarm"
chmod +x "$APP_NAME/Contents/MacOS/HardcoreAlarm"

cp "Resources/Info.plist" "$APP_NAME/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_NAME/Contents/Resources/AppIcon.icns"

# Create PkgInfo
echo -n "APPL????" > "$APP_NAME/Contents/PkgInfo"

# 5. Codesign the bundle (ad-hoc development signature)
echo "🔏 Signing application bundle..."
codesign --force --deep --sign - "$APP_NAME"

echo "🔍 Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "$APP_NAME"

echo ""
echo "======================================================="
echo "🎉 SUCCESS: HardcoreAlarm.app bundle created!"
echo "📍 Location: $(pwd)/$APP_NAME"
echo "👉 You can run it with: open $APP_NAME"
echo "======================================================="
