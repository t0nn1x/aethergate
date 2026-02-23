class_name UiPanelStyleProfile
extends Resource

@export var fill_color: Color = Color(0.07, 0.10, 0.14, 0.58)
@export var border_color: Color = Color(0.68, 0.78, 0.92, 0.72)
@export_range(0, 8, 1) var border_width: int = 1
@export_range(0, 32, 1) var corner_radius: int = 8
@export var anti_aliasing: bool = true
@export_range(0.0, 4.0, 0.1) var anti_aliasing_size: float = 0.75
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export_range(0, 64, 1) var shadow_size: int = 0
@export var shadow_offset: Vector2 = Vector2.ZERO
