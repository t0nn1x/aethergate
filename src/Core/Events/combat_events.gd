extends Node

## Combat bounded-context events.

## Emitted each time a round resolves. UI and log systems listen here.
signal round_resolved(result: CombatRoundResult)

## Emitted when the combat session is fully over (win, loss, or draw).
signal combat_ended(result: CombatRoundResult)

## Pending combat data set by overworld before scene change, consumed by CombatScene on _ready.
var pending_player_snapshot: CombatantSnapshot = null
var pending_enemy_snapshot: CombatantSnapshot = null
