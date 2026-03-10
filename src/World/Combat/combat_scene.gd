class_name CombatScene
extends Node

## Entry point for the combat game state.
## Reads pending snapshots from CombatEvents (set by overworld before scene change).

@onready var _flow_controller: CombatFlowController = $CombatFlowController
@onready var _combat_ui: Node = $CombatUi

var _context: CombatContext = null


func _ready() -> void:
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
	_flow_controller.start_combat(_context, strategy)
	if _combat_ui and _combat_ui.has_method("initialize"):
		_combat_ui.call("initialize", _context)


func _on_combat_ended(_result: CombatRoundResult) -> void:
	## Small delay so the UI can show the result before leaving.
	await get_tree().create_timer(1.5).timeout
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	get_tree().change_scene_to_file("res://src/World/main.tscn")
