#!/bin/sh
set -e

APP_NAME="ReflowClip"
BIN_NAME="reflowclip"
VERSION="${VERSION:-0.1.0}"
BUNDLE="build/${APP_NAME}.app"

rm -rf build
mkdir -p "${BUNDLE}/Contents/MacOS" "${BUNDLE}/Contents/Resources"

echo "→ Building release binary…"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"
cp "${BIN_PATH}/${APP_NAME}" "${BUNDLE}/Contents/MacOS/${BIN_NAME}"
chmod +x "${BUNDLE}/Contents/MacOS/${BIN_NAME}"

cat > "${BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>${BIN_NAME}</string>
  <key>CFBundleIdentifier</key><string>com.lovisdotio.reflowclip</string>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

echo "→ Ad-hoc signing…"
codesign --force --deep --sign - "${BUNDLE}"

echo "→ Packaging zip…"
cd build
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${APP_NAME}.app.zip"

echo ""
echo "✓ Built: build/${APP_NAME}.app"
echo "✓ Archive: build/${APP_NAME}.app.zip"
