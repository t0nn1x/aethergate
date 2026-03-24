class_name CreatureCatalogValidationTest
extends RefCounted

## Validates creature catalog consistency.
## Sprite sheets must be N×32 px (height=32, width a multiple of 32). hframes is derived from width.

const CATALOG_PATH := "res://src/Entities/Creatures/Resources/creature_catalog.tres"
const REQUIRED_SPRITE_SUFFIX := "x32.png"
const FRAME_SIZE := 32
const EXPECTED_VFRAMES := 1
const EXPECTED_FRAME_WIDTH := 32
const EXPECTED_FRAME_HEIGHT := 32

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()

	var catalog = load(CATALOG_PATH)
	if catalog == null:
		_add_failure("Catalog is missing at '%s'." % CATALOG_PATH)
		_print_summary(0)
		return false

	catalog.call("rebuild_indices")
	var creatures: Array = catalog.call("get_all") as Array
	if creatures.is_empty():
		_add_failure("Catalog contains no creature entries.")

	var seen_ids: Dictionary = {}
	for i in creatures.size():
		var creature_data = creatures[i]
		_validate_creature_data(creature_data, i, seen_ids, catalog)

	_print_summary(creatures.size())
	return _failures.is_empty()


func _validate_creature_data(
	creature_data,
	index: int,
	seen_ids: Dictionary,
	catalog
) -> void:
	if creature_data == null:
		_add_failure("Entry %d is null." % index)
		return

	var creature_id: String = String(creature_data.call("get_effective_creature_id"))
	if creature_id.is_empty():
		_add_failure("Entry %d has empty effective creature_id." % index)
	else:
		if seen_ids.has(creature_id):
			_add_failure("Duplicate creature_id '%s'." % creature_id)
		seen_ids[creature_id] = true

		var catalog_lookup = catalog.call("get_by_id", creature_id)
		if catalog_lookup != creature_data:
			_add_failure("Catalog lookup mismatch for id '%s'." % creature_id)

	var context: String = creature_id if not creature_id.is_empty() else "entry_%d" % index
	if not bool(creature_data.call("validate_for_runtime", context)):
		_add_failure("Runtime validation failed for '%s'." % context)

	_validate_sprite_source(creature_data, context)
	_validate_frame_configuration(creature_data, context)


func _validate_sprite_source(creature_data, context: String) -> void:
	var source_path: String = String(creature_data.get("source_sprite_path")).strip_edges()
	if source_path.is_empty():
		_add_failure("'%s' has empty source_sprite_path." % context)
		return
	if not source_path.ends_with(REQUIRED_SPRITE_SUFFIX):
		_add_failure(
			"'%s' source_sprite_path does not end with '%s': %s"
			% [context, REQUIRED_SPRITE_SUFFIX, source_path]
		)
		return
	var absolute_source_path: String = ProjectSettings.globalize_path(source_path)
	if not FileAccess.file_exists(absolute_source_path):
		_add_failure("'%s' source sprite is missing: %s" % [context, source_path])
		return

	var image := Image.new()
	var image_error: Error = image.load(absolute_source_path)
	if image_error != OK:
		_add_failure(
			"'%s' could not load sprite image from %s (err=%d)."
			% [context, source_path, image_error]
		)
		return

	var image_size: Vector2i = image.get_size()
	if image_size.y != FRAME_SIZE or image_size.x < FRAME_SIZE or image_size.x % FRAME_SIZE != 0:
		_add_failure(
			"'%s' texture size %s is invalid: height must be %d and width a multiple of %d."
			% [context, str(image_size), FRAME_SIZE, FRAME_SIZE]
		)


func _validate_frame_configuration(creature_data, context: String) -> void:
	var hframes: int = int(creature_data.get("hframes"))
	var vframes: int = int(creature_data.get("vframes"))
	var frame_width_pixels: int = int(creature_data.get("frame_width_pixels"))
	var frame_height_pixels: int = int(creature_data.get("frame_height_pixels"))
	var default_frame: int = int(creature_data.get("default_frame"))

	if hframes < 1:
		_add_failure("'%s' hframes must be >= 1, got %d." % [context, hframes])
	if vframes != EXPECTED_VFRAMES:
		_add_failure(
			"'%s' vframes is %d but expected %d."
			% [context, vframes, EXPECTED_VFRAMES]
		)
	if frame_width_pixels != EXPECTED_FRAME_WIDTH:
		_add_failure(
			"'%s' frame_width_pixels is %d but expected %d."
			% [context, frame_width_pixels, EXPECTED_FRAME_WIDTH]
		)
	if frame_height_pixels != EXPECTED_FRAME_HEIGHT:
		_add_failure(
			"'%s' frame_height_pixels is %d but expected %d."
			% [context, frame_height_pixels, EXPECTED_FRAME_HEIGHT]
		)

	var max_frames: int = max(hframes * vframes, 1)
	if default_frame < 0 or default_frame >= max_frames:
		_add_failure(
			"'%s' default_frame %d is outside [0, %d)."
			% [context, default_frame, max_frames]
		)


func _add_failure(message: String) -> void:
	_failures.append(message)


func _print_summary(total_entries: int) -> void:
	for failure in _failures:
		printerr("[CreatureCatalogValidation][FAIL] %s" % failure)

	if _failures.is_empty():
		print("Creature catalog validation: PASS (%d entries)." % total_entries)
	else:
		print("Creature catalog validation: FAIL (%d failures)." % _failures.size())
