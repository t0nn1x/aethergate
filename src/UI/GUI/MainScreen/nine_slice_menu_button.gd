@tool
class_name NineSliceMenuButton
extends Button

## Editor-facing size control for menu buttons that use 9-slice styles.

@export var button_size: Vector2 = Vector2(360.0, 92.0):
	set(value):
		button_size = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_apply_button_size()


func _ready() -> void:
	_apply_button_size()


func _apply_button_size() -> void:
	custom_minimum_size = button_size
