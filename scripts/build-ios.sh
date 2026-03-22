#!/bin/bash
set -e

GODOT_PROJECT="/Users/antonkhrobust/User/aethergate"
XCODE_PROJECT="/Users/antonkhrobust/User/exports/ios/AethergateIOS.xcodeproj"
PCK_PATH="/Users/antonkhrobust/User/exports/ios/AethergateIOS.pck"
BUILD_DIR="/Users/antonkhrobust/User/exports/ios/build"
BUNDLE_ID="com.t0nn1x.aethergate"
SCHEME="AethergateIOS"

# ── 1. Export Godot .pck ─────────────────────────────────────────────────────
echo "▶ Exporting Godot .pck..."
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --headless --path "$GODOT_PROJECT" --export-pack "iOS" "$PCK_PATH"
echo "  ✓ $PCK_PATH"

# ── 2. Find connected device (needed for both build and install) ──────────────
# xctrace gives the UDID format that xcodebuild actually expects
XCTRACE_OUT=$(xcrun xctrace list devices 2>/dev/null)
# Grab the first physical iPhone/iPad (skip Mac, Simulator, and Offline sections)
DEVICE_LINE=$(echo "$XCTRACE_OUT" | awk '/^== Devices ==/,/^== Devices Offline ==/' | grep -E "iPhone|iPad" | grep -v "Mac\|Simulator" | head -1)
DEVICE_ID=$(echo "$DEVICE_LINE" | sed 's/.*(\([^)]*\))$/\1/')
DEVICE_NAME=$(echo "$DEVICE_LINE" | sed 's/ ([^)]*) ([^)]*)$//')

if [ -z "$DEVICE_ID" ]; then
  echo "  ✗ No connected device found. Plug in your iPhone and try again."
  exit 1
fi
echo "▶ Device: $DEVICE_NAME ($DEVICE_ID)"

# ── 3. Build Xcode project ───────────────────────────────────────────────────
echo "▶ Building Xcode project..."
BUILD_LOG=$(mktemp)
xcodebuild \
  -project "$XCODE_PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$BUILD_DIR" \
  build 2>&1 | tee "$BUILD_LOG" | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" || true
BUILD_OK=${PIPESTATUS[0]}

if [ "$BUILD_OK" -ne 0 ]; then
  echo "  ✗ Build failed. Full log: $BUILD_LOG"
  exit 1
fi

APP_PATH=$(find "$BUILD_DIR" -name "${SCHEME}.app" -maxdepth 10 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
  echo "  ✗ .app not found after build. Full log: $BUILD_LOG"
  exit 1
fi
rm -f "$BUILD_LOG"
echo "  ✓ $APP_PATH"

# ── 4. Install ────────────────────────────────────────────────────────────────
echo "▶ Installing..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH" 2>&1 | tail -3
echo "  ✓ Installed"

# ── 5. Launch ─────────────────────────────────────────────────────────────────
echo "▶ Launching $BUNDLE_ID..."
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" 2>&1 | tail -3
echo "  ✓ Done"
