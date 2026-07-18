#!/bin/zsh
# Force-update from GitHub + clear Godot cache (keeps save games)
set -e
cd "$(dirname "$0")"
INSTALL_DIR="$(pwd)"

echo ""
echo "=== Updating Mystery Hollow ==="
echo "Folder: $INSTALL_DIR"
echo "Saves stay on this Mac — only game code updates."
echo ""

if ! command -v git >/dev/null 2>&1; then
  echo "Git is missing. Run this once in Terminal, then update again:"
  echo "  xcode-select --install"
  echo ""
  read -r "?Press Enter… "
  exit 1
fi

if [ ! -d .git ]; then
  echo "This folder is not a git install."
  echo "Re-install with:"
  echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
  echo ""
  read -r "?Press Enter… "
  exit 1
fi

echo "Before: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Fetching from GitHub…"

# Hard reset to latest main so local edits never block updates
git remote set-url origin https://github.com/Gaz444-lab/mystery-hollow.git 2>/dev/null || true
git fetch origin main || {
  echo "Fetch failed — check internet / Wi‑Fi."
  read -r "?Press Enter… "
  exit 1
}

git checkout main 2>/dev/null || git checkout -B main origin/main
git reset --hard origin/main
git clean -fd -e '.godot' 2>/dev/null || true

AFTER="$(git rev-parse --short HEAD)"
echo "After:  $AFTER"
echo ""

# Prove the black-screen fix is present
if grep -q "InteractableScript" scripts/world/TownWorld.gd 2>/dev/null; then
  echo "✓ Black-screen fix is present in this install."
else
  echo "✗ Fix file missing — re-run full setup:"
  echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
fi

if [ -f VERSION ]; then
  echo "Version file: $(cat VERSION)"
fi

# Clear Godot import cache so old broken scripts aren't reused
echo ""
echo "Clearing Godot cache (not saves)…"
rm -rf .godot
rm -rf "${HOME}/Library/Application Support/Godot/app_userdata/Mystery Hollow/shader_cache" 2>/dev/null || true
rm -rf "${HOME}/Library/Application Support/Godot/app_userdata/Mystery Hollow/vulkan" 2>/dev/null || true

chmod +x *.command launch.sh scripts/*.sh 2>/dev/null || true

# Refresh Desktop shortcuts to this folder
DESKTOP="${HOME}/Desktop"
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

echo ""
echo "=== Update complete ==="
echo "Commit: $AFTER"
echo "Now double-click Mystery Hollow.command to play."
echo "Main menu should show version: $AFTER"
echo ""
read -r "?Press Enter to close… "
