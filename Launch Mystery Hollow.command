#!/bin/bash
# Double-click launcher for macOS
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

GODOT=""
for candidate in \
  "/Applications/Godot.app/Contents/MacOS/Godot" \
  "/Applications/Godot_mono.app/Contents/MacOS/Godot" \
  "/Applications/Godot 4.app/Contents/MacOS/Godot" \
  "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
do
  if [ -x "$candidate" ]; then
    GODOT="$candidate"
    break
  fi
done

if [ -z "$GODOT" ]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT="godot"
  fi
fi

if [ -z "$GODOT" ]; then
  osascript -e 'display dialog "Godot 4 is not installed.\n\nDownload it from godotengine.org and put Godot.app in Applications.\n\nSee docs/SETUP_MAC.md" buttons {"OK"} default button 1 with title "Mystery Hollow"'
  open "https://godotengine.org/download/macos/"
  exit 1
fi

echo "Starting Mystery Hollow with: $GODOT"
exec "$GODOT" --path "$DIR"
