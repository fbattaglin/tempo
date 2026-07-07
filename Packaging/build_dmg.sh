#!/bin/bash
# Builds Tempo as a universal (arm64 + x86_64) Release .app, ad-hoc signs it,
# and packages it into a drag-to-Applications .dmg.
#
# Usage: Packaging/build_dmg.sh
#
# Requires: xcodegen, xcodebuild (Xcode command line tools). No paid Apple
# Developer account needed — the app is ad-hoc signed, so on first launch
# Gatekeeper will show an "unidentified developer" warning; right-click the
# app > Open once to bypass it (documented in the README).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/Packaging/build"
APP_NAME="Tempo"
SCHEME="Tempo"

cd "$ROOT_DIR"

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Cleaning previous package build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Building universal Release .app"
xcodebuild \
  -project "$SCHEME.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS="arm64 x86_64" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES \
  build

APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "error: build did not produce $APP_PATH" >&2
  exit 1
fi

echo "==> Verifying universal binary"
lipo -info "$APP_PATH/Contents/MacOS/$APP_NAME"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP_PATH"

echo "==> Assembling DMG staging folder"
STAGING_DIR="$BUILD_DIR/dmg_staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString)
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
rm -f "$DMG_PATH"

echo "==> Creating DMG"
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

echo
echo "Done: $DMG_PATH"
