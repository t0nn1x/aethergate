class_name PlayerAppearanceData
extends Resource

## Serializable cosmetic selection for the local player.

@export var head_id: StringName = &"head_1"
@export var body_id: StringName = &"body_1"
@export var legs_id: StringName = &"legs_1"
@export var weapon_visual_id: StringName = &""


func ensure_defaults() -> void:
	if head_id == StringName():
		head_id = &"head_1"
	if body_id == StringName():
		body_id = &"body_1"
	if legs_id == StringName():
		legs_id = &"legs_1"


func duplicate_data() -> Resource:
	var duplicated: Resource = duplicate(true)
	if duplicated == null:
		duplicated = PlayerAppearanceData.new()
		duplicated.head_id = head_id
		duplicated.body_id = body_id
		duplicated.legs_id = legs_id
		duplicated.weapon_visual_id = weapon_visual_id
	if duplicated.has_method("ensure_defaults"):
		duplicated.call("ensure_defaults")
	return duplicated


func to_dictionary() -> Dictionary:
	return {
		"head_id": String(head_id),
		"body_id": String(body_id),
		"legs_id": String(legs_id),
		"weapon_visual_id": String(weapon_visual_id)
	}


func from_dictionary(data: Dictionary) -> void:
	if data.is_empty():
		ensure_defaults()
		return
	head_id = StringName(str(data.get("head_id", head_id)))
	body_id = StringName(str(data.get("body_id", body_id)))
	legs_id = StringName(str(data.get("legs_id", legs_id)))
	weapon_visual_id = StringName(str(data.get("weapon_visual_id", weapon_visual_id)))
	ensure_defaults()
