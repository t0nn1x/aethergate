class_name WeightedRandomStrategy
extends CombatAiStrategy

## Default AI: picks a random affordable skill, falls back to auto-attack.
## The player_phase_result parameter is accepted but not yet used for reactive decisions.

func choose_action(
	self_snapshot: CombatantSnapshot,
	_opponent_snapshot: CombatantSnapshot,
	_self_current_hp: int,
	self_current_energy: int,
	_player_phase_result: CombatPhaseResult = null
) -> CombatAction:
	var affordable: Array[SkillData] = []
	for skill in self_snapshot.skill_loadout:
		if skill.energy_cost <= self_current_energy:
			affordable.append(skill)

	if affordable.is_empty():
		return CombatAction.make(self_snapshot.combatant_id, null)

	var chosen: SkillData = affordable[randi() % affordable.size()]
	return CombatAction.make(self_snapshot.combatant_id, chosen)
