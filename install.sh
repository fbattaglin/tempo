#!/bin/bash
# One-shot: builds the latest Tempo from source and installs it straight into
# /Applications, replacing whatever was there. No DMG, no manual dragging.
#
# Usage: ./install.sh
#
# After it finishes, open the Apple menu > About Tempo to confirm the build
# stamp shown matches the "Build" line this script prints — that's the
# reliable way to know you're running what was just built, not a stale copy.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BUILD_STAMP="$(date +%Y%m%d.%H%M%S)"
BUILD_DIR="$ROOT_DIR/.install-build"
APP_NAME="Tempo"

echo "==> Stopping any running instance"
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
sleep 0.5

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building (Release, universal, build $BUILD_STAMP)"
rm -rf "$BUILD_DIR"
BUILD_LOG="$(mktemp)"
if ! xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$BUILD_DIR" \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS="arm64 x86_64" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES \
  CURRENT_PROJECT_VERSION="$BUILD_STAMP" \
  build > "$BUILD_LOG" 2>&1; then
  echo "error: build failed, showing last 40 lines:" >&2
  tail -40 "$BUILD_LOG" >&2
  rm -f "$BUILD_LOG"
  rm -rf "$BUILD_DIR"
  exit 1
fi
rm -f "$BUILD_LOG"

APP_SRC="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
if [ ! -d "$APP_SRC" ]; then
  echo "error: build did not produce $APP_SRC" >&2
  exit 1
fi

echo "==> Installing to /Applications"
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_SRC" /Applications/
codesign --force --deep --sign - "/Applications/$APP_NAME.app"

rm -rf "$BUILD_DIR"

INSTALLED_VERSION=$(defaults read "/Applications/$APP_NAME.app/Contents/Info.plist" CFBundleShortVersionString)
INSTALLED_BUILD=$(defaults read "/Applications/$APP_NAME.app/Contents/Info.plist" CFBundleVersion)

echo ""
echo "Instalado: /Applications/$APP_NAME.app"
echo "Version: $INSTALLED_VERSION   Build: $INSTALLED_BUILD"
echo ""
echo "Para confirmar que está rodando essa build: abra o Tempo, menu"
echo "Apple > About Tempo (ou clique no menu \"Tempo\" na barra > About Tempo)"
echo "e confira se o número de Build bate com o de cima."
echo ""
echo "==> Abrindo o Tempo"
open "/Applications/$APP_NAME.app"
