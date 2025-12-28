#!/bin/bash

APP_NAME="Prism"
BUILD_PATH=".build/release/$APP_NAME"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 1. Create Directory Structure
echo "Creating $APP_BUNDLE structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 2. Copy Executable
echo "Copying executable..."
if [ -f "$BUILD_PATH" ]; then
    cp "$BUILD_PATH" "$MACOS_DIR/"
else
    echo "Error: Build artifact not found at $BUILD_PATH"
    exit 1
fi

# 3. Create Info.plist
echo "Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aaravgoyal.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Bluetooth is used for Passkey authentication.</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Bluetooth is used for Passkey authentication.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 4. Copy Icons and Resources
if [ -f "AppIcon.icns" ]; then
    echo "Copying AppIcon.icns..."
    cp "AppIcon.icns" "$RESOURCES_DIR/"
fi

# Copy Swift Package Resources (Bundles)
echo "Copying resource bundles..."
find .build/release -maxdepth 1 -name "*.bundle" -exec cp -r {} "$RESOURCES_DIR/" \;
# Also check the architecture specific folder
find .build/arm64-apple-macosx/release -maxdepth 1 -name "*.bundle" -exec cp -r {} "$RESOURCES_DIR/" \;

# 5. Sign App
echo "Signing app with entitlements..."
SIGNING_IDENTITY="Aarav Goyal"
if [ -f "Entitlements.plist" ]; then
    codesign --force --deep --sign "$SIGNING_IDENTITY" --entitlements Entitlements.plist "$APP_BUNDLE"
else
    echo "Warning: Entitlements.plist not found, signing without specific entitlements."
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
fi

echo "App bundle created at $PWD/$APP_BUNDLE"
echo "You can move this to your Applications folder."
