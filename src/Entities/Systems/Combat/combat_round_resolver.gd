class_name CombatRoundResolver
extends Node

## Pure, stateless round resolver.
## Inputs: two CombatActions + current HP values.
## Output: a CombatRoundResult resource — no side effects, no state stored here.

## Minimum damage dealt after defense, so combat never stalls.
const MIN_DAMAGE: int = 1


func resolve(
	round_number: int,
	player_action: CombatAction,
	enemy_action: CombatAction,
	player_snapshot: CombatantSnapshot,
	enemy_snapshot: CombatantSnapshot,
	player_current_hp: int,
	enemy_current_hp: int
) -> CombatRoundResult:
	var result := CombatRoundResult.new()
	result.round_number = round_number
	result.player_action = player_action
	result.enemy_action = enemy_action

	# Healing overrides damage for the caster.
	if _is_heal(player_action):
		result.hp_delta_player = _calculate_heal(player_action, player_snapshot)
	else:
		result.hp_delta_player = -_calculate_damage(enemy_action, enemy_snapshot, player_snapshot)

	if _is_heal(enemy_action):
		result.hp_delta_enemy = _calculate_heal(enemy_action, enemy_snapshot)
	else:
		result.hp_delta_enemy = -_calculate_damage(player_action, player_snapshot, enemy_snapshot)

	# DEFEND halves incoming damage (applied after base calculation).
	if _is_defend(player_action) and result.hp_delta_player < 0:
		result.hp_delta_player = result.hp_delta_player / 2

	if _is_defend(enemy_action) and result.hp_delta_enemy < 0:
		result.hp_delta_enemy = result.hp_delta_enemy / 2

	# Clamp to valid HP range and check win condition.
	var new_player_hp: int = clampi(
		player_current_hp + result.hp_delta_player, 0, player_snapshot.base_stats.max_hp
	)
	var new_enemy_hp: int = clampi(
		enemy_current_hp + result.hp_delta_enemy, 0, enemy_snapshot.base_stats.max_hp
	)

	if new_player_hp <= 0 or new_enemy_hp <= 0:
		result.combat_ended = true
		if new_enemy_hp <= 0 and new_player_hp > 0:
			result.winner_id = player_snapshot.combatant_id
		elif new_player_hp <= 0 and new_enemy_hp > 0:
			result.winner_id = enemy_snapshot.combatant_id
		# Simultaneous kill → winner_id stays empty (draw).

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
