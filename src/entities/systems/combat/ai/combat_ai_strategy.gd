class_name CombatAiStrategy
extends Resource

## Base class for creature AI strategies.
## Override choose_action() in subclasses.

func choose_action(
	_self_snapshot: CombatantSnapshot,
	_opponent_snapshot: CombatantSnapshot,
	_self_current_hp: int,
	_self_current_energy: int,
	_player_phase_result: CombatPhaseResult = null
) -> CombatAction:
	push_error("CombatAiStrategy.choose_action() must be overridden.")
	return CombatAction.make(_self_snapshot.combatant_id, null)
