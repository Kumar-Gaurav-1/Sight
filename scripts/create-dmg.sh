#!/bin/bash
set -e

echo "🔨 Building Sight App Bundle..."

# Build universal binary for ARM64 and x86_64
echo "Building for ARM64..."
swift build -c release --arch arm64

echo "Building for x86_64..."
swift build -c release --arch x86_64 || echo "⚠️  x86_64 build skipped (ARM-only Mac)"

# Check if we have both architectures
if [ -f ".build/x86_64-apple-macosx/release/Sight" ]; then
    echo "Creating universal binary..."
    lipo -create \
        .build/arm64-apple-macosx/release/Sight \
        .build/x86_64-apple-macosx/release/Sight \
        -output .build/release/Sight
    echo "✓ Universal binary created (ARM64 + x86_64)"
else
    echo "✓ ARM64-only binary created"
    cp .build/arm64-apple-macosx/release/Sight .build/release/Sight 2>/dev/null || true
fi

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

# Copy icons
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RESOURCES_DIR/"
fi
if [ -f "Resources/AppIcon.png" ]; then
    cp Resources/AppIcon.png "$RESOURCES_DIR/"
fi

# Create enhanced Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Sight</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.kumargaurav.Sight</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Sight</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.healthcare-fitness</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Sight. All rights reserved.</string>
    <key>NSCalendarsUsageDescription</key>
    <string>Sight needs calendar access to automatically pause breaks during your scheduled meetings.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Sight needs accessibility access to provide global keyboard shortcuts for quick timer control.</string>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

# Ad-hoc code signing (for local development)
echo "🔐 Signing app bundle..."
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || echo "⚠️  Code signing skipped (requires Xcode)"


echo "✅ App bundle created at: $APP_DIR"

# Create DMG with drag-to-Applications interface
echo "📦 Creating DMG installer with drag-to-Applications UI..."

DMG_NAME="Sight-Installer.dmg"
VOLUME_NAME="Sight"
DMG_TEMP_DIR="build/dmg-temp"

# Remove old DMG if exists
rm -f "$DMG_NAME"

# Create temporary directory for DMG contents
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR/.background"

# Copy app to temp directory
cp -R "$APP_DIR" "$DMG_TEMP_DIR/"

# Copy background image if exists
if [ -f "Resources/dmg-background.png" ]; then
    cp Resources/dmg-background.png "$DMG_TEMP_DIR/.background/background.png"
    echo "✓ Added DMG background image"
fi

# Create symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Create temporary DMG
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$DMG_TEMP_DIR" -ov -format UDRW "temp.dmg"

# Mount the temporary DMG
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "temp.dmg" | grep Volumes | sed 's/.*\/Volumes/\/Volumes/')

# Set window appearance with AppleScript
echo '
tell application "Finder"
    tell disk "'$VOLUME_NAME'"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        set position of item "Sight.app" of container window to {120, 180}
        set position of item "Applications" of container window to {380, 180}
        update without registering applications
        delay 2
        close
    end tell
end tell
' | osascript || echo "⚠️  Could not set Finder view (app may be running in background)"

# Unmount
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
hdiutil convert "temp.dmg" -format UDZO -o "$DMG_NAME"

# Clean up
rm temp.dmg
rm -rf "$DMG_TEMP_DIR"

echo "✅ DMG created: $DMG_NAME"
echo ""
echo "📥 To install:"
echo "   1. Double-click $DMG_NAME"
echo "   2. Drag Sight.app to Applications folder"
echo "   3. Launch from Applications folder"
