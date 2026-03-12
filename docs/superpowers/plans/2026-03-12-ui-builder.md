# UI Builder Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Godot EditorPlugin "UI Builder" main-screen tab for drag-and-drop placement, movement, and 9-slice-aware resizing of UI layouts across Windows / macOS / Mobile platform variants.

**Architecture:** Main-screen EditorPlugin tab (palette left / canvas center / inspector right). Canvas uses a `SubViewport` for real Godot rendering plus a transparent `SelectionOverlay` Control for editor gizmos. A new `UiLayoutConfig` resource replaces hardcoded `const` preloads in `UiManager` — saving a layout writes the `.tscn` and updates the resource; no GDScript editing ever needed again.

**Tech Stack:** Godot 4.6 GDScript, `EditorPlugin`, `SubViewport`, `SubViewportContainer`, `EditorUndoRedoManager`, `ResourceSaver`, `PackedScene`

---

## File Map

### New files (runtime)
| File | Responsibility |
|---|---|
| `src/Ui/Common/Resources/ui_layout_config.gd` | `UiLayoutConfig` resource: slot → platform → scene path |
| `src/Ui/Common/Resources/ui_layout_config.tres` | Live data file; written by builder on save |

### Modified files (runtime)
| File | Change |
|---|---|
| `src/Ui/Common/ui_manager.gd` | Add `layout_config` export; replace 3 `_resolve_*_scene()` methods with one `_resolve_scene()` |
| `src/World/Overworld/overworld.tscn` | Assign `layout_config` resource to UiManager node |

### New files (plugin — zero runtime footprint)
| File | Responsibility |
|---|---|
| `addons/aethergate_ui_builder/plugin.cfg` | Plugin metadata |
| `addons/aethergate_ui_builder/plugin.gd` | `EditorPlugin`: registers main screen, routes undo/redo |
| `addons/aethergate_ui_builder/ui_builder_main_screen.gd/.tscn` | Root Control: toolbar + 3-panel layout |
| `addons/aethergate_ui_builder/slot_registry.gd` | Static list of known slots + platform/path data |
| `addons/aethergate_ui_builder/panels/palette/ui_builder_palette.gd/.tscn` | Two-tier palette; emits `node_drag_requested` |
| `addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.gd/.tscn` | `SubViewportContainer` + `SubViewport` + scene load/save |
| `addons/aethergate_ui_builder/panels/canvas/selection_overlay.gd` | Transparent Control: hit-test, draw handles, drive move/resize |
| `addons/aethergate_ui_builder/panels/inspector/ui_builder_inspector.gd/.tscn` | Dynamic property editor for selected node |

### Tests (headless)
| File | What it tests |
|---|---|
| `src/Ui/Common/Resources/Tests/test_ui_layout_config.gd` | Resource creation, slot lookup, fallback to "windows" |
| `src/Ui/Common/Tests/test_ui_manager_resolve.gd` | `_resolve_scene()` returns correct path per slot+profile |

---

## Chunk 1: Data layer — UiLayoutConfig + UiManager refactor

**Goal:** Replace hardcoded `const` preloads in `UiManager` with a resource-driven lookup. Game still runs identically.

---

### Task 1: Create UiLayoutConfig resource

**Files:**
- Create: `src/Ui/Common/Resources/ui_layout_config.gd`

- [ ] **Step 1: Create the resource class**

```gdscript
# src/Ui/Common/Resources/ui_layout_config.gd
class_name UiLayoutConfig
extends Resource

## Maps slot_id → { "windows": path, "macos": path, "mobile": path }
## Missing platform keys fall back to "windows".
@export var slots: Dictionary = {}


func get_scene_path(slot_id: StringName, platform: StringName) -> String:
	var slot: Dictionary = slots.get(slot_id, {})
	if slot.has(platform):
		return slot[platform]
	return slot.get(&"windows", "")
```

- [ ] **Step 2: Write a headless test script**

```gdscript
# src/Ui/Common/Resources/Tests/test_ui_layout_config.gd
extends SceneTree

func _init() -> void:
	var config := UiLayoutConfig.new()
	config.slots = {
		&"system_hud": {
			&"windows": "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn",
			&"macos":   "res://src/Ui/MacOS/Hud/SystemHud/system_hud_macos.tscn",
			&"mobile":  "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn",
		}
	}

	# exact match
	assert(config.get_scene_path(&"system_hud", &"windows") == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "windows path")
	assert(config.get_scene_path(&"system_hud", &"mobile")  == "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn", "mobile path")
	# fallback to windows when platform key missing
	assert(config.get_scene_path(&"system_hud", &"unknown") == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "fallback")
	# missing slot returns empty string
	assert(config.get_scene_path(&"missing_slot", &"windows") == "", "missing slot")

	print("[PASS] UiLayoutConfig tests")
	quit(0)
```

- [ ] **Step 3: Run the test**

```bash
godot4 --headless --path . --script res://src/Ui/Common/Resources/Tests/test_ui_layout_config.gd
```

Expected: `[PASS] UiLayoutConfig tests`

- [ ] **Step 4: Commit**

```bash
git add src/Ui/Common/Resources/ui_layout_config.gd src/Ui/Common/Resources/Tests/test_ui_layout_config.gd
git commit -m "feat(ui-builder): add UiLayoutConfig resource with platform slot lookup"
```

---

### Task 2: Create ui_layout_config.tres with current scene paths

**Files:**
- Create: `src/Ui/Common/Resources/ui_layout_config.tres`

- [ ] **Step 1: Create the .tres file**

Note: `.tres` Dictionary keys must be plain quoted strings — `&""` StringName syntax is not valid in `.tres` files.

```text
# src/Ui/Common/Resources/ui_layout_config.tres
[gd_resource type="Resource" script_class="UiLayoutConfig" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/Ui/Common/Resources/ui_layout_config.gd" id="1_config"]

[resource]
script = ExtResource("1_config")
slots = {
"system_hud": {
"windows": "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn",
"macos": "res://src/Ui/MacOS/Hud/SystemHud/system_hud_macos.tscn",
"mobile": "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn"
},
"main_screen": {
"windows": "res://src/Ui/Windows/Gui/MainScreen/main_screen.tscn",
"macos": "res://src/Ui/MacOS/Gui/MainScreen/main_screen_macos.tscn"
},
"inventory_panel": {
"windows": "res://src/Ui/Windows/Inventory/inventory_panel.tscn",
"macos": "res://src/Ui/MacOS/Inventory/inventory_panel_macos.tscn",
"mobile": "res://src/Ui/Mobile/Inventory/inventory_panel_mobile.tscn"
}
}
```

Godot's `ResourceSaver` will reformat and canonicalise the file when it next saves it; the plain-string keys will be stored correctly and the runtime `get_scene_path()` uses `StringName` comparison which matches plain strings at runtime.

- [ ] **Step 2: Open the project in Godot editor and verify the resource loads without errors**

Open `res://src/Ui/Common/Resources/ui_layout_config.tres` in the FileSystem dock. It should show a Resource with `slots` Dictionary populated. No parse errors in the Output panel.

- [ ] **Step 3: Commit**

```bash
git add src/Ui/Common/Resources/ui_layout_config.tres
git commit -m "feat(ui-builder): add initial ui_layout_config.tres with current scene paths"
```

---

### Task 3: Refactor UiManager to use UiLayoutConfig

**Files:**
- Modify: `src/Ui/Common/ui_manager.gd`

- [ ] **Step 1: Add layout_config export and new _resolve_scene method**

In `ui_manager.gd`, make the following changes:

Remove these **7** `const` lines (keep `INVENTORY_CLOSE_ICON` **and** keep `DEBUG_OVERLAY_WINDOWS_SCENE` / `DEBUG_OVERLAY_MACOS_SCENE` — they are still used by `_resolve_debug_overlay_scene` which stays unchanged):
```gdscript
const SYSTEM_HUD_WINDOWS_SCENE: PackedScene = preload(...)
const SYSTEM_HUD_MACOS_SCENE: PackedScene = preload(...)
const SYSTEM_HUD_MOBILE_SCENE: PackedScene = preload(...)
const MAIN_SCREEN_WINDOWS_SCENE: PackedScene = preload(...)
const MAIN_SCREEN_MACOS_SCENE: PackedScene = preload(...)
const INVENTORY_PANEL_WINDOWS_SCENE: PackedScene = preload(...)
const INVENTORY_PANEL_MACOS_SCENE: PackedScene = preload(...)
const INVENTORY_PANEL_MOBILE_SCENE: PackedScene = preload(...)
```

Add export after the remaining `const`:
```gdscript
@export var layout_config: UiLayoutConfig
```

Replace `_resolve_system_hud_scene`, `_resolve_main_screen_scene`, and `_resolve_inventory_panel_scene` with one method:
```gdscript
func _resolve_slot_scene(slot_id: StringName, ui_profile: StringName) -> PackedScene:
	if layout_config == null:
		push_error("[UiManager] layout_config is not assigned")
		return null
	var path: String = layout_config.get_scene_path(slot_id, ui_profile)
	if path.is_empty():
		return null
	return load(path) as PackedScene
```

Update `_apply_platform_ui_variants` to call the new method. Replace the three `_replace_overlay_node` lines that reference the old resolve methods:
```gdscript
var resolved_main_screen: Node = _replace_overlay_node(main_screen_path, _resolve_main_screen_scene(ui_profile))
var resolved_system_hud: Node = _replace_overlay_node(system_hud_path, _resolve_system_hud_scene(ui_profile))
var resolved_inventory_panel: Node = _replace_overlay_node(inventory_panel_path, _resolve_inventory_panel_scene(ui_profile))
```
With:
```gdscript
var resolved_main_screen: Node = _replace_overlay_node(main_screen_path, _resolve_slot_scene(&"main_screen", ui_profile))
var resolved_system_hud: Node = _replace_overlay_node(system_hud_path, _resolve_slot_scene(&"system_hud", ui_profile))
var resolved_inventory_panel: Node = _replace_overlay_node(inventory_panel_path, _resolve_slot_scene(&"inventory_panel", ui_profile))
```

The five `if resolved_*:` reassignment lines that follow those three lines **stay unchanged** — do not remove them:
```gdscript
if resolved_main_screen:
    _main_screen = resolved_main_screen as MainScreen
if resolved_system_hud:
    _system_hud = resolved_system_hud as SystemHud
if resolved_inventory_panel:
    _inventory_panel = resolved_inventory_panel as InventoryPanel
```

Keep `_resolve_debug_overlay_scene` and both `DEBUG_OVERLAY_*` consts unchanged (debug overlay is not a builder-managed slot).

- [ ] **Step 2: Write a headless test for _resolve_scene logic**

```gdscript
# src/Ui/Common/Tests/test_ui_manager_resolve.gd
extends SceneTree

func _init() -> void:
	var config := UiLayoutConfig.new()
	config.slots = {
		&"system_hud": {
			&"windows": "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn",
			&"mobile":  "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn",
		}
	}

	# windows profile → windows scene path
	var path_w: String = config.get_scene_path(&"system_hud", &"windows")
	assert(path_w == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "windows")

	# mobile profile → mobile scene path
	var path_m: String = config.get_scene_path(&"system_hud", &"mobile")
	assert(path_m == "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn", "mobile")

	# macos profile → fallback to windows (no macos key in this test config)
	var path_mac: String = config.get_scene_path(&"system_hud", &"macos")
	assert(path_mac == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "macos fallback")

	print("[PASS] UiManager resolve tests")
	quit(0)
```

- [ ] **Step 3: Run the test**

```bash
godot4 --headless --path . --script res://src/Ui/Common/Tests/test_ui_manager_resolve.gd
```

Expected: `[PASS] UiManager resolve tests`

- [ ] **Step 4: Assign layout_config in overworld.tscn**

Open `src/World/Overworld/overworld.tscn` in the Godot editor. Select the `UiManager` node in the Scene tree. In the Inspector, find the new `Layout Config` property. Drag `res://src/Ui/Common/Resources/ui_layout_config.tres` from the FileSystem dock onto it.

- [ ] **Step 5: Run the game and verify it still works**

Press F5. The game should start normally. The HUD, inventory panel, and main screen should all appear as before. Check the Output panel — no errors.

- [ ] **Step 6: Commit**

```bash
git add src/Ui/Common/ui_manager.gd src/World/Overworld/overworld.tscn src/Ui/Common/Tests/test_ui_manager_resolve.gd
git commit -m "refactor(ui-manager): replace hardcoded const preloads with UiLayoutConfig resource lookup"
```

---

## Chunk 2: Plugin skeleton + slot registry + main screen shell

**Goal:** "UI Builder" tab appears in the Godot editor. Clicking it shows a placeholder with the 3-panel layout. No interaction yet.

---

### Task 4: Plugin metadata and entry point

**Files:**
- Create: `addons/aethergate_ui_builder/plugin.cfg`
- Create: `addons/aethergate_ui_builder/plugin.gd`

- [ ] **Step 1: Create plugin.cfg**

```ini
[plugin]

name="Aethergate UI Builder"
description="Drag-and-drop UI layout editor for Aethergate platform variants"
author="Aethergate"
version="1.0.0"
script="plugin.gd"
```

- [ ] **Step 2: Create plugin.gd**

```gdscript
# addons/aethergate_ui_builder/plugin.gd
@tool
extends EditorPlugin

# Uses load() (not preload) — the .tscn is created in Task 6.
# preload would fail at parse time if the file doesn't yet exist.
const MAIN_SCREEN_SCENE_PATH: String = \
	"res://addons/aethergate_ui_builder/ui_builder_main_screen.tscn"

var _main_screen: Control


func _enter_tree() -> void:
	var scene: PackedScene = load(MAIN_SCREEN_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("[UiBuilder] Main screen scene not found — complete Task 6 first.")
		return
	_main_screen = scene.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_main_screen)
	_make_visible(false)


func _exit_tree() -> void:
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null


func _has_main_screen() -> bool:
	return true


func _make_visible(p_visible: bool) -> void:
	if _main_screen:
		_main_screen.visible = p_visible


func _get_plugin_name() -> String:
	return "UI Builder"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(&"Node2D", &"EditorIcons")
```

- [ ] **Step 3: Commit (plugin files only — do NOT enable the plugin yet)**

The plugin uses `load()` so it won't crash, but the "UI Builder" tab will not appear until `ui_builder_main_screen.tscn` is created in Task 6. Enable the plugin only after Task 6 is complete.

```bash
git add addons/aethergate_ui_builder/plugin.cfg addons/aethergate_ui_builder/plugin.gd
git commit -m "feat(ui-builder): add EditorPlugin skeleton (plugin.cfg + plugin.gd)"
```

---

### Task 5: Slot registry

**Files:**
- Create: `addons/aethergate_ui_builder/slot_registry.gd`

- [ ] **Step 1: Create the registry**

```gdscript
# addons/aethergate_ui_builder/slot_registry.gd
@tool
class_name UiBuilderSlotRegistry

## Platform resolutions used for canvas SubViewport sizing.
const PLATFORM_SIZES: Dictionary = {
	&"windows": Vector2(1920.0, 1080.0),
	&"macos":   Vector2(1920.0, 1080.0),
	&"mobile":  Vector2(1080.0, 1920.0),
}

## Folder name for each platform (used in default save paths).
## Note: "macos".capitalize() returns "Macos" not "MacOS", so explicit mapping is required.
const PLATFORM_FOLDER_NAMES: Dictionary = {
	&"windows": "Windows",
	&"macos":   "MacOS",
	&"mobile":  "Mobile",
}

## Known UI slots. Each entry drives the toolbar slot picker + palette Aethergate tier.
## Add new entries here when a new slot is created.
const SLOTS: Array[Dictionary] = [
	{
		"id":        &"system_hud",
		"label":     "SystemHud",
		"platforms": [&"windows", &"macos", &"mobile"],
	},
	{
		"id":        &"inventory_panel",
		"label":     "InventoryPanel",
		"platforms": [&"windows", &"macos", &"mobile"],
	},
	{
		"id":        &"main_screen",
		"label":     "MainScreen",
		"platforms": [&"windows", &"macos"],
	},
]


## Returns the slot Dictionary for a given slot_id, or {} if not found.
static func find_slot(slot_id: StringName) -> Dictionary:
	for slot in SLOTS:
		if slot.id == slot_id:
			return slot
	return {}


## Returns the list of platform StringNames available for a slot_id.
static func platforms_for_slot(slot_id: StringName) -> Array:
	var slot: Dictionary = find_slot(slot_id)
	return slot.get("platforms", [&"windows"])
```

- [ ] **Step 2: Commit**

```bash
git add addons/aethergate_ui_builder/slot_registry.gd
git commit -m "feat(ui-builder): add UiBuilderSlotRegistry with slot + platform data"
```

---

### Task 6: Main screen shell (3-panel layout, no interaction)

**Files:**
- Create: `addons/aethergate_ui_builder/ui_builder_main_screen.gd`
- Create: `addons/aethergate_ui_builder/ui_builder_main_screen.tscn`

- [ ] **Step 1: Create the scene in Godot editor**

In the Godot editor FileSystem dock, right-click `addons/aethergate_ui_builder/` → New Scene.

Build this node tree:
```
UiBuilderMainScreen (Control)              ← script: ui_builder_main_screen.gd
  VBoxContainer (VBoxContainer)            ← size_flags: fill+expand
    Toolbar (HBoxContainer)                ← name="Toolbar"; custom_minimum_size.y = 36
    HSeparator
    ContentRow (HBoxContainer)             ← size_flags: fill+expand
      PalettePanel (PanelContainer)        ← custom_minimum_size.x = 180
        Palette (placeholder Label)        ← text="Palette"
      VSeparator
      CanvasPanel (PanelContainer)         ← size_flags: fill+expand (h+v)
        Canvas (placeholder Label)         ← text="Canvas"
      VSeparator
      InspectorPanel (PanelContainer)      ← custom_minimum_size.x = 200
        Inspector (placeholder Label)      ← text="Inspector"
```

Save as `addons/aethergate_ui_builder/ui_builder_main_screen.tscn`.

- [ ] **Step 2: Create the script**

```gdscript
# addons/aethergate_ui_builder/ui_builder_main_screen.gd
@tool
extends Control


func _ready() -> void:
	# Fill the editor viewport
	anchor_right = 1.0
	anchor_bottom = 1.0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

- [ ] **Step 3: Enable the plugin**

In the Godot editor: Project → Project Settings → Plugins → find "Aethergate UI Builder" → enable it.

- [ ] **Step 4: Verify the tab appears**

Click the "UI Builder" tab at the top of the editor (next to 2D / 3D / Script). The main screen should appear with three placeholder panels side by side. No errors in Output.

- [ ] **Step 5: Commit**

```bash
git add addons/aethergate_ui_builder/ui_builder_main_screen.gd addons/aethergate_ui_builder/ui_builder_main_screen.tscn
git commit -m "feat(ui-builder): add main screen shell with 3-panel layout"
```

---

## Chunk 3: Toolbar + Canvas — SubViewport rendering

**Goal:** Toolbar lets you pick a slot + platform. Canvas loads the corresponding scene into a SubViewport and renders it at the correct resolution. Zoom/pan works.

---

### Task 7: Toolbar (slot picker + platform toggle)

**Files:**
- Modify: `addons/aethergate_ui_builder/ui_builder_main_screen.gd`
- Modify: `addons/aethergate_ui_builder/ui_builder_main_screen.tscn`

- [ ] **Step 1: Replace Toolbar placeholder with real controls in the scene**

In the scene, replace the `Toolbar (HBoxContainer)` children with:
```
Toolbar (HBoxContainer)
  Label "Slot:"                    ← text="Slot:"
  SlotPicker (OptionButton)        ← name="%SlotPicker"; unique_name_in_owner=true
  VSeparator
  PlatformToggle (HBoxContainer)   ← name="%PlatformToggle"; unique_name_in_owner=true
    (buttons added at runtime by script)
  VSeparator
  UndoBtn (Button)                 ← name="%UndoBtn"; text="↩ Undo"
  RedoBtn (Button)                 ← name="%RedoBtn"; text="↪ Redo"
  Spacer (Control)                 ← size_flags_horizontal = SIZE_EXPAND_FILL
  SaveBtn (Button)                 ← name="%SaveBtn"; text="💾 Save"
```

- [ ] **Step 2: Wire toolbar in script**

```gdscript
# addons/aethergate_ui_builder/ui_builder_main_screen.gd
@tool
extends Control

signal slot_changed(slot_id: StringName, platform: StringName)

@onready var _slot_picker: OptionButton = %SlotPicker
@onready var _platform_toggle: HBoxContainer = %PlatformToggle
@onready var _undo_btn: Button = %UndoBtn
@onready var _redo_btn: Button = %RedoBtn
@onready var _save_btn: Button = %SaveBtn

var _active_slot_id: StringName = &""
var _active_platform: StringName = &"windows"
var _platform_buttons: Dictionary = {}  # platform → Button


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_populate_slot_picker()
	_slot_picker.item_selected.connect(_on_slot_selected)
	_undo_btn.pressed.connect(_on_undo_pressed)
	_redo_btn.pressed.connect(_on_redo_pressed)
	_save_btn.pressed.connect(_on_save_pressed)


func _populate_slot_picker() -> void:
	_slot_picker.clear()
	for slot: Dictionary in UiBuilderSlotRegistry.SLOTS:
		_slot_picker.add_item(slot.label)
	if UiBuilderSlotRegistry.SLOTS.size() > 0:
		_select_slot(0)


func _select_slot(index: int) -> void:
	var slot: Dictionary = UiBuilderSlotRegistry.SLOTS[index]
	_active_slot_id = slot.id
	_rebuild_platform_buttons(slot.platforms)
	_select_platform(_active_platform if _active_platform in slot.platforms else slot.platforms[0])


func _rebuild_platform_buttons(platforms: Array) -> void:
	for child in _platform_toggle.get_children():
		child.queue_free()
	_platform_buttons.clear()
	for platform: StringName in platforms:
		var btn := Button.new()
		btn.text = platform.capitalize()
		btn.toggle_mode = true
		btn.pressed.connect(_on_platform_pressed.bind(platform))
		_platform_toggle.add_child(btn)
		_platform_buttons[platform] = btn


func _select_platform(platform: StringName) -> void:
	_active_platform = platform
	for p: StringName in _platform_buttons:
		var btn: Button = _platform_buttons[p]
		btn.button_pressed = (p == platform)
	slot_changed.emit(_active_slot_id, _active_platform)


func _on_slot_selected(index: int) -> void:
	_select_slot(index)


func _on_platform_pressed(platform: StringName) -> void:
	_select_platform(platform)


func _on_undo_pressed() -> void:
	pass  # wired to EditorUndoRedoManager in Task 10


func _on_redo_pressed() -> void:
	pass  # wired to EditorUndoRedoManager in Task 10


func _on_save_pressed() -> void:
	pass  # implemented in Task 12
```

- [ ] **Step 3: Verify toolbar in editor**

Enable the plugin and open "UI Builder" tab. The toolbar should show a "Slot:" dropdown with SystemHud/InventoryPanel/MainScreen, and platform buttons that update when a slot is selected.

- [ ] **Step 4: Commit**

```bash
git add addons/aethergate_ui_builder/ui_builder_main_screen.gd addons/aethergate_ui_builder/ui_builder_main_screen.tscn
git commit -m "feat(ui-builder): add toolbar with slot picker and platform toggle buttons"
```

---

### Task 8: Canvas — SubViewport + scene loading

**Files:**
- Create: `addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.gd`
- Create: `addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.tscn`

- [ ] **Step 1: Create the canvas scene in Godot editor**

Build this node tree:
```
UiBuilderCanvas (Control)                     ← script: ui_builder_canvas.gd; size_flags fill+expand
  ScrollBg (ColorRect)                        ← color=#141414; full rect anchors; mouse_filter=IGNORE
  CanvasRoot (Control)                        ← name="%CanvasRoot"; anchors centered; no size
    SubViewportContainer (SubViewportContainer) ← name="%ViewportContainer"; stretch=true
      SubViewport (SubViewport)               ← name="%Viewport"
```

Save as `addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.tscn`.

- [ ] **Step 2: Create canvas script**

```gdscript
# addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.gd
@tool
extends Control

signal node_selected(node: Control)
signal canvas_changed()

const MIN_ZOOM: float = 0.1
const MAX_ZOOM: float = 4.0
const ZOOM_STEP: float = 0.1

@onready var _canvas_root: Control = %CanvasRoot
@onready var _viewport_container: SubViewportContainer = %ViewportContainer
@onready var _viewport: SubViewport = %Viewport

var _zoom: float = 1.0
var _pan_offset: Vector2 = Vector2.ZERO
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_offset: Vector2 = Vector2.ZERO
var _scene_root: Control = null


func _ready() -> void:
	resized.connect(_center_canvas)
	_center_canvas()


## Load a Godot scene into the SubViewport. Pass null to clear.
func load_scene(packed_scene: PackedScene) -> void:
	_clear_viewport()
	if packed_scene == null:
		return
	var instance: Node = packed_scene.instantiate()
	_viewport.add_child(instance)
	_scene_root = instance as Control
	canvas_changed.emit()


## Returns the current scene root Control, or null if empty.
func get_scene_root() -> Control:
	return _scene_root


## Set the viewport size to the given platform resolution.
func set_platform_size(size: Vector2) -> void:
	_viewport.size = Vector2i(int(size.x), int(size.y))
	_viewport_container.custom_minimum_size = size * _zoom
	_center_canvas()


func get_zoom() -> float:
	return _zoom


func get_viewport_size() -> Vector2:
	return Vector2(_viewport.size)


func _clear_viewport() -> void:
	for child in _viewport.get_children():
		child.queue_free()
	_scene_root = null


func _center_canvas() -> void:
	var canvas_size: Vector2 = size
	var vp_size: Vector2 = Vector2(_viewport.size) * _zoom
	_pan_offset = (canvas_size - vp_size) * 0.5
	_apply_transform()


func _apply_transform() -> void:
	_canvas_root.position = _pan_offset
	_viewport_container.scale = Vector2(_zoom, _zoom)


func _gui_input(event: InputEvent) -> void:
	# Pan with middle mouse
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mb.pressed
			if mb.pressed:
				_pan_start_mouse = mb.position
				_pan_start_offset = _pan_offset
		# Zoom with scroll wheel
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_set_zoom(_zoom + ZOOM_STEP, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_set_zoom(_zoom - ZOOM_STEP, mb.position)

	if event is InputEventMouseMotion and _is_panning:
		var delta: Vector2 = (event as InputEventMouseMotion).position - _pan_start_mouse
		_pan_offset = _pan_start_offset + delta
		_apply_transform()


func _set_zoom(new_zoom: float, pivot: Vector2) -> void:
	var old_zoom: float = _zoom
	_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	# Zoom toward the mouse cursor position
	var scale_change: float = _zoom / old_zoom
	_pan_offset = pivot + (_pan_offset - pivot) * scale_change
	_viewport_container.scale = Vector2(_zoom, _zoom)
	_apply_transform()


## Convert a canvas-space point to viewport-space coordinates.
func canvas_to_viewport(canvas_pos: Vector2) -> Vector2:
	return (canvas_pos - _pan_offset) / _zoom
```

- [ ] **Step 3: Wire canvas into main screen**

In `ui_builder_main_screen.tscn`, replace the `Canvas (placeholder Label)` with the canvas scene. Add a unique name `%Canvas` on the instance. In the script add:

```gdscript
# in ui_builder_main_screen.gd, add:
@onready var _canvas: UiBuilderCanvas = %Canvas

# at end of _ready():
	slot_changed.connect(_on_slot_platform_changed)

# add new method:
func _on_slot_platform_changed(slot_id: StringName, platform: StringName) -> void:
	var vp_size: Vector2 = UiBuilderSlotRegistry.PLATFORM_SIZES.get(platform, Vector2(1920, 1080))
	_canvas.set_platform_size(vp_size)
	_load_canvas_scene(slot_id, platform)


func _load_canvas_scene(slot_id: StringName, platform: StringName) -> void:
	var config: UiLayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
	if config == null:
		_canvas.load_scene(null)
		return
	var path: String = config.get_scene_path(slot_id, platform)
	if path.is_empty() or not ResourceLoader.exists(path):
		_canvas.load_scene(null)
		return
	var packed: PackedScene = load(path) as PackedScene
	_canvas.load_scene(packed)
```

- [ ] **Step 4: Verify in editor**

Open UI Builder tab. Select "SystemHud" slot + "Windows" platform. The SubViewport should render the `system_hud.tscn` scene at 1920×1080. Switch to "Mobile" — viewport resizes to 1080×1920. Zoom with scroll wheel, pan with middle mouse.

- [ ] **Step 5: Commit**

```bash
git add addons/aethergate_ui_builder/panels/canvas/ addons/aethergate_ui_builder/ui_builder_main_screen.gd addons/aethergate_ui_builder/ui_builder_main_screen.tscn
git commit -m "feat(ui-builder): canvas SubViewport loads and renders platform scenes with zoom/pan"
```

---

## Chunk 4: SelectionOverlay — click, move, resize

**Goal:** Clicking a node on the canvas selects it (blue outline + 8 handles). Dragging the body moves it. Dragging a handle resizes it. Undo/redo tracks every action.

---

### Task 9: SelectionOverlay — hit testing and selection drawing

**Files:**
- Create: `addons/aethergate_ui_builder/panels/canvas/selection_overlay.gd`
- Modify: `addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.tscn`

- [ ] **Step 1: Add SelectionOverlay node to canvas scene**

In `ui_builder_canvas.tscn`, add as a sibling of `SubViewportContainer` (inside `CanvasRoot`), **after** `SubViewportContainer` in the scene tree so it renders on top:
```
SelectionOverlay (Control)   ← name="%SelectionOverlay"; anchors full rect; mouse_filter=PASS
```

- [ ] **Step 2: Create selection_overlay.gd**

```gdscript
# addons/aethergate_ui_builder/panels/canvas/selection_overlay.gd
@tool
extends Control

signal node_selected(node: Control)
signal move_committed(node: Control, old_pos: Vector2, new_pos: Vector2)
signal resize_committed(node: Control, old_rect: Rect2, new_rect: Rect2)

const HANDLE_SIZE: float = 8.0
const HANDLE_COLOR: Color = Color(0.29, 0.565, 0.855, 1.0)
const OUTLINE_COLOR: Color = Color(0.29, 0.565, 0.855, 0.8)
const HOVER_COLOR: Color = Color(0.29, 0.565, 0.855, 0.25)
const MIN_NODE_SIZE: float = 16.0

## 8 handle indices: 0=TL, 1=TC, 2=TR, 3=ML, 4=MR, 5=BL, 6=BC, 7=BR
enum Handle { TL, TC, TR, ML, MR, BL, BC, BR }

var _canvas: Control = null          # the UiBuilderCanvas parent
var _scene_root: Control = null      # root inside SubViewport

var _selected: Control = null
var _hovered: Control = null
var _drag_mode: int = -1             # -1=none, 8=body, 0-7=handle index
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_rect: Rect2 = Rect2()


func setup(canvas: Control, scene_root: Control) -> void:
	_canvas = canvas
	_scene_root = scene_root
	_selected = null
	queue_redraw()


func deselect() -> void:
	_selected = null
	queue_redraw()


func _draw() -> void:
	if _selected == null or _canvas == null:
		return
	var rect: Rect2 = _get_screen_rect(_selected)
	# Hover highlight
	if _hovered != null and _hovered != _selected:
		draw_rect(_get_screen_rect(_hovered), HOVER_COLOR)
	# Selection outline
	draw_rect(rect, OUTLINE_COLOR, false, 2.0)
	# 8 handles
	for i in range(8):
		var hp: Vector2 = _handle_position(rect, i)
		draw_rect(Rect2(hp - Vector2(HANDLE_SIZE, HANDLE_SIZE) * 0.5, Vector2(HANDLE_SIZE, HANDLE_SIZE)), HANDLE_COLOR)


func _gui_input(event: InputEvent) -> void:
	if _scene_root == null:
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_handle_mouse_motion(mm)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_left_press(mb.position)
			else:
				_handle_left_release(mb.position)


func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if _drag_mode == -1:
		# Update hover
		var vp_pos: Vector2 = _canvas.canvas_to_viewport(mm.position)
		_hovered = _hit_test(vp_pos)
		_update_cursor(mm.position)
		queue_redraw()
		return

	if _drag_mode == 8:
		# Moving body
		var delta: Vector2 = (mm.position - _drag_start_mouse) / _canvas.get_zoom()
		var snap: float = 8.0 if not Input.is_key_pressed(KEY_CTRL) else 1.0
		var new_pos: Vector2 = (_drag_start_rect.position + delta).snapped(Vector2(snap, snap))
		_selected.position = new_pos
		queue_redraw()
	else:
		# Resizing via handle
		var delta: Vector2 = (mm.position - _drag_start_mouse) / _canvas.get_zoom()
		_apply_resize_delta(_drag_mode, delta)
		queue_redraw()


func _handle_left_press(mouse_pos: Vector2) -> void:
	var vp_pos: Vector2 = _canvas.canvas_to_viewport(mouse_pos)

	# Check handles first
	if _selected != null:
		var screen_rect: Rect2 = _get_screen_rect(_selected)
		for i in range(8):
			var hp: Vector2 = _handle_position(screen_rect, i)
			if mouse_pos.distance_to(hp) <= HANDLE_SIZE:
				_drag_mode = i
				_drag_start_mouse = mouse_pos
				_drag_start_rect = Rect2(_selected.position, _selected.size)
				return

	# Click on body
	var hit: Control = _hit_test(vp_pos)
	if hit != null:
		_selected = hit
		_drag_mode = 8  # body drag
		_drag_start_mouse = mouse_pos
		_drag_start_rect = Rect2(_selected.position, _selected.size)
		node_selected.emit(_selected)
	else:
		_selected = null
		node_selected.emit(null)
	queue_redraw()


func _handle_left_release(_mouse_pos: Vector2) -> void:
	if _drag_mode == -1 or _selected == null:
		return

	var old_rect: Rect2 = _drag_start_rect
	var new_rect: Rect2 = Rect2(_selected.position, _selected.size)

	if _drag_mode == 8 and old_rect.position != new_rect.position:
		move_committed.emit(_selected, old_rect.position, new_rect.position)
	elif _drag_mode != 8 and old_rect != new_rect:
		resize_committed.emit(_selected, old_rect, new_rect)

	_drag_mode = -1


func _hit_test(vp_pos: Vector2) -> Control:
	if _scene_root == null:
		return null
	return _walk_controls(_scene_root, vp_pos)


func _walk_controls(node: Node, vp_pos: Vector2) -> Control:
	var best: Control = null
	for child in node.get_children():
		var ctrl: Control = child as Control
		if ctrl == null or not ctrl.visible:
			continue
		var rect := Rect2(ctrl.global_position, ctrl.size)
		if rect.has_point(vp_pos):
			best = ctrl  # last match wins (topmost)
		var deeper: Control = _walk_controls(child, vp_pos)
		if deeper != null:
			best = deeper
	return best


func _apply_resize_delta(handle: int, delta: Vector2) -> void:
	var r: Rect2 = _drag_start_rect
	var snap: float = 8.0 if not Input.is_key_pressed(KEY_CTRL) else 1.0

	match handle:
		Handle.TL:
			r.position += delta
			r.size -= delta
		Handle.TC:
			r.position.y += delta.y
			r.size.y -= delta.y
		Handle.TR:
			r.position.y += delta.y
			r.size.y -= delta.y
			r.size.x += delta.x
		Handle.ML:
			r.position.x += delta.x
			r.size.x -= delta.x
		Handle.MR:
			r.size.x += delta.x
		Handle.BL:
			r.position.x += delta.x
			r.size -= Vector2(delta.x, 0.0)
			r.size.y += delta.y
		Handle.BC:
			r.size.y += delta.y
		Handle.BR:
			r.size += delta

	r.size.x = maxf(r.size.x, MIN_NODE_SIZE)
	r.size.y = maxf(r.size.y, MIN_NODE_SIZE)
	r.size = r.size.snapped(Vector2(snap, snap))
	r.position = r.position.snapped(Vector2(snap, snap))
	_selected.position = r.position
	_selected.size = r.size


func _get_screen_rect(node: Control) -> Rect2:
	if _canvas == null:
		return Rect2()
	var vp_pos: Vector2 = node.global_position
	var screen_pos: Vector2 = _canvas.get_pan_offset() + vp_pos * _canvas.get_zoom()
	return Rect2(screen_pos, node.size * _canvas.get_zoom())


func _handle_position(screen_rect: Rect2, handle: int) -> Vector2:
	var cx: float = screen_rect.position.x + screen_rect.size.x * 0.5
	var cy: float = screen_rect.position.y + screen_rect.size.y * 0.5
	match handle:
		Handle.TL: return screen_rect.position
		Handle.TC: return Vector2(cx, screen_rect.position.y)
		Handle.TR: return Vector2(screen_rect.end.x, screen_rect.position.y)
		Handle.ML: return Vector2(screen_rect.position.x, cy)
		Handle.MR: return Vector2(screen_rect.end.x, cy)
		Handle.BL: return Vector2(screen_rect.position.x, screen_rect.end.y)
		Handle.BC: return Vector2(cx, screen_rect.end.y)
		Handle.BR: return screen_rect.end
	return Vector2.ZERO


func _update_cursor(mouse_pos: Vector2) -> void:
	if _selected == null:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	var screen_rect: Rect2 = _get_screen_rect(_selected)
	for i in range(8):
		if mouse_pos.distance_to(_handle_position(screen_rect, i)) <= HANDLE_SIZE:
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			return
	mouse_default_cursor_shape = Control.CURSOR_ARROW
```

- [ ] **Step 3: Wire SelectionOverlay into UiBuilderCanvas**

In `ui_builder_canvas.gd`, add:

```gdscript
@onready var _overlay: SelectionOverlay = %SelectionOverlay

# at end of load_scene():
	_overlay.setup(self, _scene_root)

# expose overlay signals:
func connect_selection(target: Object, method: StringName) -> void:
	_overlay.node_selected.connect(Callable(target, method))

func connect_move_committed(target: Object, method: StringName) -> void:
	_overlay.move_committed.connect(Callable(target, method))

func connect_resize_committed(target: Object, method: StringName) -> void:
	_overlay.resize_committed.connect(Callable(target, method))
```

Also expose `_pan_offset` as a public getter (already used in overlay's `_get_screen_rect` above):
```gdscript
func get_pan_offset() -> Vector2:
	return _pan_offset
```

- [ ] **Step 4: Verify selection in editor**

Open UI Builder, load SystemHud. Click a slot button — it should highlight with a blue outline and 8 white handles. Drag the selected node — it moves with snap. Drag a corner handle — it resizes with live 9-slice rendering.

- [ ] **Step 5: Commit**

```bash
git add addons/aethergate_ui_builder/panels/canvas/
git commit -m "feat(ui-builder): SelectionOverlay with hit-test, move, and resize handles"
```

---

### Task 10: Undo/Redo integration

**Files:**
- Modify: `addons/aethergate_ui_builder/plugin.gd`
- Modify: `addons/aethergate_ui_builder/ui_builder_main_screen.gd`

- [ ] **Step 1: Pass EditorUndoRedoManager to main screen via plugin**

In `plugin.gd`, after instantiating main screen:
```gdscript
# in _enter_tree(), after adding _main_screen:
	_main_screen.setup_undo_redo(get_undo_redo())
```

- [ ] **Step 2: Wire undo/redo in main screen**

In `ui_builder_main_screen.gd`:

```gdscript
var _undo_redo: EditorUndoRedoManager = null


func setup_undo_redo(undo_redo: EditorUndoRedoManager) -> void:
	_undo_redo = undo_redo
	# Connect canvas signals after undo_redo is available
	_canvas.connect_move_committed(self, "_on_move_committed")
	_canvas.connect_resize_committed(self, "_on_resize_committed")


func _on_undo_pressed() -> void:
	if _undo_redo:
		_undo_redo.undo()


func _on_redo_pressed() -> void:
	if _undo_redo:
		_undo_redo.redo()


func _on_move_committed(node: Control, old_pos: Vector2, new_pos: Vector2) -> void:
	if _undo_redo == null:
		return
	_undo_redo.create_action("Move node")
	_undo_redo.add_do_property(node, "position", new_pos)
	_undo_redo.add_undo_property(node, "position", old_pos)
	_undo_redo.commit_action()


func _on_resize_committed(node: Control, old_rect: Rect2, new_rect: Rect2) -> void:
	if _undo_redo == null:
		return
	_undo_redo.create_action("Resize node")
	_undo_redo.add_do_property(node, "position", new_rect.position)
	_undo_redo.add_do_property(node, "size", new_rect.size)
	_undo_redo.add_undo_property(node, "position", old_rect.position)
	_undo_redo.add_undo_property(node, "size", old_rect.size)
	_undo_redo.commit_action()
```

- [ ] **Step 3: Verify undo/redo in editor**

Move a node, then press the Undo button — it should snap back. Press Redo — it should move again. Also verify Ctrl+Z / Ctrl+Shift+Z work (Godot editor routes these to `EditorUndoRedoManager` automatically).

- [ ] **Step 4: Commit**

```bash
git add addons/aethergate_ui_builder/plugin.gd addons/aethergate_ui_builder/ui_builder_main_screen.gd
git commit -m "feat(ui-builder): undo/redo for move and resize via EditorUndoRedoManager"
```

---

## Chunk 5: Palette + Inspector + Save

**Goal:** Palette lets you drag Aethergate components and Godot primitives onto the canvas. Inspector shows Rect + export properties for selected node. Save writes `.tscn` + updates `ui_layout_config.tres`.

---

### Task 11: Palette — two-tier widget list

**Files:**
- Create: `addons/aethergate_ui_builder/panels/palette/ui_builder_palette.gd`
- Create: `addons/aethergate_ui_builder/panels/palette/ui_builder_palette.tscn`

- [ ] **Step 1: Create palette scene**

```
UiBuilderPalette (VBoxContainer)         ← script: ui_builder_palette.gd
  AethergateLabel (Label)                ← text="AETHERGATE"; theme_override uppercase/small
  AethergateList (VBoxContainer)         ← name="%AethergateList"
  Separator (HSeparator)
  PrimitivesLabel (Label)                ← text="PRIMITIVES"
  PrimitivesList (VBoxContainer)         ← name="%PrimitivesList"
```

Save as `addons/aethergate_ui_builder/panels/palette/ui_builder_palette.tscn`.

- [ ] **Step 2: Create palette script**

```gdscript
# addons/aethergate_ui_builder/panels/palette/ui_builder_palette.gd
@tool
extends VBoxContainer

signal node_drag_requested(scene_path: String)

const PRIMITIVES: Array[Dictionary] = [
	{ "label": "Panel",          "type": "Panel" },
	{ "label": "NinePatchRect",  "type": "NinePatchRect" },
	{ "label": "HBoxContainer",  "type": "HBoxContainer" },
	{ "label": "VBoxContainer",  "type": "VBoxContainer" },
	{ "label": "Label",          "type": "Label" },
	{ "label": "Button",         "type": "Button" },
	{ "label": "TextureRect",    "type": "TextureRect" },
]

@onready var _aethergate_list: VBoxContainer = %AethergateList
@onready var _primitives_list: VBoxContainer = %PrimitivesList


func _ready() -> void:
	_populate_aethergate()
	_populate_primitives()


func _populate_aethergate() -> void:
	for slot: Dictionary in UiBuilderSlotRegistry.SLOTS:
		var config: UiLayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
		if config == null:
			continue
		var path: String = config.get_scene_path(slot.id, &"windows")
		if path.is_empty():
			continue
		_add_palette_item(_aethergate_list, slot.label, path, false)


func _populate_primitives() -> void:
	for prim: Dictionary in PRIMITIVES:
		_add_palette_item(_primitives_list, prim.label, prim.type, true)


func _add_palette_item(list: VBoxContainer, label: String, payload: String, is_primitive: bool) -> void:
	var btn := Button.new()
	btn.text = label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(_on_item_pressed.bind(payload, is_primitive))
	list.add_child(btn)


func _on_item_pressed(payload: String, is_primitive: bool) -> void:
	# For now emit as scene_path; canvas distinguishes primitive vs scene by checking ResourceLoader
	node_drag_requested.emit(payload)
```

- [ ] **Step 3: Wire palette into main screen**

Replace the `Palette (placeholder Label)` in `ui_builder_main_screen.tscn` with the palette scene instance (unique name `%Palette`).

In `ui_builder_main_screen.gd` add:
```gdscript
@onready var _palette: UiBuilderPalette = %Palette

# at end of _ready():
	_palette.node_drag_requested.connect(_on_palette_node_requested)


func _on_palette_node_requested(payload: String) -> void:
	if _canvas == null:
		return
	var node: Control = _create_node(payload)
	if node == null:
		return
	# Place at center of current viewport
	var vp_size: Vector2 = _canvas.get_viewport_size()
	node.position = (vp_size * 0.5 - node.size * 0.5).snapped(Vector2(8.0, 8.0))
	if _undo_redo:
		_undo_redo.create_action("Add node")
		_undo_redo.add_do_method(_canvas, "add_node_to_scene", node)
		_undo_redo.add_undo_method(_canvas, "remove_node_from_scene", node)
		_undo_redo.commit_action()  # applies do-method immediately
	else:
		_canvas.add_node_to_scene(node)


func _create_node(payload: String) -> Control:
	# Scene path
	if ResourceLoader.exists(payload):
		var packed: PackedScene = load(payload) as PackedScene
		return packed.instantiate() as Control if packed else null
	# Primitive type name
	var instance: Object = ClassDB.instantiate(payload)
	var ctrl: Control = instance as Control
	if ctrl == null:
		instance.free()
		return null
	ctrl.size = Vector2(200.0, 80.0)
	return ctrl
```

In `ui_builder_canvas.gd` add:
```gdscript
func add_node_to_scene(node: Control) -> void:
	if _scene_root == null:
		# Create a bare root Control if viewport is empty
		_scene_root = Control.new()
		_scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_viewport.add_child(_scene_root)
	_scene_root.add_child(node)
	_overlay.setup(self, _scene_root)
	canvas_changed.emit()


func remove_node_from_scene(node: Control) -> void:
	if _scene_root != null and node.get_parent() == _scene_root:
		_scene_root.remove_child(node)
	canvas_changed.emit()
```

- [ ] **Step 4: Verify in editor**

Open UI Builder. Click "Panel" in the Primitives section — a Panel node should appear in the center of the canvas. Click on it to select it. Verify it shows in the selection overlay.

- [ ] **Step 5: Commit**

```bash
git add addons/aethergate_ui_builder/panels/palette/
git commit -m "feat(ui-builder): palette with Aethergate components and Godot primitives"
```

---

### Task 12: Inspector — Rect + export properties

**Files:**
- Create: `addons/aethergate_ui_builder/panels/inspector/ui_builder_inspector.gd`
- Create: `addons/aethergate_ui_builder/panels/inspector/ui_builder_inspector.tscn`

- [ ] **Step 1: Create inspector scene**

```
UiBuilderInspector (VBoxContainer)           ← script: ui_builder_inspector.gd
  NodeLabel (Label)                           ← name="%NodeLabel"; text="(nothing selected)"
  HSeparator
  ScrollContainer (ScrollContainer)           ← size_flags fill+expand
    PropertiesContainer (VBoxContainer)       ← name="%PropertiesContainer"
```

Save as `addons/aethergate_ui_builder/panels/inspector/ui_builder_inspector.tscn`.

- [ ] **Step 2: Create inspector script**

```gdscript
# addons/aethergate_ui_builder/panels/inspector/ui_builder_inspector.gd
@tool
extends VBoxContainer

signal property_changed(node: Control, property: StringName, value: Variant)

@onready var _node_label: Label = %NodeLabel
@onready var _props_container: VBoxContainer = %PropertiesContainer

var _target: Control = null


func inspect(node: Control) -> void:
	_target = node
	_rebuild()


func _rebuild() -> void:
	for child in _props_container.get_children():
		child.queue_free()

	if _target == null:
		_node_label.text = "(nothing selected)"
		return

	_node_label.text = _target.get_class() + " — " + _target.name

	_add_section_header("RECT")
	_add_float_row("X", "position:x", _target.position.x)
	_add_float_row("Y", "position:y", _target.position.y)
	_add_float_row("W", "size:x", _target.size.x)
	_add_float_row("H", "size:y", _target.size.y)

	if _target.get_script() != null:
		var exports: Array[Dictionary] = _target.get_property_list().filter(
			func(p: Dictionary) -> bool:
				return p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR
		)
		if exports.size() > 0:
			_add_section_header("EXPORTS")
			for prop: Dictionary in exports:
				_add_property_row(prop)


func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override(&"font_color", Color(0.6, 0.5, 0.85))
	_props_container.add_child(lbl)


func _add_float_row(label: String, prop_path: String, value: float) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 24.0
	var spin := SpinBox.new()
	spin.value = value
	spin.step = 1.0
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(_on_float_changed.bind(prop_path))
	row.add_child(lbl)
	row.add_child(spin)
	_props_container.add_child(row)


func _add_property_row(prop: Dictionary) -> void:
	match prop.type:
		TYPE_INT, TYPE_FLOAT:
			_add_float_row(prop.name, prop.name, float(_target.get(prop.name)))
		TYPE_BOOL:
			var row := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = prop.name
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var chk := CheckBox.new()
			chk.button_pressed = bool(_target.get(prop.name))
			chk.toggled.connect(func(v: bool) -> void: _emit_change(prop.name, v))
			row.add_child(lbl)
			row.add_child(chk)
			_props_container.add_child(row)
		TYPE_STRING, TYPE_STRING_NAME:
			var row := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = prop.name
			lbl.custom_minimum_size.x = 80.0
			var field := LineEdit.new()
			field.text = str(_target.get(prop.name))
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.text_submitted.connect(func(v: String) -> void: _emit_change(prop.name, v))
			row.add_child(lbl)
			row.add_child(field)
			_props_container.add_child(row)
		_:
			pass  # skip unsupported types (Texture2D, etc.)


func _on_float_changed(value: float, prop_path: String) -> void:
	if _target == null:
		return
	if prop_path == "position:x":
		_emit_change("position", Vector2(value, _target.position.y))
	elif prop_path == "position:y":
		_emit_change("position", Vector2(_target.position.x, value))
	elif prop_path == "size:x":
		_emit_change("size", Vector2(value, _target.size.y))
	elif prop_path == "size:y":
		_emit_change("size", Vector2(_target.size.x, value))
	else:
		_emit_change(prop_path, value)


func _emit_change(property: StringName, value: Variant) -> void:
	if _target == null:
		return
	_target.set(property, value)
	property_changed.emit(_target, property, value)
```

- [ ] **Step 3: Wire inspector into main screen**

Replace `Inspector (placeholder Label)` with the inspector scene instance (unique name `%Inspector`).

In `ui_builder_main_screen.gd` add:
```gdscript
@onready var _inspector: UiBuilderInspector = %Inspector

# at end of _ready():
	_canvas.connect_selection(self, "_on_node_selected")

func _on_node_selected(node: Control) -> void:
	_inspector.inspect(node)
```

- [ ] **Step 4: Verify in editor**

Select a node on the canvas — the Inspector should show its X/Y/W/H. For SystemHud, an EXPORTS section should appear with its `@export` vars (slot_count, side_slot_scale, etc.). Changing a SpinBox value should update the node live on the canvas.

- [ ] **Step 5: Commit**

```bash
git add addons/aethergate_ui_builder/panels/inspector/
git commit -m "feat(ui-builder): inspector with Rect and @export property editor"
```

---

### Task 13: Save flow

**Files:**
- Modify: `addons/aethergate_ui_builder/ui_builder_main_screen.gd`

- [ ] **Step 1: Implement _on_save_pressed**

Replace the `pass` stub in `ui_builder_main_screen.gd`:

```gdscript
func _on_save_pressed() -> void:
	if _active_slot_id == &"" or _canvas == null:
		return

	var scene_root: Control = _canvas.get_scene_root()
	if scene_root == null:
		push_warning("[UiBuilder] Nothing on canvas to save.")
		return

	# Determine output path
	var out_path: String = _resolve_output_path(_active_slot_id, _active_platform)
	if out_path.is_empty():
		push_error("[UiBuilder] No output path defined for slot '%s' platform '%s'" % [_active_slot_id, _active_platform])
		return

	# Pack and save scene
	var packed := PackedScene.new()
	var pack_result: int = packed.pack(scene_root)
	if pack_result != OK:
		push_error("[UiBuilder] Failed to pack scene (error %d)" % pack_result)
		return

	var save_result: int = ResourceSaver.save(packed, out_path)
	if save_result != OK:
		push_error("[UiBuilder] Failed to save scene to '%s' (error %d)" % [out_path, save_result])
		return

	# Update ui_layout_config.tres
	var config: UiLayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
	if config == null:
		config = UiLayoutConfig.new()

	if not config.slots.has(_active_slot_id):
		config.slots[_active_slot_id] = {}
	config.slots[_active_slot_id][_active_platform] = out_path

	ResourceSaver.save(config, "res://src/Ui/Common/Resources/ui_layout_config.tres")
	print("[UiBuilder] Saved '%s' (%s) → %s" % [_active_slot_id, _active_platform, out_path])


func _resolve_output_path(slot_id: StringName, platform: StringName) -> String:
	# Try existing path from config first
	var config: UiLayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
	if config != null:
		var existing: String = config.get_scene_path(slot_id, platform)
		if not existing.is_empty():
			return existing

	# Derive a sensible default path
	var slot: Dictionary = UiBuilderSlotRegistry.find_slot(slot_id)
	if slot.is_empty():
		return ""
	var platform_folder: String = UiBuilderSlotRegistry.PLATFORM_FOLDER_NAMES.get(platform, str(platform).capitalize())
	var folder: String = "res://src/Ui/%s/UiBuilder/%s/" % [platform_folder, slot.label]
	return folder + slot_id + "_" + platform + ".tscn"
```

- [ ] **Step 2: Verify save in editor**

Load SystemHud / Windows. Move a slot button. Press "💾 Save". Check the Output panel — should print `[UiBuilder] Saved 'system_hud' (windows) → res://src/Ui/Windows/...`. Open the FileSystem dock and verify the `.tscn` was updated. Run the game (F5) — the moved slot button should appear at its new position.

- [ ] **Step 3: Verify round-trip (save → reload)**

After saving, switch to "macOS" platform and back to "Windows". The canvas should reload the saved scene with the moved node at its new position.

- [ ] **Step 4: Commit**

```bash
git add addons/aethergate_ui_builder/ui_builder_main_screen.gd
git commit -m "feat(ui-builder): save flow writes .tscn and updates ui_layout_config.tres"
```

---

### Task 14: Final verification + feature doc

**Files:**
- Create: `doc/features/feature-ui-builder.md`

- [ ] **Step 1: Run full acceptance checklist**

- [ ] "UI Builder" tab appears in Godot editor next to 2D / 3D / Script
- [ ] Dragging a component from palette places it on the canvas (click to place)
- [ ] Clicking a node shows 8 resize handles
- [ ] Dragging a resize handle resizes with live 9-slice rendering
- [ ] Moving a node respects 8px grid snap; Ctrl disables snap
- [ ] Undo (Ctrl+Z) and Redo (Ctrl+Shift+Z) work for place, move, resize
- [ ] Platform toggle (Windows/macOS/Mobile) changes viewport size and loads correct scene
- [ ] Save writes the `.tscn` and updates `ui_layout_config.tres`
- [ ] Running the game after save reflects the new layout
- [ ] Disabling the plugin has zero effect on game builds
- [ ] No errors in Output panel during normal use

- [ ] **Step 2: Write feature doc**

Create `doc/features/feature-ui-builder.md` following the template in `CLAUDE.md`.

- [ ] **Step 3: Final commit**

```bash
git add doc/features/feature-ui-builder.md
git commit -m "docs(ui-builder): add feature doc"
```
