#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT/.build/Runkun.app"
ZIP_PATH="$ROOT/.build/Runkun.zip"
DMG_PATH="$ROOT/.build/Runkun.dmg"
DMG_STAGING="$ROOT/.build/dmg"
ICONSET_PATH="$ROOT/.build/Runkun.iconset"
RUNNER_CLEAN_PATH="$ROOT/.build/DefaultRunner"
MODULE_CACHE="$ROOT/.build/module-cache"

cd "$ROOT"

if CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swift build -c "$CONFIGURATION"; then
  BIN_PATH="$(CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swift build -c "$CONFIGURATION" --show-bin-path)/Runkun"
else
  echo "SwiftPM failed; falling back to direct swiftc build."
  mkdir -p "$ROOT/.build/direct"
  SOURCES=("$ROOT"/Sources/Runkun/*.swift)
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" xcrun swiftc -O "${SOURCES[@]}" -o "$ROOT/.build/direct/Runkun" -framework AppKit -framework IOKit
  BIN_PATH="$ROOT/.build/direct/Runkun"
fi

rm -rf "$APP_PATH" "$ZIP_PATH" "$DMG_PATH" "$DMG_STAGING" "$ICONSET_PATH" "$RUNNER_CLEAN_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/Runkun"
cp "$ROOT/examples/runner.json" "$APP_PATH/Contents/Resources/runner.example.json"

CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" xcrun swiftc "$ROOT/scripts/clean_runner_assets.swift" -o "$ROOT/.build/clean_runner_assets" -framework AppKit
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" xcrun swiftc "$ROOT/scripts/make_app_icon.swift" -o "$ROOT/.build/make_app_icon" -framework AppKit
"$ROOT/.build/clean_runner_assets" "$ROOT/Assets/DefaultRunner" "$RUNNER_CLEAN_PATH"
cp -R "$RUNNER_CLEAN_PATH" "$APP_PATH/Contents/Resources/DefaultRunner"
cp "$ROOT/Assets/DefaultRunner/preview.png" "$APP_PATH/Contents/Resources/DefaultRunner/preview.png"
"$ROOT/.build/make_app_icon" "$RUNNER_CLEAN_PATH/frame_01.png" "$ICONSET_PATH"
iconutil -c icns "$ICONSET_PATH" -o "$APP_PATH/Contents/Resources/Runkun.icns"

cat > "$APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Runkun</string>
  <key>CFBundleIdentifier</key>
  <string>com.wantwant123.runkun</string>
  <key>CFBundleName</key>
  <string>Runkun</string>
  <key>CFBundleDisplayName</key>
  <string>Runkun</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>Runkun</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_PATH"
fi

mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/Runkun.app"
ln -s /Applications "$DMG_STAGING/Applications"

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
hdiutil create -volname "Runkun" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH"

echo "$ZIP_PATH"
echo "$DMG_PATH"
