@tool
class_name PlayerCosmeticCatalogBuilder
extends RefCounted

## Scans player part sprites and updates the cosmetic catalog resource.

const CATALOG_PATH: String = "res://src/Entities/Player/Resources/player_cosmetic_catalog.tres"
const HEAD_ROOT: String = "res://src/Entities/Player/Sprites/Parts/Head"
const BODY_ROOT: String = "res://src/Entities/Player/Sprites/Parts/Body"
const LEGS_ROOT: String = "res://src/Entities/Player/Sprites/Parts/Legs"
const EXPECTED_SHEET_SIZE: Vector2i = Vector2i(128, 32)
const CATALOG_SCRIPT: Script = preload("res://src/Entities/Player/Resources/player_cosmetic_catalog.gd")
const APPEARANCE_SCRIPT: Script = preload("res://src/Entities/Player/Resources/player_appearance_data.gd")


func build_catalog() -> Dictionary:
	var result: Dictionary = {
		"scanned": 0,
		"assigned_new": 0,
		"preserved": 0,
		"removed": 0,
		"skipped": 0,
		"errors": 0,
	}

	var catalog: Resource = _load_or_create_catalog()
	if catalog == null:
		result["errors"] += 1
		return result

	_ensure_default_appearance(catalog)

	_merge_summary(result, _rebuild_slot(catalog, "head_variants", "head_id", HEAD_ROOT, "head"))
	_merge_summary(result, _rebuild_slot(catalog, "body_variants", "body_id", BODY_ROOT, "body"))
	_merge_summary(result, _rebuild_slot(catalog, "legs_variants", "legs_id", LEGS_ROOT, "legs"))

	var save_error: Error = ResourceSaver.save(catalog, CATALOG_PATH)
	if save_error != OK:
		push_error(
			"PlayerCosmeticCatalogBuilder: failed to save catalog at '%s' (err=%d)."
			% [CATALOG_PATH, save_error]
		)
		result["errors"] += 1

	print(
		"PlayerCosmeticCatalogBuilder summary: scanned=%d assigned_new=%d preserved=%d removed=%d skipped=%d errors=%d"
		% [
			result["scanned"],
			result["assigned_new"],
			result["preserved"],
			result["removed"],
			result["skipped"],
			result["errors"],
		]
	)
	return result


func _load_or_create_catalog() -> Resource:
	var catalog: Resource = load(CATALOG_PATH) as Resource
	if catalog != null:
		return catalog

	catalog = CATALOG_SCRIPT.new()
	if catalog == null:
		push_error("PlayerCosmeticCatalogBuilder: failed to create catalog resource.")
		return null

	return catalog


func _ensure_default_appearance(catalog: Resource) -> void:
	if catalog == null:
		return

	var default_appearance: Resource = catalog.get("default_appearance") as Resource
	if default_appearance == null:
		default_appearance = APPEARANCE_SCRIPT.new()
		if default_appearance == null:
			push_warning("PlayerCosmeticCatalogBuilder: failed to create default appearance resource.")
			return
		catalog.set("default_appearance", default_appearance)

	if default_appearance.has_method("ensure_defaults"):
		default_appearance.call("ensure_defaults")


func _rebuild_slot(
	catalog: Resource,
	variant_field: String,
	default_field: String,
	slot_root: String,
	id_prefix: String
) -> Dictionary:
	var summary: Dictionary = {
		"scanned": 0,
		"assigned_new": 0,
		"preserved": 0,
		"removed": 0,
		"skipped": 0,
		"errors": 0,
	}

	var existing_variants: Dictionary = catalog.get(variant_field) as Dictionary
	var existing_path_to_id: Dictionary = {}
	var used_indices: Dictionary = {}

	for existing_id_variant in existing_variants.keys():
		var existing_id: String = str(existing_id_variant)
		_register_used_index(existing_id, id_prefix, used_indices)
		var existing_texture: Texture2D = existing_variants.get(existing_id_variant) as Texture2D
		if existing_texture and not existing_texture.resource_path.is_empty():
			existing_path_to_id[existing_texture.resource_path] = existing_id

	var sprite_paths: PackedStringArray = _find_slot_sprite_paths(slot_root)
	var rebuilt_variants: Dictionary = {}

	for sprite_path in sprite_paths:
		summary["scanned"] += 1
		if not _is_valid_sprite_sheet(sprite_path):
			summary["skipped"] += 1
			continue

		var texture: Texture2D = _try_load_texture(sprite_path)
		if texture == null:
			push_warning("PlayerCosmeticCatalogBuilder: failed to load texture '%s'." % sprite_path)
			summary["errors"] += 1
			continue

		var variant_id: String = str(existing_path_to_id.get(sprite_path, ""))
		if variant_id.is_empty():
			var next_index: int = _next_available_index(used_indices)
			used_indices[next_index] = true
			variant_id = "%s_%d" % [id_prefix, next_index]
			summary["assigned_new"] += 1
		else:
			summary["preserved"] += 1

		rebuilt_variants[variant_id] = texture

	for existing_id_variant in existing_variants.keys():
		var existing_id: String = str(existing_id_variant)
		if not rebuilt_variants.has(existing_id):
			summary["removed"] += 1

	catalog.set(variant_field, rebuilt_variants)
	_ensure_default_slot_id(catalog, default_field, rebuilt_variants, id_prefix)
	return summary


func _find_slot_sprite_paths(slot_root: String) -> PackedStringArray:
	var paths: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(slot_root)
	if dir == null:
		push_warning("PlayerCosmeticCatalogBuilder: directory does not exist '%s'." % slot_root)
		return paths

	dir.list_dir_begin()
	while true:
		var item: String = dir.get_next()
		if item.is_empty():
			break
		if item.begins_with(".") or dir.current_is_dir():
			continue
		if item.get_extension().to_lower() != "png":
			continue
		paths.append(slot_root.path_join(item))
	dir.list_dir_end()

	paths.sort()
	return paths


func _is_valid_sprite_sheet(sprite_path: String) -> bool:
	var absolute_path: String = ProjectSettings.globalize_path(sprite_path)
	if not FileAccess.file_exists(absolute_path):
		push_warning("PlayerCosmeticCatalogBuilder: missing sprite file '%s'." % sprite_path)
		return false

	var image := Image.new()
	var image_error: Error = image.load(absolute_path)
	if image_error != OK:
		push_warning(
			"PlayerCosmeticCatalogBuilder: failed to load image '%s' (err=%d)."
			% [sprite_path, image_error]
		)
		return false

	var image_size: Vector2i = image.get_size()
	if image_size != EXPECTED_SHEET_SIZE:
		push_warning(
			"PlayerCosmeticCatalogBuilder: skipped '%s' (size=%s expected=%s)."
			% [sprite_path, str(image_size), str(EXPECTED_SHEET_SIZE)]
		)
		return false

	return true


func _try_load_texture(sprite_path: String) -> Texture2D:
	if not ResourceLoader.exists(sprite_path, "Texture2D"):
		return null
	return load(sprite_path) as Texture2D


func _register_used_index(variant_id: String, id_prefix: String, used_indices: Dictionary) -> void:
	var expected_prefix: String = "%s_" % id_prefix
	if not variant_id.begins_with(expected_prefix):
		return
	var suffix: String = variant_id.trim_prefix(expected_prefix)
	if not suffix.is_valid_int():
		return
	var numeric_id: int = int(suffix)
	if numeric_id <= 0:
		return
	used_indices[numeric_id] = true


func _next_available_index(used_indices: Dictionary) -> int:
	var next_index: int = 1
	while used_indices.has(next_index):
		next_index += 1
	return next_index


func _ensure_default_slot_id(
	catalog: Resource,
	default_field: String,
	variants: Dictionary,
	id_prefix: String
) -> void:
	if catalog == null:
		return

	var default_appearance: Resource = catalog.get("default_appearance") as Resource
	if default_appearance == null:
		return

	var current_id: String = str(default_appearance.get(default_field))
	if not current_id.is_empty() and variants.has(current_id):
		return

	var fallback_id: String = _pick_fallback_id(variants, id_prefix)
	default_appearance.set(default_field, StringName(fallback_id))


func _pick_fallback_id(variants: Dictionary, id_prefix: String) -> String:
	if variants.is_empty():
		return ""

	var best_id: String = ""
	var best_index: int = 2147483647
	var expected_prefix: String = "%s_" % id_prefix
	for key_variant in variants.keys():
		var key: String = str(key_variant)
		if not key.begins_with(expected_prefix):
			continue
		var suffix: String = key.trim_prefix(expected_prefix)
		if not suffix.is_valid_int():
			continue
		var index_value: int = int(suffix)
		if index_value <= 0:
			continue
		if index_value < best_index:
			best_index = index_value
			best_id = key

	if not best_id.is_empty():
		return best_id

	var sorted_keys: Array[String] = []
	for key_variant in variants.keys():
		sorted_keys.append(str(key_variant))
	sorted_keys.sort()
	return sorted_keys[0]


func _merge_summary(result: Dictionary, summary: Dictionary) -> void:
	for key_variant in summary.keys():
		var key: String = str(key_variant)
		result[key] = int(result.get(key, 0)) + int(summary.get(key, 0))
