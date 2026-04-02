class_name GamePlatformProfile
extends Resource

## Platform-specific runtime toggles.

@export var profile_name: String = "desktop"
@export var allow_mouse_pointer_input: bool = true
@export var allow_touch_input: bool = false
@export var touch_hold_retarget_enabled: bool = false
@export var default_camera_zoom: float = 4.0
@export var pinch_zoom_enabled: bool = false
@export var mouse_wheel_zoom_enabled: bool = true
