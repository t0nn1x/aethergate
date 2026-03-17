class_name CombatRoundResolver
extends Node

## Pure, stateless phase resolver.
## Input: one CombatAction + attacker/defender snapshots + defender's current HP.
## Output: a CombatPhaseResult resource — no side effects, no state stored here.

## Minimum damage dealt after defense, so combat never stalls.
const MIN_DAMAGE: int = 1


## Resolve a single phase: one combatant acts against another.
## Heal actions restore the attacker's HP (attacker_hp_delta > 0, defender unaffected).
## Defend actions deal 0 damage (defensive benefit tracked externally for future use).
func resolve_phase(
	action: CombatAction,
	attacker_snapshot: CombatantSnapshot,
	defender_snapshot: CombatantSnapshot,
	defender_current_hp: int
) -> CombatPhaseResult:
	var result := CombatPhaseResult.new()
	result.attacker_id = attacker_snapshot.combatant_id
	result.defender_id = defender_snapshot.combatant_id
	result.action = action

	if _is_heal(action):
		result.attacker_hp_delta = _calculate_heal(action, attacker_snapshot)
		result.defender_hp_delta = 0
		result.defender_hp_after = defender_current_hp
	elif _is_defend(action):
		result.attacker_hp_delta = 0
		result.defender_hp_delta = 0
		result.defender_hp_after = defender_current_hp
	else:
		var damage: int = _calculate_damage(action, attacker_snapshot, defender_snapshot)
		result.defender_hp_delta = -damage
		result.attacker_hp_delta = 0
		result.defender_hp_after = clampi(
			defender_current_hp - damage, 0, defender_snapshot.base_stats.max_hp
		)

	if result.defender_hp_after <= 0:
		result.combat_ended = true

	return result


# --- Private helpers ---

func _calculate_damage(
	action: CombatAction,
	attacker: CombatantSnapshot,
	defender: CombatantSnapshot
) -> int:
	if _is_heal(action) or _is_defend(action):
		return 0
	var power: float = attacker.base_stats.attack
	if action.skill_used != null:
		power += action.skill_used.base_power
	return int(maxf(power - defender.base_stats.defense, float(MIN_DAMAGE)))


func _calculate_heal(action: CombatAction, caster: CombatantSnapshot) -> int:
	if action.skill_used == null:
		return 0
	return int(action.skill_used.base_power + caster.base_stats.attack * 0.5)


func _is_defend(action: CombatAction) -> bool:
	return action.skill_used != null \
		and action.skill_used.skill_type == SkillData.SkillType.DEFEND


func _is_heal(action: CombatAction) -> bool:
	return action.skill_used != null \
		and action.skill_used.skill_type == SkillData.SkillType.HEAL
