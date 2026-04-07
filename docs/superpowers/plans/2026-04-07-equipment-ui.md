# Equipment UI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the CharacterBoard in InventoryPanel to show 5 equipment slots + stats with full drag-and-drop from the inventory grid.

**Architecture:** `InventoryPanel` owns all equipment display logic. `UiManager` injects `PlayerEquipmentComponent` the same way it already injects `PlayerInventoryComponent`. A new `EquipmentSlotButton` mirrors `InventorySlotButton` — both delegate to the same panel instance, so the existing `source_panel_id` guard works automatically. The HUD "equipment" slot (slot 0) becomes an alias for `toggle_inventory()`.

**Tech Stack:** Godot 4.6, GDScript with static typing. No new dependencies.

---

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `src/ui/desktop/inventory/equipment_slot_button.gd` | **Create** | TextureButton subclass: delegates all D&D to InventoryPanel for one equipment slot |
| `src/ui/desktop/inventory/inventory_panel.gd` | **Modify** | Add equipment component injection, CharacterBoard setup, stats section, equipment D&D methods; remove dead doll code |
| `src/ui/desktop/inventory/inventory_panel.tscn` | **Modify** | Remove 12 doll TextureButton nodes; change SkillsContent to VBoxContainer |
| `src/ui/common/ui_manager.gd` | **Modify** | Add `bind_equipment_component()`; wire HUD slot 0 to `toggle_inventory()` |
| `src/world/overworld/overworld.gd` | **Modify** | Call `bind_equipment_component` in `_wire_inventory_panel_dependency()` |

---

## Chunk 1: EquipmentSlotButton + Panel Foundation

### Task 1: Create EquipmentSlotButton

**Files:**
- Create: `src/ui/desktop/inventory/equipment_slot_button.gd`

Context: `InventorySlotButton` at `src/ui/desktop/inventory/inventory_slot_button.gd` is the exact pattern to mirror. The key difference is this button stores an `EquipmentData.EquipmentSlot` enum value instead of an integer slot index, and delegates to different panel methods.

No test needed for this task — it is a thin delegation wrapper; behavior is tested through the panel integration in later tasks.

- [ ] **Step 1: Create the file**

```gdscript
# src/ui/desktop/inventory/equipment_slot_button.gd
extends TextureButton

var _slot: EquipmentData.EquipmentSlot = EquipmentData.EquipmentSlot.WEAPON
var _inventory_panel: Node = null


func configure(inventory_panel: Node, slot: EquipmentData.EquipmentSlot) -> void:
	_inventory_panel = inventory_panel
	_slot = slot


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _inventory_panel == null:
		return null
	if not _inventory_panel.has_method("build_equipment_drag_data"):
		return null
	var drag_data: Variant = _inventory_panel.call("build_equipment_drag_data", _slot)
	if drag_data == null:
		return null
	if _inventory_panel.has_method("create_slot_drag_preview"):
		var preview: Control = _inventory_panel.call("create_slot_drag_preview", drag_data) as Control
		if preview:
			set_drag_preview(preview)
	return drag_data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if _inventory_panel == null:
		return false
	if not _inventory_panel.has_method("can_drop_on_equipment_slot"):
		return false
	return bool(_inventory_panel.call("can_drop_on_equipment_slot", _slot, data))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _inventory_panel == null:
		return
	if not _inventory_panel.has_method("drop_on_equipment_slot"):
		return
	_inventory_panel.call("drop_on_equipment_slot", _slot, data)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return
	if _inventory_panel == null:
		return
	if not _inventory_panel.has_method("end_equipment_drag_visual"):
		return
	_inventory_panel.call("end_equipment_drag_visual", _slot)
```

- [ ] **Step 2: Verify the file loads in Godot without errors**

Open the Godot editor (or run headless). There should be no parse errors for this file. If errors appear, fix them before continuing.

- [ ] **Step 3: Commit**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git add src/ui/desktop/inventory/equipment_slot_button.gd
git status --short   # confirm .gd.uid was generated too
git add src/ui/desktop/inventory/equipment_slot_button.gd.uid
git commit -m "feat: add EquipmentSlotButton delegation wrapper"
```

---

### Task 2: Remove doll nodes from inventory_panel.tscn

**Files:**
- Modify: `src/ui/desktop/inventory/inventory_panel.tscn`

Context: The CharacterBoard currently has 12 TextureButton nodes (HeadSlot, LeftShoulderSlot, RightShoulderSlot, LeftHandSlot, RightHandSlot, TorsoSlot, LegsSlot, LeftBootSlot, RightBootSlot, RingLeftSlot, RingRightSlot, RelicSlot) inside `CharacterSlots` (a VBoxContainer with scene unique name `%CharacterSlots`). These are pure visual decoration with no wiring — they are being replaced by a runtime-built 5-slot list.

Also: `SkillsSection` has a child `SkillsContent` that is currently a plain `Control` — change it to a `VBoxContainer` so `_setup_stats_section()` can append children to it.

- [ ] **Step 1: Open inventory_panel.tscn in the Godot editor**

Navigate to `src/ui/desktop/inventory/inventory_panel.tscn`. In the Scene tree, expand `CharacterBoard > CharacterMargin > CharacterVBox > CharacterSlots`.

- [ ] **Step 2: Delete all 12 doll slot nodes**

Select and delete all 12 nodes: HeadSlot, LeftShoulderSlot, RightShoulderSlot, LeftHandSlot, RightHandSlot, TorsoSlot, LegsSlot, LeftBootSlot, RightBootSlot, RingLeftSlot, RingRightSlot, RelicSlot (plus any intermediate row HBoxContainers: TopRow, MidRow, LowerRow, BottomRow).

After deletion, `CharacterSlots` (VBoxContainer) should be empty.

- [ ] **Step 3: Change SkillsContent from Control to VBoxContainer**

Find `SkillsSection > SkillsSectionVBox > SkillsVBox > SkillsContent` (or similar path — find the node named `SkillsContent` under `SkillsSection`). Change its type from `Control` to `VBoxContainer`. Keep the same scene unique name if it has one.

- [ ] **Step 4: Save the scene**

Save `inventory_panel.tscn`. The scene should save cleanly with no errors.

- [ ] **Step 5: Commit**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git add src/ui/desktop/inventory/inventory_panel.tscn
git commit -m "feat: remove character doll nodes from inventory panel scene"
```

---

### Task 3: Remove dead doll code from inventory_panel.gd

**Files:**
- Modify: `src/ui/desktop/inventory/inventory_panel.gd`

Context: Three methods and one variable reference the 12-slot doll. All are dead after Task 2.

Exact locations (do not guess — read the file before editing):
- `var _character_slots: Dictionary = {}` — line 68. Remove this line.
- `_cache_character_slots()` call — line 83 in `_ready()`. Remove this call.
- `func _cache_character_slots() -> void` — lines 403–422. Remove the entire function.
- `_apply_character_slot_sizes(inventory_slot_size)` call — line 506. Remove this call.
- `func _apply_character_slot_sizes(base_slot_size: float) -> void` — lines 703–726. Remove the entire function.
- `var slots_rect: Rect2 = _resolve_character_slots_global_rect()` — line 597 in `_apply_windows_character_background_layout()`. Replace with:
  ```gdscript
  var equipment_list: Control = _character_slots_root.get_node_or_null("EquipmentSlotList") as Control
  var slots_rect: Rect2 = equipment_list.get_global_rect() if equipment_list != null else Rect2(Vector2.ZERO, Vector2.ZERO)
  ```
- `func _resolve_character_slots_global_rect() -> Rect2` — lines 666–687. Remove the entire function.

**Important:** `_character_slots_root` (`%CharacterSlots`) is the VBoxContainer that previously held the doll nodes. After Task 2 it is empty; after Task 5 it will contain the new `EquipmentSlotList`.

- [ ] **Step 1: Read the file to confirm line numbers**

Read `src/ui/desktop/inventory/inventory_panel.gd` and verify the locations above match. Line numbers may have shifted slightly — find each by content, not just by number.

- [ ] **Step 2: Remove `var _character_slots: Dictionary = {}`**

Remove line 68 (or wherever it is).

- [ ] **Step 3: Remove `_cache_character_slots()` call from `_ready()`**

In `_ready()`, remove the line `_cache_character_slots()`.

- [ ] **Step 4: Remove `func _cache_character_slots() -> void` entirely**

Remove the function body (the whole function from `func` to the closing `}`).

- [ ] **Step 5: Remove `_apply_character_slot_sizes(inventory_slot_size)` call**

In `_apply_responsive_layout()`, remove the call.

- [ ] **Step 6: Remove `func _apply_character_slot_sizes()` entirely**

- [ ] **Step 7: Replace the `slots_rect` line in `_apply_windows_character_background_layout()`**

Find: `var slots_rect: Rect2 = _resolve_character_slots_global_rect()`

Replace with:
```gdscript
var equipment_list: Control = _character_slots_root.get_node_or_null("EquipmentSlotList") as Control
var slots_rect: Rect2 = equipment_list.get_global_rect() if equipment_list != null else Rect2(Vector2.ZERO, Vector2.ZERO)
```

- [ ] **Step 8: Remove `func _resolve_character_slots_global_rect() -> Rect2` entirely**

- [ ] **Step 9: Add new member variables after the existing `var _inventory_component: Node` line**

```gdscript
var _equipment_component: PlayerEquipmentComponent = null
var _equipment_slot_buttons: Dictionary = {}
var _equipment_item_labels: Dictionary = {}
var _stat_value_labels: Dictionary = {}
```

- [ ] **Step 10: Add new constants after `DRAG_DATA_TYPE_SLOT`**

```gdscript
const DRAG_DATA_TYPE_EQUIPMENT_SLOT: StringName = &"equipment_slot"
const EQUIPMENT_SLOT_BUTTON_SCRIPT := preload("res://src/ui/desktop/inventory/equipment_slot_button.gd")
```

Note: `DRAG_DATA_SOURCE_PANEL_KEY` (used in the D&D methods in Chunk 2) already exists in this file at line 12 — do **not** redeclare it.

- [ ] **Step 11: Verify Godot parses the file without errors**

Run headless to check for parse errors:
```
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | head -40
```
Expected: No errors about `inventory_panel.gd`.

- [ ] **Step 12: Commit**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git add src/ui/desktop/inventory/inventory_panel.gd
git commit -m "refactor: remove character doll dead code from inventory panel"
```

---

### Task 4: Add `set_equipment_component()` and `_refresh_character_board()` to inventory_panel.gd

**Files:**
- Modify: `src/ui/desktop/inventory/inventory_panel.gd`

Context: These are the core injection and refresh methods. `set_equipment_component` must be idempotent (called on every inventory toggle). `_refresh_character_board` matches the `equipment_changed` signal shape `(slot, item)` but ignores both params and always does a full refresh.

- [ ] **Step 1: Add `set_equipment_component` after `set_inventory_component`**

Find `func set_inventory_component(component: Node) -> void:` and add the following function immediately after it (after its closing brace):

```gdscript
func set_equipment_component(comp: PlayerEquipmentComponent) -> void:
	if _equipment_component == comp:
		return
	if _equipment_component != null:
		if _equipment_component.equipment_changed.is_connected(_refresh_character_board):
			_equipment_component.equipment_changed.disconnect(_refresh_character_board)
	_equipment_component = comp
	if comp != null:
		comp.equipment_changed.connect(_refresh_character_board)
		_refresh_character_board()
```

Note: Use the direct Godot 4 callable reference form `_refresh_character_board` (not `Callable(self, "_refresh_character_board")`). The direct form is the idiomatic Godot 4 pattern and must be used consistently in all three places (connect, is_connected, disconnect) — mixing forms causes `is_connected` to return false and breaks the reconnection guard.

- [ ] **Step 2: Add `_refresh_character_board` at the end of the file (before the final closing)**

```gdscript
func _refresh_character_board(_slot: EquipmentData.EquipmentSlot = EquipmentData.EquipmentSlot.WEAPON, _item: EquipmentData = null) -> void:
	if _equipment_component == null:
		return
	# Update equipment slot buttons and item name labels
	for slot_int in _equipment_slot_buttons.keys():
		var slot: EquipmentData.EquipmentSlot = slot_int as EquipmentData.EquipmentSlot
		var btn: TextureButton = _equipment_slot_buttons[slot_int] as TextureButton
		var name_label: Label = _equipment_item_labels[slot_int] as Label
		var equipped: EquipmentData = _equipment_component.get_item_in_slot(slot)
		if equipped != null:
			var icon: Texture2D = _resolve_item_icon(equipped)
			_set_equipment_slot_visual(btn, icon)
			name_label.text = equipped.display_name
			name_label.remove_theme_color_override("font_color")
		else:
			_set_equipment_slot_visual(btn, null)
			name_label.text = "— Empty —"
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	# Update stat labels
	if _stat_value_labels.is_empty():
		return
	var snap: CombatantSnapshot = PlayerProgressionService.build_player_snapshot()
	if snap == null or snap.base_stats == null:
		return
	_stat_value_labels[&"max_hp"].text    = str(snap.base_stats.max_hp)
	_stat_value_labels[&"max_energy"].text = str(snap.base_stats.max_energy)
	_stat_value_labels[&"attack"].text    = str(int(snap.base_stats.attack))
	_stat_value_labels[&"defense"].text   = str(int(snap.base_stats.defense))


func _set_equipment_slot_visual(btn: TextureButton, icon: Texture2D) -> void:
	if btn == null:
		return
	_ensure_slot_visual_nodes(btn)
	var icon_node: TextureRect = btn.get_node_or_null("ItemIcon") as TextureRect
	if icon_node:
		icon_node.texture = icon
		icon_node.visible = icon != null
```

Note: `_resolve_item_icon(item)` already exists in `inventory_panel.gd` — reuse it.
Note: `_ensure_slot_visual_nodes(btn)` already exists — reuse it (injects `ItemIcon` TextureRect child).

- [ ] **Step 3: Add `_setup_character_board()` method**

```gdscript
func _setup_character_board() -> void:
	if _character_slots_root == null:
		return
	# Clear any leftover nodes
	for child in _character_slots_root.get_children():
		child.queue_free()

	var slot_list: VBoxContainer = VBoxContainer.new()
	slot_list.name = "EquipmentSlotList"
	_character_slots_root.add_child(slot_list)

	var slot_defs: Array = [
		[EquipmentData.EquipmentSlot.WEAPON,    "Weapon"],
		[EquipmentData.EquipmentSlot.HELMET,    "Helmet"],
		[EquipmentData.EquipmentSlot.CHEST,     "Chest"],
		[EquipmentData.EquipmentSlot.BOOTS,     "Boots"],
		[EquipmentData.EquipmentSlot.ACCESSORY, "Accessory"],
	]
	for entry in slot_defs:
		var slot: EquipmentData.EquipmentSlot = entry[0] as EquipmentData.EquipmentSlot
		var label_text: String = entry[1] as String

		var row: HBoxContainer = HBoxContainer.new()
		row.name = label_text + "Row"
		slot_list.add_child(row)

		var btn: TextureButton = EQUIPMENT_SLOT_BUTTON_SCRIPT.new() as TextureButton
		btn.name = label_text + "SlotBtn"
		btn.custom_minimum_size = Vector2(64.0, 64.0)
		btn.texture_normal = slot_texture  # @export Texture2D defined at top of inventory_panel.gd (line 17)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.add_child(btn)
		btn.configure(self, slot)
		_ensure_slot_visual_nodes(btn)
		_equipment_slot_buttons[int(slot)] = btn

		var slot_label: Label = Label.new()
		slot_label.text = label_text
		row.add_child(slot_label)

		var item_label: Label = Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		item_label.text = "— Empty —"
		item_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(item_label)
		_equipment_item_labels[int(slot)] = item_label
```

- [ ] **Step 4: Add `_setup_stats_section()` method**

```gdscript
func _setup_stats_section() -> void:
	# Find SkillsContent — the VBoxContainer inside SkillsSection
	var skills_content: VBoxContainer = null
	if _skills_section != null:
		skills_content = _skills_section.find_child("SkillsContent", true, false) as VBoxContainer
	if skills_content == null:
		return

	for child in skills_content.get_children():
		child.queue_free()

	var stat_defs: Array = [
		[&"max_hp",     "Max HP"],
		[&"max_energy", "Max Energy"],
		[&"attack",     "Attack"],
		[&"defense",    "Defense"],
	]
	for entry in stat_defs:
		var key: StringName = entry[0] as StringName
		var label_text: String = entry[1] as String

		var row: HBoxContainer = HBoxContainer.new()
		skills_content.add_child(row)

		var name_label: Label = Label.new()
		name_label.text = label_text
		row.add_child(name_label)

		var value_label: Label = Label.new()
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.text = "—"
		row.add_child(value_label)
		_stat_value_labels[key] = value_label
```

- [ ] **Step 5: Call both setup methods from `_ready()`**

In `_ready()`, after `_rebuild_inventory_slots()` add:
```gdscript
_setup_character_board()
_setup_stats_section()
```

- [ ] **Step 6: Verify parse — no errors**

```
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | head -40
```

- [ ] **Step 7: Commit**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git add src/ui/desktop/inventory/inventory_panel.gd
git commit -m "feat: add equipment component injection and character board setup"
```

---

## Chunk 2: Drag-and-Drop, Stats, Wiring

### Task 5: Add equipment drag-and-drop panel methods

**Files:**
- Modify: `src/ui/desktop/inventory/inventory_panel.gd`

Context: Four new panel methods handle equipment D&D. Two existing methods (`can_drop_slot_drag_data`, `drop_slot_drag_data`) are extended with equipment paths inserted **before** the existing `_is_valid_drag_payload` guard.

Current line numbers (verify before editing):
- `func can_drop_slot_drag_data` — line 194
- `func drop_slot_drag_data` — line 213

- [ ] **Step 1: Add `build_equipment_drag_data` near the other `build_slot_drag_data` method**

Find `func build_slot_drag_data(slot_index: int) -> Variant:` and add the following function immediately after it:

```gdscript
func build_equipment_drag_data(slot: EquipmentData.EquipmentSlot) -> Variant:
	if _equipment_component == null:
		return null
	var item: EquipmentData = _equipment_component.get_item_in_slot(slot)
	if item == null:
		return null
	return {
		DRAG_DATA_TYPE_KEY:         DRAG_DATA_TYPE_EQUIPMENT_SLOT,
		&"source_slot":             slot,
		DRAG_DATA_SOURCE_PANEL_KEY: get_instance_id(),
		DRAG_DATA_ICON_KEY:         _resolve_item_icon(item),
		DRAG_DATA_AMOUNT_KEY:       1
	}
```

- [ ] **Step 2: Add `can_drop_on_equipment_slot`**

Add this method near the other `can_drop_*` methods:

```gdscript
func can_drop_on_equipment_slot(target_slot: EquipmentData.EquipmentSlot, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var payload: Dictionary = data
	var drag_type: StringName = payload.get(DRAG_DATA_TYPE_KEY, &"")
	# Equipment-to-equipment: not supported in this iteration
	if drag_type == DRAG_DATA_TYPE_EQUIPMENT_SLOT:
		return false
	# Only accept inventory-slot drags
	if drag_type != DRAG_DATA_TYPE_SLOT:
		return false
	if int(payload.get(DRAG_DATA_SOURCE_PANEL_KEY, -1)) != get_instance_id():
		return false
	if _equipment_component == null:
		return false
	var source_index: int = int(payload.get(DRAG_DATA_SOURCE_SLOT_KEY, -1))
	var slot_data: Resource = _get_inventory_slot_data(source_index)
	if not _slot_has_item(slot_data):
		return false
	var item: EquipmentData = slot_data.get("item") as EquipmentData
	if item == null:
		return false
	return item.slot == target_slot
```

- [ ] **Step 3: Add `drop_on_equipment_slot`**

```gdscript
func drop_on_equipment_slot(target_slot: EquipmentData.EquipmentSlot, data: Variant) -> void:
	var source_index: int = int(data[DRAG_DATA_SOURCE_SLOT_KEY])
	var slot_data: Resource = _get_inventory_slot_data(source_index)
	if slot_data == null:
		return
	var item: EquipmentData = slot_data.get("item") as EquipmentData
	if item == null:
		return
	# Capture displaced item BEFORE equipping (equip() returns void).
	# equip() is infallible here: can_drop_on_equipment_slot verified item.slot == target_slot.
	var displaced: EquipmentData = _equipment_component.get_item_in_slot(target_slot)
	_equipment_component.equip(item)
	var inv_data: Resource = _inventory_component.call("get_inventory_data")
	inv_data.call("set_slot", source_index, null, 0)
	if displaced != null:
		inv_data.call("set_slot", source_index, displaced, 1)
	_inventory_component.call("notify_inventory_changed")
	_refresh_inventory_slots_from_data()
	_refresh_character_board()
```

- [ ] **Step 4: Add `end_equipment_drag_visual`**

```gdscript
func end_equipment_drag_visual(_slot: EquipmentData.EquipmentSlot) -> void:
	_refresh_character_board()
```

- [ ] **Step 5: Extend `can_drop_slot_drag_data` — insert equipment path BEFORE `_is_valid_drag_payload`**

Find `func can_drop_slot_drag_data(target_slot_index: int, data: Variant) -> bool:`. The very first line of this function is `if not _is_valid_drag_payload(data):`. Insert a new block **before** that line:

```gdscript
	# Equipment-slot unequip path: must be before _is_valid_drag_payload (which rejects this type)
	if data is Dictionary and data.get(DRAG_DATA_TYPE_KEY) == DRAG_DATA_TYPE_EQUIPMENT_SLOT:
		return int(data.get(DRAG_DATA_SOURCE_PANEL_KEY, -1)) == get_instance_id() \
			and _equipment_component != null
```

So the function now reads:
```gdscript
func can_drop_slot_drag_data(target_slot_index: int, data: Variant) -> bool:
	# Equipment-slot unequip path: must be before _is_valid_drag_payload (which rejects this type)
	if data is Dictionary and data.get(DRAG_DATA_TYPE_KEY) == DRAG_DATA_TYPE_EQUIPMENT_SLOT:
		return int(data.get(DRAG_DATA_SOURCE_PANEL_KEY, -1)) == get_instance_id() \
			and _equipment_component != null
	if not _is_valid_drag_payload(data):
		return false
	# ... rest of function unchanged
```

- [ ] **Step 6: Extend `drop_slot_drag_data` — insert equipment path BEFORE the existing guard**

Find `func drop_slot_drag_data(target_slot_index: int, data: Variant) -> void:`. The very first line is `if not can_drop_slot_drag_data(target_slot_index, data):`. Insert a new block **before** it:

```gdscript
	# Equipment-slot unequip path: must be before can_drop_slot_drag_data
	if data is Dictionary and data.get(DRAG_DATA_TYPE_KEY) == DRAG_DATA_TYPE_EQUIPMENT_SLOT:
		if not can_drop_slot_drag_data(target_slot_index, data):
			return
		var source_slot: EquipmentData.EquipmentSlot = data[&"source_slot"] as EquipmentData.EquipmentSlot
		var item: EquipmentData = _equipment_component.get_item_in_slot(source_slot)
		if item == null:
			return
		_equipment_component.unequip(source_slot)
		var inv_data: Resource = _inventory_component.call("get_inventory_data")
		inv_data.call("set_slot", target_slot_index, item, 1)
		_inventory_component.call("notify_inventory_changed")
		_refresh_inventory_slots_from_data()
		_refresh_character_board()
		return
```

- [ ] **Step 7: Verify parse — no errors**

```
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | head -40
```

- [ ] **Step 8: Commit**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git add src/ui/desktop/inventory/inventory_panel.gd
git commit -m "feat: add equipment drag-and-drop to inventory panel"
```

---

### Task 6: Wire UiManager and Overworld

**Files:**
- Modify: `src/ui/common/ui_manager.gd`
- Modify: `src/world/overworld/overworld.gd`

Context:
- `UiManager._on_hud_slot_pressed` currently only reacts to `action_id == "inventory"` or `slot_index == inventory_hud_slot_index`. The "equipment" HUD slot (slot 0) does nothing.
- `Overworld._wire_inventory_panel_dependency()` currently only calls `ui_manager.bind_inventory_component()`. It is called both on player registration AND on every inventory toggle keypress — so the new call must be idempotent (it is, because `set_equipment_component` has the `if _equipment_component == comp: return` guard).

- [ ] **Step 1: Add `bind_equipment_component` to ui_manager.gd**

Find `func bind_inventory_component(component: Node) -> void:` in `src/ui/common/ui_manager.gd`. Add the following function immediately after it:

```gdscript
func bind_equipment_component(comp: PlayerEquipmentComponent) -> void:
	if _inventory_panel == null:
		return
	if _inventory_panel.has_method("set_equipment_component"):
		_inventory_panel.call("set_equipment_component", comp)
```

**Important:** The parameter type is `PlayerEquipmentComponent` (concrete type), NOT `Node` like `bind_inventory_component`. Do not copy the `Node` type from the inventory version — the stronger typing is intentional.

- [ ] **Step 2: Extend `_on_hud_slot_pressed` in ui_manager.gd**

Find:
```gdscript
func _on_hud_slot_pressed(action_id: StringName, slot_index: int) -> void:
	if is_menu_visible():
		return
	if action_id == StringName("inventory") or slot_index == inventory_hud_slot_index:
		toggle_inventory()
```

Change to:
```gdscript
func _on_hud_slot_pressed(action_id: StringName, slot_index: int) -> void:
	if is_menu_visible():
		return
	if action_id == StringName("inventory") or action_id == StringName("equipment") \
			or slot_index == inventory_hud_slot_index:
		toggle_inventory()
```

- [ ] **Step 3: Add `bind_equipment_component` call in overworld.gd**

Find `func _wire_inventory_panel_dependency(player_instance: Player) -> void:` in `src/world/overworld/overworld.gd`. It currently reads:

```gdscript
func _wire_inventory_panel_dependency(player_instance: Player) -> void:
	if ui_manager == null or player_instance == null:
		return
	var inventory_component: Node = player_instance.get_node_or_null("PlayerInventoryComponent") as Node
	ui_manager.bind_inventory_component(inventory_component)
```

Add one line after `ui_manager.bind_inventory_component(inventory_component)`:

```gdscript
	ui_manager.bind_equipment_component(player_instance.equipment_component)
```

Note: `player_instance.equipment_component` is the `@onready` typed property on `player.gd` pointing to `PlayerEquipmentComponent`. This property already exists from the items-skills implementation.

- [ ] **Step 4: Verify parse — no errors**

```
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | head -40
```

- [ ] **Step 5: Commit**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git add src/ui/common/ui_manager.gd src/world/overworld/overworld.gd
git status --short  # verify no other files accidentally staged
git commit -m "feat: wire equipment component to inventory panel via UiManager"
```

---

### Task 7: Manual smoke test

This feature has no headless test coverage (it is pure UI). Test manually by running the game.

- [ ] **Step 1: Start the game**

Open the project in Godot and run from the editor (or launch the executable).

- [ ] **Step 2: Test — CharacterBoard renders correctly**

1. Start a session and open the inventory panel (press the inventory HUD button OR the equipment HUD button at slot 0)
2. The CharacterBoard (right side) should show 5 rows: Weapon, Helmet, Chest, Boots, Accessory
3. Each row shows: a 64×64 slot button | label | "— Empty —" (grey)
4. The stats section (left board, top half) should show: Max HP, Max Energy, Attack, Defense with numeric values

- [ ] **Step 3: Test — equip an item via drag**

Precondition: The iron_sword item resource exists at `res://src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres`. If no item is in the player's inventory, add it temporarily via the Godot debugger or a test scene.

1. Drag an item from the inventory grid over the correct equipment slot (e.g., a weapon onto the Weapon row)
2. Drop it — the inventory slot should empty, the equipment slot should show the item's icon and name
3. The Stats section should update immediately with new values

- [ ] **Step 4: Test — unequip via drag back**

1. Drag the equipped item from the equipment slot back to an empty inventory grid slot
2. The equipment slot should return to "— Empty —" (grey)
3. The inventory slot should show the item again

- [ ] **Step 5: Test — wrong slot rejection**

1. Try to drag a weapon onto the Helmet slot — the drop should be rejected (item snaps back)

- [ ] **Step 6: Test — equipment HUD button**

1. Press the equipment HUD button (slot 0, leftmost button) — the inventory panel should open/close

- [ ] **Step 7: Commit if all tests pass**

```bash
cd "C:/Users/Anton.Khrobust/projects/aethergate"
git status --short
git commit --allow-empty -m "test: equipment UI manual smoke test passed"
```

If any test fails, fix the issue before committing.
