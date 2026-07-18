# Mystery Hollow — Mac setup (you + your son)

## Option A — Play with Godot (recommended while developing)

### On your Mac (this machine)

1. Install Godot 4.3+ from https://godotengine.org/download/macos/
2. Project lives at: `~/mystery-hollow`
3. Open Godot → Import → that folder → Play (F5)

### On your son’s MacBook

1. Create a free GitHub account (or use family access to yours).
2. Install **Git** (Xcode Command Line Tools):
   ```bash
   xcode-select --install
   ```
3. Install **Godot 4** from the link above (drag Godot into Applications).
4. In Terminal:
   ```bash
   cd ~
   git clone https://github.com/Gaz444-lab/mystery-hollow.git
   open -a Godot mystery-hollow
   ```
   If `open -a Godot` fails, open Godot manually → **Import** → `~/mystery-hollow`.
5. Press **Play**.

### Getting updates on his Mac

```bash
cd ~/mystery-hollow
git pull
```

Then open the project again in Godot.

---

## Option B — Double-click launcher

After Godot is installed in `/Applications`:

1. In Finder, open the `mystery-hollow` folder.
2. Double-click **`Launch Mystery Hollow.command`**
3. If macOS blocks it: **System Settings → Privacy & Security → Open Anyway**

---

## Option C — Exported app (later)

When the game is more polished:

1. In Godot: **Project → Export → macOS**
2. Export a `.app` or `.dmg`
3. AirDrop / shared Drive the build to his MacBook  
   (No Godot install required for him.)

---

## Saves

Saves are **local to each computer**:

`~/Library/Application Support/Godot/app_userdata/Mystery Hollow/saves/`

They are **not** overwritten by `git pull`.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| “Godot not found” | Install Godot into `/Applications` and rename app to `Godot.app` if needed |
| Project fails to open | Use Godot **4.3+**, not Godot 3 |
| Black screen | Click the game window; press Esc then click to recapture mouse |
| Git clone denied | Repo must be public, or he must be invited as collaborator |
