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


func apply_result(result: CombatRoundResult) -> void:
	player_current_hp = clampi(
		player_current_hp + result.hp_delta_player, 0, player_snapshot.base_stats.max_hp
	)
	enemy_current_hp = clampi(
		enemy_current_hp + result.hp_delta_enemy, 0, enemy_snapshot.base_stats.max_hp
	)
	## Deduct energy for skills used (skip for null / auto-attack).
	if result.player_action and result.player_action.skill_used:
		player_current_energy = maxi(
			player_current_energy - result.player_action.skill_used.energy_cost, 0
		)
	if result.enemy_action and result.enemy_action.skill_used:
		enemy_current_energy = maxi(
			enemy_current_energy - result.enemy_action.skill_used.energy_cost, 0
		)
