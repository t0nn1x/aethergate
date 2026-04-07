# Equipment UI Design

## Goal

Wire the existing `CharacterBoard` in `InventoryPanel` to display and interact with the player's equipped items and combined stats, using drag-and-drop from the inventory grid.

## Scope

Desktop only. Mobile hides `CharacterBoard` — no mobile work in this iteration. Skills display is out of scope.

---

## Architecture

`InventoryPanel` owns all equipment display logic. Two separate injections exist — both wired inside `overworld.gd`'s `_wire_inventory_panel_dependency(player_instance)`, which is already called from `_wire_local_player_dependencies()` (on player registration) and from `_toggle_inventory_panel()` (on every inventory key press):

- **Existing:** `ui_manager.bind_inventory_component(inventory_component)`
- **New:** `ui_manager.bind_equipment_component(equipment_component)`  
  → `UiManager.bind_equipment_component(comp: PlayerEquipmentComponent) -> void`  
  → calls `_inventory_panel.call("set_equipment_component", comp)`

`InventoryPanel` gains:

```gdscript
func set_equipment_component(comp: PlayerEquipmentComponent) -> void:
    if _equipment_component == comp:
        return  # reconnection guard — called on every toggle, must be idempotent
    if _equipment_component != null and _equipment_component.equipment_changed.is_connected(_refresh_character_board):
        _equipment_component.equipment_changed.disconnect(_refresh_character_board)
    _equipment_component = comp
    if comp != null:
        comp.equipment_changed.connect(_refresh_character_board)
        _refresh_character_board()
```

The guard ensures repeated calls (every inventory toggle) are no-ops when the same component is passed. Signal connections are never duplicated.

`_refresh_character_board()` signature:
```gdscript
func _refresh_character_board(_slot: EquipmentData.EquipmentSlot = EquipmentData.EquipmentSlot.WEAPON, _item: EquipmentData = null) -> void:
```
The two parameters match `equipment_changed` signal shape but are ignored — the method always does a full refresh. This allows it to be connected directly to the signal and also called standalone.

**`_refresh_character_board()` logic:**
1. Guard: `if _equipment_component == null: return`
2. For each of 5 slots: read `_equipment_component.get_item_in_slot(slot)`, update the corresponding `EquipmentSlotButton` visual and item name label
3. Call `PlayerProgressionService.build_player_snapshot()` → read `.base_stats` (a `CombatStats` — already includes equipment bonuses) → update 4 stat value labels

**Cold-start safety:** If called before the component is injected, the guard exits early. If `PlayerProgressionService` has no equipment component yet, `build_player_snapshot()` returns level-only base stats — correct display until equipment is wired.

**HUD slot 0 ("equipment"):** Wire in `UiManager._on_hud_slot_pressed` by extending the existing condition:

```gdscript
if action_id == StringName("inventory") or action_id == StringName("equipment") \
        or slot_index == inventory_hud_slot_index:
    toggle_inventory()
```

Both buttons open/close the same `InventoryPanel`. The HUD icon flip logic (`_sync_inventory_hud_slot_icon`) covers slot 3 only — slot 0 gets no icon flip in this iteration.

---

## Components

### CharacterBoard — Clean 5-Slot List

The 12 `TextureButton` doll nodes (`HeadSlot`, `LeftShoulderSlot`, etc.) are **removed entirely** from `inventory_panel.tscn`. The following dead code is also removed from `inventory_panel.gd`:

- `_character_slots: Dictionary`
- `_cache_character_slots()` and its call in `_ready()`
- `_apply_character_slot_sizes()` and its call in `_apply_responsive_layout()`
- `_resolve_character_slots_global_rect()` — used in `_apply_windows_character_background_layout()` to compute `slots_rect`. After removing the doll, replace the call with `$CharacterBoard/CharacterVBox/EquipmentSlotList.get_global_rect()` (the new list's tight bounding rect serves the same purpose — computing content height for the Windows background panel). Remove `_resolve_character_slots_global_rect()` entirely.

`CharacterBoard` gets a clean vertical layout (built at runtime in `_setup_character_board()`, called from `_ready()`):

```
CharacterBoard
└── CharacterVBox (VBoxContainer)
    ├── CharacterTitle (Label) — "Character"
    └── EquipmentSlotList (VBoxContainer, name="EquipmentSlotList")
        ├── WeaponRow    (HBoxContainer)
        ├── HelmetRow    (HBoxContainer)
        ├── ChestRow     (HBoxContainer)
        ├── BootsRow     (HBoxContainer)
        └── AccessoryRow (HBoxContainer)
```

Each row contains:
- **`EquipmentSlotButton`** (64×64, script: `equipment_slot_button.gd`) — slot texture asset, draggable if equipped, always a drop target
- **Slot name label** (Label) — "Weapon", "Helmet", "Chest", "Boots", "Accessory"
- **Item name label** (Label, `size_flags_horizontal = Control.SIZE_EXPAND_FILL`, `horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT`) — `display_name` if equipped; `"— Empty —"` with `add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))` if not

All 5 `EquipmentSlotButton` instances are cached in a new `_equipment_slot_buttons: Dictionary` (keyed by `EquipmentData.EquipmentSlot` enum int) for O(1) access during refresh.

All 5 item name labels are cached in `_equipment_item_labels: Dictionary` (same keying) for O(1) access during refresh.

### EquipmentSlotButton (`src/ui/desktop/inventory/equipment_slot_button.gd`)

Mirrors `inventory_slot_button.gd`. Key members:

```gdscript
var _slot: EquipmentData.EquipmentSlot = EquipmentData.EquipmentSlot.WEAPON
var _inventory_panel: Node = null

func configure(inventory_panel: Node, slot: EquipmentData.EquipmentSlot) -> void:
    _inventory_panel = inventory_panel
    _slot = slot

func _get_drag_data(_pos: Vector2) -> Variant:
    return _inventory_panel.build_equipment_drag_data(_slot)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
    return _inventory_panel.can_drop_on_equipment_slot(_slot, data)

func _drop_data(_pos: Vector2, data: Variant) -> void:
    _inventory_panel.drop_on_equipment_slot(_slot, data)

func _notification(what: int) -> void:
    if what == NOTIFICATION_DRAG_END:
        _inventory_panel.end_equipment_drag_visual(_slot)
```

### Drag-and-Drop — New Panel Methods

New constants in `inventory_panel.gd`:
```gdscript
const DRAG_DATA_TYPE_EQUIPMENT_SLOT: StringName = &"equipment_slot"
# Note: existing DRAG_DATA_TYPE_SLOT = &"inventory_slot" is a StringName — use StringName comparisons throughout
```

**`build_equipment_drag_data(slot: EquipmentData.EquipmentSlot) -> Variant`**
```gdscript
func build_equipment_drag_data(slot: EquipmentData.EquipmentSlot) -> Variant:
    if _equipment_component == null:
        return null
    var item: EquipmentData = _equipment_component.get_item_in_slot(slot)
    if item == null:
        return null
    return {
        DRAG_DATA_TYPE_KEY:        DRAG_DATA_TYPE_EQUIPMENT_SLOT,
        &"source_slot":            slot,
        DRAG_DATA_SOURCE_PANEL_KEY: get_instance_id(),
        DRAG_DATA_ICON_KEY:        item.get_icon_texture(),  # ItemData.get_icon_texture() — auto-resolves
        DRAG_DATA_AMOUNT_KEY:      1
    }
```

**`can_drop_on_equipment_slot(target_slot: EquipmentData.EquipmentSlot, data: Variant) -> bool`**
- Accepts `drag_type == DRAG_DATA_TYPE_SLOT` (inventory → equipment):
  - `data[DRAG_DATA_SOURCE_PANEL_KEY] == get_instance_id()`
  - Source inventory slot index is valid and not empty
  - Item at that slot `is EquipmentData` and `item.slot == target_slot`
- Rejects `drag_type == DRAG_DATA_TYPE_EQUIPMENT_SLOT` (equipment-to-equipment not supported in this iteration)
- Returns `false` for all other types

**`drop_on_equipment_slot(target_slot: EquipmentData.EquipmentSlot, data: Variant) -> void`**
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
    # equip() is infallible at this call site: can_drop_on_equipment_slot already verified
    # item.slot == target_slot and item is EquipmentData, so equip() cannot reject.
    var displaced: EquipmentData = _equipment_component.get_item_in_slot(target_slot)
    _equipment_component.equip(item)
    # Clear the inventory source slot
    var inv_data: Resource = _inventory_component.call("get_inventory_data")
    inv_data.call("set_slot", source_index, null, 0)
    if displaced != null:
        # Put displaced item back into the source slot
        inv_data.call("set_slot", source_index, displaced, 1)
    _inventory_component.call("notify_inventory_changed")
    _refresh_inventory_slots_from_data()
    _refresh_character_board()
```

**`end_equipment_drag_visual(slot: EquipmentData.EquipmentSlot) -> void`**
- Calls `_refresh_character_board()` to restore visuals if drag was cancelled.

**`can_drop_slot_drag_data` (existing, extended)**

`_is_valid_drag_payload` hard-rejects anything that isn't `DRAG_DATA_TYPE_SLOT`. The equipment-unequip path must be inserted **before** `_is_valid_drag_payload` is called, at the very top of `can_drop_slot_drag_data`:
```gdscript
func can_drop_slot_drag_data(target_slot_index: int, data: Variant) -> bool:
    # NEW: equipment-slot unequip path — must be checked BEFORE _is_valid_drag_payload
    if data is Dictionary and data.get(DRAG_DATA_TYPE_KEY) == DRAG_DATA_TYPE_EQUIPMENT_SLOT:
        return int(data.get(DRAG_DATA_SOURCE_PANEL_KEY, -1)) == get_instance_id() \
            and _equipment_component != null
    # ... existing code unchanged below this line
    if not _is_valid_drag_payload(data):
        ...
```

**`drop_slot_drag_data` (existing, extended)**

Likewise, the equipment path must be inserted **before** `can_drop_slot_drag_data` is called (which would reject it):
```gdscript
func drop_slot_drag_data(target_slot_index: int, data: Variant) -> void:
    # NEW: equipment-slot unequip path — before the existing guard
    if data is Dictionary and data.get(DRAG_DATA_TYPE_KEY) == DRAG_DATA_TYPE_EQUIPMENT_SLOT:
        if not can_drop_slot_drag_data(target_slot_index, data):
            return
        var source_slot: EquipmentData.EquipmentSlot = data[&"source_slot"]
        # Capture item BEFORE unequipping (unequip() returns void)
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
    # ... existing inventory-swap path continues unchanged
    if not can_drop_slot_drag_data(target_slot_index, data):
        return
    ...
```

### Stats Section

`SkillsContent` (currently empty `Control` inside `SkillsSection`) is replaced with a `VBoxContainer` in the `.tscn`, then populated with 4 stat rows at runtime in `_setup_stats_section()` called from `_ready()`:

```
SkillsContent (VBoxContainer)
    ├── HpRow     (HBoxContainer) — Label "Max HP"     | Label [value] HORIZONTAL_ALIGNMENT_RIGHT
    ├── EnergyRow (HBoxContainer) — Label "Max Energy" | Label [value] HORIZONTAL_ALIGNMENT_RIGHT
    ├── AtkRow    (HBoxContainer) — Label "Attack"     | Label [value] HORIZONTAL_ALIGNMENT_RIGHT
    └── DefRow    (HBoxContainer) — Label "Defense"    | Label [value] HORIZONTAL_ALIGNMENT_RIGHT
```

Value labels cached in `_stat_value_labels: Dictionary` keyed by `StringName` (`&"max_hp"`, `&"max_energy"`, `&"attack"`, `&"defense"`). Updated each `_refresh_character_board()` call:

```gdscript
var snap: CombatantSnapshot = PlayerProgressionService.build_player_snapshot()
_stat_value_labels[&"max_hp"].text    = str(snap.base_stats.max_hp)
_stat_value_labels[&"max_energy"].text = str(snap.base_stats.max_energy)
_stat_value_labels[&"attack"].text    = str(int(snap.base_stats.attack))
_stat_value_labels[&"defense"].text   = str(int(snap.base_stats.defense))
```

---

## Files Changed

| File | Change |
|---|---|
| `src/ui/desktop/inventory/inventory_panel.tscn` | Remove 12 doll `TextureButton` nodes; `SkillsContent` becomes `VBoxContainer`; `EquipmentSlotList` rows added (or built entirely at runtime) |
| `src/ui/desktop/inventory/inventory_panel.gd` | Add `set_equipment_component()`, `_refresh_character_board()`, `_setup_character_board()`, `_setup_stats_section()`, all equipment D&D methods; remove `_character_slots`, `_cache_character_slots()`, `_apply_character_slot_sizes()`, `_resolve_character_slots_global_rect()` (replace call in `_apply_windows_character_background_layout` with `$CharacterBoard/CharacterVBox/EquipmentSlotList.get_global_rect()`); extend `can_drop_slot_drag_data` and `drop_slot_drag_data` with equipment path **inserted before** existing guard calls |
| `src/ui/desktop/inventory/equipment_slot_button.gd` | **New file** — mirrors `inventory_slot_button.gd` for equipment slots |
| `src/ui/common/ui_manager.gd` | Add `bind_equipment_component(comp: PlayerEquipmentComponent) -> void`; wire `"equipment"` action in `_on_hud_slot_pressed` |
| `src/world/overworld/overworld.gd` | In `_wire_inventory_panel_dependency()`: add `ui_manager.bind_equipment_component(player_instance.equipment_component)` alongside the existing `bind_inventory_component` call |

---

## Out of Scope

- Skills display in `SkillsSection`
- Mobile equipment UI (`InventoryPanelMobile` keeps `CharacterBoard` hidden)
- Equipment-to-equipment slot swapping
- Tap-to-equip (drag only)
- Item tooltips / detail popups
- HUD icon flip for the equipment button (slot 0)
