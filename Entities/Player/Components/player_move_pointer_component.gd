class_name PlayerMovePointerComponent
extends Node2D

## Temporary click/tap indicator rendered as an animated ring.
## Replace later with a sprite-based marker if desired.

@export var tap_lifetime: float = 0.30
@export var hold_lifetime: float = 0.16
@export var base_radius: float = 4.0
@export var max_radius: float = 10.0
@export var ring_width: float = 1.0
@export var ring_color: Color = Color(0.2, 0.9, 1.0, 0.95)
@export var fill_color: Color = Color(0.2, 0.9, 1.0, 0.25)

var creature: Creature
var input_component: PlayerInputComponent
var _time_left: float = 0.0
var _duration: float = 0.0


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerMovePointerComponent must be a child of a Creature.")

	top_level = true
	visible = false

	input_component = creature.get_node_or_null("PlayerInputComponent") as PlayerInputComponent
	if input_component:
		input_component.move_target_queued.connect(_on_move_target_queued)


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		if visible:
			visible = false
			queue_redraw()
		return

	_time_left = max(0.0, _time_left - delta)
	queue_redraw()


func _draw() -> void:
	if _time_left <= 0.0:
		return

	var normalized: float = 1.0
	if _duration > 0.0:
		normalized = 1.0 - (_time_left / _duration)
	normalized = clamp(normalized, 0.0, 1.0)

	var radius: float = lerpf(base_radius, max_radius, normalized)
	var alpha: float = 1.0 - normalized

	var fill := fill_color
	fill.a *= alpha
	draw_circle(Vector2.ZERO, radius * 0.55, fill)

	var ring := ring_color
	ring.a *= alpha
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring, max(ring_width, 0.5), true)


func _on_move_target_queued(world_position: Vector2, from_hold: bool) -> void:
	global_position = world_position
	_duration = max(0.01, hold_lifetime if from_hold else tap_lifetime)
	_time_left = _duration
	visible = true
	queue_redraw()
