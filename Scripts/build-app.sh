#!/bin/bash
#
# Builds OpenTracker and wraps it into a proper `.app` bundle with an Info.plist.
# This gives the app a real bundle identifier, which is what unlocks:
#   - macOS notifications (Pomodoro phase-end banners)
#   - Automation permission prompts for browser (domain) tracking
#   - running as a clean menu-bar agent (no Dock icon)
#
# Usage:  ./Scripts/build-app.sh        (build + launch)
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="OpenTracker"
CONFIG="release"

echo "▶︎  Building ($CONFIG)…"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"
APP_DIR="$BIN_PATH/$APP_NAME.app"

echo "▶︎  Assembling $APP_NAME.app…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# Ad-hoc code signature gives TCC (automation / notifications) a stable identity.
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "✓  Built: $APP_DIR"
echo "▶︎  Launching…"
open "$APP_DIR"

echo ""
echo "Tipp: Beim ersten Browser-Wechsel fragt macOS einmal nach Erlaubnis"
echo "      (\"OpenTracker möchte … steuern\"). Auf \"OK\" klicken, damit die"
echo "      Domain-Erfassung funktioniert."
