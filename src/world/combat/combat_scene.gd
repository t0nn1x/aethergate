class_name CombatScene
extends CanvasLayer

## Entry point for the combat game state.
## Reads pending snapshots from CombatEvents (set by overworld before scene change).

@onready var _flow_controller: CombatFlowController = $CombatFlowController
@onready var _combat_ui: Node = $CombatUi
@onready var _result_panel: CombatResultPanel = $CombatResultPanel

var _context: CombatContext = null
var _is_victory: bool = false
var _xp_awarded: int = 0
var _leveled_up: bool = false
var _new_level: int = 1


func _ready() -> void:
	_result_panel.continue_pressed.connect(_on_result_panel_continue)
	if not CombatEvents.combat_ended.is_connected(_on_combat_ended):
		CombatEvents.combat_ended.connect(_on_combat_ended)
	if not PlayerProgressionService.level_up.is_connected(_on_level_up):
		PlayerProgressionService.level_up.connect(_on_level_up)
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
	_leveled_up = false
	_new_level = PlayerProfileService.get_player_level()
	if _is_victory:
		_xp_awarded = _context.enemy_snapshot.xp_reward
		PlayerProgressionService.award_xp(_xp_awarded)
		# Award mastery XP for the weapon family used in this combat
		var enemy_level: int = _context.enemy_snapshot.level
		var mastery_xp: int = 10 + enemy_level * 2
		var family_id: StringName = _context.player_snapshot.weapon_family_id
		if family_id != &"":
			MasteryService.award_mastery_xp(family_id, mastery_xp)
	else:
		_xp_awarded = 0
	# Delay result panel so the death animation (float + fade, ~1.2s) plays first.
	get_tree().create_timer(1.4).timeout.connect(
		func() -> void:
			_result_panel.show_result(
				_is_victory,
				_context.enemy_snapshot.display_name,
				_xp_awarded,
				_leveled_up,
				_new_level
			)
	)


func _on_level_up(new_level: int, _stats: CombatStats) -> void:
	_leveled_up = true
	_new_level = new_level


func _on_result_panel_continue() -> void:
	GameManager.change_state(GameManager.GameState.OVERWORLD)
