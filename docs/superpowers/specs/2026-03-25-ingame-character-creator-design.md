# In-Game Character Creator — Design Spec

**Date:** 2026-03-25
**Branch:** feature/ui

---

## Overview

Replace the current menu-embedded `CharacterCreatorPanel` with an in-game customization experience. When a new player clicks Play for the first time, the main menu hides, the player spawns directly in the overworld, and a side panel HUD appears letting them choose their cosmetics with live preview on the actual in-world sprite. Clicking "Begin Adventure" saves the choice and unlocks movement.

---

## User Flow

1. Player clicks **Play** on the main menu
2. `should_open()` returns `true` (first run — `PlayerProfileService.has_completed_setup()` is false)
3. Main menu hides via `hide_menu()`
4. Session starts → player spawns in overworld with the **default appearance**
5. `PlayerEvents.player_spawned` fires → `OverworldCharacterCreatorController` intercepts
6. Player **movement is locked** (PlayerInputComponent disabled)
7. **`OverworldCreatorHud`** fades in on the right side of the screen
8. A "CUSTOMIZING" label appears above the player in world space
9. Player cycles Head / Body / Legs slots — each change calls `player.apply_appearance(appearance, catalog)` live
10. **"Begin Adventure"** clicked → appearance saved via `PlayerProfileService.set_appearance(appearance, true)`, HUD fades out, movement unlocks
11. Gameplay proceeds normally

On all subsequent Play presses: `should_open()` returns `false`, steps 5–10 are skipped entirely.

---

## Architecture

### Delete

| File | Reason |
|------|--------|
| `src/Ui/Desktop/CharacterCreator/character_creator_panel.gd` | Replaced by OverworldCreatorHud |
| `src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn` | Replaced by OverworldCreatorHud |

### Create

#### `src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd`

```
class_name OverworldCreatorHud
extends CanvasLayer  (layer = 28)
# Layer 28 sits between system HUD (26) and creature HUD (30).
# The creator HUD is only active before gameplay begins so it never
# conflicts with those layers at runtime.

Signals:
  confirmed(appearance: PlayerAppearanceData)

Public API:
  show_for_player(player: Player, catalog: PlayerCosmeticCatalog, initial_appearance: PlayerAppearanceData)
  hide_hud()

Internals:
  - Stores current head/body/legs indices
  - On prev/next: cycles index, builds PlayerAppearanceData, calls player.apply_appearance(appearance, catalog) immediately
  - On randomize: picks random indices, calls player.apply_appearance(appearance, catalog) live
  - On "Begin Adventure": emits confirmed(appearance)
  - Fade in/out via tween on modulate.a
```

#### `src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.tscn`

Scene structure:
```
OverworldCreatorHud (CanvasLayer, layer=28)
└── Panel (Control, right-anchored, ~300px wide, full height)
    ├── Header (Label: "YOUR ADVENTURER")
    ├── SlotsContainer (VBoxContainer, expand)
    │   ├── HeadSlot (HBoxContainer: PrevButton, Label, NextButton)
    │   ├── BodySlot (HBoxContainer: PrevButton, Label, NextButton)
    │   └── LegsSlot (HBoxContainer: PrevButton, Label, NextButton)
    └── BottomButtons (VBoxContainer, pinned bottom)
        ├── RandomizeButton
        └── BeginAdventureButton
```

The "CUSTOMIZING" label above the player is a plain `Label` node added as a child of the player node, positioned with a negative `y` offset so it floats above the sprite. It moves with the player automatically. Removed (queue_free) on confirm.

### Modify

#### `overworld_character_creator_controller.gd`

- **Remove:** `open_panel()`, `_on_begin_adventure_pressed()`, `_on_appearance_confirmed()`, `_on_creation_cancelled()`, all `_main_screen` references
- **Change:** `initialize(main_screen, session_controller)` → `initialize(session_controller)` — drop the `main_screen` parameter entirely
- **Change:** `should_open()` body: currently `return true` — change to `return not PlayerProfileService.has_completed_setup()`
- **Change:** `is_visible()` body: change to `return _creator_hud != null and _creator_hud.visible` (this is used by `overworld.gd._unhandled_input` to block world interaction while the HUD is open — keep the method, update its implementation)
- **Add:** `@onready var _creator_hud: OverworldCreatorHud = $OverworldCreatorHud`
- **Add:** In `initialize()`, connect `PlayerEvents.player_spawned` → `_on_player_spawned`
- **Add:** `_on_player_spawned(player: Node)` — `PlayerEvents.player_spawned` emits `Node`; cast internally: `var p := player as Player`. If `should_open()`: get catalog + appearance from `PlayerProfileService`, call `_creator_hud.show_for_player(p, catalog, appearance)`, disable player input
- **Add:** `_on_hud_confirmed(appearance: PlayerAppearanceData)` — call `PlayerProfileService.set_appearance(appearance, true)`, re-enable player input, call `_creator_hud.hide_hud()`

**Movement lock:**
```gdscript
var _input_component: PlayerInputComponent = player.get_node_or_null("PlayerInputComponent")
if _input_component:
    _input_component.process_mode = Node.PROCESS_MODE_DISABLED
```
Unlock: restore to `PROCESS_MODE_INHERIT`.

#### `overworld.gd`

- `_on_main_screen_play_pressed()`: remove the `character_creator_controller.should_open()` gate — always call `hide_menu()` + `session_controller.start_session()` directly
- Remove `_on_begin_adventure_pressed()` method, its `main_screen.begin_adventure_pressed.connect(...)` line in `_wire_main_screen_signals()`, and any other reference to `begin_adventure_pressed`
- `_initialize_character_creator_controller()`: change call to `character_creator_controller.initialize(session_controller)` — drop `main_screen` argument
- The `_unhandled_input` guard `character_creator_controller.is_visible()` **stays unchanged** — it will now route through the updated `is_visible()` in the controller

#### `main_screen.gd`

Remove all `CharacterCreatorPanel` wiring — the new flow never touches `main_screen` for the creator:

- **Remove signal:** `signal begin_adventure_pressed`
- **Remove export:** `@export var creator_panel_path`
- **Remove fields:** `var _creator_panel: CharacterCreatorPanel`, `var _creator_overlay_mode: bool`
- **Remove methods:** `animate_play_transition()`, `animate_menu_out()`, `set_creator_overlay_mode()`, `_on_begin_pressed()`, `_on_creator_cancelled()`, `_compute_creator_anchors()`
- **Remove from `_cache_nodes()`:** the `_creator_panel = get_node_or_null(...)` line
- **Remove from `_connect_signals()`:** `_creator_panel.confirmed.connect(...)` and `_creator_panel.creation_cancelled.connect(...)`
- **Remove from `show_menu()` and `hide_menu()`:** `set_creator_overlay_mode(false)` calls
- Keep everything else unchanged

#### `player_profile_service.gd`

`has_completed_setup()` is currently hardcoded to `return false`, and `set_appearance` has an unused `_mark_completed` parameter. Fix:

1. Rename parameter `_mark_completed` → `mark_complete` and implement it.
2. Add `var _setup_completed: bool = false` field.
3. In `set_appearance(appearance, mark_complete)`: if `mark_complete` is true, set `_setup_completed = true` and persist it to `user://player_profile.cfg` under section `[profile]`, key `setup_completed = true`.
4. In `_load_profile()` (or `_ready()`): read `setup_completed` from cfg; default to `false` if missing.
5. `has_completed_setup()` returns `_setup_completed`.

#### `overworld.tscn`

- In the Godot editor, add `OverworldCreatorHud` (the new `.tscn`) as a **child of `OverworldCharacterCreatorController`** in the overworld scene tree. The `@onready var _creator_hud` path `$OverworldCreatorHud` must resolve from the controller node.

---

## Styling

Matches the existing gold-on-dark aesthetic:

- Panel background: `Color(0.031, 0.055, 0.102, 0.93)`
- Border: `Color(0.784, 0.659, 0.478, 0.25)` (gold, subtle)
- Slot labels: `Color(0.478, 0.604, 0.800)` (blue-grey, matches HEAD/BODY/LEGS in current panel)
- Value text: `Color(0.910, 0.847, 0.722)` (warm white)
- Buttons: Awesome 9.ttf font, gold color palette (same as main menu buttons)
- Begin Adventure button: slightly brighter border to make it stand out

---

## What Does NOT Change

- `PlayerVisualComponent.apply_appearance()` — used as-is
- `PlayerCosmeticCatalog` — used as-is
- `PlayerAppearanceData` — used as-is
- `OverworldPlayerSpawner` — spawns with default appearance as-is
- `OverworldSessionController` — unchanged
- Mobile UI — unaffected (this is desktop-only path)
