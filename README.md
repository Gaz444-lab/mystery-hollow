# Mystery Hollow

**Open-world detective life simulator** built with **Godot 4**.

Live in a cozy, atmospheric small town. Customize your detective, pick an era, manage daily needs, explore freely, and solve murders — starting with **The Riverside Murder**.

> Inspirations: *The Sims* / life-sim systems · *RDR2* / *GTA* open-world feel · *L.A. Noire* investigation.

---

## For your son (MacBook) — quick start

1. **Install Godot 4.3+** (macOS):  
   https://godotengine.org/download/macos/  
   Choose the **standard** build (not .NET unless you prefer C#).
2. **Get the game** (pick one):
   - **Clone:**  
     ```bash
     git clone https://github.com/Gaz444-lab/mystery-hollow.git
     cd mystery-hollow
     ```
   - **Or** download ZIP from GitHub → **Code → Download ZIP** → unzip.
3. **Open the project:**
   - Launch Godot → **Import** → select the `mystery-hollow` folder → **Import & Edit**
   - Press **F5** (or the Play button)
4. **Optional launcher:** double-click **`Launch Mystery Hollow.command`** (after Godot is installed).

**Shared family tip:** Keep the project in a folder you both can clone (GitHub). Saves are stored **per Mac** under Godot’s user data (`user://saves`), not inside the repo — so each player has their own progress.

---

## Controls

| Key | Action |
|-----|--------|
| **WASD** / arrows | Move |
| **Mouse** | Look |
| **Shift** | Sprint |
| **E** | Interact |
| **J** | Detective journal / case board |
| **I** | Inventory |
| **Esc** | Free / capture mouse · Pause menu |
| **B** | Build mode hint (at home) |

---

## How to play (first session)

1. **Main menu** → **New Game** → pick an **era** (1900s → Present Day).
2. **Character creator** → name, body, outfit (era-aware clothing/accessories).
3. Explore **Mystery Hollow**:
   - **Blue-accent building** = Detective Agency → accept **The Riverside Murder**
   - **Your Home** (west) → sleep, eat, case board
   - **River (east)** = crime scene — collect glowing evidence
   - **Warehouse** = ledger evidence
4. Interview townsfolk (E). Watch for **lie tells** on key suspects.
5. When you have the required clues, return to the Agency → **Make an accusation**.

**Correct killer (spoiler):** Marcus Reed — watch, boots, note, ledger.

---

## Project structure

```
mystery-hollow/
├── project.godot              # Godot 4 project
├── data/cases/                # Case JSON (dialogue, evidence, endings)
├── scenes/
│   ├── main/MainMenu.tscn
│   ├── ui/CharacterCustomizer.tscn, HUD.tscn
│   ├── player/Player.tscn
│   └── world/Town.tscn
├── scripts/
│   ├── autoload/              # GameState, Era, Save, Time, Cases, EventBus
│   ├── player/
│   ├── world/                 # Town, NPCs, interactables
│   └── ui/
├── assets/ui/
├── docs/
├── Launch Mystery Hollow.command
└── scripts/setup_mac.sh
```

### Core systems

| System | Role |
|--------|------|
| **EraManager** | 1900s / 80s / 90s / 2000s / Present — palette, fashion, tools |
| **GameState** | Character, needs (hunger/energy/mood), inventory, reputation, relationships, house furniture |
| **TimeSystem** | Day/night clock + lighting |
| **CaseManager** | Multi-case pipeline, evidence gates, accusations, endings |
| **SaveSystem** | 3 save slots (`user://saves/slot_N.json`) |
| **TownWorld** | Procedural small-town open world (roads, buildings, river, forest, NPCs) |

### Cases included

1. **The Riverside Murder** — fully playable loop (crime scene, warehouse, interviews, accusation, multiple endings).
2. **Midnight at the Diner** — data-ready (unlock wiring next).
3. **The Silent Bell** — data-ready (expansion).

---

## Requirements

- **Godot 4.3+** (4.3 / 4.4 / 4.5 recommended)
- macOS, Windows, or Linux
- GPU capable of Forward+ 3D (any recent Mac is fine)

---

## Setup (developer)

```bash
git clone https://github.com/Gaz444-lab/mystery-hollow.git
cd mystery-hollow
# Open folder in Godot 4 → F5
```

Or:

```bash
./scripts/setup_mac.sh   # checks/installs guidance for Godot via Homebrew if available
```

---

## Design notes (foundation vs full vision)

This repo is a **playable vertical slice / foundation**, not a finished AAA title:

**Implemented now**
- Era select + character customizer  
- Third-person open town  
- Needs, day/night, save/load  
- Home + agency interaction loops  
- Full first murder case (evidence, dialogue trees, lie detection, accusation)  
- Modular case JSON for expansion  

**Next expansion ideas**
- Full interior scenes (navmesh rooms)  
- Furniture build mode grid placement  
- Vehicles per era  
- Animated character meshes / clothing  
- Cases 2–3 world markers + unlock after case 1  
- Relationship social minigames  
- Multiplayer co-op investigation (stretch)  
- Exported `.app` builds for one-click play without Godot editor  

---

## GitHub

- **Repo:** https://github.com/Gaz444-lab/mystery-hollow  
- **Owner account:** Gaz444-lab  

---

## License

Personal / family project. Add a license file if you open-source publicly.
