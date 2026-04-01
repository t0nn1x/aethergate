class_name CombatPhaseResult
extends Resource

## Immutable result of a single combat phase (one combatant's action).
## Created by CombatRoundResolver.resolve_phase() — never mutated after creation.

## Who attacked and who defended.
var attacker_id: StringName = &""
var defender_id: StringName = &""

## The action the attacker took (null skill means auto-attack).
var action: CombatAction = null

## Damage dealt to defender (always ≤ 0). Zero for heal/defend actions.
var defender_hp_delta: int = 0

## Self-heal amount for attacker (always ≥ 0). Zero unless action is HEAL.
var attacker_hp_delta: int = 0

## Defender's HP after this phase (clamped to [0, max_hp]).
var defender_hp_after: int = 0

## True when the defender's HP reached 0 this phase.
var combat_ended: bool = false
