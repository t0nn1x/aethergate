class_name PlayerTouchInputAdapter
extends RefCounted

## Touch-specific input adapter used by PlayerInputComponent.

var _touch_points: Dictionary = {}
var _is_multi_touch_active: bool = false
var _touch_tap_candidate_index: int = -1
var _touch_tap_candidate_start_position: Vector2 = Vector2.ZERO
var _touch_tap_candidate_latest_position: Vector2 = Vector2.ZERO
var _suppress_touch_tap_until_clear: bool = false


func handle_touch(
	owner: PlayerInputComponent,
	touch_event: InputEventScreenTouch,
	disable_move_while_multitouch: bool,
	touch_tap_max_drag_distance: float
) -> void:
	if touch_event.pressed:
		_touch_points[touch_event.index] = touch_event.position
	else:
		_touch_points.erase(touch_event.index)
	_update_multi_touch_state(owner)

	if touch_event.pressed:
		if disable_move_while_multitouch and _is_multi_touch_active:
			_clear_touch_tap_candidate(touch_event.index)
			return
		if owner._is_pointer_held and owner._active_touch_index != -1 and touch_event.index != owner._active_touch_index:
			# Ignore extra touches so two-finger pinch doesn't retarget movement.
			return
		if owner._is_pointer_over_ui(touch_event.position):
			_clear_touch_tap_candidate(touch_event.index)
			return

		owner._last_pointer_screen_position = touch_event.position
		owner._set_pointer_held(true, touch_event.index)
		_set_touch_tap_candidate(touch_event.index, touch_event.position)
		return

	var should_queue_tap: bool = _should_queue_touch_tap(owner, touch_event, disable_move_while_multitouch, touch_tap_max_drag_distance)
	if owner._is_pointer_held and touch_event.index == owner._active_touch_index:
		owner._set_pointer_held(false)
	if should_queue_tap:
		owner._queue_move_target(touch_event.position, false)
	_clear_touch_tap_candidate(touch_event.index)


func handle_drag(owner: PlayerInputComponent, drag_event: InputEventScreenDrag, disable_move_while_multitouch: bool) -> void:
	if _touch_points.has(drag_event.index):
		_touch_points[drag_event.index] = drag_event.position
	if _touch_tap_candidate_index == drag_event.index:
		_touch_tap_candidate_latest_position = drag_event.position
	_update_multi_touch_state(owner)

	if disable_move_while_multitouch and _is_multi_touch_active:
		return
	if not owner._is_pointer_held:
		return
	if drag_event.index != owner._active_touch_index:
		return
	owner._last_pointer_screen_position = drag_event.position


func is_multi_touch_active() -> bool:
	return _is_multi_touch_active


func _update_multi_touch_state(owner: PlayerInputComponent) -> void:
	var was_multi_touch_active: bool = _is_multi_touch_active
	_is_multi_touch_active = _touch_points.size() >= 2
	if _is_multi_touch_active and not was_multi_touch_active:
		# Cancel pending move requests while pinch gesture is active.
		_suppress_touch_tap_until_clear = true
		_touch_tap_candidate_index = -1
		if owner._is_pointer_held and owner._active_touch_index != -1:
			owner._set_pointer_held(false)
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


func _should_queue_touch_tap(
	owner: PlayerInputComponent,
	touch_event: InputEventScreenTouch,
	disable_move_while_multitouch: bool,
	touch_tap_max_drag_distance: float
) -> bool:
	if _suppress_touch_tap_until_clear:
		return false
	if disable_move_while_multitouch and _is_multi_touch_active:
		return false
	if _touch_tap_candidate_index != touch_event.index:
		return false
	if owner._is_pointer_over_ui(touch_event.position):
		return false

	var drag_distance: float = _touch_tap_candidate_start_position.distance_to(_touch_tap_candidate_latest_position)
	return drag_distance <= maxf(touch_tap_max_drag_distance, 0.0)
