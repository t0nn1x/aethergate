class_name PlayerProfileServiceMigrationTest
extends RefCounted

## Validates player profile appearance persistence and migration behavior.

const PROFILE_SAVE_PATH := "user://player_profile.cfg"
const PROFILE_SECTION := "profile"
const KEY_APPEARANCE := "appearance"
const SERVICE_SCRIPT: Script = preload("res://src/core/player_profile_service.gd")
const APPEARANCE_SCRIPT: Script = preload(
	"res://src/entities/player/resources/player_appearance_data.gd"
)

var _failures: Array[String] = []
var _had_profile_backup: bool = false
var _profile_backup: PackedByteArray = PackedByteArray()


func run() -> bool:
	_failures.clear()
	_backup_profile_file()
	_clear_profile_file()

	_validate_catalog_accessors_and_default_resolution()
	_validate_invalid_skin_persists_as_default()
	_validate_reset_profile_persists_default()
	_validate_non_default_skin_and_shims_persist()
	_validate_legacy_dictionary_falls_back_to_default()
	_validate_weapon_visual_rules()

	_restore_profile_file()
	_print_summary()
	return _failures.is_empty()


func _validate_catalog_accessors_and_default_resolution() -> void:
	var service: Node = _make_service()
	var legacy_catalog: Resource = service.call("get_catalog") as Resource
	var skin_catalog: Resource = service.call("get_skin_catalog") as Resource

	if legacy_catalog == null:
		_add_failure("get_catalog() returned null.")
	else:
		if not legacy_catalog.has_method("get_head_texture"):
			_add_failure("get_catalog() no longer exposes get_head_texture().")
		if not legacy_catalog.has_method("get_body_texture"):
			_add_failure("get_catalog() no longer exposes get_body_texture().")
		if not legacy_catalog.has_method("get_legs_texture"):
			_add_failure("get_catalog() no longer exposes get_legs_texture().")
		if not legacy_catalog.has_method("get_ids_for_slot"):
			_add_failure("get_catalog() no longer exposes get_ids_for_slot().")
		if not legacy_catalog.has_method("is_valid_id"):
			_add_failure("get_catalog() no longer exposes is_valid_id().")
		if not legacy_catalog.has_method("get_weapon_front_texture"):
			_add_failure("get_catalog() no longer exposes weapon lookup methods.")

	if skin_catalog == null:
		_add_failure("get_skin_catalog() returned null.")
		return
	if not skin_catalog.has_method("get_default_skin"):
		_add_failure("get_skin_catalog() does not expose get_default_skin().")
		return

	var default_skin: Resource = skin_catalog.call("get_default_skin") as Resource
	if default_skin == null:
		_add_failure("Skin catalog default skin is missing.")
		return

	var resolved_default: Resource = service.call("_resolve_default_appearance") as Resource
	if resolved_default == null:
		_add_failure("Profile service did not resolve a default appearance.")
		return

	var expected_skin_id: String = String(default_skin.get("skin_id"))
	var actual_skin_id: String = String(resolved_default.get("skin_id"))
	if actual_skin_id != expected_skin_id:
		_add_failure(
			"Default appearance skin_id '%s' did not match catalog default '%s'."
			% [actual_skin_id, expected_skin_id]
		)
	_assert_legacy_shims(resolved_default, "default appearance")


func _validate_invalid_skin_persists_as_default() -> void:
	var service: Node = _make_service()
	var default_skin_id: String = _default_skin_id(service)
	var appearance: Resource = APPEARANCE_SCRIPT.new()
	appearance.set("skin_id", &"does_not_exist")
	appearance.set("weapon_visual_id", StringName())

	service.call("set_appearance", appearance, false)

	var reloaded_service: Node = _make_service()
	var stored: Resource = reloaded_service.call("get_appearance") as Resource
	if stored == null:
		_add_failure("Reloaded appearance is null after saving invalid skin_id.")
		return

	if String(stored.get("skin_id")) != default_skin_id:
		_add_failure("Invalid skin_id did not sanitize to the default skin.")
	if String(stored.get("weapon_visual_id")) != "":
		_add_failure("Blank weapon_visual_id should remain blank.")
	_assert_legacy_shims(stored, "invalid skin reload")


func _validate_reset_profile_persists_default() -> void:
	var service: Node = _make_service()
	var default_skin_id: String = _default_skin_id(service)
	var appearance: Resource = APPEARANCE_SCRIPT.new()
	appearance.set("skin_id", &"2")
	appearance.set("weapon_visual_id", StringName())
	service.call("set_appearance", appearance, false)
	service.call("reset_profile")

	var reloaded_service: Node = _make_service()
	var stored: Resource = reloaded_service.call("get_appearance") as Resource
	if stored == null:
		_add_failure("Reloaded appearance is null after reset_profile().")
		return

	if String(stored.get("skin_id")) != default_skin_id:
		_add_failure("reset_profile() did not persist the default skin.")
	if String(stored.get("weapon_visual_id")) != "":
		_add_failure("reset_profile() should clear weapon_visual_id to blank default.")
	_assert_legacy_shims(stored, "reset profile reload")


func _validate_non_default_skin_and_shims_persist() -> void:
	var service: Node = _make_service()
	var skin_catalog: Resource = service.call("get_skin_catalog") as Resource
	var valid_skin_id: String = "2"
	if skin_catalog != null:
		var selectable_skins: Array = skin_catalog.call("get_selectable_skins")
		if selectable_skins.size() > 1:
			valid_skin_id = String(selectable_skins[1].get("skin_id"))

	var appearance: Resource = APPEARANCE_SCRIPT.new()
	appearance.set("skin_id", StringName(valid_skin_id))
	appearance.set("head_id", &"head_2")
	appearance.set("body_id", &"body_2")
	appearance.set("legs_id", &"legs_2")
	appearance.set("weapon_visual_id", StringName())
	service.call("set_appearance", appearance, false)

	var reloaded_service: Node = _make_service()
	var stored: Resource = reloaded_service.call("get_appearance") as Resource
	if stored == null:
		_add_failure("Reloaded appearance is null after saving non-default skin.")
		return

	if String(stored.get("skin_id")) != valid_skin_id:
		_add_failure("Non-default skin_id did not persist through reload.")
	_assert_shims_equal(stored, "head_2", "body_2", "legs_2", "non-default skin reload")
	if String(stored.get("weapon_visual_id")) != "":
		_add_failure("Blank weapon_visual_id should persist through reload.")

	var invalid_weapon_appearance: Resource = stored.call("duplicate_data") as Resource
	invalid_weapon_appearance.set("weapon_visual_id", &"invalid_weapon")
	service.call("set_appearance", invalid_weapon_appearance, false)

	var invalid_weapon_reload: Node = _make_service()
	var invalid_weapon_stored: Resource = invalid_weapon_reload.call("get_appearance") as Resource
	if invalid_weapon_stored == null:
		_add_failure("Reloaded appearance is null after invalid weapon save.")
		return
	if String(invalid_weapon_stored.get("weapon_visual_id")) != "":
		_add_failure("Invalid weapon_visual_id should sanitize to blank.")
	_assert_shims_equal(invalid_weapon_stored, "head_2", "body_2", "legs_2", "invalid weapon reload")


func _validate_legacy_dictionary_falls_back_to_default() -> void:
	var service: Node = _make_service()
	var default_skin_id: String = _default_skin_id(service)
	_write_profile_file({
		"head_id": "head_2",
		"body_id": "body_2",
		"legs_id": "legs_2",
		"weapon_visual_id": ""
	})

	var reloaded_service: Node = _make_service()
	var appearance: Resource = reloaded_service.call("get_appearance") as Resource
	if appearance == null:
		_add_failure("Legacy profile load returned null appearance.")
		return

	if String(appearance.get("skin_id")) != default_skin_id:
		_add_failure("Legacy slot-era profile did not resolve to the active default skin.")
	if String(appearance.get("weapon_visual_id")) != "":
		_add_failure("Legacy slot-era profile should preserve a blank weapon_visual_id.")
	_assert_shims_equal(appearance, "head_2", "body_2", "legs_2", "legacy profile load")


func _validate_weapon_visual_rules() -> void:
	var service: Node = _make_service()
	var default_skin_id: String = _default_skin_id(service)

	var blank_weapon_appearance: Resource = APPEARANCE_SCRIPT.new()
	blank_weapon_appearance.set("skin_id", StringName(default_skin_id))
	blank_weapon_appearance.set("weapon_visual_id", StringName())
	service.call("set_appearance", blank_weapon_appearance, false)

	var blank_weapon_reload: Node = _make_service()
	var blank_weapon_stored: Resource = blank_weapon_reload.call("get_appearance") as Resource
	if blank_weapon_stored == null:
		_add_failure("Reloaded appearance is null for blank weapon test.")
		return
	if String(blank_weapon_stored.get("weapon_visual_id")) != "":
		_add_failure("Blank weapon_visual_id should survive persistence unchanged.")
	_assert_legacy_shims(blank_weapon_stored, "blank weapon reload")

	var invalid_weapon_appearance: Resource = APPEARANCE_SCRIPT.new()
	invalid_weapon_appearance.set("skin_id", StringName(default_skin_id))
	invalid_weapon_appearance.set("weapon_visual_id", &"invalid_weapon")
	service.call("set_appearance", invalid_weapon_appearance, false)

	var invalid_weapon_reload: Node = _make_service()
	var invalid_weapon_stored: Resource = invalid_weapon_reload.call("get_appearance") as Resource
	if invalid_weapon_stored == null:
		_add_failure("Reloaded appearance is null for invalid weapon test.")
		return
	if String(invalid_weapon_stored.get("weapon_visual_id")) != "":
		_add_failure("Invalid weapon_visual_id should sanitize to blank.")
	_assert_legacy_shims(invalid_weapon_stored, "invalid weapon reload")


func _make_service() -> Node:
	var service: Node = SERVICE_SCRIPT.new()
	if service.has_method("_ready"):
		service.call("_ready")
	return service


func _default_skin_id(service: Node) -> String:
	var resolved_default: Resource = service.call("_resolve_default_appearance") as Resource
	if resolved_default == null:
		return ""
	return String(resolved_default.get("skin_id"))


func _assert_legacy_shims(appearance: Resource, context: String) -> void:
	if appearance == null:
		_add_failure("%s appearance is null while checking legacy shims." % context)
		return

	var head_id: String = String(appearance.get("head_id"))
	var body_id: String = String(appearance.get("body_id"))
	var legs_id: String = String(appearance.get("legs_id"))
	if head_id.is_empty() or body_id.is_empty() or legs_id.is_empty():
		_add_failure("%s is missing one or more legacy shim fields." % context)


func _assert_shims_equal(
	appearance: Resource,
	expected_head_id: String,
	expected_body_id: String,
	expected_legs_id: String,
	context: String
) -> void:
	_assert_legacy_shims(appearance, context)
	if appearance == null:
		return

	if String(appearance.get("head_id")) != expected_head_id:
		_add_failure("%s head_id did not persist." % context)
	if String(appearance.get("body_id")) != expected_body_id:
		_add_failure("%s body_id did not persist." % context)
	if String(appearance.get("legs_id")) != expected_legs_id:
		_add_failure("%s legs_id did not persist." % context)


func _write_profile_file(profile_payload: Dictionary) -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	profile_data.set_value(PROFILE_SECTION, KEY_APPEARANCE, profile_payload)
	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
	if save_error != OK:
		_add_failure("Failed to write legacy profile payload for test.")


func _backup_profile_file() -> void:
	_had_profile_backup = FileAccess.file_exists(PROFILE_SAVE_PATH)
	if not _had_profile_backup:
		return

	var file: FileAccess = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.READ)
	if file == null:
		_add_failure("Unable to back up existing player profile file.")
		_had_profile_backup = false
		return

	_profile_backup = file.get_buffer(file.get_length())


func _clear_profile_file() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(PROFILE_SAVE_PATH)
	if FileAccess.file_exists(PROFILE_SAVE_PATH):
		var remove_error: Error = DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			_add_failure("Failed to clear player profile file before test run.")


func _restore_profile_file() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(PROFILE_SAVE_PATH)
	if _had_profile_backup:
		var file: FileAccess = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
		if file == null:
			_add_failure("Unable to restore player profile backup.")
			return
		file.store_buffer(_profile_backup)
	elif FileAccess.file_exists(PROFILE_SAVE_PATH):
		var remove_error: Error = DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			_add_failure("Failed to remove player profile file created by test.")


func _add_failure(message: String) -> void:
	_failures.append(message)


func _print_summary() -> void:
	for failure in _failures:
		printerr("[PlayerProfileServiceMigrationTest][FAIL] %s" % failure)

	if _failures.is_empty():
		print("Player profile service migration test: PASS")
	else:
		print("Player profile service migration test: FAIL (%d failures)." % _failures.size())
