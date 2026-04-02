# Design: Thorough Codebase Refactor

**Date:** 2026-03-09
**Approach:** Phased (Structure → Patterns → UI)
**Constraint:** Behavior must remain identical — restructure only, no gameplay changes

## Phase 1: Folder Structure

Consolidate split directories, co-locate scenes with scripts, fix naming.

### Moves

| Before | After | Reason |
|---|---|---|
| `src/Map/main.tscn`, `main.gd` | `src/world/main.tscn`, `main.gd` | Co-locate with World scripts |
| `src/Map/Overworld/Chunks/` | `src/world/Overworld/Chunks/` | Co-locate chunk scenes with chunk scripts |
| `src/Map/Overworld/Shaders/` | `src/world/Overworld/Shaders/` | Co-locate with World |
| `src/Map/Locations/` | `src/world/Locations/` | Co-locate with World |
| `src/Map/` | (deleted) | Fully merged into `src/world/` |
| `src/common/State_Machine/` | `src/common/StateMachine/` | Consistent naming (no underscores in folder names) |
| `src/Utilities/music_player.gd` | `src/core/music_player.gd` | It's an autoload — lives with other autoloads |
| `src/entities/Systems/Navigation/` | `src/common/Navigation/` | Cross-cutting concern used by Player and Creatures |
| `src/Utilities/icon_preview/` | `tools/icon_preview/` | Dev tool, not game source |

### What stays

`src/core/`, `src/config/`, `src/entities/`, `src/ui/`, `src/localization/` — already well-placed.

## Phase 2: Pattern Cleanup

### 2a — Remove EventBus legacy shim

Three remaining references:
- `player.gd`: `EventBus.player_spawned.emit(self)` → `PlayerEvents.player_spawned.emit(self)`
- `overworld.gd` (2 places): fallback chains trying `CreatureEvents` then `EventBus` → use `CreatureEvents` directly

After migration: remove `EventBus` from `project.godot` autoloads, delete `event_bus.gd`.

### 2b — Decompose Overworld god-class

`overworld.gd` has 35 methods doing 4 unrelated jobs. Split into:

| Node/Script | Responsibility | Approx size |
|---|---|---|
| `Overworld` (stays) | Composition root — references, delegation, player registration, input routing | ~80 lines |
| `OverworldCreatureSelectionController` (new) | Creature tap → action HUD → fight event lifecycle | ~120 lines |
| `OverworldCharacterCreatorController` (new) | Character creator open/confirm/cancel flow | ~80 lines |

Already extracted: `OverworldSessionController`, `OverworldPlayerSpawner`, `OverworldCreatureSpawner`.

### 2c — Standardize component references

Replace runtime `get_node_or_null("ComponentName")` with typed `@onready` vars:
```gdscript
# Before
var visual = get_node_or_null("PlayerVisualComponent")

# After
@onready var visual: PlayerVisualComponent = $PlayerVisualComponent
```

Apply to both Player and Creature component access patterns.

### 2d — Navigation references

Update all `preload`/`class_name` references after the `Entities/Systems/Navigation/` → `Common/Navigation/` move from Phase 1.

## Phase 3: UI Cleanup

### 3a — AdaptiveOverlayPanel adoption

Currently only 3 Windows panels extend it. MacOS and Mobile variants don't. All overlay panels across all platforms should extend `AdaptiveOverlayPanel`.

### 3b — Platform variant base classes

Extract shared behavior into base scripts in `src/ui/Common/`:
- `BaseInventoryPanel` — open/close, slot binding, toggle signal
- `BaseSystemHud` — slot input, layout lifecycle

Platform variants inherit and override only platform-specific differences.

### 3c — Consolidate debug overlay

Merge `debug_overlay.gd` (Windows) and `debug_overlay_macos.gd` into one shared debug overlay at `src/ui/Common/Debug/debug_overlay.gd`.

## Sequencing

Each phase ships as independent commits that leave the game fully functional:
- Phase 1 commits: file moves + reference updates (no logic changes)
- Phase 2 commits: one per sub-task (EventBus removal, Overworld split, component refs)
- Phase 3 commits: one per panel type (incremental, verify visually after each)

## Risks

- **Godot UID files:** moving `.gd` files requires updating corresponding `.gd.uid` files and any `.tscn` references that use `uid://` paths
- **Phase 3 visual regressions:** UI scene changes need manual visual verification on each platform
- **`project.godot` autoload paths:** must update after file moves in Phase 1
