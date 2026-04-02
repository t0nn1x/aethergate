# Codebase Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure folder layout, remove legacy patterns, and decompose god-classes so the codebase is clean, navigable, and easy to extend — with zero behavior changes.

**Architecture:** Three phases executed sequentially. Phase 1 consolidates the split `Map/`+`World/` folders and relocates misplaced files. Phase 2 removes the `EventBus` shim, decomposes the 450-line `overworld.gd` god-class, and standardizes component references. Phase 3 consolidates duplicate UI variants and extends `AdaptiveOverlayPanel` adoption.

**Tech Stack:** Godot 4.6, GDScript, `res://` and `uid://` resource paths

**Constraint:** Game behavior must remain identical after each commit.

---

## Phase 1: Folder Structure

### Task 1: Merge `src/Map/` into `src/world/`

**Files to move (use `git mv`):**
- `src/Map/main.gd` → `src/world/main.gd`
- `src/Map/main.gd.uid` → `src/world/main.gd.uid`
- `src/Map/main.tscn` → `src/world/main.tscn`
- `src/Map/Overworld/overworld.tscn` → `src/world/Overworld/overworld.tscn`
- `src/Map/Overworld/Chunks/` → `src/world/Overworld/Chunks/` (entire directory)
- `src/Map/Overworld/Shaders/` → `src/world/Overworld/Shaders/` (entire directory)
- `src/Map/Overworld/Tilesets/` → `src/world/Overworld/Tilesets/` (entire directory)
- `src/Map/Locations/` → `src/world/Locations/` (entire directory)

**Step 1: Move all files**

```bash
git mv src/Map/main.gd src/world/main.gd
git mv src/Map/main.gd.uid src/world/main.gd.uid
git mv src/Map/main.tscn src/world/main.tscn
git mv src/Map/Overworld/overworld.tscn src/world/Overworld/overworld.tscn
git mv src/Map/Overworld/Chunks src/world/Overworld/Chunks
git mv src/Map/Overworld/Shaders src/world/Overworld/Shaders
git mv src/Map/Overworld/Tilesets src/world/Overworld/Tilesets
git mv src/Map/Locations src/world/Locations
# Remove the now-empty src/Map/ directory
```

**Step 2: Update `res://` path references in code**

These files contain hardcoded `res://src/Map/` paths that must be updated:

| File | Line | Old | New |
|---|---|---|---|
| `project.godot` | `run/main_scene` | `res://src/Map/main.tscn` | `res://src/world/main.tscn` |
| `src/world/main.tscn` | ext_resource path | `res://src/Map/main.gd` | `res://src/world/main.gd` |
| `src/world/main.tscn` | ext_resource path | `res://src/Map/Overworld/overworld.tscn` | `res://src/world/Overworld/overworld.tscn` |
| `src/ui/Common/startup_splash_screen.tscn` | ext_resource path | `res://src/Map/main.tscn` | `res://src/world/main.tscn` |
| `src/world/Streaming/chunk_manager.gd:12` | `@export_dir` default | `res://src/Map/Overworld/Chunks/Midra` | `res://src/world/Overworld/Chunks/Midra` |
| `src/world/Streaming/overworld_chunk_water_shader.gd:11` | `load()` path | `res://src/Map/Overworld/Shaders/water.gdshader` | `res://src/world/Overworld/Shaders/water.gdshader` |

Also search-and-replace `res://src/Map/` → `res://src/world/` across ALL `.tscn` files in `src/world/Overworld/` (chunk scenes reference tilesets, chunk script, etc. via `path=` attributes). Godot resolves by `uid://` first, but stale `path=` values cause editor warnings.

**Step 3: Update CLAUDE.md and doc references**

Update paths in `.claude/CLAUDE.md` and `doc/plans/2026-03-09-codebase-refactor-design.md` that reference `src/Map/`.

**Step 4: Verify and commit**

```bash
# Verify no stale references remain
grep -r "src/Map/" src/ project.godot .claude/ --include="*.gd" --include="*.tscn" --include="*.godot" --include="*.md"
git add -A
git commit -m "refactor(structure): merge src/Map into src/world"
```

---

### Task 2: Rename `State_Machine` → `StateMachine`

**Files to move:**
- `src/common/State_Machine/state.gd` → `src/common/StateMachine/state.gd`
- `src/common/State_Machine/state.gd.uid` → `src/common/StateMachine/state.gd.uid`
- `src/common/State_Machine/state_machine.gd` → `src/common/StateMachine/state_machine.gd`
- `src/common/State_Machine/state_machine.gd.uid` → `src/common/StateMachine/state_machine.gd.uid`

**Step 1: Move files**

```bash
mkdir -p src/common/StateMachine
git mv "src/common/State_Machine/state.gd" src/common/StateMachine/state.gd
git mv "src/common/State_Machine/state.gd.uid" src/common/StateMachine/state.gd.uid
git mv "src/common/State_Machine/state_machine.gd" src/common/StateMachine/state_machine.gd
git mv "src/common/State_Machine/state_machine.gd.uid" src/common/StateMachine/state_machine.gd.uid
```

**Step 2: Update `res://` references**

| File | Old | New |
|---|---|---|
| `src/entities/Player/player.tscn:13` | `res://src/common/State_Machine/state_machine.gd` | `res://src/common/StateMachine/state_machine.gd` |

Search all `.tscn` files for `State_Machine` references and update them.

**Step 3: Update CLAUDE.md**

Update the "State machine" convention line in `.claude/CLAUDE.md`.

**Step 4: Verify and commit**

```bash
grep -r "State_Machine" src/ .claude/ --include="*.gd" --include="*.tscn" --include="*.md"
git add -A
git commit -m "refactor(structure): rename State_Machine to StateMachine"
```

---

### Task 3: Relocate `music_player.gd` to `src/core/`

**Files to move:**
- `src/Utilities/music_player.gd` → `src/core/music_player.gd`
- `src/Utilities/music_player.gd.uid` → `src/core/music_player.gd.uid`

**Step 1: Move files**

```bash
git mv src/Utilities/music_player.gd src/core/music_player.gd
git mv src/Utilities/music_player.gd.uid src/core/music_player.gd.uid
```

**Step 2: Update `project.godot` autoload**

Change:
```
MusicPlayer="*res://src/Utilities/music_player.gd"
```
To:
```
MusicPlayer="*res://src/core/music_player.gd"
```

**Step 3: Verify and commit**

```bash
grep -r "music_player" project.godot src/ --include="*.gd" --include="*.tscn" --include="*.godot"
git add -A
git commit -m "refactor(structure): move music_player autoload to src/core"
```

---

### Task 4: Relocate `icon_preview/` to `tools/`

**Step 1: Move directory**

```bash
git mv src/Utilities/icon_preview tools/icon_preview
```

**Step 2: Remove empty `src/Utilities/` directory if empty**

```bash
# Check if anything remains
ls src/Utilities/
# If empty, remove it
rmdir src/Utilities/
```

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor(structure): move icon_preview to tools/"
```

---

### Task 5: Relocate `src/entities/Systems/Navigation/` to `src/common/Navigation/`

**Files to move:**
- `src/entities/Systems/Navigation/creature_navigation_component.gd` (+ `.uid`)
- `src/entities/Systems/Navigation/player_move_target_blocker_component.gd` (+ `.uid`)
- `src/entities/Systems/Navigation/Policies/move_target_reject_inside_polygon_policy.gd` (+ `.uid`)
- `src/entities/Systems/Navigation/Policies/move_target_snap_to_boundary_policy.gd` (+ `.uid`)
- `src/entities/Systems/Navigation/Policies/move_target_snap_to_nav_map_policy.gd` (+ `.uid`)

**Step 1: Move files**

```bash
mkdir -p src/common/Navigation/Policies
git mv src/entities/Systems/Navigation/creature_navigation_component.gd src/common/Navigation/
git mv src/entities/Systems/Navigation/creature_navigation_component.gd.uid src/common/Navigation/
git mv src/entities/Systems/Navigation/player_move_target_blocker_component.gd src/common/Navigation/
git mv src/entities/Systems/Navigation/player_move_target_blocker_component.gd.uid src/common/Navigation/
git mv src/entities/Systems/Navigation/Policies/* src/common/Navigation/Policies/
```

**Step 2: Update any `res://` references**

Search for `Entities/Systems/Navigation` in all `.gd` and `.tscn` files and update to `Common/Navigation`.

**Step 3: Verify and commit**

```bash
grep -r "Entities/Systems/Navigation" src/ --include="*.gd" --include="*.tscn"
git add -A
git commit -m "refactor(structure): move Navigation to src/common (cross-cutting concern)"
```

---

### Task 6: Remove empty `src/common/Time/`

```bash
rm src/common/Time/.gitkeep
rmdir src/common/Time
git add -A
git commit -m "refactor(structure): remove empty Common/Time placeholder"
```

---

## Phase 2: Pattern Cleanup

### Task 7: Remove EventBus legacy shim

**Step 1: Fix `player.gd` — use `PlayerEvents` directly**

In `src/entities/Player/player.gd`, replace the `_emit_player_spawned_event` method:

```gdscript
# Before (lines 37-42):
func _emit_player_spawned_event() -> void:
	var player_events: Node = get_node_or_null("/root/PlayerEvents")
	if player_events and player_events.has_signal("player_spawned"):
		player_events.emit_signal("player_spawned", self)
		return
	EventBus.player_spawned.emit(self)

# After:
func _emit_player_spawned_event() -> void:
	PlayerEvents.player_spawned.emit(self)
```

**Step 2: Fix `overworld.gd` — remove EventBus fallbacks**

In `src/world/Overworld/overworld.gd`, replace `_get_creature_event_source`:

```gdscript
# Before (lines 230-234):
func _get_creature_event_source() -> Node:
	var creature_events: Node = get_node_or_null("/root/CreatureEvents")
	if creature_events != null:
		return creature_events
	return get_node_or_null("/root/EventBus")

# After:
func _get_creature_event_source() -> Node:
	return CreatureEvents
```

Replace `_emit_creature_fight_requested_event`:

```gdscript
# Before (lines 342-349):
func _emit_creature_fight_requested_event(creature_node: Creature) -> void:
	var creature_events: Node = get_node_or_null("/root/CreatureEvents")
	if creature_events and creature_events.has_signal("creature_fight_requested"):
		creature_events.emit_signal("creature_fight_requested", creature_node)
		return
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("creature_fight_requested"):
		event_bus.emit_signal("creature_fight_requested", creature_node)

# After:
func _emit_creature_fight_requested_event(creature_node: Creature) -> void:
	CreatureEvents.creature_fight_requested.emit(creature_node)
```

**Step 3: Search for any remaining EventBus references**

```bash
grep -r "EventBus" src/ --include="*.gd"
```

Fix any remaining references.

**Step 4: Remove EventBus autoload from `project.godot`**

Delete this line from `project.godot`:
```
EventBus="*res://src/core/event_bus.gd"
```

**Step 5: Delete `event_bus.gd`**

```bash
git rm src/core/event_bus.gd src/core/event_bus.gd.uid
```

**Step 6: Update CLAUDE.md**

Remove the `EventBus` row from the autoloads table and the "fall back to EventBus" convention.

**Step 7: Verify and commit**

```bash
grep -r "EventBus\|event_bus" src/ project.godot --include="*.gd" --include="*.tscn" --include="*.godot"
git add -A
git commit -m "refactor(events): remove EventBus legacy shim, use typed singletons only"
```

---

### Task 8: Extract `OverworldCreatureSelectionController` from `overworld.gd`

**Create:** `src/world/Overworld/overworld_creature_selection_controller.gd`

**Step 1: Create the new controller script**

Extract these methods from `overworld.gd` into the new file:
- `_wire_creature_interaction_signals()`
- `_on_creature_selected(creature_node: Node)`
- `_on_creature_deselected()`
- `_set_selected_creature(creature_node: Creature)`
- `_clear_selected_creature()`
- `_can_show_creature_action_hud() -> bool`
- `_connect_selected_creature_signals()`
- `_disconnect_selected_creature_signals()`
- `_on_selected_creature_died()`
- `_on_selected_creature_tree_exited()`
- `_on_creature_despawned(creature_node: Creature, _chunk_coord: Vector2i)`
- `_on_creature_action_hud_fight_pressed(creature_node: Creature)`
- `_emit_creature_fight_requested_event(creature_node: Creature)`
- `_on_inventory_toggled(is_open: bool)`

The new controller needs:
- `@export` references to `creature_action_hud`, `creature_spawner`, `main_screen`
- A `character_creator_visible_callback: Callable` or reference to check creator visibility
- An `initialize(...)` method called from `Overworld._ready()`

```gdscript
class_name OverworldCreatureSelectionController
extends Node

@export var creature_action_hud_path: NodePath
@export var creature_spawner_path: NodePath

var _selected_creature: Creature = null
var _creature_action_hud: CreatureActionHud
var _creature_spawner: OverworldCreatureSpawner
var _main_screen: MainScreen
var _is_overlay_visible_callback: Callable

func initialize(main_screen: MainScreen, overlay_check: Callable) -> void:
	_main_screen = main_screen
	_is_overlay_visible_callback = overlay_check
	_creature_action_hud = get_node_or_null(creature_action_hud_path) as CreatureActionHud
	_creature_spawner = get_node_or_null(creature_spawner_path) as OverworldCreatureSpawner
	_wire_creature_interaction_signals()
# ... (move all creature selection methods here)
```

**Step 2: Update `overworld.gd`**

Remove all extracted methods. Add `@onready` reference to the new controller node. Call `creature_selection_controller.initialize(...)` from `_ready()`.

**Step 3: Add the new node to `overworld.tscn`**

Add `OverworldCreatureSelectionController` as a child node of the Overworld scene.

**Step 4: Verify and commit**

```bash
git add -A
git commit -m "refactor(overworld): extract creature selection into dedicated controller"
```

---

### Task 9: Extract `OverworldCharacterCreatorController` from `overworld.gd`

**Create:** `src/world/Overworld/overworld_character_creator_controller.gd`

**Step 1: Create the new controller script**

Extract these methods:
- `_wire_character_creator_signals()`
- `_should_open_character_creator() -> bool`
- `_open_character_creator_panel()`
- `_on_character_creator_appearance_confirmed(appearance: Resource)`
- `_on_character_creator_cancelled()`
- `_get_player_profile_service() -> Node`
- `_is_character_creator_visible() -> bool`

The controller needs references to `character_creator_panel`, `main_screen`, and `session_controller`.

**Step 2: Update `overworld.gd`**

Remove extracted methods. Add `@onready` reference. Call `character_creator_controller.initialize(...)` from `_ready()`. Keep a thin `is_character_creator_visible()` proxy if other code needs it, or expose from the controller.

**Step 3: Add the new node to `overworld.tscn`**

**Step 4: Verify and commit**

```bash
git add -A
git commit -m "refactor(overworld): extract character creator flow into dedicated controller"
```

---

### Task 10: Standardize `@onready` component references in `player.gd`

**Step 1: Replace `get_node_or_null` calls with typed `@onready` vars**

In `src/entities/Player/player.gd`:

```gdscript
# Add at top of class:
@onready var visual_component: PlayerVisualComponent = $PlayerVisualComponent

# Replace in apply_appearance():
# Before: var visual_component: Node = get_node_or_null("PlayerVisualComponent")
# After: use the @onready var directly

# Replace in set_weapon_visual():
# Before: var visual_component: Node = get_node_or_null("PlayerVisualComponent")
# After: use the @onready var directly
```

**Step 2: Verify and commit**

```bash
git add -A
git commit -m "refactor(player): use @onready typed refs instead of runtime get_node_or_null"
```

---

## Phase 3: UI Cleanup

### Task 11: Delete empty platform HUD variants

`system_hud_macos.gd` and `system_hud_mobile.gd` are empty — they just `extends SystemHud` with no overrides.

**Step 1: Check if `.tscn` scenes reference these scripts**

Search for references to determine if removal is safe or if the `.tscn` files need updating.

**Step 2: Update `.tscn` files to reference `SystemHud` directly**

Point the MacOS and Mobile system HUD scenes at `src/ui/Windows/Hud/SystemHud/system_hud.gd` (or move `system_hud.gd` to `src/ui/Common/Hud/` first).

**Step 3: Delete empty scripts**

```bash
git rm src/ui/MacOS/Hud/SystemHud/system_hud_macos.gd
git rm src/ui/Mobile/Hud/SystemHud/system_hud_mobile.gd
```

**Step 4: Verify and commit**

```bash
git add -A
git commit -m "refactor(ui): remove empty platform HUD variants, use shared SystemHud"
```

---

### Task 12: Consolidate debug overlay

`debug_overlay_macos.gd` only sets `screen_padding` — this can be a platform config instead.

**Step 1: Move `debug_overlay.gd` to shared location**

```bash
mkdir -p src/ui/Common/Debug
git mv src/ui/Windows/Debug/debug_overlay.gd src/ui/Common/Debug/debug_overlay.gd
git mv src/ui/Windows/Debug/debug_overlay.gd.uid src/ui/Common/Debug/debug_overlay.gd.uid
```

**Step 2: Add platform-aware padding to `DebugOverlay`**

In `debug_overlay.gd`, add platform detection for padding:

```gdscript
func _ready() -> void:
	if _is_macos():
		screen_padding = Vector2(12.0, 12.0)
	# ... rest of _ready
```

Or make `screen_padding` an `@export` so each `.tscn` scene can set it.

**Step 3: Update MacOS debug overlay `.tscn`** to use the shared script. Delete `debug_overlay_macos.gd`.

**Step 4: Move debug providers to shared location**

```bash
git mv src/ui/Windows/Debug/Providers src/ui/Common/Debug/Providers
```

**Step 5: Verify and commit**

```bash
git add -A
git commit -m "refactor(ui): consolidate debug overlay into src/ui/Common/Debug"
```

---

### Task 13: Update CLAUDE.md and documentation

**Step 1: Update `.claude/CLAUDE.md`**

- Update all file paths that changed (autoloads table, architecture tree, etc.)
- Remove EventBus references
- Update StateMachine path
- Update folder descriptions

**Step 2: Update `doc/DESCRIPTION.md`**

Reflect the new folder structure.

**Step 3: Commit**

```bash
git add -A
git commit -m "docs: update CLAUDE.md and DESCRIPTION.md for new project structure"
```

---

## Verification Checklist

After all tasks, verify:
- [ ] `grep -r "src/Map/" src/ project.godot` returns no hits
- [ ] `grep -r "State_Machine" src/` returns no hits
- [ ] `grep -r "EventBus" src/ project.godot` returns no hits
- [ ] `grep -r "Utilities/music_player" src/ project.godot` returns no hits
- [ ] `grep -r "Entities/Systems/Navigation" src/` returns no hits
- [ ] Game launches and reaches overworld without errors
- [ ] Creature catalog validation test passes: `godot4 --headless --path . --script res://src/entities/Creatures/Tests/run_creature_catalog_validation.gd`
- [ ] Creature spawn zone test passes: `godot4 --headless --path . --script res://src/entities/Creatures/Tests/run_creature_spawn_zone_test.gd`
