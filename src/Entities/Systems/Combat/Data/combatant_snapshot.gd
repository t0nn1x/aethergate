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

	return snap
