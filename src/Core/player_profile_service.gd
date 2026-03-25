extends Node

## Holds local player appearance selection for current runtime only.

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/Entities/Player/Resources/player_appearance_data.gd"
)
const PROFILE_SAVE_PATH: String = "user://player_profile.cfg"
const SETTINGS_SECTION: String = "settings"
const SETTINGS_KEY_PREFERRED_LOCALE: String = "preferred_locale"
const COMBAT_SECTION: String = "combat"
const KEY_PLAYER_LEVEL: String = "player_level"
const KEY_PLAYER_XP: String = "player_xp"
const BASE_XP_PER_LEVEL: int = 100  ## XP needed: level * BASE_XP_PER_LEVEL
const PROFILE_SECTION: String = "profile"
const KEY_SETUP_COMPLETED: String = "setup_completed"

@export var cosmetic_catalog: Resource = preload(
	"res://src/Entities/Player/Resources/player_cosmetic_catalog.tres"
)

var _appearance: Resource
var _preferred_locale: StringName = StringName()
var _player_level: int = 1
var _player_xp: int = 0
var _setup_completed: bool = false


func _ready() -> void:
	_appearance = _resolve_default_appearance()
	_load_locale_preference()
	_load_combat_profile()
	_load_setup_completed()


func get_catalog() -> Resource:
	return cosmetic_catalog


func get_appearance() -> Resource:
	if _appearance == null:
		_appearance = _resolve_default_appearance()
	if _appearance and _appearance.has_method("duplicate_data"):
		return _appearance.call("duplicate_data") as Resource
	return _appearance


func set_appearance(appearance: Resource, mark_complete: bool = true) -> void:
	if appearance == null:
		push_warning("PlayerProfileService: cannot save null appearance.")
		return

	_appearance = _sanitize_appearance(appearance)
	if mark_complete and not _setup_completed:
		_setup_completed = true
		_save_setup_completed()


func has_completed_setup() -> bool:
	return _setup_completed


func mark_setup_completed(completed: bool = true) -> void:
	if _setup_completed == completed:
		return
	_setup_completed = completed
	_save_setup_completed()


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


func get_player_level() -> int:
	return _player_level


func get_player_xp() -> int:
	return _player_xp


func add_xp(amount: int) -> void:
	_player_xp += amount
	var xp_needed: int = _player_level * BASE_XP_PER_LEVEL
	while _player_xp >= xp_needed:
		_player_xp -= xp_needed
		_player_level += 1
		xp_needed = _player_level * BASE_XP_PER_LEVEL
	_save_combat_profile()


func _load_combat_profile() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	if profile_data.load(PROFILE_SAVE_PATH) != OK:
		return
	_player_level = int(profile_data.get_value(COMBAT_SECTION, KEY_PLAYER_LEVEL, 1))
	_player_xp = int(profile_data.get_value(COMBAT_SECTION, KEY_PLAYER_XP, 0))


func _load_setup_completed() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	if profile_data.load(PROFILE_SAVE_PATH) != OK:
		return
	_setup_completed = bool(profile_data.get_value(PROFILE_SECTION, KEY_SETUP_COMPLETED, false))


func _save_setup_completed() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	profile_data.load(PROFILE_SAVE_PATH)
	profile_data.set_value(PROFILE_SECTION, KEY_SETUP_COMPLETED, _setup_completed)
	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
	if save_error != OK and OS.is_debug_build():
		push_warning("PlayerProfileService: failed to save setup_completed (%d)." % int(save_error))


func _save_combat_profile() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	profile_data.load(PROFILE_SAVE_PATH)
	profile_data.set_value(COMBAT_SECTION, KEY_PLAYER_LEVEL, _player_level)
	profile_data.set_value(COMBAT_SECTION, KEY_PLAYER_XP, _player_xp)
	profile_data.save(PROFILE_SAVE_PATH)


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
