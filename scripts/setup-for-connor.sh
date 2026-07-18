#!/bin/bash
# One-time setup OR full repair on Connor's MacBook.
#
#   curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash
#
set -euo pipefail

REPO_URL="https://github.com/Gaz444-lab/mystery-hollow.git"
INSTALL_DIR="${HOME}/Documents/mystery-hollow"
DESKTOP="${HOME}/Desktop"
GODOT_APP="/Applications/Godot.app"
GODOT_ZIP_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"

echo ""
echo "🔎 Setting up / repairing Mystery Hollow…"
echo ""

if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. Finish Xcode Command Line Tools first, then re-run:"
  echo "  xcode-select --install"
  echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
  exit 1
fi

# Always force latest main (repair-friendly)
if [ -d "${INSTALL_DIR}/.git" ]; then
  echo "Updating existing install at ${INSTALL_DIR}…"
  git -C "$INSTALL_DIR" remote set-url origin "$REPO_URL"
  git -C "$INSTALL_DIR" fetch origin main
  git -C "$INSTALL_DIR" checkout main 2>/dev/null || git -C "$INSTALL_DIR" checkout -B main origin/main
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  echo "Downloading to ${INSTALL_DIR}…"
  rm -rf "$INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
echo "Commit: $(git rev-parse --short HEAD)"
if [ -f VERSION ]; then echo "Version: $(cat VERSION)"; fi

# Clear caches
rm -rf .godot
rm -rf "${HOME}/Library/Application Support/Godot/app_userdata/Mystery Hollow/shader_cache" 2>/dev/null || true

chmod +x *.command launch.sh scripts/*.sh 2>/dev/null || true

find_godot() {
  for candidate in \
    "/Applications/Godot.app/Contents/MacOS/Godot" \
    "/Applications/Godot 4.app/Contents/MacOS/Godot" \
    "/Applications/Godot_mono.app/Contents/MacOS/Godot" \
    "${HOME}/Applications/Godot.app/Contents/MacOS/Godot"
  do
    if [ -x "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  return 1
}

install_godot() {
  echo ""
  echo "Godot 4 not found — installing…"
  if command -v brew >/dev/null 2>&1; then
    brew install --cask godot || true
    if find_godot >/dev/null 2>&1; then
      echo "Godot installed via Homebrew."
      return 0
    fi
  fi
  TMPDIR_G="$(mktemp -d)"
  ZIP="${TMPDIR_G}/godot.zip"
  echo "Downloading Godot 4.3…"
  curl -fL --progress-bar -o "$ZIP" "$GODOT_ZIP_URL"
  ditto -x -k "$ZIP" "$TMPDIR_G"
  FOUND_APP="$(find "$TMPDIR_G" -maxdepth 2 -name 'Godot.app' -type d | head -1)"
  if [ -z "$FOUND_APP" ]; then
    echo "Could not find Godot.app in download."
    rm -rf "$TMPDIR_G"
    return 1
  fi
  if [ -d "$GODOT_APP" ]; then
    rm -rf "$GODOT_APP" 2>/dev/null || sudo rm -rf "$GODOT_APP"
  fi
  if ! mv "$FOUND_APP" "$GODOT_APP" 2>/dev/null; then
    sudo mv "$FOUND_APP" "$GODOT_APP"
  fi
  xattr -dr com.apple.quarantine "$GODOT_APP" 2>/dev/null || true
  rm -rf "$TMPDIR_G"
  find_godot >/dev/null 2>&1
}

if find_godot >/dev/null 2>&1; then
  echo "Godot: $(find_godot)"
else
  install_godot || {
    echo "Install Godot manually: https://godotengine.org/download/macos/"
  }
fi

# Desktop shortcuts
cat > "${DESKTOP}/Mystery Hollow.command" << EOF
#!/bin/zsh
cd "${INSTALL_DIR}"
exec "${INSTALL_DIR}/Mystery Hollow.command"
EOF
cat > "${DESKTOP}/Update Mystery Hollow.command" << EOF
#!/bin/zsh
cd "${INSTALL_DIR}"
exec "${INSTALL_DIR}/Update Mystery Hollow.command"
EOF
chmod +x "${DESKTOP}/Mystery Hollow.command" "${DESKTOP}/Update Mystery Hollow.command"
xattr -dr com.apple.quarantine "${DESKTOP}/Mystery Hollow.command" 2>/dev/null || true
xattr -dr com.apple.quarantine "${DESKTOP}/Update Mystery Hollow.command" 2>/dev/null || true
xattr -dr com.apple.quarantine "${INSTALL_DIR}" 2>/dev/null || true
xattr -dr com.apple.quarantine "/Applications/Godot.app" 2>/dev/null || true

# Verify fix present
echo ""
if grep -q "InteractableScript" scripts/world/TownWorld.gd 2>/dev/null; then
  echo "✓ Black-screen fix confirmed on disk."
else
  echo "✗ WARNING: fix not found after install — check internet and re-run."
fi

echo ""
echo "✅ Done!"
echo ""
echo "Desktop:"
echo "  • Mystery Hollow.command        — play"
echo "  • Update Mystery Hollow.command — update from Dad"
echo ""
echo "Game folder: ${INSTALL_DIR}"
echo "Commit:      $(git rev-parse --short HEAD)"
echo ""
echo "First open may ask macOS to allow Terminal — click Open."
echo "If Godot is blocked: System Settings → Privacy & Security → Open Anyway."
echo ""
