class_name CombatFlowController
extends Node

## Owns the round loop, action timer, and AI submission.
## Emits CombatEvents signals. Delegates damage math to CombatRoundResolver.

const ACTION_TIMEOUT_SECONDS: float = 20.0

signal round_started(round_number: int)
signal awaiting_player_action()
signal round_result_ready(result: CombatRoundResult)

@onready var _resolver: CombatRoundResolver = $CombatRoundResolver

var _context: CombatContext = null
var _ai_strategy: CombatAiStrategy = null
var _player_action: CombatAction = null
var _timer: float = 0.0
var _waiting_for_player: bool = false


func start_combat(context: CombatContext, ai_strategy: CombatAiStrategy) -> void:
	_context = context
	_ai_strategy = ai_strategy
	_start_next_round()


## Called by UI when player taps a skill button.
func submit_player_action(skill: SkillData) -> void:
	if not _waiting_for_player:
		return
	_player_action = CombatAction.make(_context.player_snapshot.combatant_id, skill)
	_waiting_for_player = false
	_resolve_round()


func _process(delta: float) -> void:
	if not _waiting_for_player:
		return
	_timer -= delta
	if _timer <= 0.0:
		# Timeout: auto-attack with no skill.
		submit_player_action(null)


func _start_next_round() -> void:
	_context.current_round += 1
	_player_action = null
	_timer = ACTION_TIMEOUT_SECONDS
	_waiting_for_player = true
	round_started.emit(_context.current_round)
	awaiting_player_action.emit()


func _resolve_round() -> void:
	_waiting_for_player = false
	var enemy_action: CombatAction = _ai_strategy.choose_action(
		_context.enemy_snapshot,
		_context.player_snapshot,
		_context.enemy_current_hp,
		_context.enemy_current_energy
	)

	var result: CombatRoundResult = _resolver.resolve(
		_context.current_round,
		_player_action,
		enemy_action,
		_context.player_snapshot,
		_context.enemy_snapshot,
		_context.player_current_hp,
		_context.enemy_current_hp
	)

	_context.apply_result(result)
	CombatEvents.round_resolved.emit(result)
	round_result_ready.emit(result)

	if result.combat_ended:
		CombatEvents.combat_ended.emit(result)
	else:
		_start_next_round()
