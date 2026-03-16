class_name CombatantSnapshot
extends Resource

## Immutable snapshot of a combatant taken at combat start.
## Live HP and energy are tracked in CombatContext — never mutate this.

var combatant_id: StringName = &""
var display_name: String = ""
var portrait: Texture2D = null
var level: int = 1
var base_stats: CombatStats = null
## Resolved skill loadout: base skills + gear-granted skills combined.
var skill_loadout: Array[SkillData] = []

## Sprite animation data for combat UI.
var sprite_hframes: int = 1
var sprite_vframes: int = 1
var sprite_frame_width: int = 32
var sprite_frame_height: int = 32
var sprite_idle_fps: float = 1.5
var sprite_default_frame: int = 0

## VFX played over the defender when this combatant auto-attacks (skill_used == null).
var default_attack_vfx_texture: Texture2D = null
var default_attack_vfx_hframes: int = 1
var default_attack_vfx_fps: float = 12.0
var default_attack_vfx_impact_frame: int = 0
var default_attack_vfx_scale: float = 1.0


## Build a snapshot from a CreatureData resource.
static func from_creature(creature_data: CreatureData) -> CombatantSnapshot:
	var snap := CombatantSnapshot.new()
	snap.combatant_id = StringName(creature_data.get_effective_creature_id())
	snap.display_name = creature_data.display_name
	snap.portrait = creature_data.sprite_sheet
	snap.level = 1

	var stats := CombatStats.new()
	stats.max_hp = int(creature_data.max_health)
	stats.max_energy = 100
	stats.attack = creature_data.damage
	stats.defense = creature_data.armor
	snap.base_stats = stats

	if creature_data.has_method("get_skill_loadout"):
		snap.skill_loadout = creature_data.call("get_skill_loadout") as Array[SkillData]

	snap.sprite_hframes = creature_data.hframes
	snap.sprite_vframes = creature_data.vframes
	snap.sprite_frame_width = creature_data.frame_width_pixels
	snap.sprite_frame_height = creature_data.frame_height_pixels
	snap.sprite_idle_fps = creature_data.idle_animation_fps
	snap.sprite_default_frame = creature_data.default_frame

	return snap
