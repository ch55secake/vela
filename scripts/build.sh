#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Vela.app"
CONTENTS="$APP/Contents"

swift build --package-path "$ROOT" --configuration release --product Vela

mkdir -p "$CONTENTS/MacOS"
cp "$ROOT/.build/release/Vela" "$CONTENTS/MacOS/Vela"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

/usr/bin/codesign --force --deep --sign - "$APP"

echo "Built $APP"
