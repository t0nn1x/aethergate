# UI Builder — Design Spec

**Date:** 2026-03-12
**Branch:** feature/ui-builder (to be created from current HEAD)
**Status:** Approved

---

## Overview

A Godot `EditorPlugin` that adds a "UI Builder" main-screen tab to the editor. Lets you visually drag, place, move, and resize UI elements for the three Aethergate platform variants (Windows, macOS, Mobile) without touching GDScript. All elements are rendered through Godot's real pipeline so 9-slice panels look exactly as they will in-game.

---

## Decisions Made

| Question | Answer |
|---|---|
| Where does it live? | Godot EditorPlugin (`addons/`) — zero runtime footprint |
| Workflow | Both build from scratch AND edit existing scenes |
| Palette contents | Two tiers: Aethergate components + Godot primitives |
| Platform variants | Single canvas, toggle between Windows / macOS / Mobile |
| Save / UiManager integration | New `UiLayoutConfig` resource — no GDScript patching |
| Inspector | Rect (X/Y/W/H) + component `@export` vars |
| Scope | Aethergate registered slots only (SystemHud, InventoryPanel, MainScreen) |
| Editor layout | Main screen tab (like TileMap editor) — palette left, canvas center, inspector right |

---

## File Structure

```
addons/aethergate_ui_builder/
  plugin.cfg
  plugin.gd                              ← EditorPlugin: registers main screen
  ui_builder_main_screen.gd/.tscn        ← root Control, hosts 3 panels + toolbar
  panels/
    palette/
      ui_builder_palette.gd/.tscn        ← two-tier widget list, emits drag events
    canvas/
      ui_builder_canvas.gd/.tscn         ← SubViewport + SelectionOverlay
    inspector/
      ui_builder_inspector.gd/.tscn      ← dynamic property editor
  resources/
    ui_builder_slot_registry.gd          ← static list of known slots + platforms

src/Ui/Common/Resources/
  ui_layout_config.gd                    ← Resource: slot→platform→scene_path
  ui_layout_config.tres                  ← live data file, written by builder
```

---

## Architecture

### Canvas (the core)

Two layers stacked:

1. **`SubViewport`** (inside `SubViewportContainer`) — renders at full platform resolution using Godot's real rendering pipeline. Actual UI nodes live here. 9-slice, themes, and responsive layout all work exactly as in-game.

2. **`SelectionOverlay`** (transparent `Control`, `mouse_filter = PASS`) — sits on top of the SubViewport at screen coordinates. Draws selection rect, 8 resize handles, hover highlight, drop ghost. Receives all mouse input.

These layers never mix: the SubViewport is pure rendering, the overlay is pure editor gizmos.

### Palette

Two sections:
- **Aethergate** (purple) — component scenes registered in `UiBuilderSlotRegistry` (SystemHud, InventoryPanel, etc.)
- **Godot Primitives** (green) — Panel, NinePatchRect, HBoxContainer, VBoxContainer, Label, Button, TextureRect

Drag from palette → ghost element follows cursor → drop instantiates into SubViewport at snapped position.

### Inspector

Dynamically built when a node is selected. Two collapsible sections:
- **Rect** — X, Y, W, H (editable, updates node in SubViewport live)
- **Exports** — reads `get_script().get_script_property_list()`, renders appropriate controls per type (int, float, bool, String, Texture2D)

### Toolbar

```
[Slot: SystemHud ▼]  |  [Windows] [macOS] [Mobile]  |  [↩ Undo] [↪ Redo]  |  [💾 Save]
```

- **Slot picker** — dropdown populated from `UiBuilderSlotRegistry`
- **Platform toggle** — swaps SubViewport size + loads/saves the per-platform scene
- **Undo/Redo** — `EditorUndoRedoManager`
- **Save** — writes `.tscn` + updates `ui_layout_config.tres`

---

## Interaction Flows

### ① Drag from palette → place
1. Palette emits `node_requested(scene_path)`
2. Canvas shows ghost element under cursor
3. On drop: instantiate scene into SubViewport, set `position` (snapped to 8px grid)
4. Push `add_node` action to `EditorUndoRedoManager`

### ② Click to select
1. `SelectionOverlay` hit-tests SubViewport node rects at cursor position
2. Finds topmost node whose rect contains the point
3. Emits `node_selected(node)`
4. Overlay draws 8-handle selection box
5. Inspector populates

### ③ Drag to move
1. Mouse down on selected node body (not a handle)
2. Track position delta each `_input` event, update node `position` in SubViewport
3. Snap to 8px grid (hold Ctrl to disable snap)
4. On mouse release: push `move_node` action to UndoRedo

### ④ Drag handle to resize
1. Mouse down on one of 8 handles (corners + edge midpoints)
2. Resize node `size` (adjust `position` for top/left handles so opposite edge stays fixed)
3. `NinePatchRect`/`Panel` stretches live — real 9-slice rendering in SubViewport
4. Minimum size enforced (≥ 16px per axis)
5. On mouse release: push `resize_node` action to UndoRedo

### ⑤ Save
1. Pack SubViewport scene root → `PackedScene`
2. Write `.tscn` to the correct platform folder (e.g. `src/Ui/Windows/Hud/SystemHud/system_hud.tscn`)
3. Update `ui_layout_config.tres` with the path for this slot+platform
4. `ResourceSaver.save()` both resources
5. `UiManager` picks up changes on next game run — no code editing needed

### ⑥ Edit existing scene
Same as above — on slot+platform selection:
- If a path exists in `ui_layout_config.tres` and the file is on disk → load scene into SubViewport
- Otherwise → start with empty SubViewport

No special "edit mode" — it's the same code path.

---

## UiLayoutConfig Resource

```gdscript
# src/Ui/Common/Resources/ui_layout_config.gd
class_name UiLayoutConfig
extends Resource

# slot_id → { "windows": path, "macos": path, "mobile": path }
@export var slots: Dictionary = {}
```

---

## UiManager Refactor

`UiManager` gains one export:
```gdscript
@export var layout_config: UiLayoutConfig
```

The three `_resolve_*_scene()` methods collapse into one:
```gdscript
func _resolve_scene(slot_id: StringName, profile: StringName) -> PackedScene:
    var slot: Dictionary = layout_config.slots.get(slot_id, {})
    var path: String = slot.get(profile, slot.get("windows", ""))
    if path.is_empty():
        return null
    return load(path)
```

All existing hardcoded `const` preloads and `match ui_profile` blocks are removed.

---

## Slot Registry

```gdscript
# addons/aethergate_ui_builder/resources/ui_builder_slot_registry.gd
class_name UiBuilderSlotRegistry

const SLOTS: Array[Dictionary] = [
    { "id": "system_hud",      "label": "SystemHud",      "platforms": ["windows", "macos", "mobile"] },
    { "id": "inventory_panel", "label": "InventoryPanel",  "platforms": ["windows", "macos", "mobile"] },
    { "id": "main_screen",     "label": "MainScreen",      "platforms": ["windows", "macos"] },
]
```

Adding a new slot requires only adding an entry here — it automatically appears in the toolbar dropdown and the palette.

---

## Out of Scope

- Editing arbitrary `.tscn` files (only registered Aethergate slots)
- In-game runtime editor mode
- Multi-select / group operations
- Animations or tweens
- Parent-child node reparenting within the builder

---

## Acceptance Criteria

- [ ] "UI Builder" tab appears in Godot editor next to 2D / 3D / Script
- [ ] Dragging a component from the palette places it on the canvas at the correct position
- [ ] Selecting a node shows 8 resize handles; dragging handles resizes with live 9-slice rendering
- [ ] Moving a node updates its position with 8px grid snap
- [ ] Undo/Redo works for place, move, resize, delete
- [ ] Platform toggle (Windows/macOS/Mobile) changes the SubViewport size and loads the correct scene
- [ ] Save writes the `.tscn` and updates `ui_layout_config.tres`
- [ ] `UiManager` uses `UiLayoutConfig` resource — no hardcoded const preloads
- [ ] Plugin disabled/removed has zero effect on a running game build
