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
