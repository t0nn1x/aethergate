class_name WindowsCombatUi
extends Control

## Desktop landscape combat UI (1920x1080).
## Layout: enemy panel (top) / round log (center) / player panel + skills (bottom).

@onready var _enemy_name: Label = $EnemyPanel/NameLabel
@onready var _enemy_hp_bar: ProgressBar = $EnemyPanel/HpBar
@onready var _player_hp_bar: ProgressBar = $PlayerPanel/HpBar
@onready var _player_energy_bar: ProgressBar = $PlayerPanel/EnergyBar
@onready var _round_log: RichTextLabel = $RoundLog
@onready var _skill_bar: HBoxContainer = $PlayerPanel/SkillBar
@onready var _timer_label: Label = $PlayerPanel/TimerLabel

var _context: CombatContext = null
var _flow_controller: CombatFlowController = null


func initialize(context: CombatContext) -> void:
	_context = context
	_refresh_hp_bars()
	_enemy_name.text = context.enemy_snapshot.display_name
	_build_skill_bar(context.player_snapshot.skill_loadout)

	## Wire to flow controller signals.
	var flow: CombatFlowController = get_tree().get_first_node_in_group("combat_flow")
	if flow:
		_flow_controller = flow
		flow.round_started.connect(_on_round_started)
		flow.round_result_ready.connect(_on_round_result)
		flow.awaiting_player_action.connect(_on_awaiting_player_action)

	CombatEvents.round_resolved.connect(_on_round_resolved)


func _on_round_started(round_number: int) -> void:
	_round_log.append_text("\n--- Round %d ---" % round_number)
	_timer_label.text = "20s"


func _on_awaiting_player_action() -> void:
	_set_skill_bar_enabled(true)


func _on_round_result(result: CombatRoundResult) -> void:
	_set_skill_bar_enabled(false)
	_refresh_hp_bars()
	_append_round_log(result)


func _on_round_resolved(_result: CombatRoundResult) -> void:
	pass  # reserved for animations


func _refresh_hp_bars() -> void:
	if _context == null:
		return
	_enemy_hp_bar.max_value = _context.enemy_snapshot.base_stats.max_hp
	_enemy_hp_bar.value = _context.enemy_current_hp
	_player_hp_bar.max_value = _context.player_snapshot.base_stats.max_hp
	_player_hp_bar.value = _context.player_current_hp
	_player_energy_bar.max_value = _context.player_snapshot.base_stats.max_energy
	_player_energy_bar.value = _context.player_current_energy


func _build_skill_bar(skills: Array[SkillData]) -> void:
	for child in _skill_bar.get_children():
		child.queue_free()
	for skill in skills:
		var btn := Button.new()
		btn.text = skill.display_name
		btn.tooltip_text = "%s\nCost: %d energy" % [skill.display_name, skill.energy_cost]
		btn.pressed.connect(func(): _on_skill_pressed(skill))
		_skill_bar.add_child(btn)


func _on_skill_pressed(skill: SkillData) -> void:
	if _flow_controller:
		_flow_controller.submit_player_action(skill)


func _set_skill_bar_enabled(enabled: bool) -> void:
	for child in _skill_bar.get_children():
		if child is Button:
			(child as Button).disabled = not enabled


func _append_round_log(result: CombatRoundResult) -> void:
	if result.hp_delta_enemy < 0:
		_round_log.append_text("\nYou dealt %d damage." % abs(result.hp_delta_enemy))
	elif result.hp_delta_enemy > 0:
		_round_log.append_text("\nYou healed enemy for %d." % result.hp_delta_enemy)
	if result.hp_delta_player < 0:
		_round_log.append_text("\nEnemy dealt %d damage to you." % abs(result.hp_delta_player))
	elif result.hp_delta_player > 0:
		_round_log.append_text("\nYou healed %d HP." % result.hp_delta_player)
	if result.combat_ended:
		if result.winner_id == _context.player_snapshot.combatant_id:
			_round_log.append_text("\n[b]Victory![/b]")
		elif result.winner_id == _context.enemy_snapshot.combatant_id:
			_round_log.append_text("\n[b]Defeated![/b]")
		else:
			_round_log.append_text("\n[b]Draw![/b]")
