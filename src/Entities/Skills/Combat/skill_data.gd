class_name SkillData
extends Resource

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
