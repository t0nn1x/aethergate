class_name PlayerSkinCatalogValidationTest
extends RefCounted

## Validates player skin catalog consistency.
## Each selectable preset must have complete metadata and valid sprite frame sizes.

const CATALOG_PATH := "res://src/Entities/player/resources/player_skin_catalog.tres"
const OVERWORLD_FRAME_SIZE := Vector2i(16, 16)
const BATTLE_FRAME_SIZE := Vector2i(32, 32)

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()

	var catalog: PlayerSkinCatalog = load(CATALOG_PATH) as PlayerSkinCatalog
	if catalog == null:
		_add_failure("Catalog is missing at '%s'." % CATALOG_PATH)
		_print_summary(0)
		return false

	catalog.rebuild_indices()

	var authored_skins: Array[PlayerSkinDefinition] = catalog.skins
	if authored_skins.is_empty():
		_add_failure("Catalog contains no authored skins.")

	var selectable_skins: Array[PlayerSkinDefinition] = catalog.get_selectable_skins()
	if selectable_skins.is_empty():
		_add_failure("Catalog contains no complete selectable skins.")

	var seen_ids: Dictionary = {}
	for skin: PlayerSkinDefinition in authored_skins:
		_validate_skin(skin)
		_validate_authored_entry(catalog, skin, seen_ids)

	_validate_default_skin(catalog)

	if not authored_skins.is_empty():
		var selectable_ids: Dictionary = {}
		for skin: PlayerSkinDefinition in selectable_skins:
			selectable_ids[String(skin.skin_id).strip_edges()] = true
		for skin: PlayerSkinDefinition in authored_skins:
			var skin_id: String = String(skin.skin_id).strip_edges()
			if not selectable_ids.has(skin_id):
				_add_failure("Authored skin '%s' is not selectable." % skin_id)

	_print_summary(authored_skins.size())
	return _failures.is_empty()


func _validate_authored_entry(
	catalog: PlayerSkinCatalog,
	skin: PlayerSkinDefinition,
	seen_ids: Dictionary
) -> void:
	if skin == null:
		_add_failure("Authored skin entry is null.")
		return

	var skin_id: String = String(skin.skin_id).strip_edges()
	if skin_id.is_empty():
		_add_failure("Authored skin entry has empty skin_id.")
		return

	if seen_ids.has(skin_id):
		_add_failure("Duplicate skin_id '%s'." % skin_id)
	else:
		seen_ids[skin_id] = true

	if catalog.get_skin(skin.skin_id) != skin:
		_add_failure("Catalog lookup mismatch for skin_id '%s'." % skin_id)

	if not skin.is_complete():
		_add_failure("Authored skin '%s' is incomplete." % skin_id)


func _validate_default_skin(catalog: PlayerSkinCatalog) -> void:
	var default_skin_id: String = String(catalog.default_skin_id).strip_edges()
	if default_skin_id.is_empty():
		_add_failure("Catalog default_skin_id is empty.")
		return

	var default_skin: PlayerSkinDefinition = catalog.get_skin(catalog.default_skin_id)
	if default_skin == null:
		_add_failure("Catalog default_skin_id '%s' does not resolve to a skin." % default_skin_id)
		return

	if not default_skin.is_complete():
		_add_failure("Catalog default_skin_id '%s' resolves to an incomplete skin." % default_skin_id)

	var resolved_default: PlayerSkinDefinition = catalog.get_default_skin()
	if resolved_default != default_skin:
		_add_failure(
			"Catalog get_default_skin() does not return default_skin_id '%s'."
			% default_skin_id
		)


func _validate_skin(skin) -> void:
	if skin == null:
		_add_failure("Authored skin entry is null.")
		return

	var skin_id: String = String(skin.skin_id).strip_edges()
	if skin_id.is_empty():
		_add_failure("Authored skin entry has empty skin_id.")

	var display_name: String = String(skin.display_name).strip_edges()
	if display_name.is_empty():
		_add_failure("Skin '%s' has empty display_name." % skin_id)
	if not skin.is_complete():
		_add_failure("Authored skin '%s' is incomplete." % skin_id)

	_validate_texture(skin.overworld_idle_texture, OVERWORLD_FRAME_SIZE, skin_id, "overworld")
	_validate_texture(skin.battle_idle_texture, BATTLE_FRAME_SIZE, skin_id, "battle")


func _validate_texture(texture, frame_size: Vector2i, skin_id: String, label: String) -> void:
	if texture == null:
		_add_failure("Skin '%s' is missing %s texture." % [skin_id, label])
		return

	var path: String = String(texture.resource_path).strip_edges()
	if path.is_empty():
		_add_failure("Skin '%s' %s texture has no resource path." % [skin_id, label])
		return

	var image := Image.new()
	var err: Error = image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		_add_failure(
			"Skin '%s' failed to load %s texture '%s' (err=%d)." % [skin_id, label, path, err]
		)
		return

	var size: Vector2i = image.get_size()
	if size.y != frame_size.y or size.x < frame_size.x or size.x % frame_size.x != 0:
		_add_failure(
			"Skin '%s' %s texture size %s is invalid for frame size %s."
			% [skin_id, label, str(size), str(frame_size)]
		)


func _add_failure(message: String) -> void:
	_failures.append(message)


func _print_summary(total_entries: int) -> void:
	for failure in _failures:
		printerr("[PlayerSkinCatalogValidation][FAIL] %s" % failure)

	if _failures.is_empty():
		print("Player skin catalog validation: PASS (%d entries)." % total_entries)
	else:
		print("Player skin catalog validation: FAIL (%d failures)." % _failures.size())
