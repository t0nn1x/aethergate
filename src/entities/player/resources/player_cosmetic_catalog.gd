class_name PlayerCosmeticCatalog
extends Resource

## Data catalog for player cosmetic variants.

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/entities/player/resources/player_appearance_data.gd"
)

const SLOT_HEAD: StringName = &"head"
const SLOT_BODY: StringName = &"body"
const SLOT_LEGS: StringName = &"legs"
const SLOT_WEAPON: StringName = &"weapon"

@export var default_appearance: Resource
@export var head_variants: Dictionary = {}
@export var body_variants: Dictionary = {}
@export var legs_variants: Dictionary = {}
@export var weapon_front_variants: Dictionary = {}
@export var weapon_back_variants: Dictionary = {}


func get_default_appearance() -> Resource:
	if default_appearance == null:
		var fallback: Resource = PLAYER_APPEARANCE_DATA_SCRIPT.new()
		if fallback and fallback.has_method("ensure_defaults"):
			fallback.call("ensure_defaults")
		return fallback
	if default_appearance.has_method("duplicate_data"):
		return default_appearance.call("duplicate_data") as Resource
	return default_appearance


func get_ids_for_slot(slot: StringName) -> Array[StringName]:
	var source: Dictionary = _get_variant_dictionary(slot)
	var id_strings: Array[String] = []
	for key_variant in source.keys():
		id_strings.append(str(key_variant))
	id_strings.sort()

	var ids: Array[StringName] = []
	for id_string in id_strings:
		ids.append(StringName(id_string))
	return ids


func is_valid_id(slot: StringName, candidate_id: StringName) -> bool:
	if candidate_id == StringName():
		return false
	var source: Dictionary = _get_variant_dictionary(slot)
	return source.has(String(candidate_id))


func get_head_texture(head_id: StringName) -> Texture2D:
	return _resolve_part_texture(SLOT_HEAD, head_id)


func get_body_texture(body_id: StringName) -> Texture2D:
	return _resolve_part_texture(SLOT_BODY, body_id)


func get_legs_texture(legs_id: StringName) -> Texture2D:
	return _resolve_part_texture(SLOT_LEGS, legs_id)


func get_weapon_front_texture(weapon_visual_id: StringName) -> Texture2D:
	return _resolve_weapon_texture(weapon_front_variants, weapon_visual_id)


func get_weapon_back_texture(weapon_visual_id: StringName) -> Texture2D:
	return _resolve_weapon_texture(weapon_back_variants, weapon_visual_id)


func _resolve_part_texture(slot: StringName, variant_id: StringName) -> Texture2D:
	var source: Dictionary = _get_variant_dictionary(slot)
	var default_id: StringName = _get_default_id_for_slot(slot)
	var texture: Texture2D = _resolve_texture_with_fallback(source, variant_id, default_id)
	if texture:
		return texture

	push_warning("PlayerCosmeticCatalog: no texture resolved for slot '%s'." % String(slot))
	return null


func _resolve_weapon_texture(source: Dictionary, variant_id: StringName) -> Texture2D:
	if variant_id == StringName():
		return null
	var default_id: StringName = _get_default_id_for_slot(SLOT_WEAPON)
	return _resolve_texture_with_fallback(source, variant_id, default_id)


func _resolve_texture_with_fallback(
	source: Dictionary,
	variant_id: StringName,
	default_id: StringName
) -> Texture2D:
	var requested_key: String = String(variant_id)
	if not requested_key.is_empty() and source.has(requested_key):
		return source.get(requested_key) as Texture2D

	var fallback_key: String = String(default_id)
	if not fallback_key.is_empty() and source.has(fallback_key):
		return source.get(fallback_key) as Texture2D

	if source.is_empty():
		return null

	var sorted_keys: Array[String] = []
	for key_variant in source.keys():
		sorted_keys.append(str(key_variant))
	sorted_keys.sort()
	var first_key: String = sorted_keys[0]
	return source.get(first_key) as Texture2D


func _get_default_id_for_slot(slot: StringName) -> StringName:
	if default_appearance == null:
		return StringName()
	var key: String = ""
	match slot:
		SLOT_HEAD:
			key = "head_id"
		SLOT_BODY:
			key = "body_id"
		SLOT_LEGS:
			key = "legs_id"
		SLOT_WEAPON:
			key = "weapon_visual_id"
		_:
			return StringName()
	return StringName(str(default_appearance.get(key)))


func _get_variant_dictionary(slot: StringName) -> Dictionary:
	match slot:
		SLOT_HEAD:
			return head_variants
		SLOT_BODY:
			return body_variants
		SLOT_LEGS:
			return legs_variants
		SLOT_WEAPON:
			return weapon_front_variants
	return {}
