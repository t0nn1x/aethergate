extends Node

## Persists player profile data (locale, combat progress, setup state) to user://player_profile.cfg.

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/entities/player/resources/player_appearance_data.gd"
)
const PLAYER_SKIN_CATALOG_SCRIPT := preload(
	"res://src/entities/player/resources/player_skin_catalog.tres"
)
const PLAYER_WEAPON_CATALOG_SCRIPT := preload(
	"res://src/entities/player/resources/player_cosmetic_catalog.tres"
)
const PROFILE_SAVE_PATH: String = "user://player_profile.cfg"
const SETTINGS_SECTION: String = "settings"
const SETTINGS_KEY_PREFERRED_LOCALE: String = "preferred_locale"
const COMBAT_SECTION: String = "combat"
const KEY_PLAYER_LEVEL: String = "player_level"
const KEY_PLAYER_XP: String = "player_xp"
const PROFILE_SECTION: String = "profile"
const KEY_APPEARANCE: String = "appearance"
const KEY_SETUP_COMPLETED: String = "setup_completed"

@export var skin_catalog: Resource = PLAYER_SKIN_CATALOG_SCRIPT
@export var weapon_catalog: Resource = PLAYER_WEAPON_CATALOG_SCRIPT

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
	_load_appearance_profile()


func get_catalog() -> Resource:
	return weapon_catalog


func get_skin_catalog() -> Resource:
	return skin_catalog


func get_weapon_catalog() -> Resource:
	return weapon_catalog


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
	_save_appearance_profile()
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
	_save_appearance_profile()
	_preferred_locale = StringName()
	_save_locale_preference()
	_setup_completed = false
	_save_setup_completed()


func get_preferred_locale() -> StringName:
	return _preferred_locale


func set_preferred_locale(locale_code: StringName) -> void:
	var normalized_locale: StringName = StringName(String(locale_code).strip_edges().to_lower())
	if normalized_locale == _preferred_locale:
		return
	_preferred_locale = normalized_locale
	_save_locale_preference()


func _resolve_default_appearance() -> Resource:
	var fallback: Resource = PLAYER_APPEARANCE_DATA_SCRIPT.new()
	if fallback == null:
		return null
	var default_skin_id: StringName = _resolve_default_skin_id()
	if default_skin_id != StringName():
		fallback.set("skin_id", default_skin_id)
	if fallback and fallback.has_method("ensure_defaults"):
		fallback.call("ensure_defaults")
	return fallback


func _sanitize_appearance(appearance: Resource) -> Resource:
	var sanitized: Resource = appearance
	if appearance and appearance.has_method("duplicate_data"):
		sanitized = appearance.call("duplicate_data") as Resource

	if skin_catalog != null:
		var defaults: Resource = _resolve_default_appearance()
		var skin_id: StringName = StringName(str(sanitized.get("skin_id")))
		if not _catalog_is_valid_skin_id(skin_id):
			sanitized.set("skin_id", StringName(str(defaults.get("skin_id"))))

	var weapon_id: StringName = StringName(str(sanitized.get("weapon_visual_id")))
	if weapon_id != StringName():
		var has_weapon_front: bool = _catalog_get_weapon_texture("get_weapon_front_texture", weapon_id) != null
		var has_weapon_back: bool = _catalog_get_weapon_texture("get_weapon_back_texture", weapon_id) != null
		if not has_weapon_front and not has_weapon_back:
			sanitized.set("weapon_visual_id", StringName())

	return sanitized


func _catalog_is_valid_skin_id(candidate_id: StringName) -> bool:
	if skin_catalog == null or not skin_catalog.has_method("get_skin"):
		return false
	return skin_catalog.call("get_skin", candidate_id) != null


func _catalog_get_weapon_texture(method_name: String, weapon_id: StringName) -> Texture2D:
	if weapon_catalog == null or not weapon_catalog.has_method(method_name):
		return null
	return weapon_catalog.call(method_name, weapon_id) as Texture2D


func _resolve_default_skin_id() -> StringName:
	if skin_catalog == null:
		return PlayerAppearanceData.DEFAULT_SKIN_ID
	if skin_catalog.has_method("get_default_skin"):
		var default_skin: Resource = skin_catalog.call("get_default_skin") as Resource
		if default_skin != null:
			var skin_id: StringName = StringName(str(default_skin.get("skin_id")))
			if skin_id != StringName():
				return skin_id
	if skin_catalog.has_method("get_selectable_skins"):
		var selectable_skins: Array = skin_catalog.call("get_selectable_skins")
		for skin in selectable_skins:
			if skin == null:
				continue
			var skin_id: StringName = StringName(str(skin.get("skin_id")))
			if skin_id != StringName():
				return skin_id
	return PlayerAppearanceData.DEFAULT_SKIN_ID


func get_player_level() -> int:
	return _player_level


func get_player_xp() -> int:
	return _player_xp


## Persists XP directly. Level-up logic lives in PlayerProgressionService.
func add_xp(amount: int) -> void:
	_player_xp += amount
	_save_combat_profile()


## Called by PlayerProgressionService after resolving level-ups.
func set_xp_and_level(new_xp: int, new_level: int) -> void:
	_player_xp = new_xp
	_player_level = new_level
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


func _load_appearance_profile() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	if profile_data.load(PROFILE_SAVE_PATH) != OK:
		return

	var stored_appearance: Variant = profile_data.get_value(PROFILE_SECTION, KEY_APPEARANCE, {})
	if not (stored_appearance is Dictionary):
		return
	var has_legacy_slots: bool = stored_appearance.has("head_id") or stored_appearance.has("body_id") or stored_appearance.has("legs_id")
	var has_skin_id: bool = stored_appearance.has("skin_id")

	var loaded_appearance: Resource = PLAYER_APPEARANCE_DATA_SCRIPT.new()
	if loaded_appearance and loaded_appearance.has_method("from_dictionary"):
		loaded_appearance.call("from_dictionary", stored_appearance)
	if has_legacy_slots and not has_skin_id:
		loaded_appearance.set("skin_id", _resolve_default_skin_id())
	if loaded_appearance and loaded_appearance.has_method("ensure_defaults"):
		loaded_appearance.call("ensure_defaults")
	_appearance = _sanitize_appearance(loaded_appearance)


func _save_setup_completed() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	profile_data.load(PROFILE_SAVE_PATH)
	profile_data.set_value(PROFILE_SECTION, KEY_SETUP_COMPLETED, _setup_completed)
	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
	if save_error != OK and OS.is_debug_build():
		push_warning("PlayerProfileService: failed to save setup_completed (%d)." % int(save_error))


func _save_appearance_profile() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	profile_data.load(PROFILE_SAVE_PATH)
	var appearance_dict: Dictionary = {}
	if _appearance != null and _appearance.has_method("to_dictionary"):
		appearance_dict = _appearance.call("to_dictionary") as Dictionary
	profile_data.set_value(PROFILE_SECTION, KEY_APPEARANCE, appearance_dict)
	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
	if save_error != OK and OS.is_debug_build():
		push_warning("PlayerProfileService: failed to save appearance (%d)." % int(save_error))


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
		if profile_data.has_section_key(SETTINGS_SECTION, SETTINGS_KEY_PREFERRED_LOCALE):
			profile_data.erase_section_key(SETTINGS_SECTION, SETTINGS_KEY_PREFERRED_LOCALE)
	else:
		profile_data.set_value(SETTINGS_SECTION, SETTINGS_KEY_PREFERRED_LOCALE, locale_text)

	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
	if save_error != OK and OS.is_debug_build():
		push_warning("PlayerProfileService: failed to save profile config (%d)." % int(save_error))
