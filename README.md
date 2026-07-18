# Mystery Hollow

**Grounded open-world detective life simulator** — Godot 4.3+.

Live in a small town. Manage your life. Solve murders.  
Tone: *Twin Peaks* intimacy + *The Sims* life systems + *RDR2* exploration — **not** cartoon or Minecraft.

---

## Run (Dad or Connor)

### Connor’s Mac (family install)

```bash
curl -fsSL https://raw.githubusercontent.com/Gaz444-lab/mystery-hollow/main/scripts/setup-for-connor.sh | bash
```

Then **Mystery Hollow.command** on Desktop.  
Updates: **Update Mystery Hollow.command**  
Menu should show version **`0.3.0-grounded-vision`**.

### Developer

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Open folder `mystery-hollow` → **F5**
3. Or: `Godot --path ~/mystery-hollow`

Local repo: `~/mystery-hollow`  
GitHub: https://github.com/Gaz444-lab/mystery-hollow

---

## New game flow

1. **Main menu** → New Game  
2. **Era** — 1900s / 1980s / 1990s / 2000s / Present  
3. **Character** — body, face, era clothing, accessories, backstory + 3D preview  
4. **World** — explore, live, investigate  

### Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Look |
| Shift | Sprint |
| E | Interact |
| J | Journal / case board |
| I | Inventory |
| Esc | Cursor / pause & save |

### First case loop

1. **Detective Agency** (brick building downtown) → accept **Riverside Murder**  
2. **River / docks** — collect evidence  
3. **Warehouse** — ledger  
4. Interview townsfolk (watch for lie tells)  
5. Accuse when the journal says you can  

---

## Systems (current)

- **Life sim:** Hunger, Thirst, Energy, Hygiene, Mood  
- **Home:** Sleep, eat, drink, wash, case board  
- **World districts:** Downtown · Residential · Outskirts (forest, docks, factory, mansion)  
- **Detective:** Case JSON, evidence, dialogue trees, lie tells, accusation endings  
- **Meta:** Day/night, weather, reputation, relationships, 3 save slots  
- **Art:** Stylized realistic low-poly placeholders (swap later for final models)

---

## Project structure

See `docs/DESIGN.md` for architecture and how to add cases.

---

## Export

Godot → **Project → Export** → Windows / macOS / Linux.  
Saves stay local (`user://saves`) per machine.
