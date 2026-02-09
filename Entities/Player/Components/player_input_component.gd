class_name PlayerInputComponent
extends Node

## Handles click/tap move requests.

signal move_target_queued(world_position: Vector2, from_hold: bool)
signal pointer_hold_changed(is_held: bool)

var creature: Creature

@export var click_move_action: StringName = "click_move"
@export var hold_retarget_enabled: bool = true
@export var hold_retarget_interval: float = 0.06
@export var hold_retarget_min_distance: float = 8.0
@export var reject_targets_inside_navigation_polygons: bool = true
@export var blocker_polygon_refresh_interval: float = 0.5

var _pending_move_target: Vector2 = Vector2.ZERO
var _has_pending_move_target: bool = false
var _is_pointer_held: bool = false
var _active_touch_index: int = -1
var _last_pointer_screen_position: Vector2 = Vector2.ZERO
var _hold_retarget_timer: float = 0.0
var _has_last_hold_target: bool = false
var _last_hold_target_world: Vector2 = Vector2.ZERO
var _cached_blocker_polygons: Array[Polygon2D] = []
var _next_blocker_refresh_msec: int = 0


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerInputComponent must be a child of a Creature.")
	_refresh_blocker_polygons_cache()


func _process(delta: float) -> void:
	if not hold_retarget_enabled or not _is_pointer_held:
		return
	if not creature or not creature.is_alive:
		return
	if _active_touch_index == -1:
		var viewport := creature.get_viewport()
		if viewport:
			_last_pointer_screen_position = viewport.get_mouse_position()

	_hold_retarget_timer -= delta
	if _hold_retarget_timer > 0.0:
		return
	_hold_retarget_timer = max(hold_retarget_interval, 0.01)
	if _active_touch_index == -1:
		_queue_move_target_world(_get_mouse_world_position(), _last_pointer_screen_position, true)
		return
	_queue_move_target(_last_pointer_screen_position, true)


func _unhandled_input(event: InputEvent) -> void:
	if not creature or not creature.is_alive:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT and not mouse_event.is_action(click_move_action):
			return
		_last_pointer_screen_position = _get_mouse_viewport_position(mouse_event.position)
		if mouse_event.pressed:
			if _is_pointer_over_ui(_last_pointer_screen_position):
				_set_pointer_held(false)
				return
			_set_pointer_held(true, -1)
			_queue_move_target_world(_get_mouse_world_position(), _last_pointer_screen_position, false)
		else:
			_set_pointer_held(false)
		return

	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if _is_pointer_held and _active_touch_index == -1:
			_last_pointer_screen_position = _get_mouse_viewport_position(motion_event.position)
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if _is_pointer_over_ui(touch_event.position):
				return
			_last_pointer_screen_position = touch_event.position
			_set_pointer_held(true, touch_event.index)
			_queue_move_target(touch_event.position, false)
		elif _is_pointer_held and touch_event.index == _active_touch_index:
			_set_pointer_held(false)
		return

	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if not _is_pointer_held:
			return
		if drag_event.index != _active_touch_index:
			return
		_last_pointer_screen_position = drag_event.position


## Returns and clears one pending move target request.
## Returns null when no request is queued.
func consume_move_target_request() -> Variant:
	if not _has_pending_move_target:
		return null
	_has_pending_move_target = false
	return _pending_move_target


func _queue_move_target(screen_position: Vector2, from_hold: bool) -> void:
	var world_position: Vector2 = _screen_to_world(screen_position)
	_queue_move_target_world(world_position, screen_position, from_hold)


func _queue_move_target_world(world_position: Vector2, screen_position: Vector2, from_hold: bool) -> void:
	if _is_pointer_over_ui(screen_position):
		return
	if _is_world_position_in_blocked_polygon(world_position):
		return
	if from_hold and _has_last_hold_target:
		if world_position.distance_to(_last_hold_target_world) < max(hold_retarget_min_distance, 0.0):
			return
	_last_hold_target_world = world_position
	_has_last_hold_target = true
	_pending_move_target = world_position
	_has_pending_move_target = true
	move_target_queued.emit(world_position, from_hold)


func _screen_to_world(screen_position: Vector2) -> Vector2:
	var viewport := creature.get_viewport()
	if viewport == null:
		return creature.global_position
	return viewport.get_canvas_transform().affine_inverse() * screen_position


func _get_mouse_viewport_position(fallback_position: Vector2) -> Vector2:
	var viewport := creature.get_viewport()
	if viewport == null:
		return fallback_position
	return viewport.get_mouse_position()


func _get_mouse_world_position() -> Vector2:
	if creature == null:
		return Vector2.ZERO

	var tree := creature.get_tree()
	if tree:
		var pixel_root: Node = tree.get_first_node_in_group("pixel_viewport_root")
		if pixel_root:
			var viewport_container := pixel_root.get_node_or_null("WorldViewportContainer") as SubViewportContainer
			var world_viewport := pixel_root.get_node_or_null("WorldViewportContainer/WorldViewport") as SubViewport
			if viewport_container and world_viewport:
				var root_mouse: Vector2 = tree.root.get_mouse_position()
				var container_mouse: Vector2 = viewport_container.get_global_transform_with_canvas().affine_inverse() * root_mouse
				var container_size: Vector2 = viewport_container.size
				if container_size.x > 0.0 and container_size.y > 0.0:
					var normalized: Vector2 = Vector2(
						container_mouse.x / container_size.x,
						container_mouse.y / container_size.y
					)
					var viewport_mouse: Vector2 = Vector2(
						normalized.x * float(world_viewport.size.x),
						normalized.y * float(world_viewport.size.y)
					)
					return world_viewport.get_canvas_transform().affine_inverse() * viewport_mouse

	return creature.get_global_mouse_position()


func _is_pointer_over_ui(_screen_position: Vector2) -> bool:
	var viewport := creature.get_viewport()
	if viewport == null:
		return false

	var hovered: Control = viewport.gui_get_hovered_control()
	if hovered and hovered.is_visible_in_tree():
		return true

	var focused: Control = viewport.gui_get_focus_owner()
	return focused != null and focused.is_visible_in_tree()


func _set_pointer_held(value: bool, touch_index: int = -1) -> void:
	var was_held := _is_pointer_held
	_is_pointer_held = value
	_active_touch_index = touch_index if value else -1
	_hold_retarget_timer = 0.0
	if not value:
		_has_last_hold_target = false
	if was_held != _is_pointer_held:
		pointer_hold_changed.emit(_is_pointer_held)


func _is_world_position_in_blocked_polygon(world_position: Vector2) -> bool:
	if not reject_targets_inside_navigation_polygons:
		return false

	_refresh_blocker_polygons_cache_if_needed()
	for polygon in _cached_blocker_polygons:
		if not is_instance_valid(polygon):
			continue
		var local_point: Vector2 = polygon.to_local(world_position)
		if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
			return true
	return false


func _refresh_blocker_polygons_cache_if_needed() -> void:
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _next_blocker_refresh_msec and not _cached_blocker_polygons.is_empty():
		return
	_refresh_blocker_polygons_cache()


func _refresh_blocker_polygons_cache() -> void:
	_cached_blocker_polygons.clear()
	_next_blocker_refresh_msec = Time.get_ticks_msec() + int(max(blocker_polygon_refresh_interval, 0.05) * 1000.0)

	if not creature:
		return
	var tree := creature.get_tree()
	if tree == null:
		return

	var root: Node = tree.current_scene if tree.current_scene else tree.root
	if root == null:
		return

	for node in root.find_children("*", "NavigationRegion2D", true, false):
		var region := node as NavigationRegion2D
		if region == null:
			continue
		for child in region.find_children("*", "Polygon2D", true, false):
			var polygon := child as Polygon2D
			if polygon and polygon.polygon.size() >= 3:
				_cached_blocker_polygons.append(polygon)
