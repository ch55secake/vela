#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Vela.app"
CONTENTS="$APP/Contents"
ICONSET="$ROOT/build/Vela.iconset"
ICON_SOURCE="$ROOT/build/Vela-icon.png"

swift build --package-path "$ROOT" --configuration release --product Vela

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$ICONSET"
cp "$ROOT/.build/release/Vela" "$CONTENTS/MacOS/Vela"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

swift "$ROOT/scripts/generate-icon.swift" "$ICON_SOURCE"

for size in 16 32 64 128 256 512 1024; do
  case "$size" in
    16) name="icon_16x16.png" ;;
    32) name="icon_16x16@2x.png" ;;
    64) name="icon_32x32@2x.png" ;;
    128) name="icon_128x128.png" ;;
    256) name="icon_128x128@2x.png" ;;
    512) name="icon_256x256@2x.png" ;;
    1024) name="icon_512x512@2x.png" ;;
  esac
  sips -s format png -z "$size" "$size" "$ICON_SOURCE" \
    --out "$ICONSET/$name" >/dev/null
done

cp "$ICONSET/icon_16x16@2x.png" "$ICONSET/icon_32x32.png"
cp "$ICONSET/icon_128x128@2x.png" "$ICONSET/icon_256x256.png"
cp "$ICONSET/icon_256x256@2x.png" "$ICONSET/icon_512x512.png"
/usr/bin/iconutil --convert icns "$ICONSET" --output "$CONTENTS/Resources/AppIcon.icns"

/usr/bin/codesign --force --deep --sign - "$APP"

echo "Built $APP"
