class_name CreaturePressFeedback
extends Node2D

@export_range(0.05, 1.0, 0.01) var duration_seconds: float = 0.2
@export_range(1.0, 32.0, 0.5) var start_radius: float = 6.0
@export_range(4.0, 96.0, 0.5) var end_radius: float = 22.0
@export var ring_color: Color = Color(1.0, 1.0, 1.0, 0.35)
@export_range(8, 128, 1) var arc_segments: int = 40
@export_range(0.5, 4.0, 0.1) var arc_width: float = 1.5

var _elapsed: float = 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = 200
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration_seconds:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var safe_duration: float = maxf(duration_seconds, 0.001)
	var t: float = clampf(_elapsed / safe_duration, 0.0, 1.0)
	var eased_t: float = 1.0 - pow(1.0 - t, 3.0)
	var radius: float = lerpf(start_radius, end_radius, eased_t)

	var fill_color: Color = ring_color
	fill_color.a *= 1.0 - t
	draw_circle(Vector2.ZERO, radius, fill_color)

	var stroke_color: Color = ring_color
	stroke_color.a *= (1.0 - t) * 0.9
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, max(arc_segments, 8), stroke_color, arc_width, true)
