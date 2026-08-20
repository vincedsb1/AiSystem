#!/usr/bin/env bash
# Add AI System.app to macOS Dock

APP_PATH="$HOME/Applications/AI System.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: $APP_PATH not found"
  echo "Run: make build-gui-app"
  exit 1
fi

# Use AppleScript to add app to Dock
osascript << EOF
tell application "Dock"
  activate
end tell

delay 1

tell application "Finder"
  activate
end tell

delay 1

tell application "System Events"
  tell application process "Dock"
    -- Get the dock preferences
    set dockPref to (system attribute "com.apple.LaunchServices.QuarantineResolver")
  end tell
end tell

-- Alternative: Use defaults command to add to Dock
EOF

# Use defaults command (more reliable)
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$APP_PATH</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"

# Restart Dock to apply changes
killall Dock

echo "✓ AI System.app added to Dock"
echo "  The Dock will refresh in a moment..."
sleep 2
echo "✓ Done! Look for the AI System icon in your Dock."
