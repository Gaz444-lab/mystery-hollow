# Mystery Hollow — Design Alignment

**Core fantasy:** Live as a detective in a living small town. Balance personal life with serious cases.  
**Tone:** Twin Peaks × The Sims × RDR2 — intimate, grounded, atmospheric. **No cartoon / no Minecraft.**  
**Engine:** Godot 4.3+ · GDScript · third-person.

## Architecture

| Autoload | Role |
|----------|------|
| `EventBus` | Decoupled signals |
| `GameState` | GameManager: character, needs, inventory, relationships |
| `EraManager` | Era selection → fashion/tech/palette |
| `SaveSystem` | JSON slots under `user://saves` |
| `TimeSystem` | Day/night clock |
| `CaseManager` | Cases, evidence, interrogations, endings |

### Scene map

- `scenes/main/MainMenu.tscn` — title, New / Continue / Settings / Quit, era cards
- `scenes/ui/CharacterCustomizer.tscn` — body/head/clothing/accessories/backstory + 3D preview
- `scenes/player/Player.tscn` — third-person controller
- `scenes/world/Town.tscn` — open world (districts)
- `scenes/ui/HUD.tscn` — needs, journal, dialogue, accusation, pause/save

### Folders

```
scripts/autoload|player|world|ui|character|cases|systems
scenes/main|player|world|ui|office|house|cases
data/cases/          # JSON case packs
assets/              # final art placeholders
docs/
```

## Implemented (Phase 1–3 foundation)

- Main menu + era select + character customizer (3D preview) + backstory
- Open world districts: Downtown, Residential, Outskirts (forest, docks, factory, mansion)
- Needs: Hunger, Thirst, Energy, Hygiene, Mood
- Home interactables: sleep, eat, drink, wash, journal
- Detective Agency: accept case, board, accusation
- Case 1 fully playable (Riverside Murder); cases 2–3 data + unlock chain
- Day/night + simple weather rotation
- Save/load 3 slots
- Stylized realistic low-poly humanoids + town geometry (placeholder art)

## Planned expansion

- NPC daily schedules / pathing
- Drag-drop furniture store
- Corkboard pin UI with drawable links
- Separate DetectiveOffice.tscn interior scene
- Final models, audio, credits screen art
- 2 more fully staged world cases

## Add a new case

1. Copy `data/cases/case_01_riverside.json` → `case_04_….json`
2. Fill evidence, dialogues, suspects, endings
3. Set `starts_available` or unlock via `CaseManager._unlock_next_case`
4. Place evidence markers in `TownWorld.gd` if needed
