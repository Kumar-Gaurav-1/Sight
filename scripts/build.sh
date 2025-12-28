#!/bin/bash

# Sight App Build Script
# Builds the app bundle for distribution

set -e

echo "🛠  Building Sight for release..."

# Clean build folder
rm -rf .build/release 2>/dev/null || true

# Build release
swift build -c release

echo "📦 Creating app bundle..."

# Create app bundle structure
APP_NAME="Sight"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

rm -rf "$APP_BUNDLE" 2>/dev/null || true
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/Sight" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Sight</string>
    <key>CFBundleDisplayName</key>
    <string>Sight</string>
    <key>CFBundleIdentifier</key>
    <string>com.sight.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Sight</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Sight. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "✅ App bundle created at: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
echo ""
echo "⚠️  Note: This app is unsigned. To run it:"
echo "   1. Right-click the app and select 'Open'"
echo "   2. Click 'Open' in the dialog"
echo ""
echo "For distribution, you would need to:"
echo "   1. Sign with: codesign --sign 'Developer ID Application' $APP_BUNDLE"
echo "   2. Notarize with: xcrun notarytool"
echo "   3. Create DMG with: hdiutil create"
