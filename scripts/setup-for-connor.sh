#!/bin/bash
# One-time setup on Connor's MacBook (same pattern as School Hub).
# After Xcode CLT / git is installed:
#
#   curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash
#
set -euo pipefail

REPO_URL="https://github.com/Gaz444-lab/mystery-hollow.git"
INSTALL_DIR="${HOME}/Documents/mystery-hollow"
DESKTOP="${HOME}/Desktop"
GODOT_APP="/Applications/Godot.app"
# Official macOS universal build (Godot 4.3 — matches project)
GODOT_ZIP_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"

echo ""
echo "🔎 Setting up Mystery Hollow (detective game)…"
echo ""

# --- Git ---
if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. Finish Xcode Command Line Tools first, then re-run:"
  echo "  xcode-select --install"
  echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
  exit 1
fi

# --- Clone / update game ---
if [ -d "${INSTALL_DIR}/.git" ]; then
  echo "Game already installed — updating code…"
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Downloading game to ${INSTALL_DIR}…"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
chmod +x *.command launch.sh scripts/*.sh 2>/dev/null || true

# --- Godot engine ---
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
  echo "Godot 4 not found — installing the game engine (one-time)…"

  # Prefer Homebrew when available
  if command -v brew >/dev/null 2>&1; then
    echo "Using Homebrew…"
    brew install --cask godot || true
    if find_godot >/dev/null 2>&1; then
      echo "Godot installed via Homebrew."
      return 0
    fi
  fi

  # Direct download from official Godot releases
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl missing — open https://godotengine.org/download/macos/ and install Godot manually."
    return 1
  fi

  TMPDIR_G="$(mktemp -d)"
  ZIP="${TMPDIR_G}/godot.zip"
  echo "Downloading Godot 4.3 for Mac…"
  curl -fL --progress-bar -o "$ZIP" "$GODOT_ZIP_URL"

  echo "Installing to /Applications/Godot.app (may ask for password)…"
  ditto -x -k "$ZIP" "$TMPDIR_G"

  # Zip contains Godot.app
  FOUND_APP="$(find "$TMPDIR_G" -maxdepth 2 -name 'Godot.app' -type d | head -1)"
  if [ -z "$FOUND_APP" ]; then
    echo "Could not find Godot.app inside the download."
    rm -rf "$TMPDIR_G"
    return 1
  fi

  if [ -d "$GODOT_APP" ]; then
    echo "Replacing existing Godot.app…"
    rm -rf "$GODOT_APP" 2>/dev/null || sudo rm -rf "$GODOT_APP"
  fi

  if mv "$FOUND_APP" "$GODOT_APP" 2>/dev/null; then
    :
  else
    sudo mv "$FOUND_APP" "$GODOT_APP"
  fi

  # Clear quarantine so double-click / launch works
  xattr -dr com.apple.quarantine "$GODOT_APP" 2>/dev/null || true

  rm -rf "$TMPDIR_G"

  if find_godot >/dev/null 2>&1; then
    echo "Godot installed at $GODOT_APP"
    return 0
  fi
  return 1
}

if find_godot >/dev/null 2>&1; then
  echo "Godot already installed: $(find_godot)"
else
  if ! install_godot; then
    echo ""
    echo "⚠️  Could not auto-install Godot."
    echo "    Download manually: https://godotengine.org/download/macos/"
    echo "    Drag Godot into Applications, then double-click Mystery Hollow.command"
    echo ""
  fi
fi

# --- Desktop shortcuts (same idea as School Hub) ---
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

# Clear quarantine on desktop shortcuts (first-run macOS Gatekeeper)
xattr -dr com.apple.quarantine "${DESKTOP}/Mystery Hollow.command" 2>/dev/null || true
xattr -dr com.apple.quarantine "${DESKTOP}/Update Mystery Hollow.command" 2>/dev/null || true
xattr -dr com.apple.quarantine "${INSTALL_DIR}" 2>/dev/null || true

echo ""
echo "✅ Done!"
echo ""
echo "On Connor's Desktop:"
echo "  • Mystery Hollow.command          — play the game"
echo "  • Update Mystery Hollow.command   — after Dad pushes updates"
echo ""
echo "Game folder: ${INSTALL_DIR}"
echo "Saves stay on this Mac only (not wiped by updates)."
echo ""
echo "First open may ask macOS to allow Terminal — click Open."
echo "If macOS blocks Godot: System Settings → Privacy & Security → Open Anyway."
echo ""
echo "To play now: double-click Mystery Hollow.command on the Desktop."
echo ""
