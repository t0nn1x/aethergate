class_name PlayerMouseInputAdapter
extends RefCounted

## Mouse-specific input adapter used by PlayerInputComponent.

func handle_button(owner: PlayerInputComponent, mouse_event: InputEventMouseButton, click_move_action: StringName) -> void:
	if mouse_event.button_index != MOUSE_BUTTON_LEFT and not mouse_event.is_action(click_move_action):
		return

	owner._last_pointer_screen_position = mouse_event.position
	if mouse_event.pressed:
		if owner._is_pointer_over_ui(owner._last_pointer_screen_position):
			owner._set_pointer_held(false)
			return
		if owner._try_select_creature_at_screen_position(owner._last_pointer_screen_position):
			owner._set_pointer_held(false)
			return
		owner._set_pointer_held(true, -1)
		var screen_world_position: Vector2 = owner._screen_to_world(owner._last_pointer_screen_position)
		if OS.is_debug_build():
			var mouse_world_position: Vector2 = owner.creature.get_global_mouse_position()
			var world_delta: Vector2 = mouse_world_position - screen_world_position
			print(
				"[FIX][Cursor] move_click screen=%s queued_world=%s mouse_world=%s delta=%s"
				% [
					owner._last_pointer_screen_position,
					screen_world_position,
					mouse_world_position,
					world_delta
				]
			)
		owner._queue_move_target_world(screen_world_position, owner._last_pointer_screen_position, false)
		return
	owner._set_pointer_held(false)


func handle_motion(owner: PlayerInputComponent, motion_event: InputEventMouseMotion) -> void:
	if owner._is_pointer_held and owner._active_touch_index == -1:
		owner._last_pointer_screen_position = motion_event.position
