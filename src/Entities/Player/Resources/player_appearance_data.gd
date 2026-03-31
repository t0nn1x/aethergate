class_name PlayerAppearanceData
extends Resource

## Serializable skin selection for the local player.

const DEFAULT_SKIN_ID: StringName = &"1"
const DEFAULT_HEAD_ID: StringName = &"head_1"
const DEFAULT_BODY_ID: StringName = &"body_1"
const DEFAULT_LEGS_ID: StringName = &"legs_1"

@export var skin_id: StringName = StringName()
@export var head_id: StringName = DEFAULT_HEAD_ID
@export var body_id: StringName = DEFAULT_BODY_ID
@export var legs_id: StringName = DEFAULT_LEGS_ID
@export var weapon_visual_id: StringName = &""


func ensure_defaults() -> void:
	if skin_id == StringName():
		skin_id = DEFAULT_SKIN_ID
	if head_id == StringName():
		head_id = DEFAULT_HEAD_ID
	if body_id == StringName():
		body_id = DEFAULT_BODY_ID
	if legs_id == StringName():
		legs_id = DEFAULT_LEGS_ID


func duplicate_data() -> Resource:
	var duplicated: Resource = duplicate(true)
	if duplicated == null:
		duplicated = PlayerAppearanceData.new()
		duplicated.skin_id = skin_id
		duplicated.head_id = head_id
		duplicated.body_id = body_id
		duplicated.legs_id = legs_id
		duplicated.weapon_visual_id = weapon_visual_id
	if duplicated.has_method("ensure_defaults"):
		duplicated.call("ensure_defaults")
	return duplicated


func to_dictionary() -> Dictionary:
	return {
		"skin_id": String(skin_id),
		"head_id": String(head_id),
		"body_id": String(body_id),
		"legs_id": String(legs_id),
		"weapon_visual_id": String(weapon_visual_id)
	}


func from_dictionary(data: Dictionary) -> void:
	if data.is_empty():
		ensure_defaults()
		return

	var has_skin_id: bool = data.has("skin_id")
	var has_legacy_slots: bool = data.has("head_id") or data.has("body_id") or data.has("legs_id")
	if has_skin_id:
		skin_id = StringName(str(data.get("skin_id", skin_id)))
	if has_legacy_slots:
		head_id = StringName(str(data.get("head_id", head_id)))
		body_id = StringName(str(data.get("body_id", body_id)))
		legs_id = StringName(str(data.get("legs_id", legs_id)))
		ensure_legacy_defaults()
	elif not has_skin_id:
		ensure_defaults()
	weapon_visual_id = StringName(str(data.get("weapon_visual_id", weapon_visual_id)))


func ensure_legacy_defaults() -> void:
	if head_id == StringName():
		head_id = DEFAULT_HEAD_ID
	if body_id == StringName():
		body_id = DEFAULT_BODY_ID
	if legs_id == StringName():
		legs_id = DEFAULT_LEGS_ID
