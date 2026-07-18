# Mystery Hollow — Mac setup (you + your son)

Same family flow as **School Hub**.

---

## Connor’s MacBook (recommended)

### First time

```bash
xcode-select --install   # only if git is missing — wait for it to finish
curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash
```

That installs the game + Godot and puts on the **Desktop**:

| Shortcut | Use |
|----------|-----|
| **Mystery Hollow.command** | Play |
| **Update Mystery Hollow.command** | After Dad pushes updates |

### Play

Double-click **Mystery Hollow.command**

### Update

Double-click **Update Mystery Hollow.command**, then play again.

---

## Dad’s Mac (develop)

Project: `~/mystery-hollow`  
Repo: https://github.com/Gaz444-lab/mystery-hollow

```bash
cd ~/mystery-hollow
# edit…
git add -A
git commit -m "Describe change"
git push
```

Tell Connor to run **Update Mystery Hollow.command**.

---

## Saves

Local to each Mac (not in git):

`~/Library/Application Support/Godot/app_userdata/Mystery Hollow/saves/`

Updates never wipe saves.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| “Git is required” | Run `xcode-select --install`, wait, re-run curl setup |
| Godot blocked by macOS | System Settings → Privacy & Security → **Open Anyway** |
| “Godot not found” | Re-run setup, or install from https://godotengine.org/download/macos/ |
| Black / no mouse | Click game window; **Esc** frees cursor |
| Update failed | Check internet; re-run the curl setup line |
| Project fails | Need **Godot 4.3+**, not Godot 3 |
