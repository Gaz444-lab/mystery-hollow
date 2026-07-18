#!/bin/zsh
# Double-click to play Mystery Hollow
set -e
cd "$(dirname "$0")"
LOG="${HOME}/Desktop/MysteryHollow-last-run.log"

echo ""
echo "=== Mystery Hollow ==="
echo "Folder: $(pwd)"
if [ -d .git ]; then
  echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
fi
if [ -f VERSION ]; then
  echo "Version: $(cat VERSION)"
fi
echo "Log: $LOG"
echo ""

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
  echo "Run setup:"
  echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
  open "https://godotengine.org/download/macos/" 2>/dev/null || true
  read -r "?Press Enter to close… "
  exit 1
fi

if [ ! -f "project.godot" ]; then
  echo "project.godot missing in $(pwd)"
  read -r "?Press Enter to close… "
  exit 1
fi

# Warn if black-screen fix missing
if ! grep -q "InteractableScript" scripts/world/TownWorld.gd 2>/dev/null; then
  echo "WARNING: This install looks OLD (missing black-screen fix)."
  echo "Run Update Mystery Hollow.command first!"
  echo ""
  read -r "?Press Enter to try anyway, or Ctrl+C to cancel… "
fi

xattr -dr com.apple.quarantine "/Applications/Godot.app" 2>/dev/null || true
xattr -dr com.apple.quarantine "$(pwd)" 2>/dev/null || true

echo "Starting… (close the game window when done)"
echo ""

# Force compatibility renderer — most reliable on varied Macs
set +e
"$GODOT" --path "$(pwd)" --rendering-method gl_compatibility >"$LOG" 2>&1
EXIT=$?
set -e

echo ""
if [ $EXIT -ne 0 ]; then
  echo "Game exited with code $EXIT."
  echo "Last log lines:"
  tail -30 "$LOG" 2>/dev/null || true
  echo ""
  echo "Full log saved to Desktop: MysteryHollow-last-run.log"
  echo "Send that file to Dad if it still black-screens."
fi
read -r "?Press Enter to close this window… "
