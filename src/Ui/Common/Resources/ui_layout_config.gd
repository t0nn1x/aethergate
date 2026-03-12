@tool
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
