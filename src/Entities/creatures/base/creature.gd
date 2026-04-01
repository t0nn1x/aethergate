class_name Creature
extends CharacterBody2D

## Base class for all living entities in the game (player, enemies, NPCs).
## A thin shell: holds stats, visuals, and component child nodes.
## Configure via a CreatureData resource; behavior lives in components/states.

const CreatureData = preload("res://src/Entities/creatures/base/creature_data.gd")

## Emergency fallback if non_boss_world_scale is invalid. Matches the field default in CreatureData.
const DEFAULT_NON_BOSS_WORLD_SCALE: Vector2 = Vector2(1.0, 1.0)

@export var creature_data: CreatureData

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var _silhouette: Sprite2D = get_node_or_null("Silhouette") as Sprite2D

## --- Stats (applied from creature_data or set manually for Player) ---
var creature_name: String = "Creature"
var max_health: float = 100.0
var current_health: float = 100.0
var movement_speed: float = 200.0
var damage: float = 0.0
var armor: float = 0.0
var is_alive: bool = true

## --- Signals ---
signal health_changed(new_health: float, max_health: float)
signal died()
signal creature_data_applied(data: CreatureData)
signal damaged(amount: float, source: Node)

## --- Lifecycle ---

func _ready() -> void:
	add_to_group("creatures")
	if creature_data:
		_apply_creature_data()
	_emit_creature_spawned_event()
	_on_creature_ready()


## Applies stats and visuals from a CreatureData resource.
func _apply_creature_data() -> void:
	if not creature_data.validate_for_runtime(creature_data.display_name):
		push_warning("Creature '%s': creature_data validation failed." % name)

	creature_name = creature_data.display_name
	max_health = creature_data.max_health
	current_health = max_health
	movement_speed = creature_data.movement_speed
	damage = creature_data.damage
	armor = creature_data.armor
	_apply_world_scale_from_data(creature_data)
	_apply_visual_data(creature_data)

	creature_data_applied.emit(creature_data)
	_on_creature_data_applied(creature_data)


## Reapplies current CreatureData (useful after runtime edits).
func refresh_from_creature_data() -> void:
	if creature_data == null:
		push_warning("Creature '%s': refresh requested without creature_data." % name)
		return
	_apply_creature_data()


## --- Health ---

## Deals damage to this creature, reduced by armor.
func take_damage(amount: float, source: Node = null) -> void:
	if not is_alive:
		return

	var effective_damage: float = max(1.0, amount - armor)
	current_health = max(0.0, current_health - effective_damage)
	damaged.emit(effective_damage, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		die()


## Heals the creature by the given amount.
func heal(amount: float) -> void:
	if not is_alive:
		return

	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Kills the creature.
func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()
	_emit_creature_died_event()
	_on_death()


## Virtual — override in subclasses for custom death behavior.
func _on_death() -> void:
	queue_free()


## Virtual hook called once Creature is initialized.
func _on_creature_ready() -> void:
	pass


## Virtual hook called after CreatureData was applied.
func _on_creature_data_applied(_data: CreatureData) -> void:
	pass


## Returns the current health as a ratio 0.0–1.0.
func get_health_percentage() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health


func _apply_visual_data(data: CreatureData) -> void:
	if _sprite == null:
		push_warning("Creature '%s': Sprite2D node is missing." % name)
		return

	var texture: Texture2D
	var hframes: int
	var vframes: int
	if data.overworld_sprite_sheet != null:
		texture = data.overworld_sprite_sheet
		if texture.get_width() % CreatureData.OVERWORLD_FRAME_SIZE != 0:
			push_warning(
				"Creature '%s': overworld sprite width %d is not a multiple of %d."
				% [name, texture.get_width(), CreatureData.OVERWORLD_FRAME_SIZE]
			)
		hframes = maxi(1, texture.get_width() / CreatureData.OVERWORLD_FRAME_SIZE)
		vframes = 1
		if data.vframes != 1:
			push_warning(
				"Creature '%s': vframes=%d ignored for overworld sprite (must be 1)."
				% [name, data.vframes]
			)
	else:
		texture = data.sprite_sheet
		if texture == null and not data.source_sprite_path.is_empty():
			texture = load(data.source_sprite_path) as Texture2D
		hframes = maxi(data.hframes, 1)
		vframes = maxi(data.vframes, 1)

	if texture == null:
		push_warning(
			"Creature '%s': no sprite texture found (source='%s')."
			% [name, data.source_sprite_path]
		)
		return

	_sprite.texture = texture
	_sprite.hframes = hframes
	_sprite.vframes = vframes
	_sprite.frame = clampi(data.default_frame, 0, _sprite.hframes * _sprite.vframes - 1)

	if _silhouette == null:
		return

	_silhouette.texture = texture
	_silhouette.hframes = _sprite.hframes
	_silhouette.vframes = _sprite.vframes
	_silhouette.frame = _sprite.frame
	_apply_silhouette_color(data.silhouette_color)


func _apply_world_scale_from_data(data: CreatureData) -> void:
	if data.is_boss:
		scale = Vector2.ONE
		return

	var target_scale: Vector2 = data.non_boss_world_scale
	if target_scale.x <= 0.0 or target_scale.y <= 0.0:
		push_warning(
			"Creature '%s': invalid non_boss_world_scale %s, using %s."
			% [name, str(target_scale), str(DEFAULT_NON_BOSS_WORLD_SCALE)]
		)
		target_scale = DEFAULT_NON_BOSS_WORLD_SCALE
	scale = target_scale


func _apply_silhouette_color(color: Color) -> void:
	if _silhouette == null:
		return
	if _silhouette.material is ShaderMaterial:
		var shader_material: ShaderMaterial = _silhouette.material as ShaderMaterial
		shader_material.set_shader_parameter("silhouette_color", color)
	else:
		_silhouette.modulate = color


func _emit_creature_spawned_event() -> void:
	CreatureEvents.creature_spawned.emit(self)


func _emit_creature_died_event() -> void:
	CreatureEvents.creature_died.emit(self, creature_data)
