#!/usr/bin/env bash
set -euo pipefail

# Build AI System.app from AppleScript with icon

AI_SYSTEM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$AI_SYSTEM_ROOT/scripts/ai_system_gui.applescript"
APP_NAME="AI System"
APPS_DIR="$HOME/Applications"
APP_PATH="$APPS_DIR/$APP_NAME.app"
ICON_PATH="$AI_SYSTEM_ROOT/assets/AI-System.icns"

# Create assets directory if it doesn't exist
mkdir -p "$AI_SYSTEM_ROOT/assets"

# Create a simple icon if it doesn't exist (optional)
if [[ ! -f "$ICON_PATH" ]]; then
  echo "Note: Icon creation skipped (PIL not available). App will use default icon."
  # This is non-fatal - the app will still be created with a default icon
fi

# Remove old app if it exists
if [[ -d "$APP_PATH" ]]; then
  echo "Removing old app..."
  rm -rf "$APP_PATH"
fi

# Create Applications directory if needed
mkdir -p "$APPS_DIR"

# Compile AppleScript to app
echo "Building $APP_NAME.app..."
osacompile -o "$APP_PATH" "$SCRIPT_PATH"

# Add icon if it was created
if [[ -f "$ICON_PATH" ]]; then
  # Copy icon to app bundle
  cp "$ICON_PATH" "$APP_PATH/Contents/Resources/applet.icns"
  echo "✓ Icon added to app bundle"
fi

# Update permissions
chmod +x "$APP_PATH/Contents/MacOS/applet"

# Refresh Finder and Dock
if command -v touch &> /dev/null; then
  touch "$APP_PATH"
fi

echo "✓ $APP_NAME.app built successfully"
echo "  Location: $APP_PATH"
echo ""
echo "To add to Dock:"
echo "  open $APP_PATH"
echo "  (then right-click the Dock icon > Options > Keep in Dock)"
