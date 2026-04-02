class_name BackgroundController
extends Node

## Applies a random cloud variation set at startup.
## All layers are loaded from one selected folder (Clouds 1..Clouds N).

@export_dir var backgrounds_root: String = "res://src/ui/Assets/Parallax-Backgrounds"
@export var background_set_prefix: String = "Clouds"
@export var layers_root_path: NodePath = ^"../Root/BackgroundContainer"
@export var random_seed_override: int = -1
@export var composition_base_size: Vector2 = Vector2(576.0, 324.0)
@export var composition_zoom: float = 1.0
@export var composition_vertical_offset: float = 0.0
@export_range(0.0, 8.0, 0.5) var layer_overscan_pixels: float = 2.0
@export var base_scroll_speed: float = 22.0
@export var layer_scroll_speed_multipliers: PackedFloat32Array = PackedFloat32Array([0.08, 0.12, 0.18, 0.26, 0.36, 0.5])
@export_range(1, 64, 1) var max_background_set_probe_count: int = 24
@export_range(1, 32, 1) var max_layer_probe_count: int = 8

enum LayerFitMode {
	CONTAIN,
	COVER
}

@export var layer_fit_mode: LayerFitMode = LayerFitMode.COVER

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _layer_nodes: Array[TextureRect] = []
var _scroll_shader: Shader
var _viewport: Viewport

const LAYER_FILE_EXTENSIONS := ["png", "webp", "jpg", "jpeg"]


func _ready() -> void:
	_viewport = get_viewport()
	_collect_layer_nodes()
	_wire_viewport_resize()
	_apply_random_background_set()
	print("[FIX][BackgroundController] layer_fit_mode=%s" % ("COVER" if layer_fit_mode == LayerFitMode.COVER else "CONTAIN"))
	print("[FIX][BackgroundController] layer_overscan_pixels=%.1f texture_repeat=enabled" % layer_overscan_pixels)


func _collect_layer_nodes() -> void:
	_layer_nodes.clear()
	var layers_root: Node = get_node_or_null(layers_root_path)
	if layers_root == null:
		push_warning("BackgroundController: layers_root_path is invalid.")
		return

	for child in layers_root.get_children():
		var layer: TextureRect = child as TextureRect
		if layer:
			layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			layer.stretch_mode = TextureRect.STRETCH_SCALE
			_layer_nodes.append(layer)


func _apply_random_background_set() -> void:
	if _layer_nodes.is_empty():
		push_warning("[FIX][BackgroundController] no TextureRect layers found.")
		return

	var background_folders: Array[String] = _get_background_folders()
	if background_folders.is_empty():
		push_warning(
			"[FIX][BackgroundController] no folders found in %s with prefix '%s'."
			% [backgrounds_root, background_set_prefix]
		)
		return

	if random_seed_override >= 0:
		_rng.seed = random_seed_override
	else:
		_rng.randomize()

	var selected_folder: String = background_folders[_rng.randi_range(0, background_folders.size() - 1)]
	var selected_folder_path: String = "%s/%s" % [backgrounds_root, selected_folder]
	var layer_paths: Array[String] = _get_sorted_layer_paths(selected_folder_path)
	if layer_paths.is_empty():
		push_warning("[FIX][BackgroundController] folder '%s' has no png layers." % selected_folder)
		return

	print("[FIX][BackgroundController] Selected cloud folder: %s" % selected_folder)
	print("[FIX][BackgroundController] Layer files after filtering: %d, target slots: %d" % [layer_paths.size(), _layer_nodes.size()])

	for index in range(_layer_nodes.size()):
		var layer: TextureRect = _layer_nodes[index]
		if layer == null:
			continue
		if index >= layer_paths.size():
			layer.texture = null
			layer.visible = false
			continue

		var texture_path: String = layer_paths[index]
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture == null:
			push_warning("[FIX][BackgroundController] failed to load texture '%s'." % texture_path)
			layer.texture = null
			layer.visible = false
			continue

		layer.texture = texture
		layer.visible = true
		_apply_scroll_material(layer, index, texture)
		_apply_layer_fit(layer, texture)
		print("[FIX][BackgroundController] layer_%d <- %s" % [index + 1, texture_path])

	if layer_paths.size() > _layer_nodes.size():
		push_warning("[FIX][BackgroundController] %d extra layers were not shown (increase layer slots)." % (layer_paths.size() - _layer_nodes.size()))


func _get_background_folders() -> Array[String]:
	var folders: Array[String] = []
	var dir: DirAccess = DirAccess.open(backgrounds_root)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var entry: String = dir.get_next()
			if entry.is_empty():
				break
			if entry.begins_with("."):
				continue
			if dir.current_is_dir() and _matches_background_set_prefix(entry):
				folders.append(entry)
		dir.list_dir_end()

	if folders.is_empty():
		folders = _probe_background_folders()
		if not folders.is_empty():
			print(
				"[FIX][BackgroundController] DirAccess listing unavailable/empty. Using export-safe background-set probe (%d sets)."
				% folders.size()
			)

	folders.sort()
	return folders


func _matches_background_set_prefix(folder_name: String) -> bool:
	if background_set_prefix.is_empty():
		return true
	return folder_name.to_lower().begins_with(background_set_prefix.strip_edges().to_lower())


func _get_sorted_layer_paths(folder_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var entry: String = dir.get_next()
			if entry.is_empty():
				break
			if dir.current_is_dir():
				continue
			if not entry.to_lower().ends_with(".png"):
				continue
			files.append("%s/%s" % [folder_path, entry])
		dir.list_dir_end()

	if files.is_empty():
		files = _probe_layer_paths(folder_path, max_layer_probe_count)
		if not files.is_empty():
			print(
				"[FIX][BackgroundController] DirAccess layer listing unavailable/empty for %s. Using export-safe layer probe (%d layers)."
				% [folder_path, files.size()]
			)

	files.sort_custom(func(a: String, b: String) -> bool:
		return _layer_path_sort_key(a) < _layer_path_sort_key(b)
	)

	if files.is_empty():
		return files

	# Some packs include mixed source sizes (e.g. one very large "composed" frame).
	# Pick the most common size bucket to avoid accidental zoom/crop artifacts.
	var size_buckets: Dictionary = {}
	for file_path in files:
		var size: Vector2i = _get_texture_size(file_path)
		var size_key: String = "%dx%d" % [size.x, size.y]
		if not size_buckets.has(size_key):
			size_buckets[size_key] = []
		var bucket: Array = size_buckets[size_key] as Array
		bucket.append(file_path)
		size_buckets[size_key] = bucket

	var canonical_key: String = ""
	var canonical_paths: Array = []
	for key_variant in size_buckets.keys():
		var key: String = str(key_variant)
		var bucket_paths: Array = size_buckets[key] as Array
		if bucket_paths.size() > canonical_paths.size():
			canonical_key = key
			canonical_paths = bucket_paths.duplicate()

	if canonical_key.is_empty():
		return files

	if canonical_paths.size() != files.size():
		print(
			"[FIX][BackgroundController] Filtered mixed-size layers in %s. Canonical: %s, kept %d/%d."
			% [folder_path, canonical_key, canonical_paths.size(), files.size()]
		)

	var typed_paths: Array[String] = []
	for path_variant in canonical_paths:
		typed_paths.append(str(path_variant))
	return typed_paths


func _probe_background_folders() -> Array[String]:
	var folders: Array[String] = []
	var trimmed_prefix: String = background_set_prefix.strip_edges()
	if trimmed_prefix.is_empty():
		return folders

	for set_index in range(1, max_background_set_probe_count + 1):
		var folder_name: String = "%s %d" % [trimmed_prefix, set_index]
		var folder_path: String = "%s/%s" % [backgrounds_root, folder_name]
		if _folder_has_any_layer(folder_path):
			folders.append(folder_name)

	return folders


func _folder_has_any_layer(folder_path: String) -> bool:
	return not _resolve_layer_resource_path(folder_path, 1).is_empty()


func _probe_layer_paths(folder_path: String, max_layers: int) -> Array[String]:
	var files: Array[String] = []
	var miss_count: int = 0
	for layer_index in range(1, max_layers + 1):
		var path: String = _resolve_layer_resource_path(folder_path, layer_index)
		if path.is_empty():
			miss_count += 1
			if not files.is_empty() and miss_count >= 2:
				break
			continue
		files.append(path)
		miss_count = 0
	return files


func _resolve_layer_resource_path(folder_path: String, layer_index: int) -> String:
	for extension in LAYER_FILE_EXTENSIONS:
		var path: String = "%s/%d.%s" % [folder_path, layer_index, extension]
		if ResourceLoader.exists(path, "Texture2D"):
			return path
	return ""


func _layer_path_sort_key(path: String) -> int:
	var name: String = path.get_file().get_basename()
	if name.is_valid_int():
		return int(name)
	return 2147483647


func _get_scroll_multiplier(index: int) -> float:
	if index >= 0 and index < layer_scroll_speed_multipliers.size():
		return layer_scroll_speed_multipliers[index]
	return 1.0


func _get_texture_size(path: String) -> Vector2i:
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return Vector2i.ZERO
	return Vector2i(texture.get_width(), texture.get_height())


func _wire_viewport_resize() -> void:
	if _viewport == null:
		return
	if not _viewport.size_changed.is_connected(_on_viewport_size_changed):
		_viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	for layer in _layer_nodes:
		if layer and layer.texture:
			_apply_layer_fit(layer, layer.texture)


func _apply_layer_fit(layer: TextureRect, texture: Texture2D) -> void:
	if layer == null or texture == null:
		return

	var viewport_size: Vector2 = _resolve_viewport_size()
	var base_size: Vector2 = _resolve_composition_base_size(texture)
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		base_size = Vector2(1.0, 1.0)

	var width_scale: float = viewport_size.x / base_size.x
	var height_scale: float = viewport_size.y / base_size.y
	var scale_factor: float = (
		maxf(width_scale, height_scale)
		if layer_fit_mode == LayerFitMode.COVER
		else minf(width_scale, height_scale)
	)
	# Clamp so zoom can only keep full fit or zoom further out, never in.
	var zoom_factor: float = clampf(composition_zoom, 0.01, 1.0)
	scale_factor *= zoom_factor
	var drawn_size: Vector2 = base_size * scale_factor
	var offset: Vector2 = (viewport_size - drawn_size) * 0.5
	offset.y += composition_vertical_offset
	var overscan: float = maxf(layer_overscan_pixels, 0.0)
	var left: float = floorf(offset.x) - overscan
	var top: float = floorf(offset.y) - overscan
	var right: float = ceilf(offset.x + drawn_size.x) + overscan
	var bottom: float = ceilf(offset.y + drawn_size.y) + overscan

	layer.anchors_preset = Control.PRESET_TOP_LEFT
	layer.anchor_left = 0.0
	layer.anchor_top = 0.0
	layer.anchor_right = 0.0
	layer.anchor_bottom = 0.0
	layer.offset_left = left
	layer.offset_top = top
	layer.offset_right = right
	layer.offset_bottom = bottom


func _resolve_viewport_size() -> Vector2:
	if _viewport:
		var size: Vector2 = _viewport.get_visible_rect().size
		if size.x > 0.0 and size.y > 0.0:
			return size
	return Vector2(1920.0, 1080.0)


func _resolve_composition_base_size(texture: Texture2D) -> Vector2:
	if composition_base_size.x > 0.0 and composition_base_size.y > 0.0:
		return composition_base_size
	return Vector2(float(texture.get_width()), float(texture.get_height()))


func _apply_scroll_material(layer: TextureRect, index: int, texture: Texture2D) -> void:
	if layer == null:
		return
	if base_scroll_speed <= 0.0:
		layer.material = null
		return

	var texture_width: float = maxf(float(texture.get_width()), 1.0)
	var speed_pixels: float = base_scroll_speed * _get_scroll_multiplier(index)
	var uv_speed: float = speed_pixels / texture_width

	if _scroll_shader == null:
		_scroll_shader = Shader.new()
		_scroll_shader.code = """
shader_type canvas_item;
uniform float scroll_speed = 0.02;

void fragment() {
	vec2 uv = UV;
	uv.x += TIME * scroll_speed;
	COLOR = texture(TEXTURE, uv);
}
"""

	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = _scroll_shader
	material.set_shader_parameter("scroll_speed", uv_speed)
	layer.material = material
	layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
