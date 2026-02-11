class_name ChunkManagerEditorPreview
extends RefCounted

## Editor-only preview utilities extracted from ChunkManager.

const PREVIEW_ROOT_NAME := "_EditorPreviewAll"
const PREVIEW_Z_INDEX := 100
const CHUNK_SCENE_PREFIX := "chunk_"
const CHUNK_TEMPLATE_NAME := "chunk_template.tscn"
const CHUNK_SCENE_EXT := ".tscn"


static func rebuild_preview(
	owner: Node2D,
	current_preview_root: Node2D,
	preview_all_in_editor: bool,
	chunk_scene_dir: String,
	chunk_size_tiles: int,
	tile_size: Vector2i
) -> Node2D:
	if current_preview_root and is_instance_valid(current_preview_root):
		current_preview_root.queue_free()
	current_preview_root = null

	if not preview_all_in_editor:
		return null

	var preview_root := Node2D.new()
	preview_root.name = PREVIEW_ROOT_NAME
	preview_root.z_index = PREVIEW_Z_INDEX
	preview_root.owner = null
	owner.add_child(preview_root)

	var dir := DirAccess.open(chunk_scene_dir)
	if dir == null:
		return preview_root

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if _is_chunk_scene(file_name):
			var path := chunk_scene_dir.path_join(file_name)
			var coord := _parse_chunk_coord(file_name)
			var scene: PackedScene = load(path) as PackedScene
			if scene:
				var instance: Node = scene.instantiate()
				instance.name = "_Preview_%s" % file_name.substr(0, file_name.length() - CHUNK_SCENE_EXT.length())
				instance.owner = null
				if instance is OverworldChunk:
					_configure_preview_chunk(instance, coord, chunk_size_tiles, tile_size)
				preview_root.add_child(instance)
		file_name = dir.get_next()
	dir.list_dir_end()

	return preview_root


static func _is_chunk_scene(file_name: String) -> bool:
	if not file_name.begins_with(CHUNK_SCENE_PREFIX) or not file_name.ends_with(CHUNK_SCENE_EXT):
		return false
	if file_name == CHUNK_TEMPLATE_NAME:
		return false

	var prefix_len := CHUNK_SCENE_PREFIX.length()
	var base := file_name.substr(prefix_len, file_name.length() - prefix_len - CHUNK_SCENE_EXT.length())
	var parts := base.split("_")
	if parts.size() != 2:
		return false

	return parts[0].is_valid_int() and parts[1].is_valid_int()


static func _parse_chunk_coord(file_name: String) -> Vector2i:
	var prefix_len := CHUNK_SCENE_PREFIX.length()
	var base := file_name.substr(prefix_len, file_name.length() - prefix_len - CHUNK_SCENE_EXT.length())
	var parts := base.split("_")
	return Vector2i(int(parts[0]), int(parts[1]))


static func _configure_preview_chunk(
	instance: OverworldChunk,
	coord: Vector2i,
	chunk_size_tiles: int,
	tile_size: Vector2i
) -> void:
	instance.chunk_coord = coord
	instance.chunk_size_tiles = chunk_size_tiles
	instance.tile_size = tile_size
	instance.preview_neighbors = false
	instance.enforce_bounds_in_editor = false
	instance.cleanup_out_of_bounds = false
	instance.show_bounds = true
	instance.bounds_line_width = max(instance.bounds_line_width, 1.0)
	instance.z_index = PREVIEW_Z_INDEX
