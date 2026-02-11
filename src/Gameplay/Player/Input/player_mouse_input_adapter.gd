class_name PlayerMouseInputAdapter
extends RefCounted

## Mouse-specific input adapter used by PlayerInputComponent.

const MOBILE_FEATURES: PackedStringArray = ["android", "ios", "mobile"]


func handle_button(owner: PlayerInputComponent, mouse_event: InputEventMouseButton, click_move_action: StringName) -> void:
	if _is_mobile_platform():
		# On mobile, touches can be mirrored as mouse events.
		# Ignore mouse path to avoid accidental move commands during pinch.
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT and not mouse_event.is_action(click_move_action):
		return

	owner._last_pointer_screen_position = owner._get_mouse_viewport_position(mouse_event.position)
	if mouse_event.pressed:
		if owner._is_pointer_over_ui(owner._last_pointer_screen_position):
			owner._set_pointer_held(false)
			return
		owner._set_pointer_held(true, -1)
		owner._queue_move_target_world(owner._get_mouse_world_position(), owner._last_pointer_screen_position, false)
		return
	owner._set_pointer_held(false)


func handle_motion(owner: PlayerInputComponent, motion_event: InputEventMouseMotion) -> void:
	if _is_mobile_platform():
		return
	if owner._is_pointer_held and owner._active_touch_index == -1:
		owner._last_pointer_screen_position = owner._get_mouse_viewport_position(motion_event.position)


func _is_mobile_platform() -> bool:
	for feature in MOBILE_FEATURES:
		if OS.has_feature(feature):
			return true
	return false
