class_name CreatureData
extends Resource

const SkillData = preload("res://src/entities/skills/combat/skill_data.gd")

## Data resource defining a creature's type, stats, sprite, and behavior.
## Create .tres instances for each creature variant (wolf, skeleton, etc.)

## Pixel size of one frame in the overworld 16×16 sprite sheet.
const OVERWORLD_FRAME_SIZE: int = 16

## The creature type categories matching the tileset.
enum CreatureType {
	HUMANOID,
	ANIMAL,
	HOLY,
	MONSTER,
	DRAGON,
	VERMIN,
	MAGICAL,
	UNDEAD,
	DEMON,
}

## Legacy temperament profile kept for data compatibility.
## Autonomous combat behavior is currently disabled; this is reserved for turn-based systems.
enum BehaviorProfile {
	PASSIVE,   ## Reserved tag for future encounter logic
	NEUTRAL,   ## Reserved tag for future encounter logic
	AGGRESSIVE ## Reserved tag for future encounter logic
}

@export_group("Identity")
## Stable identifier used by catalogs/spawners.
@export var creature_id: String = ""
@export var display_name: String = "Creature"
@export var creature_type: CreatureType = CreatureType.ANIMAL
## Reserved for turn-based encounter behavior selection.
@export var behavior_profile: BehaviorProfile = BehaviorProfile.NEUTRAL
## Boss creatures keep full world scale (Vector2.ONE).
@export var is_boss: bool = false
## Top-level folder under catalog (humanoids, animals, ...).
@export var source_category: String = ""
## Source sprite expected to point to a *_128x32.png asset.
@export_file("*.png") var source_sprite_path: String = ""

@export_group("Presentation")
## Non-boss creatures default to player-like scale.
@export var non_boss_world_scale: Vector2 = Vector2(1.0, 1.0)

@export_group("Stats")
@export var max_health: float = 50.0
@export var movement_speed: float = 70.0
@export var damage: float = 10.0
@export var armor: float = 0.0
## Reserved for turn-based combat range tuning.
@export var attack_range: float = 24.0
## Reserved for turn-based cooldown/action cadence tuning.
@export var attack_cooldown: float = 1.0

@export_group("Ambient Wander")
## Lightweight ambient movement around spawn point.
@export var enable_ambient_wander: bool = true
@export var wander_radius: float = 32.0
@export_range(0.0, 10.0, 0.05) var wander_interval_seconds: float = 7.0

@export_group("Sprite")
@export var sprite_sheet: Texture2D
## 16×16 sprite sheet used on the overworld (native pixels, no downscaling).
## Populated automatically by the catalog builder from the Name.png asset.
@export var overworld_sprite_sheet: Texture2D
## 128x32 sheets default to 4 horizontal frames (4x 32x32).
@export var hframes: int = 4
@export var vframes: int = 1
@export var default_frame: int = 0
@export var frame_width_pixels: int = 32
@export var frame_height_pixels: int = 32
@export_range(0.1, 60.0, 0.1) var idle_animation_fps: float = 1.5

@export_group("Autonomous Combat AI Legacy (Dormant)")
## Legacy combat AI tuning fields kept for compatibility with existing .tres data.
@export var aggro_range: float = 72.0
@export var deaggro_range: float = 96.0
@export_range(0.0, 5.0, 0.05) var chase_repath_interval_seconds: float = 0.45
@export_range(0.0, 10.0, 0.05) var aggression_grace_seconds: float = 1.0
@export var can_flee_when_low_health: bool = false
@export_range(0.0, 1.0, 0.01) var flee_health_threshold: float = 0.2

@export_group("Silhouette")
@export var silhouette_color: Color = Color(1.0, 1.0, 1.0, 0.4)

@export_group("Loot")
@export var xp_reward: int = 50
## Loot table reference — will be typed when loot system is built.
@export var loot_table: Resource = null

@export_group("Turn-Based Combat")
## Skills available in turn-based combat. Populated via .tres in the editor.
@export var skill_loadout: Array[SkillData] = []
## AI strategy (CombatAiStrategy subclass) used in turn-based encounters.
## Typed as Resource to avoid a forward-reference parse error before uid files exist.
@export var ai_strategy: Resource = null


func get_effective_creature_id() -> String:
	var normalized_id: String = creature_id.strip_edges().to_lower()
	if not normalized_id.is_empty():
		return normalized_id
	return _sanitize_id("%s_%s" % [CreatureType.keys()[creature_type], display_name])


func get_skill_loadout() -> Array[SkillData]:
	return skill_loadout


func get_ai_strategy() -> Resource:
	if ai_strategy:
		return ai_strategy
	return load("res://src/entities/systems/combat/ai/weighted_random_strategy.gd").new()


func validate_for_runtime(log_context: String = "") -> bool:
	var context: String = log_context
	if context.is_empty():
		context = display_name

	var is_valid: bool = true
	if creature_id.strip_edges().is_empty():
		push_warning("CreatureData[%s]: creature_id is empty." % context)
		is_valid = false
	if source_sprite_path.strip_edges().is_empty():
		push_warning("CreatureData[%s]: source_sprite_path is empty." % context)
		is_valid = false
	if hframes <= 0:
		push_warning("CreatureData[%s]: hframes must be > 0." % context)
		is_valid = false
	if vframes <= 0:
		push_warning("CreatureData[%s]: vframes must be > 0." % context)
		is_valid = false
	if default_frame < 0 or default_frame >= hframes * vframes:
		push_warning("CreatureData[%s]: default_frame is out of range." % context)
		is_valid = false
	if frame_width_pixels <= 0 or frame_height_pixels <= 0:
		push_warning("CreatureData[%s]: frame pixel size must be > 0." % context)
		is_valid = false
	if idle_animation_fps <= 0.0:
		push_warning("CreatureData[%s]: idle_animation_fps must be > 0." % context)
		is_valid = false
	if enable_ambient_wander and wander_radius < 0.0:
		push_warning("CreatureData[%s]: wander_radius must be >= 0." % context)
		is_valid = false
	if enable_ambient_wander and wander_interval_seconds <= 0.0:
		push_warning("CreatureData[%s]: wander_interval_seconds must be > 0." % context)
		is_valid = false
	if non_boss_world_scale.x <= 0.0 or non_boss_world_scale.y <= 0.0:
		push_warning("CreatureData[%s]: non_boss_world_scale must be > 0 on both axes." % context)
		is_valid = false

	# overworld_sprite_sheet is intentionally not validated: null is valid and triggers fallback
	# to sprite_sheet at runtime in creature.gd.
	return is_valid


func _sanitize_id(value: String) -> String:
	var id: String = value.strip_edges().to_lower()
	var regex := RegEx.new()
	var compile_error: Error = regex.compile("[^a-z0-9]+")
	if compile_error != OK:
		push_error("CreatureData: failed to compile id sanitization regex.")
		return id
	id = regex.sub(id, "_", true)
	id = id.trim_prefix("_").trim_suffix("_")
	return id
