#!/bin/bash
# Setup helper for Mac — checks Git + Godot, clones if needed
set -euo pipefail

echo "=== Mystery Hollow — Mac setup ==="

if ! command -v git >/dev/null 2>&1; then
  echo "Git not found. Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "Re-run this script after the installer finishes."
  exit 1
fi

if [ ! -f "project.godot" ]; then
  echo "Run this from inside the mystery-hollow project folder."
  exit 1
fi

GODOT_FOUND=0
for candidate in \
  "/Applications/Godot.app" \
  "/Applications/Godot 4.app" \
  "$HOME/Applications/Godot.app"
do
  if [ -d "$candidate" ]; then
    echo "Found Godot: $candidate"
    GODOT_FOUND=1
    break
  fi
done

if [ "$GODOT_FOUND" -eq 0 ]; then
  echo "Godot 4 not found in Applications."
  if command -v brew >/dev/null 2>&1; then
    echo "You can install with Homebrew:"
    echo "  brew install --cask godot"
  else
    echo "Download: https://godotengine.org/download/macos/"
  fi
else
  echo "Ready. Open the project in Godot or run: ./Launch\\ Mystery\\ Hollow.command"
fi

chmod +x "Launch Mystery Hollow.command" 2>/dev/null || true
echo "Done."
