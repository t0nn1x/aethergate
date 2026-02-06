@tool
class_name BridgeZone
extends Area2D

## Place this Area2D over any bridge to let the player walk across water.
## When the player enters, World-layer collision is disabled so
## water-edge polygons are ignored.  When the player exits, it's restored.
##
## Uses an overlap counter so adjacent / overlapping bridge zones
## don't flicker the collision back on prematurely.

## Size of the bridge zone in pixels. Adjust per-instance in the inspector.
@export var zone_size: Vector2 = Vector2(64, 128):
	set(value):
		zone_size = value
		_update_shape()

## Z-index applied to the player while on the bridge.
## Set to 1+ so the player draws above the water tiles underneath.
@export var bridge_z_index: int = 1

## Show a translucent rectangle in the editor so you can see the zone.
@export var debug_draw: bool = true

# Track how many BridgeZones a single body is inside at once.
# Shared across ALL BridgeZone instances via a static dictionary.
static var _overlap_counts: Dictionary = {}  # Node -> int

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_update_shape()

	if Engine.is_editor_hint():
		return

	# Runtime only — detect the Player layer
	collision_layer = 0
	collision_mask = 2  # Player (layer 2)
	monitoring = true
	monitorable = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _update_shape() -> void:
	if not is_inside_tree():
		return
	if _collision_shape == null:
		return
	var rect_shape := _collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		_collision_shape.shape = rect_shape
	rect_shape.size = zone_size
	queue_redraw()


func _draw() -> void:
	if not debug_draw:
		return
	if not Engine.is_editor_hint():
		return
	var rect := Rect2(-zone_size / 2.0, zone_size)
	draw_rect(rect, Color(0.2, 0.6, 1.0, 0.25))
	draw_rect(rect, Color(0.2, 0.6, 1.0, 0.6), false, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	var count: int = _overlap_counts.get(body, 0) + 1
	_overlap_counts[body] = count

	if count == 1:
		# First bridge zone entered — disable World collision
		body.set_collision_mask_value(1, false)  # World layer
		body.z_index = bridge_z_index


func _on_body_exited(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	var count: int = _overlap_counts.get(body, 1) - 1
	_overlap_counts[body] = count

	if count <= 0:
		# Last bridge zone exited — restore World collision
		body.set_collision_mask_value(1, true)  # World layer
		body.z_index = 0
		_overlap_counts.erase(body)
