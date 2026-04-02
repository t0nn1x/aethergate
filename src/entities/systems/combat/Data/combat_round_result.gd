class_name CombatRoundResult
extends Resource

## Aggregated result of a complete turn (player phase + enemy phase).
## Built by CombatFlowController after both phases resolve.
## Never mutated after creation.

## Which turn this result represents (1-based).
var turn_number: int = 0

## Result of the player's action phase. Always present.
var player_phase: CombatPhaseResult = null

## Result of the enemy's action phase. Null if combat ended during player phase
## (enemy never got to act).
var enemy_phase: CombatPhaseResult = null

## combatant_id of the winner. Empty StringName if combat is still ongoing.
var winner_id: StringName = &""
