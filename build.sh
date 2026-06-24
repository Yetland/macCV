#!/bin/bash
set -euo pipefail

APP_NAME="MacCV"
CONFIG="${1:-debug}"

if [ "$CONFIG" = "release" ]; then
    echo "==> Building $APP_NAME (release)..."
    swift build -c release
    BINARY=".build/release/$APP_NAME"
else
    echo "==> Building $APP_NAME (debug)..."
    swift build
    BINARY=".build/debug/$APP_NAME"
fi

APP_BUNDLE="build/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP_BUNDLE" 2>/dev/null

echo "==> Done: $APP_BUNDLE"
echo "    open $APP_BUNDLE"
