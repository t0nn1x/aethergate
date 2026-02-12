class_name StartupSplashScreen
extends Node

@export_range(0.1, 10.0, 0.1) var minimum_splash_duration: float = 3.0
@export_range(0.1, 10.0, 0.1) var fade_in_duration: float = 1.0
@export_range(0.0, 10.0, 0.1) var fade_out_duration: float = 0.8
@export_range(0.0, 10.0, 0.1) var background_fade_out_duration: float = 0.7
@export_range(0.1, 1.0, 0.01) var logo_max_width_ratio_portrait: float = 0.72
@export_range(0.1, 1.0, 0.01) var logo_max_width_ratio_landscape: float = 0.48
@export_range(0.05, 1.0, 0.01) var logo_max_height_ratio_portrait: float = 0.22
@export_range(0.05, 1.0, 0.01) var logo_max_height_ratio_landscape: float = 0.36

@onready var _splash_layer: CanvasLayer = $SplashLayer
@onready var _overlay_root: Control = $SplashLayer/Root
@onready var _background: ColorRect = $SplashLayer/Root/Background
@onready var _logo: TextureRect = $SplashLayer/Root/Logo

var _viewport: Viewport


func _ready() -> void:
	_viewport = get_viewport()
	_wire_viewport_resize_signal()
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_background.color = Color(0.0, 0.0, 0.0, 1.0)
	_logo.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_apply_logo_layout()
	await _play_splash_then_reveal_main_menu()


func _wire_viewport_resize_signal() -> void:
	if _viewport == null:
		return
	if not _viewport.size_changed.is_connected(_on_viewport_size_changed):
		_viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_apply_logo_layout()


func _apply_logo_layout() -> void:
	var texture: Texture2D = _logo.texture
	if texture == null:
		push_warning("StartupSplashScreen: logo texture is missing.")
		return

	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var viewport_size: Vector2 = _resolve_viewport_size()
	var is_portrait: bool = viewport_size.y >= viewport_size.x
	var max_width_ratio: float = logo_max_width_ratio_portrait if is_portrait else logo_max_width_ratio_landscape
	var max_height_ratio: float = logo_max_height_ratio_portrait if is_portrait else logo_max_height_ratio_landscape
	var max_logo_size: Vector2 = Vector2(viewport_size.x * max_width_ratio, viewport_size.y * max_height_ratio)

	var scale_factor: float = minf(max_logo_size.x / texture_size.x, max_logo_size.y / texture_size.y)
	scale_factor = maxf(scale_factor, 0.01)

	var target_size: Vector2 = (texture_size * scale_factor).round()
	_logo.custom_minimum_size = target_size
	_logo.size = target_size
	_logo.position = (viewport_size - target_size) * 0.5


func _resolve_viewport_size() -> Vector2:
	if _viewport:
		var rect_size: Vector2 = _viewport.get_visible_rect().size
		if rect_size.x > 0.0 and rect_size.y > 0.0:
			return rect_size
	return Vector2(1920.0, 1080.0)


func _play_splash_then_reveal_main_menu() -> void:
	var started_usec: int = Time.get_ticks_usec()
	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(_logo, "modulate:a", 1.0, maxf(0.01, fade_in_duration))
	await fade_in_tween.finished

	var elapsed_seconds: float = float(Time.get_ticks_usec() - started_usec) / 1000000.0
	var remaining_seconds: float = maxf(0.0, minimum_splash_duration - elapsed_seconds)
	if remaining_seconds > 0.0:
		await get_tree().create_timer(remaining_seconds).timeout

	if fade_out_duration > 0.0:
		var fade_out_tween: Tween = create_tween()
		fade_out_tween.tween_property(_logo, "modulate:a", 0.0, fade_out_duration)
		await fade_out_tween.finished

	if background_fade_out_duration > 0.0:
		var background_tween: Tween = create_tween()
		background_tween.tween_property(_background, "color:a", 0.0, background_fade_out_duration)
		await background_tween.finished
	else:
		var color_without_alpha: Color = _background.color
		color_without_alpha.a = 0.0
		_background.color = color_without_alpha

	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_splash_layer.queue_free()
