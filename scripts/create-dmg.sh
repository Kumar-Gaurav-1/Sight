#!/bin/bash
set -e

echo "🔨 Building Sight App Bundle..."

# Build in release mode
swift build -c release

# Create app bundle structure
APP_NAME="Sight.app"
APP_DIR="build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean and create directories
rm -rf build
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/Sight "$MACOS_DIR/"

# Copy icon if exists
if [ -f "Resources/AppIcon.png" ]; then
    cp Resources/AppIcon.png "$RESOURCES_DIR/"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Sight</string>
    <key>CFBundleIdentifier</key>
    <string>com.sight.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Sight</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Sight. All rights reserved.</string>
</dict>
</plist>
EOF

echo "✅ App bundle created at: $APP_DIR"

# Create DMG
echo "📦 Creating DMG installer..."

DMG_NAME="Sight-Installer.dmg"
VOLUME_NAME="Sight"

# Remove old DMG if exists
rm -f "$DMG_NAME"

# Create temporary DMG
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$APP_DIR" -ov -format UDZO "$DMG_NAME"

echo "✅ DMG created: $DMG_NAME"
echo ""
echo "📥 To install:"
echo "   1. Double-click $DMG_NAME"
echo "   2. Drag Sight.app to /Applications"
echo "   3. Launch from Applications folder"
