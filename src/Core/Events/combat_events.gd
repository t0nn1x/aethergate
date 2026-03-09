extends Node

## Combat bounded-context events.

## Emitted each time a round resolves. UI and log systems listen here.
signal round_resolved(result: CombatRoundResult)

## Emitted when the combat session is fully over (win, loss, or draw).
signal combat_ended(result: CombatRoundResult)

## Emitted by the overworld once the player confirms they want to fight.
## CombatScene listens here to receive both snapshots and start the session.
signal combat_confirmed(player_snapshot: CombatantSnapshot, enemy_snapshot: CombatantSnapshot)
