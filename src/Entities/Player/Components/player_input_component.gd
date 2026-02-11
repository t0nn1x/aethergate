class_name PlayerInputComponent
extends Node

## Handles click/tap move requests.

signal move_target_queued(world_position: Vector2, from_hold: bool)
signal pointer_hold_changed(is_held: bool)

const MOBILE_FEATURES: PackedStringArray = ["android", "ios", "mobile"]

var creature: Creature

@export var click_move_action: StringName = "click_move"
@export var hold_retarget_enabled: bool = true
@export var touch_hold_retarget_enabled_mobile: bool = false
@export var touch_tap_max_drag_distance: float = 12.0
@export var hold_retarget_interval: float = 0.06
@export var hold_retarget_min_distance: float = 8.0
@export var reject_targets_inside_navigation_polygons: bool = true
@export var blocker_polygon_refresh_interval: float = 0.5
@export var disable_move_while_multitouch: bool = true

var _pending_move_target: Vector2 = Vector2.ZERO
var _has_pending_move_target: bool = false
var _is_pointer_held: bool = false
var _active_touch_index: int = -1
var _last_pointer_screen_position: Vector2 = Vector2.ZERO
var _hold_retarget_timer: float = 0.0
var _has_last_hold_target: bool = false
var _last_hold_target_world: Vector2 = Vector2.ZERO
var _touch_points: Dictionary = {}
var _is_multi_touch_active: bool = false
var _touch_tap_candidate_index: int = -1
var _touch_tap_candidate_start_position: Vector2 = Vector2.ZERO
var _touch_tap_candidate_latest_position: Vector2 = Vector2.ZERO
var _suppress_touch_tap_until_clear: bool = false
var _target_blocker: PlayerMoveTargetBlockerComponent
var _warned_missing_target_blocker: bool = false


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerInputComponent must be a child of a Creature.")
	_target_blocker = creature.get_node_or_null("PlayerMoveTargetBlockerComponent") as PlayerMoveTargetBlockerComponent
	if _target_blocker:
		_target_blocker.blocker_polygon_refresh_interval = blocker_polygon_refresh_interval
	elif reject_targets_inside_navigation_polygons and OS.is_debug_build():
		push_warning("PlayerInputComponent: PlayerMoveTargetBlockerComponent is missing.")


func _process(delta: float) -> void:
	if not _should_process_hold_retarget():
		return
	_sync_pointer_position_for_hold_retarget()
	_hold_retarget_timer -= delta
	if _hold_retarget_timer > 0.0:
		return
	_hold_retarget_timer = max(hold_retarget_interval, 0.01)
	_queue_hold_retarget_target()


func _unhandled_input(event: InputEvent) -> void:
	if not creature or not creature.is_alive:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
		return

	if event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		return

	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


## Returns and clears one pending move target request.
## Returns null when no request is queued.
func consume_move_target_request() -> Variant:
	if not _has_pending_move_target:
		return null
	_has_pending_move_target = false
	return _pending_move_target


func _should_process_hold_retarget() -> bool:
	if not _is_pointer_held:
		return false
	if not creature or not creature.is_alive:
		return false
	if _active_touch_index == -1:
		if not hold_retarget_enabled:
			return false
	elif not _is_touch_hold_retarget_enabled():
		return false
	if disable_move_while_multitouch and _is_multi_touch_active:
		return false
	return true


func _sync_pointer_position_for_hold_retarget() -> void:
	if _active_touch_index != -1:
		return
	var viewport := creature.get_viewport()
	if viewport:
		_last_pointer_screen_position = viewport.get_mouse_position()


func _queue_hold_retarget_target() -> void:
	if _active_touch_index == -1:
		_queue_move_target_world(_get_mouse_world_position(), _last_pointer_screen_position, true)
		return
	_queue_move_target(_last_pointer_screen_position, true)


func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
	if _is_mobile_platform():
		# On mobile, touches can be mirrored as mouse events.
		# Ignore mouse path to avoid accidental move commands during pinch.
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT and not mouse_event.is_action(click_move_action):
		return

	_last_pointer_screen_position = _get_mouse_viewport_position(mouse_event.position)
	if mouse_event.pressed:
		if _is_pointer_over_ui(_last_pointer_screen_position):
			_set_pointer_held(false)
			return
		_set_pointer_held(true, -1)
		_queue_move_target_world(_get_mouse_world_position(), _last_pointer_screen_position, false)
		return
	_set_pointer_held(false)


func _handle_mouse_motion(motion_event: InputEventMouseMotion) -> void:
	if _is_mobile_platform():
		return
	if _is_pointer_held and _active_touch_index == -1:
		_last_pointer_screen_position = _get_mouse_viewport_position(motion_event.position)


func _handle_screen_touch(touch_event: InputEventScreenTouch) -> void:
	if touch_event.pressed:
		_on_screen_touch_pressed(touch_event)
		return
	_on_screen_touch_released(touch_event)


func _on_screen_touch_pressed(touch_event: InputEventScreenTouch) -> void:
	_touch_points[touch_event.index] = touch_event.position
	_update_multi_touch_state()
	if disable_move_while_multitouch and _is_multi_touch_active:
		_clear_touch_tap_candidate(touch_event.index)
		return
	if _is_pointer_held and _active_touch_index != -1 and touch_event.index != _active_touch_index:
		# Ignore extra touches so two-finger pinch doesn't retarget movement.
		return
	if _is_pointer_over_ui(touch_event.position):
		_clear_touch_tap_candidate(touch_event.index)
		return

	_last_pointer_screen_position = touch_event.position
	_set_pointer_held(true, touch_event.index)
	_set_touch_tap_candidate(touch_event.index, touch_event.position)


func _on_screen_touch_released(touch_event: InputEventScreenTouch) -> void:
	_touch_points.erase(touch_event.index)
	_update_multi_touch_state()

	var should_queue_tap: bool = _should_queue_touch_tap(touch_event)
	if _is_pointer_held and touch_event.index == _active_touch_index:
		_set_pointer_held(false)
	if should_queue_tap:
		_queue_move_target(touch_event.position, false)
	_clear_touch_tap_candidate(touch_event.index)


func _handle_screen_drag(drag_event: InputEventScreenDrag) -> void:
	if _touch_points.has(drag_event.index):
		_touch_points[drag_event.index] = drag_event.position
	if _touch_tap_candidate_index == drag_event.index:
		_touch_tap_candidate_latest_position = drag_event.position
	_update_multi_touch_state()
	if disable_move_while_multitouch and _is_multi_touch_active:
		return
	if not _is_pointer_held:
		return
	if drag_event.index != _active_touch_index:
		return
	_last_pointer_screen_position = drag_event.position


func _queue_move_target(screen_position: Vector2, from_hold: bool) -> void:
	var world_position: Vector2 = _screen_to_world(screen_position)
	_queue_move_target_world(world_position, screen_position, from_hold)


func _queue_move_target_world(world_position: Vector2, screen_position: Vector2, from_hold: bool) -> void:
	if _is_pointer_over_ui(screen_position):
		return
	var resolved_world_position: Vector2 = _resolve_blocked_world_target(world_position)
	if _is_world_position_in_blocked_polygon(resolved_world_position):
		return
	if from_hold and _has_last_hold_target:
		if resolved_world_position.distance_to(_last_hold_target_world) < max(hold_retarget_min_distance, 0.0):
			return
	_last_hold_target_world = resolved_world_position
	_has_last_hold_target = true
	_pending_move_target = resolved_world_position
	_has_pending_move_target = true
	# Keep the marker at the exact click/tap location, even when movement snaps.
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


func _update_multi_touch_state() -> void:
	var was_multi_touch_active: bool = _is_multi_touch_active
	_is_multi_touch_active = _touch_points.size() >= 2
	if _is_multi_touch_active and not was_multi_touch_active:
		# Cancel pending move requests while pinch gesture is active.
		_suppress_touch_tap_until_clear = true
		_has_pending_move_target = false
		_touch_tap_candidate_index = -1
		if _is_pointer_held and _active_touch_index != -1:
			_set_pointer_held(false)
	if _touch_points.is_empty():
		_suppress_touch_tap_until_clear = false


func _set_touch_tap_candidate(index: int, position: Vector2) -> void:
	_touch_tap_candidate_index = index
	_touch_tap_candidate_start_position = position
	_touch_tap_candidate_latest_position = position


func _clear_touch_tap_candidate(index: int) -> void:
	if _touch_tap_candidate_index != index:
		return
	_touch_tap_candidate_index = -1
	_touch_tap_candidate_start_position = Vector2.ZERO
	_touch_tap_candidate_latest_position = Vector2.ZERO


func _should_queue_touch_tap(touch_event: InputEventScreenTouch) -> bool:
	if _suppress_touch_tap_until_clear:
		return false
	if disable_move_while_multitouch and _is_multi_touch_active:
		return false
	if _touch_tap_candidate_index != touch_event.index:
		return false
	if _is_pointer_over_ui(touch_event.position):
		return false
	var drag_distance: float = _touch_tap_candidate_start_position.distance_to(_touch_tap_candidate_latest_position)
	return drag_distance <= maxf(touch_tap_max_drag_distance, 0.0)


func _is_touch_hold_retarget_enabled() -> bool:
	if _is_mobile_platform():
		return touch_hold_retarget_enabled_mobile
	return hold_retarget_enabled


func _is_mobile_platform() -> bool:
	for feature in MOBILE_FEATURES:
		if OS.has_feature(feature):
			return true
	return false


func _is_world_position_in_blocked_polygon(world_position: Vector2) -> bool:
	if not reject_targets_inside_navigation_polygons:
		return false
	if _target_blocker == null:
		if not _warned_missing_target_blocker and OS.is_debug_build():
			push_warning("PlayerInputComponent: move target blocker unavailable; blocked-target checks are disabled.")
			_warned_missing_target_blocker = true
		return false

	_sync_target_blocker_config()
	return _target_blocker.is_world_position_blocked(world_position)


func _resolve_blocked_world_target(world_position: Vector2) -> Vector2:
	if not reject_targets_inside_navigation_polygons:
		return world_position
	if _target_blocker == null:
		return world_position

	_sync_target_blocker_config()
	return _target_blocker.resolve_world_target(world_position)


func _sync_target_blocker_config() -> void:
	if _target_blocker:
		_target_blocker.blocker_polygon_refresh_interval = blocker_polygon_refresh_interval
