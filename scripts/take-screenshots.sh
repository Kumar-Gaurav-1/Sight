#!/bin/bash
set -e

SCREENSHOT_DIR="Resources/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

echo "📸 Taking screenshots of Sight app..."
echo ""
echo "⏳ Waiting 3 seconds for you to open the menu bar dashboard..."
echo "   (Click the eye icon in your menu bar now!)"
sleep 3

# Screenshot 1: Menu bar dashboard
echo "📸 Capturing menu bar dashboard..."
screencapture -x -w "$SCREENSHOT_DIR/dashboard.png" 2>/dev/null || echo "⚠️  Please take dashboard screenshot manually"

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

# Screenshot 2: Have user trigger break overlay
echo "📸 Next, we'll capture the break overlay."
echo "   Click 'Take Break' in the menu, then press Enter here..."
read -p "Press Enter when break overlay is showing: "
screencapture -x "$SCREENSHOT_DIR/overlay.png" 2>/dev/null || echo "⚠️  Please take overlay screenshot manually"

# Press Escape to dismiss overlay
osascript -e 'tell application "System Events" to key code 53'

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

# Screenshot 3: Preferences window
echo "📸 Next, we'll capture preferences."
echo "   Right-click menu bar icon → Preferences, then press Enter..."
read -p "Press Enter when preferences window is showing: "
screencapture -x -w "$SCREENSHOT_DIR/preferences.png" 2>/dev/null || echo "⚠️  Please take preferences screenshot manually"

echo ""
echo "✅ Screenshots saved to: $SCREENSHOT_DIR"
echo ""
echo "Review screenshots:"
ls -lh "$SCREENSHOT_DIR"/*.png 2>/dev/null || echo "No screenshots found"
