@tool
class_name CreatureCatalogBuilder
extends RefCounted

## Deterministically builds CreatureData resources from *_128x32.png assets.

const TYPES_ROOT: String = "res://src/Entities/Creatures/Types"
const CATALOG_PATH: String = "res://src/Entities/Creatures/Resources/creature_catalog.tres"
const SPRITE_SUFFIX: String = "_128x32.png"
const EXPECTED_SHEET_SIZE: Vector2i = Vector2i(128, 32)
const CREATURE_CATALOG_SCRIPT: Script = preload("res://src/Entities/Creatures/creature_catalog.gd")

var _type_by_category: Dictionary = {
	"humanoids": CreatureData.CreatureType.HUMANOID,
	"animals": CreatureData.CreatureType.ANIMAL,
	"holy": CreatureData.CreatureType.HOLY,
	"monsters": CreatureData.CreatureType.MONSTER,
	"dragons": CreatureData.CreatureType.DRAGON,
	"vermin": CreatureData.CreatureType.VERMIN,
	"magical": CreatureData.CreatureType.MAGICAL,
	"undead": CreatureData.CreatureType.UNDEAD,
	"demons": CreatureData.CreatureType.DEMON,
}


func build_catalog() -> Dictionary:
	var result: Dictionary = {
		"processed": 0,
		"created": 0,
		"updated": 0,
		"skipped": 0,
		"errors": 0,
	}

	var sprite_paths: PackedStringArray = _find_sprite_paths(TYPES_ROOT)
	if sprite_paths.is_empty():
		push_warning("CreatureCatalogBuilder: no sprite sheets found in '%s'." % TYPES_ROOT)
		return result

	var entries: Array[Dictionary] = []
	for sprite_path in sprite_paths:
		if not _is_valid_sprite_sheet(sprite_path):
			result["skipped"] += 1
			continue
		var parsed: Dictionary = _parse_sprite_path(sprite_path)
		if parsed.is_empty():
			result["skipped"] += 1
			continue
		entries.append(parsed)

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["creature_id"]) < String(b["creature_id"])
	)

	var creatures: Array[CreatureData] = []
	var seen_ids: Dictionary = {}
	for entry in entries:
		var creature_id: String = entry["creature_id"]
		if seen_ids.has(creature_id):
			push_warning("CreatureCatalogBuilder: duplicate creature_id '%s' skipped." % creature_id)
			result["skipped"] += 1
			continue
		seen_ids[creature_id] = true

		var data_path: String = _entry_resource_path(entry)
		if not _ensure_entry_output_directory(data_path):
			result["errors"] += 1
			continue

		var creature_data: CreatureData = null
		var existed: bool = ResourceLoader.exists(data_path)
		if existed:
			creature_data = load(data_path) as CreatureData
		if creature_data == null:
			creature_data = CreatureData.new()
		_apply_entry_to_data(creature_data, entry)

		var save_error: Error = ResourceSaver.save(creature_data, data_path)
		if save_error != OK:
			push_error(
				"CreatureCatalogBuilder: failed to save CreatureData '%s' at '%s' (err=%d)."
				% [creature_id, data_path, save_error]
			)
			result["errors"] += 1
			continue

		result["processed"] += 1
		if existed:
			result["updated"] += 1
		else:
			result["created"] += 1
		creatures.append(load(data_path) as CreatureData)

	var catalog: Resource = CREATURE_CATALOG_SCRIPT.new()
	catalog.set("creatures", creatures)
	catalog.call("rebuild_indices")
	var catalog_save_error: Error = ResourceSaver.save(catalog, CATALOG_PATH)
	if catalog_save_error != OK:
		push_error(
			"CreatureCatalogBuilder: failed to save catalog at '%s' (err=%d)."
			% [CATALOG_PATH, catalog_save_error]
		)
		result["errors"] += 1

	print(
		"CreatureCatalogBuilder summary: processed=%d created=%d updated=%d skipped=%d errors=%d"
		% [
			result["processed"],
			result["created"],
			result["updated"],
			result["skipped"],
			result["errors"],
		]
	)
	return result


func _find_sprite_paths(root_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	_collect_sprite_paths(root_path, result)
	result.sort()
	return result


func _collect_sprite_paths(dir_path: String, out_paths: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var item: String = dir.get_next()
		if item.is_empty():
			break
		if item.begins_with("."):
			continue

		var full_path: String = dir_path.path_join(item)
		if dir.current_is_dir():
			_collect_sprite_paths(full_path, out_paths)
		elif item.ends_with(SPRITE_SUFFIX):
			out_paths.append(full_path)
	dir.list_dir_end()


func _parse_sprite_path(sprite_path: String) -> Dictionary:
	if not sprite_path.begins_with(TYPES_ROOT + "/"):
		return {}

	var relative_path: String = sprite_path.trim_prefix(TYPES_ROOT + "/")
	var parts: PackedStringArray = relative_path.split("/")
	if parts.size() < 4:
		push_warning("CreatureCatalogBuilder: unexpected sprite path format '%s'." % sprite_path)
		return {}

	var category: String = parts[0]
	var creature_folder: String = parts[1]
	if parts[2].to_lower() != "sprites":
		push_warning("CreatureCatalogBuilder: sprite must be under 'Sprites/' in '%s'." % sprite_path)
		return {}

	var creature_id: String = _sanitize("%s_%s" % [category, creature_folder])
	if creature_id.is_empty():
		push_warning("CreatureCatalogBuilder: failed to derive creature_id from '%s'." % sprite_path)
		return {}

	return {
		"creature_id": creature_id,
		"display_name": creature_folder,
		"category": category,
		"category_lower": category.to_lower(),
		"type_value": _resolve_creature_type(category),
		"sprite_path": sprite_path,
	}


func _entry_resource_path(entry: Dictionary) -> String:
	var category: String = String(entry["category"])
	var creature_folder: String = String(entry["display_name"])
	return TYPES_ROOT.path_join(
		"%s/%s/Data/%s.tres"
		% [category, creature_folder, String(entry["creature_id"])]
	)


func _apply_entry_to_data(creature_data: CreatureData, entry: Dictionary) -> void:
	var sprite_path: String = entry["sprite_path"]
	creature_data.creature_id = entry["creature_id"]
	creature_data.display_name = entry["display_name"]
	creature_data.creature_type = entry["type_value"]
	creature_data.source_category = entry["category"]
	creature_data.source_sprite_path = sprite_path
	creature_data.sprite_sheet = _try_load_texture(sprite_path)
	creature_data.hframes = 4
	creature_data.vframes = 1
	creature_data.default_frame = 0
	creature_data.frame_width_pixels = 32
	creature_data.frame_height_pixels = 32

	# Keep builder output focused on core identity/presentation; legacy AI fields stay untouched.
	if creature_data.idle_animation_fps <= 0.0:
		creature_data.idle_animation_fps = 1.5
	if creature_data.max_health <= 0.0:
		creature_data.max_health = 50.0
	if creature_data.movement_speed <= 0.0:
		creature_data.movement_speed = 70.0
	if creature_data.damage <= 0.0:
		creature_data.damage = 10.0

	creature_data.validate_for_runtime(creature_data.creature_id)


func _resolve_creature_type(category: String) -> CreatureData.CreatureType:
	var key: String = category.strip_edges().to_lower()
	if _type_by_category.has(key):
		return _type_by_category[key]
	push_warning(
		"CreatureCatalogBuilder: unknown category '%s', defaulting to MONSTER."
		% category
	)
	return CreatureData.CreatureType.MONSTER


func _ensure_entry_output_directory(data_path: String) -> bool:
	var output_directory: String = data_path.get_base_dir()
	var global_output_path: String = ProjectSettings.globalize_path(output_directory)
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(global_output_path)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		push_error(
			"CreatureCatalogBuilder: failed to create output directory '%s' (err=%d)."
			% [output_directory, dir_error]
		)
		return false
	return true


func _sanitize(value: String) -> String:
	var id: String = value.strip_edges().to_lower()
	var regex := RegEx.new()
	var compile_error: Error = regex.compile("[^a-z0-9]+")
	if compile_error != OK:
		push_error("CreatureCatalogBuilder: failed to compile sanitize regex.")
		return id
	id = regex.sub(id, "_", true)
	id = id.trim_prefix("_").trim_suffix("_")
	return id


func _is_valid_sprite_sheet(sprite_path: String) -> bool:
	var absolute_path: String = ProjectSettings.globalize_path(sprite_path)
	if not FileAccess.file_exists(absolute_path):
		push_warning("CreatureCatalogBuilder: missing sprite file '%s'." % sprite_path)
		return false

	var image := Image.new()
	var image_error: Error = image.load(absolute_path)
	if image_error != OK:
		push_warning(
			"CreatureCatalogBuilder: failed to load image '%s' (err=%d)."
			% [sprite_path, image_error]
		)
		return false

	var image_size: Vector2i = image.get_size()
	if image_size != EXPECTED_SHEET_SIZE:
		push_warning(
			"CreatureCatalogBuilder: skipped '%s' (size=%s expected=%s)."
			% [sprite_path, str(image_size), str(EXPECTED_SHEET_SIZE)]
		)
		return false

	return true


func _try_load_texture(sprite_path: String) -> Texture2D:
	if not ResourceLoader.exists(sprite_path, "Texture2D"):
		return null
	return load(sprite_path) as Texture2D
