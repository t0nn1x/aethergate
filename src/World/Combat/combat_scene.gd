class_name CombatScene
extends Node

## Entry point for the combat game state.
## Reads pending snapshots from CombatEvents (set by overworld before scene change).

@onready var _flow_controller: CombatFlowController = $CombatFlowController
@onready var _combat_ui: Node = $CombatUi
@onready var _result_panel: CombatResultPanel = $CombatResultPanel

var _context: CombatContext = null
var _is_victory: bool = false


func _ready() -> void:
	_result_panel.continue_pressed.connect(_on_result_panel_continue)
	if not CombatEvents.combat_ended.is_connected(_on_combat_ended):
		CombatEvents.combat_ended.connect(_on_combat_ended)
	if CombatEvents.pending_player_snapshot and CombatEvents.pending_enemy_snapshot:
		_start_combat(CombatEvents.pending_player_snapshot, CombatEvents.pending_enemy_snapshot)
		CombatEvents.pending_player_snapshot = null
		CombatEvents.pending_enemy_snapshot = null


func _start_combat(
	player_snapshot: CombatantSnapshot,
	enemy_snapshot: CombatantSnapshot
) -> void:
	_context = CombatContext.from_snapshots(player_snapshot, enemy_snapshot)
	var strategy: CombatAiStrategy = WeightedRandomStrategy.new()
	if _combat_ui and _combat_ui.has_method("initialize"):
		_combat_ui.call("initialize", _context)
	_flow_controller.start_combat(_context, strategy)


func _on_combat_ended(result: CombatRoundResult) -> void:
	_is_victory = result.winner_id == _context.player_snapshot.combatant_id
	_result_panel.show_result(_is_victory, _context.enemy_snapshot.display_name, 50)


func _on_result_panel_continue() -> void:
	CombatEvents.returning_from_combat = true
	CombatEvents.player_won_last_combat = _is_victory
	CombatEvents.defeated_enemy_creature_id = _context.enemy_snapshot.combatant_id if _is_victory else &""
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	get_tree().change_scene_to_file("res://src/World/main.tscn")
