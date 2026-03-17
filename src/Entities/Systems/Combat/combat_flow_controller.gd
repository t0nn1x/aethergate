class_name CombatFlowController
extends Node

## Phase-based state machine that drives the combat turn loop.
## Player always acts first, then enemy reacts after a brief pause.
## Emits CombatEvents signals. Delegates damage math to CombatRoundResolver.

const ACTION_TIMEOUT_SECONDS: float = 20.0
const ENEMY_PAUSE_MIN: float = 0.8
const ENEMY_PAUSE_MAX: float = 1.2

enum CombatPhase {
	IDLE,
	PLAYER_TURN,
	RESOLVING_PLAYER,
	ENEMY_TURN,
	RESOLVING_ENEMY,
	ROUND_END,
	COMBAT_END
}

signal round_started(turn_number: int)
signal awaiting_player_action()

@onready var _resolver: CombatRoundResolver = $CombatRoundResolver

var _context: CombatContext = null
var _ai_strategy: CombatAiStrategy = null
var _current_phase: CombatPhase = CombatPhase.IDLE
var _turn_number: int = 0
var _player_action: CombatAction = null
var _player_phase_result: CombatPhaseResult = null
var _enemy_phase_result: CombatPhaseResult = null

var _action_timeout_timer: Timer = null
var _enemy_pause_timer: Timer = null


func _ready() -> void:
	_action_timeout_timer = Timer.new()
	_action_timeout_timer.one_shot = true
	_action_timeout_timer.timeout.connect(_on_action_timeout)
	add_child(_action_timeout_timer)

	_enemy_pause_timer = Timer.new()
	_enemy_pause_timer.one_shot = true
	_enemy_pause_timer.timeout.connect(_on_enemy_pause_complete)
	add_child(_enemy_pause_timer)


func start_combat(context: CombatContext, ai_strategy: CombatAiStrategy) -> void:
	_context = context
	_ai_strategy = ai_strategy
	_turn_number = 0
	_enter_player_turn()


## Called by UI when player taps a skill button.
func submit_player_action(skill: SkillData) -> void:
	if _current_phase != CombatPhase.PLAYER_TURN:
		return
	_action_timeout_timer.stop()
	_player_action = CombatAction.make(_context.player_snapshot.combatant_id, skill)
	_enter_resolving_player()


# ── Phase transitions ────────────────────────────────────────────────────────

func _enter_player_turn() -> void:
	_turn_number += 1
	_current_phase = CombatPhase.PLAYER_TURN
	_player_action = null
	_player_phase_result = null
	_enemy_phase_result = null
	round_started.emit(_turn_number)
	awaiting_player_action.emit()
	_action_timeout_timer.start(ACTION_TIMEOUT_SECONDS)


func _enter_resolving_player() -> void:
	_current_phase = CombatPhase.RESOLVING_PLAYER

	_player_phase_result = _resolver.resolve_phase(
		_player_action,
		_context.player_snapshot,
		_context.enemy_snapshot,
		_context.enemy_current_hp
	)
	_context.apply_phase_result(_player_phase_result)
	CombatEvents.player_phase_resolved.emit(_player_phase_result)

	if _player_phase_result.combat_ended:
		_enter_combat_end(_context.player_snapshot.combatant_id)
	else:
		_enter_enemy_turn()


func _enter_enemy_turn() -> void:
	_current_phase = CombatPhase.ENEMY_TURN
	var delay: float = randf_range(ENEMY_PAUSE_MIN, ENEMY_PAUSE_MAX)
	_enemy_pause_timer.start(delay)


func _on_enemy_pause_complete() -> void:
	if _current_phase != CombatPhase.ENEMY_TURN:
		return

	var enemy_action: CombatAction = _ai_strategy.choose_action(
		_context.enemy_snapshot,
		_context.player_snapshot,
		_context.enemy_current_hp,
		_context.enemy_current_energy,
		_player_phase_result
	)
	_enter_resolving_enemy(enemy_action)


func _enter_resolving_enemy(enemy_action: CombatAction) -> void:
	_current_phase = CombatPhase.RESOLVING_ENEMY

	_enemy_phase_result = _resolver.resolve_phase(
		enemy_action,
		_context.enemy_snapshot,
		_context.player_snapshot,
		_context.player_current_hp
	)
	_context.apply_phase_result(_enemy_phase_result)
	CombatEvents.enemy_phase_resolved.emit(_enemy_phase_result)

	if _enemy_phase_result.combat_ended:
		_enter_combat_end(_context.enemy_snapshot.combatant_id)
	else:
		_enter_round_end()


func _enter_round_end() -> void:
	_current_phase = CombatPhase.ROUND_END
	CombatEvents.round_completed.emit(_turn_number, _player_phase_result, _enemy_phase_result)
	_enter_player_turn()


func _enter_combat_end(winner_id: StringName) -> void:
	_current_phase = CombatPhase.COMBAT_END
	_action_timeout_timer.stop()
	_enemy_pause_timer.stop()

	var round_result := CombatRoundResult.new()
	round_result.turn_number = _turn_number
	round_result.player_phase = _player_phase_result
	round_result.enemy_phase = _enemy_phase_result  # null if enemy died in player phase
	round_result.winner_id = winner_id
	CombatEvents.combat_ended.emit(round_result)


# ── Timer callback ───────────────────────────────────────────────────────────

func _on_action_timeout() -> void:
	if _current_phase == CombatPhase.PLAYER_TURN:
		submit_player_action(null)
