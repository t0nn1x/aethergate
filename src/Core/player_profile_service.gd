extends Node

## Holds local player appearance selection for current runtime only.

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/Entities/Player/Resources/player_appearance_data.gd"
)
const PROFILE_SAVE_PATH: String = "user://player_profile.cfg"
const SETTINGS_SECTION: String = "settings"
const SETTINGS_KEY_PREFERRED_LOCALE: String = "preferred_locale"

@export var cosmetic_catalog: Resource = preload(
	"res://src/Entities/Player/Resources/player_cosmetic_catalog.tres"
)

var _appearance: Resource
var _preferred_locale: StringName = StringName()


func _ready() -> void:
	_appearance = _resolve_default_appearance()
	_load_locale_preference()


func get_catalog() -> Resource:
	return cosmetic_catalog


func get_appearance() -> Resource:
	if _appearance == null:
		_appearance = _resolve_default_appearance()
	if _appearance and _appearance.has_method("duplicate_data"):
		return _appearance.call("duplicate_data") as Resource
	return _appearance


func set_appearance(appearance: Resource, _mark_completed: bool = true) -> void:
	if appearance == null:
		push_warning("PlayerProfileService: cannot save null appearance.")
		return

	_appearance = _sanitize_appearance(appearance)
	# Persistence is intentionally disabled for now.
	# Keep selected appearance only for the current runtime session.


func has_completed_setup() -> bool:
	# Force creator flow on every Play for now.
	return false


func mark_setup_completed(_completed: bool = true) -> void:
	pass


func reset_profile() -> void:
	_appearance = _resolve_default_appearance()
	_preferred_locale = StringName()
	_save_locale_preference()


func get_preferred_locale() -> StringName:
	return _preferred_locale


func set_preferred_locale(locale_code: StringName) -> void:
	var normalized_locale: StringName = StringName(String(locale_code).strip_edges().to_lower())
	if normalized_locale == _preferred_locale:
		return
	_preferred_locale = normalized_locale
	_save_locale_preference()


func _resolve_default_appearance() -> Resource:
	if cosmetic_catalog and cosmetic_catalog.has_method("get_default_appearance"):
		return cosmetic_catalog.call("get_default_appearance") as Resource
	var fallback: Resource = PLAYER_APPEARANCE_DATA_SCRIPT.new()
	if fallback and fallback.has_method("ensure_defaults"):
		fallback.call("ensure_defaults")
	return fallback


func _sanitize_appearance(appearance: Resource) -> Resource:
	var sanitized: Resource = appearance
	if appearance and appearance.has_method("duplicate_data"):
		sanitized = appearance.call("duplicate_data") as Resource
	if cosmetic_catalog == null:
		return sanitized

	var defaults: Resource = _resolve_default_appearance()
	_sanitize_slot_id(sanitized, defaults, "head_id", "head")
	_sanitize_slot_id(sanitized, defaults, "body_id", "body")
	_sanitize_slot_id(sanitized, defaults, "legs_id", "legs")

	var weapon_id: StringName = StringName(str(sanitized.get("weapon_visual_id")))
	if weapon_id != StringName():
		var has_weapon_front: bool = _catalog_get_weapon_texture("get_weapon_front_texture", weapon_id) != null
		var has_weapon_back: bool = _catalog_get_weapon_texture("get_weapon_back_texture", weapon_id) != null
		if not has_weapon_front and not has_weapon_back:
			sanitized.set("weapon_visual_id", StringName())

	return sanitized


func _sanitize_slot_id(
	sanitized: Resource,
	defaults: Resource,
	field_name: String,
	slot_name: StringName
) -> void:
	if sanitized == null or defaults == null:
		return
	var current_id: StringName = StringName(str(sanitized.get(field_name)))
	if _catalog_is_valid_id(slot_name, current_id):
		return
	sanitized.set(field_name, StringName(str(defaults.get(field_name))))


func _catalog_is_valid_id(slot_name: StringName, candidate_id: StringName) -> bool:
	if cosmetic_catalog == null or not cosmetic_catalog.has_method("is_valid_id"):
		return false
	return bool(cosmetic_catalog.call("is_valid_id", slot_name, candidate_id))


func _catalog_get_weapon_texture(method_name: String, weapon_id: StringName) -> Texture2D:
	if cosmetic_catalog == null or not cosmetic_catalog.has_method(method_name):
		return null
	return cosmetic_catalog.call(method_name, weapon_id) as Texture2D


func _load_locale_preference() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	var load_error: Error = profile_data.load(PROFILE_SAVE_PATH)
	if load_error != OK:
		return

	var stored_locale: String = String(
		profile_data.get_value(SETTINGS_SECTION, SETTINGS_KEY_PREFERRED_LOCALE, "")
	).strip_edges().to_lower()
	if stored_locale.is_empty():
		return

	_preferred_locale = StringName(stored_locale)


func _save_locale_preference() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	var load_error: Error = profile_data.load(PROFILE_SAVE_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		if OS.is_debug_build():
			push_warning("PlayerProfileService: failed to load profile config (%d)." % int(load_error))
		return

	var locale_text: String = String(_preferred_locale).strip_edges().to_lower()
	if locale_text.is_empty():
		profile_data.erase_section_key(SETTINGS_SECTION, SETTINGS_KEY_PREFERRED_LOCALE)
	else:
		profile_data.set_value(SETTINGS_SECTION, SETTINGS_KEY_PREFERRED_LOCALE, locale_text)

	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
	if save_error != OK and OS.is_debug_build():
		push_warning("PlayerProfileService: failed to save profile config (%d)." % int(save_error))
