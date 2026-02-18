class_name UiTextStyleProfile
extends Resource

@export var font: Font
@export var font_color: Color = Color(0.93, 0.96, 1.0, 0.95)
@export_range(8, 80, 1) var desktop_font_size: int = 30
@export_range(8, 80, 1) var mobile_font_size: int = 24
@export_range(-16, 16, 1) var portrait_font_size_delta: int = -2

