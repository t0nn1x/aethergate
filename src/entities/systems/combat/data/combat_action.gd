class_name CombatAction
extends Resource

## Represents one combatant's chosen action for a single round.
## Created fresh each round; never mutated after creation.

## Identifies which combatant took this action.
var actor_id: StringName = &""
## The skill chosen. Null means auto-attack (no energy cost, base attack power only).
var skill_used: SkillData = null


static func make(actor: StringName, skill: SkillData = null) -> CombatAction:
	var action := CombatAction.new()
	action.actor_id = actor
	action.skill_used = skill
	return action
