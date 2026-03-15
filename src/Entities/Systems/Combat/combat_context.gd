class_name CombatContext
extends Resource

## Mutable live state for an ongoing combat session.
## CombatantSnapshots are immutable; only HP/energy/round change here.

var player_snapshot: CombatantSnapshot = null
var enemy_snapshot: CombatantSnapshot = null

var player_current_hp: int = 0
var player_current_energy: int = 0
var enemy_current_hp: int = 0
var enemy_current_energy: int = 0
var current_round: int = 0


static func from_snapshots(
	player: CombatantSnapshot,
	enemy: CombatantSnapshot
) -> CombatContext:
	var ctx := CombatContext.new()
	ctx.player_snapshot = player
	ctx.enemy_snapshot = enemy
	ctx.player_current_hp = player.base_stats.max_hp
	ctx.player_current_energy = player.base_stats.max_energy
	ctx.enemy_current_hp = enemy.base_stats.max_hp
	ctx.enemy_current_energy = enemy.base_stats.max_energy
	ctx.current_round = 0
	return ctx


## Apply a single phase result. Call once after each phase.
## Updates defender HP (damage), attacker HP (self-heal), and attacker energy.
func apply_phase_result(result: CombatPhaseResult) -> void:
	# --- Defender HP (damage) ---
	if result.defender_hp_delta != 0:
		if result.defender_id == player_snapshot.combatant_id:
			player_current_hp = clampi(
				player_current_hp + result.defender_hp_delta, 0, player_snapshot.base_stats.max_hp
			)
		else:
			enemy_current_hp = clampi(
				enemy_current_hp + result.defender_hp_delta, 0, enemy_snapshot.base_stats.max_hp
			)

	# --- Attacker HP (self-heal) ---
	if result.attacker_hp_delta > 0:
		if result.attacker_id == player_snapshot.combatant_id:
			player_current_hp = clampi(
				player_current_hp + result.attacker_hp_delta, 0, player_snapshot.base_stats.max_hp
			)
		else:
			enemy_current_hp = clampi(
				enemy_current_hp + result.attacker_hp_delta, 0, enemy_snapshot.base_stats.max_hp
			)

	# --- Attacker energy ---
	if result.action and result.action.skill_used:
		var cost: int = result.action.skill_used.energy_cost
		if result.attacker_id == player_snapshot.combatant_id:
			player_current_energy = maxi(player_current_energy - cost, 0)
		else:
			enemy_current_energy = maxi(enemy_current_energy - cost, 0)
