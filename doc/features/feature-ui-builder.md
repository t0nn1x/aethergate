# Implementation Plan: UI Builder

Branch: feature/ui-builder
Created: 2026-03-12

## Settings
- Testing: yes (headless)
- Logging: minimal

## Scope
Godot EditorPlugin "UI Builder" main-screen tab for drag-and-drop placement, movement,
and 9-slice-aware resizing of UI layouts across Windows / macOS / Mobile platform variants.
Replaces hardcoded `const` preloads in `UiManager` with a `UiLayoutConfig` resource.

## Commit Plan
- Commit 1: `feat(ui-builder): add UiLayoutConfig resource with platform slot lookup`
- Commit 2: `feat(ui-builder): add initial ui_layout_config.tres with current scene paths`
- Commit 3: `refactor(ui-manager): replace hardcoded const preloads with UiLayoutConfig resource lookup`
- Commit 4: `feat(ui-builder): add EditorPlugin skeleton (plugin.cfg + plugin.gd)`
- Commit 5: `feat(ui-builder): add UiBuilderSlotRegistry with slot + platform data`
- Commit 6: `feat(ui-builder): add main screen shell with 3-panel layout`
- Commit 7: `feat(ui-builder): canvas SubViewport with SelectionOverlay`
- Commit 8: `feat(ui-builder): palette with Aethergate components and Godot primitives`
- Commit 9: `feat(ui-builder): inspector with Rect and @export property editor`

## Tasks

### Phase 1: Data Layer (Chunk 1)
- [x] Task 1: Create UiLayoutConfig resource (`src/Ui/Common/Resources/ui_layout_config.gd`)
- [x] Task 2: Create ui_layout_config.tres with current scene paths
- [x] Task 3: Refactor UiManager to use UiLayoutConfig

### Phase 2: Plugin Skeleton (Chunk 2)
- [x] Task 4: Plugin metadata and entry point (`plugin.cfg` + `plugin.gd`)
- [x] Task 5: Slot registry (`slot_registry.gd`)
- [x] Task 6: Main screen shell (3-panel layout)

### Phase 3: Toolbar + Canvas (Chunk 3)
- [x] Task 7: Toolbar (slot picker + platform toggle) — built into main screen
- [x] Task 8: Canvas — SubViewport + scene loading
- [x] Task 9: SelectionOverlay — hit testing, selection, move, resize

### Phase 4: Integration (Chunk 4)
- [x] Task 10: Undo/Redo integration — built into main screen + plugin.gd

### Phase 5: Palette + Inspector + Save (Chunk 5)
- [x] Task 11: Palette — two-tier widget list
- [x] Task 12: Inspector — Rect + export properties
- [x] Task 13: Save flow — built into main screen

## Acceptance Criteria
- "UI Builder" tab appears in Godot editor next to 2D / 3D / Script
- Dragging a component from palette places it on the canvas
- Selecting a node shows 8 resize handles; dragging handles resizes with live 9-slice rendering
- Moving a node respects 8px grid snap; Ctrl disables snap
- Undo/Redo works for place, move, resize
- Platform toggle changes SubViewport size and loads correct scene
- Save writes .tscn and updates ui_layout_config.tres
- UiManager uses UiLayoutConfig resource — no hardcoded const preloads
- Plugin disabled/removed has zero effect on running game build

## Risks / Notes
- The `.tscn` files for the plugin scenes were created manually (not via the Godot editor's scene builder), so they may need minor adjustments when first opened in the editor (layout anchors, etc.)
- The SelectionOverlay mouse_filter must be PASS (0) to receive input while letting clicks through to the scroll background
- `EditorUndoRedoManager` is only available in the editor context; headless tests for undo/redo are not feasible
