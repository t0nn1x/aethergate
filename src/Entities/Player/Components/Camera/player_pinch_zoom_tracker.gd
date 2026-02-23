class_name PlayerPinchZoomTracker
extends RefCounted

## Tracks two-finger pinch state and produces zoom target updates.

var _touch_points: Dictionary = {}
var _pinch_active: bool = false
var _pinch_start_distance: float = 0.0
var _pinch_start_zoom: float = 4.0


func register_touch(index: int, position: Vector2, pressed: bool) -> void:
	if pressed:
		_touch_points[index] = position
	else:
		_touch_points.erase(index)


func has_touch(index: int) -> bool:
	return _touch_points.has(index)


func update_touch_position(index: int, position: Vector2) -> void:
	if _touch_points.has(index):
		_touch_points[index] = position


## Returns a zoom target when pinch should update zoom, otherwise null.
func compute_zoom_target(current_zoom_target: float, pinch_min_distance: float, pinch_zoom_sensitivity: float) -> Variant:
	if _touch_points.size() != 2:
		_pinch_active = false
		return null

	var touch_positions: Array[Vector2] = _get_two_touch_positions()
	if touch_positions.size() < 2:
		_pinch_active = false
		return null

	var current_distance: float = touch_positions[0].distance_to(touch_positions[1])
	if current_distance <= pinch_min_distance:
		return null

	if not _pinch_active:
		_pinch_active = true
		_pinch_start_distance = current_distance
		_pinch_start_zoom = current_zoom_target
		return null

	if _pinch_start_distance <= 0.0:
		return null

	var ratio: float = current_distance / _pinch_start_distance
	var adjusted_ratio: float = pow(ratio, maxf(pinch_zoom_sensitivity, 0.01))
	return _pinch_start_zoom * adjusted_ratio


func _get_two_touch_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for value in _touch_points.values():
		positions.append(value as Vector2)
		if positions.size() >= 2:
			break
	return positions
