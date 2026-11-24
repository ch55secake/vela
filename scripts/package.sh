#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Vela.app"
ARCH="${ARCH:-$(uname -m)}"

case "$ARCH" in
  arm64|aarch64)
    ARCH="arm64"
    ;;
  x86_64|amd64)
    ARCH="x86_64"
    ;;
  *)
    echo "Unsupported release architecture: $ARCH" >&2
    exit 1
    ;;
esac

if [[ ! -d "$APP" ]]; then
  echo "App bundle not found at $APP; run scripts/build.sh first." >&2
  exit 1
fi

ARCHIVE="Vela-${ARCH}.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/build/$ARCHIVE"
(
  cd "$ROOT/build"
  shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"
)

echo "Packaged $ROOT/build/$ARCHIVE"
