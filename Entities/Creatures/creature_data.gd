class_name CreatureData
extends Resource

## Data resource defining a creature's type, stats, sprite, and behavior.
## Create .tres instances for each creature variant (wolf, skeleton, etc.)

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

## How the creature behaves toward the player by default.
enum BehaviorProfile {
	PASSIVE,   ## Flees when attacked, never initiates combat
	NEUTRAL,   ## Ignores player unless provoked
	AGGRESSIVE ## Attacks player on sight within aggro range
}

@export_group("Identity")
@export var display_name: String = "Creature"
@export var creature_type: CreatureType = CreatureType.ANIMAL
@export var behavior_profile: BehaviorProfile = BehaviorProfile.NEUTRAL

@export_group("Stats")
@export var max_health: float = 50.0
@export var movement_speed: float = 100.0
@export var damage: float = 10.0
@export var armor: float = 0.0
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 1.0

@export_group("Detection")
@export var aggro_range: float = 96.0
@export var deaggro_range: float = 144.0
@export var wander_radius: float = 64.0

@export_group("Sprite")
@export var sprite_sheet: Texture2D
@export var hframes: int = 1
@export var vframes: int = 1
@export var default_frame: int = 0

@export_group("Silhouette")
@export var silhouette_color: Color = Color(1.0, 1.0, 1.0, 0.4)

@export_group("Loot")
@export var experience_reward: float = 10.0
## Loot table reference — will be typed when loot system is built.
@export var loot_table: Resource = null
