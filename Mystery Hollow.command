#!/bin/zsh
# Double-click to play Mystery Hollow (same idea as School Hub.command)
set -e
cd "$(dirname "$0")"

echo ""
echo "=== Mystery Hollow ==="
echo ""

# Find Godot
GODOT=""
for candidate in \
  "/Applications/Godot.app/Contents/MacOS/Godot" \
  "/Applications/Godot 4.app/Contents/MacOS/Godot" \
  "/Applications/Godot_mono.app/Contents/MacOS/Godot" \
  "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
do
  if [ -x "$candidate" ]; then
    GODOT="$candidate"
    break
  fi
done

if [ -z "$GODOT" ] && command -v godot >/dev/null 2>&1; then
  GODOT="$(command -v godot)"
fi

if [ -z "$GODOT" ]; then
  echo "Godot 4 is not installed."
  echo ""
  echo "Run the setup script again, or install from:"
  echo "  https://godotengine.org/download/macos/"
  echo ""
  echo "Or in Terminal:"
  echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
  echo ""
  open "https://godotengine.org/download/macos/" 2>/dev/null || true
  read -r "?Press Enter to close… "
  exit 1
fi

if [ ! -f "project.godot" ]; then
  echo "project.godot not found in $(pwd)"
  echo "Re-run setup, or make sure you're in the mystery-hollow folder."
  read -r "?Press Enter to close… "
  exit 1
fi

# Clear quarantine if macOS is being fussy
xattr -dr com.apple.quarantine "/Applications/Godot.app" 2>/dev/null || true

echo "Starting game…"
echo "(Close the game window when you're done. Leave this Terminal open while playing.)"
echo ""

# Run the game project directly (no editor UI)
"$GODOT" --path "$(pwd)"
EXIT=$?

echo ""
if [ $EXIT -ne 0 ]; then
  echo "Game exited with code $EXIT."
  echo "If something looked wrong, try Update Mystery Hollow.command then play again."
fi
read -r "?Press Enter to close this window… "
