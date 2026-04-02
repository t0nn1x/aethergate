class_name SkillData
extends Resource

const CombatVfxConfig = preload("res://src/entities/systems/combat/Data/combat_vfx_config.gd")

## Data resource defining a single combat skill.
## Assign .tres instances to creature skill_loadout arrays or player gear slots.

enum Element { NONE, FIRE, WATER, EARTH, ARCANE }
enum SkillType { ATTACK, DEFEND, HEAL, BUFF, DEBUFF }

@export_group("Identity")
@export var skill_id: StringName = &""
@export var display_name: String = "Skill"
@export_multiline var description: String = ""

@export_group("Combat")
@export var skill_type: SkillType = SkillType.ATTACK
@export var element: Element = Element.NONE
@export var energy_cost: int = 10
@export var base_power: float = 15.0

@export_group("Presentation")
## Icon shown on the skill bar button.
@export var icon: Texture2D

@export_group("Mastery")
## Stronger skill variants unlocked at mastery tiers 3, 6, 10.
## Each entry should be a SkillData resource.
@export var mastery_variants: Array[Resource] = []

@export_group("VFX")
## Sprite sheet played over the defender when this skill lands.
## Leave blank to play no VFX.
@export var vfx_texture: Texture2D = null
@export var vfx_hframes: int = 1
@export var vfx_fps: float = 12.0
## Frame index (0-based) at which the HP bar updates.
@export var vfx_impact_frame: int = 0
@export var vfx_scale: float = 1.0
## Who the VFX is centered over. Use ATTACKER for self-buffs.
@export var vfx_target: CombatVfxConfig.VfxTarget = CombatVfxConfig.VfxTarget.DEFENDER
