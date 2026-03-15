extends Node

## Combat bounded-context events.

## Emitted after the player's phase resolves. UI updates enemy HP bar.
signal player_phase_resolved(result: CombatPhaseResult)

## Emitted after the enemy's phase resolves. UI updates player HP bar.
signal enemy_phase_resolved(result: CombatPhaseResult)

## Emitted after both phases of a turn complete.
signal round_completed(turn_number: int, player_phase: CombatPhaseResult, enemy_phase: CombatPhaseResult)

## Emitted when the combat session is fully over (win or loss).
signal combat_ended(result: CombatRoundResult)

## Pending combat data set by overworld before scene change, consumed by CombatScene on _ready.
var pending_player_snapshot: CombatantSnapshot = null
var pending_enemy_snapshot: CombatantSnapshot = null
