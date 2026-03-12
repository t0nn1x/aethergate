class_name CombatRoundResult
extends Resource

## Pure data output of CombatRoundResolver.resolve().
## Never mutated after creation. UI and context read from this.

var round_number: int = 0
var player_action: CombatAction = null
var enemy_action: CombatAction = null

## Negative = damage taken, positive = healing received.
var hp_delta_player: int = 0
var hp_delta_enemy: int = 0

## True when either combatant reached 0 HP this round.
var combat_ended: bool = false
## combatant_id of the winner. Empty StringName if combat continues or draw.
var winner_id: StringName = &""
