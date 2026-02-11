class_name OverworldChunkEditorPreview
extends RefCounted

## Editor preview orchestration extracted from OverworldChunk.

const PREVIEW_ROOT_NAME := "_PreviewNeighbors"
const PREVIEW_Z_INDEX := 100


static func rebuild_preview(owner: OverworldChunk, current_preview_root: Node2D) -> Node2D:
	if not Engine.is_editor_hint():
		return current_preview_root

	if current_preview_root and is_instance_valid(current_preview_root):
		current_preview_root.queue_free()
	current_preview_root = null

	if not owner.preview_neighbors:
		return null

	var preview_root := Node2D.new()
	preview_root.name = PREVIEW_ROOT_NAME
	preview_root.z_index = PREVIEW_Z_INDEX
	preview_root.owner = null
	owner.add_child(preview_root)

	var loaded_count := 0
	for offset in _preview_offsets(owner.preview_radius):
		var coord: Vector2i = owner.chunk_coord + offset
		var path := owner.chunk_scene_dir.path_join("chunk_%d_%d.tscn" % [coord.x, coord.y])
		var scene: PackedScene = load(path) as PackedScene
		if scene == null:
			continue

		var instance: Node = scene.instantiate()
		if instance is OverworldChunk:
			_configure_preview_chunk(owner, instance, coord)
		instance.name = "_Preview_%d_%d" % [coord.x, coord.y]
		instance.owner = null
		preview_root.add_child(instance)
		loaded_count += 1

	if loaded_count == 0:
		push_warning("Preview neighbors: no scenes found for %s in %s" % [owner.chunk_coord, owner.chunk_scene_dir])

	return preview_root


static func _configure_preview_chunk(owner: OverworldChunk, instance: OverworldChunk, coord: Vector2i) -> void:
	instance._is_preview_instance = true
	instance._preview_origin_coord = owner.chunk_coord
	instance.preview_neighbors = false
	instance.preview_radius = owner.preview_radius
	instance.enforce_bounds_in_editor = false
	instance.cleanup_out_of_bounds = false
	instance.show_bounds = true
	instance.bounds_line_width = max(instance.bounds_line_width, 1.0)
	instance.z_index = PREVIEW_Z_INDEX
	instance.chunk_size_tiles = owner.chunk_size_tiles
	instance.tile_size = owner.tile_size
	instance.chunk_coord = coord


static func _preview_offsets(radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x == 0 and y == 0:
				continue
			result.append(Vector2i(x, y))
	return result
