#!/usr/bin/env bash
set -euo pipefail

# Build and install AI System.app (SwiftUI) locally
# This script builds the Xcode project and installs to ~/Applications

AI_SYSTEM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT_PATH="$AI_SYSTEM_ROOT/apps/AI-System/AI System.xcodeproj"
XCODE_SCHEME="AI System"
BUILD_CONFIG="${BUILD_CONFIG:-Release}"
APPS_DIR="$HOME/Applications"
APP_NAME="AI System"
APP_PATH="$APPS_DIR/$APP_NAME.app"
BUILD_LAUNCH="${BUILD_LAUNCH:-0}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --launch)
      BUILD_LAUNCH=1
      shift
      ;;
    --debug)
      BUILD_CONFIG="Debug"
      shift
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      echo "Usage: $0 [--launch] [--debug]" >&2
      exit 1
      ;;
  esac
done

echo "=== AI System SwiftUI App Builder ==="
echo "Configuration: $BUILD_CONFIG"
echo "Project: $XCODE_PROJECT_PATH"
echo "Scheme: $XCODE_SCHEME"
echo ""

# Verify xcodebuild is available
if ! command -v xcodebuild &>/dev/null; then
  echo "Error: xcodebuild not found. Make sure Xcode is installed." >&2
  exit 1
fi

# Verify project exists
if [[ ! -d "$XCODE_PROJECT_PATH" ]]; then
  echo "Error: Xcode project not found at $XCODE_PROJECT_PATH" >&2
  exit 1
fi

# Create Applications directory if needed
mkdir -p "$APPS_DIR"

# Clean previous build intermediates (optional, but ensures clean build)
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
BUILD_DIRS=$(find "$DERIVED_DATA_PATH" -type d -name "*AI_System*" 2>/dev/null || true)
if [[ -n "$BUILD_DIRS" ]]; then
  echo "Note: Xcode build cache will be reused (not cleaned for speed)"
fi

# Build the app
echo "Building $APP_NAME.app with $BUILD_CONFIG configuration..."
if ! xcodebuild \
  -project "$XCODE_PROJECT_PATH" \
  -scheme "$XCODE_SCHEME" \
  -configuration "$BUILD_CONFIG" \
  build &>/dev/null; then
  echo "Error: Build failed. Run with --debug for details:" >&2
  echo "  xcodebuild -project \"$XCODE_PROJECT_PATH\" -scheme \"$XCODE_SCHEME\" -configuration \"$BUILD_CONFIG\" build" >&2
  exit 1
fi
echo "✓ Build succeeded"

# Locate the built app (in Xcode DerivedData)
DERIVED_DATA_PRODUCT=$(find "$DERIVED_DATA_PATH" -path "*/Build/Products/$BUILD_CONFIG/$APP_NAME.app" 2>/dev/null | head -1)

if [[ -z "$DERIVED_DATA_PRODUCT" || ! -d "$DERIVED_DATA_PRODUCT" ]]; then
  echo "Error: Could not find built app in DerivedData" >&2
  exit 1
fi

echo "Built app found at: $DERIVED_DATA_PRODUCT"
echo ""

# Remove old app if it exists
if [[ -d "$APP_PATH" ]]; then
  echo "Removing previous installation..."
  rm -rf "$APP_PATH"
fi

# Copy built app to ~/Applications
echo "Installing to $APP_PATH..."
cp -r "$DERIVED_DATA_PRODUCT" "$APP_PATH"

# Verify installation
if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: Installation failed" >&2
  exit 1
fi

# Make sure it's executable
if [[ -f "$APP_PATH/Contents/MacOS/$APP_NAME" ]]; then
  chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"
fi

# Register with Launch Services
if command -v touch &>/dev/null; then
  touch "$APP_PATH"
fi

echo "✓ $APP_NAME.app installed successfully"
echo "  Location: $APP_PATH"
echo ""
echo "To launch:"
echo "  open '$APP_PATH'"
echo ""
echo "To add to Dock:"
echo "  1. open '$APP_PATH'"
echo "  2. Right-click the Dock icon"
echo "  3. Select Options > Keep in Dock"
echo ""

# Launch if requested
if [[ "$BUILD_LAUNCH" == "1" ]]; then
  echo "Launching app..."
  open "$APP_PATH"
fi

exit 0
