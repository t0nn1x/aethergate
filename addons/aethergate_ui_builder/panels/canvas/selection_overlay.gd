# addons/aethergate_ui_builder/panels/canvas/selection_overlay.gd
@tool
extends Control

signal node_selected(node: Control)
signal move_committed(node: Control, old_pos: Vector2, new_pos: Vector2)
signal resize_committed(node: Control, old_rect: Rect2, new_rect: Rect2)

const HANDLE_SIZE: float = 8.0
const HANDLE_COLOR: Color = Color(0.29, 0.565, 0.855, 1.0)
const OUTLINE_COLOR: Color = Color(0.29, 0.565, 0.855, 0.8)
const HOVER_COLOR: Color = Color(0.29, 0.565, 0.855, 0.25)
const MIN_NODE_SIZE: float = 16.0

## 8 handle indices: 0=TL, 1=TC, 2=TR, 3=ML, 4=MR, 5=BL, 6=BC, 7=BR
enum Handle { TL, TC, TR, ML, MR, BL, BC, BR }

var _canvas: Control = null          # the UiBuilderCanvas parent
var _scene_root: Control = null      # root inside SubViewport

var _selected: Control = null
var _hovered: Control = null
var _drag_mode: int = -1             # -1=none, 8=body, 0-7=handle index
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_rect: Rect2 = Rect2()


func setup(canvas: Control, scene_root: Control) -> void:
	_canvas = canvas
	_scene_root = scene_root
	_selected = null
	queue_redraw()


func deselect() -> void:
	_selected = null
	queue_redraw()


func _draw() -> void:
	if _selected == null or _canvas == null:
		return
	var rect: Rect2 = _get_screen_rect(_selected)
	# Hover highlight
	if _hovered != null and _hovered != _selected:
		draw_rect(_get_screen_rect(_hovered), HOVER_COLOR)
	# Selection outline
	draw_rect(rect, OUTLINE_COLOR, false, 2.0)
	# 8 handles
	for i in range(8):
		var hp: Vector2 = _handle_position(rect, i)
		draw_rect(Rect2(hp - Vector2(HANDLE_SIZE, HANDLE_SIZE) * 0.5, Vector2(HANDLE_SIZE, HANDLE_SIZE)), HANDLE_COLOR)


func _gui_input(event: InputEvent) -> void:
	if _scene_root == null:
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_handle_mouse_motion(mm)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_left_press(mb.position)
			else:
				_handle_left_release(mb.position)


func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if _drag_mode == -1:
		# Update hover
		var vp_pos: Vector2 = _canvas.canvas_to_viewport(mm.position)
		_hovered = _hit_test(vp_pos)
		_update_cursor(mm.position)
		queue_redraw()
		return

	if _drag_mode == 8:
		# Moving body
		var delta: Vector2 = (mm.position - _drag_start_mouse) / _canvas.get_zoom()
		var snap: float = 8.0 if not Input.is_key_pressed(KEY_CTRL) else 1.0
		var new_pos: Vector2 = (_drag_start_rect.position + delta).snapped(Vector2(snap, snap))
		_selected.position = new_pos
		queue_redraw()
	else:
		# Resizing via handle
		var delta: Vector2 = (mm.position - _drag_start_mouse) / _canvas.get_zoom()
		_apply_resize_delta(_drag_mode, delta)
		queue_redraw()


func _handle_left_press(mouse_pos: Vector2) -> void:
	var vp_pos: Vector2 = _canvas.canvas_to_viewport(mouse_pos)

	# Check handles first
	if _selected != null:
		var screen_rect: Rect2 = _get_screen_rect(_selected)
		for i in range(8):
			var hp: Vector2 = _handle_position(screen_rect, i)
			if mouse_pos.distance_to(hp) <= HANDLE_SIZE:
				_drag_mode = i
				_drag_start_mouse = mouse_pos
				_drag_start_rect = Rect2(_selected.position, _selected.size)
				return

	# Click on body
	var hit: Control = _hit_test(vp_pos)
	if hit != null:
		_selected = hit
		_drag_mode = 8  # body drag
		_drag_start_mouse = mouse_pos
		_drag_start_rect = Rect2(_selected.position, _selected.size)
		node_selected.emit(_selected)
	else:
		_selected = null
		node_selected.emit(null)
	queue_redraw()


func _handle_left_release(_mouse_pos: Vector2) -> void:
	if _drag_mode == -1 or _selected == null:
		return

	var old_rect: Rect2 = _drag_start_rect
	var new_rect: Rect2 = Rect2(_selected.position, _selected.size)

	if _drag_mode == 8 and old_rect.position != new_rect.position:
		move_committed.emit(_selected, old_rect.position, new_rect.position)
	elif _drag_mode != 8 and old_rect != new_rect:
		resize_committed.emit(_selected, old_rect, new_rect)

	_drag_mode = -1


func _hit_test(vp_pos: Vector2) -> Control:
	if _scene_root == null:
		return null
	return _walk_controls(_scene_root, vp_pos)


func _walk_controls(node: Node, vp_pos: Vector2) -> Control:
	var best: Control = null
	for child in node.get_children():
		var ctrl: Control = child as Control
		if ctrl == null or not ctrl.visible:
			continue
		var rect := Rect2(ctrl.global_position, ctrl.size)
		if rect.has_point(vp_pos):
			best = ctrl  # last match wins (topmost)
		var deeper: Control = _walk_controls(child, vp_pos)
		if deeper != null:
			best = deeper
	return best


func _apply_resize_delta(handle: int, delta: Vector2) -> void:
	var r: Rect2 = _drag_start_rect
	var snap: float = 8.0 if not Input.is_key_pressed(KEY_CTRL) else 1.0

	match handle:
		Handle.TL:
			r.position += delta
			r.size -= delta
		Handle.TC:
			r.position.y += delta.y
			r.size.y -= delta.y
		Handle.TR:
			r.position.y += delta.y
			r.size.y -= delta.y
			r.size.x += delta.x
		Handle.ML:
			r.position.x += delta.x
			r.size.x -= delta.x
		Handle.MR:
			r.size.x += delta.x
		Handle.BL:
			r.position.x += delta.x
			r.size -= Vector2(delta.x, 0.0)
			r.size.y += delta.y
		Handle.BC:
			r.size.y += delta.y
		Handle.BR:
			r.size += delta

	r.size.x = maxf(r.size.x, MIN_NODE_SIZE)
	r.size.y = maxf(r.size.y, MIN_NODE_SIZE)
	r.size = r.size.snapped(Vector2(snap, snap))
	r.position = r.position.snapped(Vector2(snap, snap))
	_selected.position = r.position
	_selected.size = r.size


func _get_screen_rect(node: Control) -> Rect2:
	if _canvas == null:
		return Rect2()
	var vp_pos: Vector2 = node.global_position
	var screen_pos: Vector2 = _canvas.get_pan_offset() + vp_pos * _canvas.get_zoom()
	return Rect2(screen_pos, node.size * _canvas.get_zoom())


func _handle_position(screen_rect: Rect2, handle: int) -> Vector2:
	var cx: float = screen_rect.position.x + screen_rect.size.x * 0.5
	var cy: float = screen_rect.position.y + screen_rect.size.y * 0.5
	match handle:
		Handle.TL: return screen_rect.position
		Handle.TC: return Vector2(cx, screen_rect.position.y)
		Handle.TR: return Vector2(screen_rect.end.x, screen_rect.position.y)
		Handle.ML: return Vector2(screen_rect.position.x, cy)
		Handle.MR: return Vector2(screen_rect.end.x, cy)
		Handle.BL: return Vector2(screen_rect.position.x, screen_rect.end.y)
		Handle.BC: return Vector2(cx, screen_rect.end.y)
		Handle.BR: return screen_rect.end
	return Vector2.ZERO


func _update_cursor(mouse_pos: Vector2) -> void:
	if _selected == null:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	var screen_rect: Rect2 = _get_screen_rect(_selected)
	for i in range(8):
		if mouse_pos.distance_to(_handle_position(screen_rect, i)) <= HANDLE_SIZE:
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			return
	mouse_default_cursor_shape = Control.CURSOR_ARROW
