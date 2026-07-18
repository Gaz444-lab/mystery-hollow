#!/bin/zsh
# Pull latest game code from GitHub (keeps Connor's save games)
set -e
cd "$(dirname "$0")"

echo ""
echo "=== Updating Mystery Hollow ==="
echo "Your save games stay on this Mac — only the game code updates."
echo ""

if [ -d .git ]; then
  echo "Pulling latest code from GitHub…"
  git pull --ff-only || {
    echo ""
    echo "git pull failed. Check internet, or re-run setup:"
    echo "  curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash"
    echo ""
    read -r "?Press Enter… "
    exit 1
  }
else
  echo "No git repo — skipped pull. Re-run the setup script to install properly."
fi

chmod +x *.command launch.sh scripts/*.sh 2>/dev/null || true

echo ""
echo "=== Update complete ==="
echo "Double-click Mystery Hollow.command to play."
echo ""
read -r "?Press Enter to close… "
