# addons/aethergate_ui_builder/panels/canvas/ui_builder_canvas.gd
@tool
extends Control
## Canvas panel that renders a scene inside a SubViewport and displays it via
## a TextureRect. Zoom and pan are applied by transforming a wrapper Control
## (CanvasRoot) that contains the TextureRect and the SelectionOverlay.

signal node_selected(node: Control)
signal canvas_changed()

const MIN_ZOOM: float = 0.05
const MAX_ZOOM: float = 4.0
const ZOOM_STEP: float = 0.1

@onready var _canvas_root: Control = %CanvasRoot
@onready var _viewport_frame: TextureRect = %ViewportFrame
@onready var _viewport: SubViewport = %SubViewport
@onready var _overlay: Control = %SelectionOverlay

var _zoom: float = 1.0
var _pan_offset: Vector2 = Vector2.ZERO
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_offset: Vector2 = Vector2.ZERO
var _scene_root: Control = null
var _platform_size: Vector2 = Vector2(1920, 1080)


func _ready() -> void:
	resized.connect(_on_resized)
	# Defer initial layout so the control has its final size.
	call_deferred(&"_initial_layout")


func _initial_layout() -> void:
	_zoom_to_fit(_platform_size)
	_center_canvas()
	_apply_transform()


# ── Public API ───────────────────────────────────────────────────────────────

## Load a Godot scene into the SubViewport. Pass null to clear.
func load_scene(packed_scene: PackedScene) -> void:
	_clear_viewport()
	if packed_scene == null:
		return
	var instance: Node = packed_scene.instantiate()
	_viewport.add_child(instance)
	_scene_root = instance as Control
	_overlay.setup(self, _scene_root)
	canvas_changed.emit()


## Returns the current scene root Control, or null if empty.
func get_scene_root() -> Control:
	return _scene_root


## Set the viewport size to the given platform resolution.
func set_platform_size(p_size: Vector2) -> void:
	_platform_size = p_size
	_viewport.size = Vector2i(int(p_size.x), int(p_size.y))
	# Wait one frame so the viewport texture updates to the new size.
	await get_tree().process_frame
	_viewport_frame.texture = _viewport.get_texture()
	_zoom_to_fit(p_size)
	_center_canvas()
	_apply_transform()


func get_zoom() -> float:
	return _zoom


func get_pan_offset() -> Vector2:
	return _pan_offset


func get_viewport_size() -> Vector2:
	return _platform_size


# ── Overlay signal forwarding ────────────────────────────────────────────────

func connect_selection(target: Object, method: StringName) -> void:
	_overlay.node_selected.connect(Callable(target, method))


func connect_move_committed(target: Object, method: StringName) -> void:
	_overlay.move_committed.connect(Callable(target, method))


func connect_resize_committed(target: Object, method: StringName) -> void:
	_overlay.resize_committed.connect(Callable(target, method))


# ── Adding / removing nodes (for palette + undo) ────────────────────────────

func add_node_to_scene(node: Control) -> void:
	if _scene_root == null:
		_scene_root = Control.new()
		_scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_viewport.add_child(_scene_root)
	_scene_root.add_child(node)
	_overlay.setup(self, _scene_root)
	canvas_changed.emit()


func remove_node_from_scene(node: Control) -> void:
	if _scene_root != null and node.get_parent() == _scene_root:
		_scene_root.remove_child(node)
	canvas_changed.emit()


## Convert a canvas-space point to viewport-space coordinates.
func canvas_to_viewport(canvas_pos: Vector2) -> Vector2:
	return (canvas_pos - _pan_offset) / _zoom


# ── Internal ─────────────────────────────────────────────────────────────────

func _clear_viewport() -> void:
	for child in _viewport.get_children():
		child.queue_free()
	_scene_root = null


func _on_resized() -> void:
	_zoom_to_fit(_platform_size)
	_center_canvas()
	_apply_transform()


func _zoom_to_fit(vp_size: Vector2) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var pad: float = 40.0
	var avail: Vector2 = size - Vector2(pad * 2.0, pad * 2.0)
	if avail.x <= 0.0 or avail.y <= 0.0:
		return
	_zoom = clampf(minf(avail.x / vp_size.x, avail.y / vp_size.y), MIN_ZOOM, MAX_ZOOM)


func _center_canvas() -> void:
	var scaled: Vector2 = _platform_size * _zoom
	_pan_offset = (size - scaled) * 0.5
	_apply_transform()


func _apply_transform() -> void:
	# Position the canvas root so the viewport frame is centered / panned.
	_canvas_root.position = _pan_offset
	_canvas_root.scale = Vector2(_zoom, _zoom)

	# Size the TextureRect to exactly the platform resolution (zoom is via
	# the parent CanvasRoot's scale).
	_viewport_frame.size = _platform_size

	# Assign the viewport texture if not yet assigned.
	if _viewport_frame.texture == null and _viewport != null:
		_viewport_frame.texture = _viewport.get_texture()

	# Size the overlay the same so hit-test coordinates line up.
	_overlay.size = _platform_size


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mb.pressed
			if mb.pressed:
				_pan_start_mouse = mb.position
				_pan_start_offset = _pan_offset
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_set_zoom(_zoom + ZOOM_STEP, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_set_zoom(_zoom - ZOOM_STEP, mb.position)

	if event is InputEventMouseMotion and _is_panning:
		var delta: Vector2 = (event as InputEventMouseMotion).position - _pan_start_mouse
		_pan_offset = _pan_start_offset + delta
		_apply_transform()


func _set_zoom(new_zoom: float, pivot: Vector2) -> void:
	var old_zoom: float = _zoom
	_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	var scale_change: float = _zoom / old_zoom
	_pan_offset = pivot + (_pan_offset - pivot) * scale_change
	_apply_transform()
