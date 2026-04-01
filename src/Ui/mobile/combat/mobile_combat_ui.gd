class_name MobileCombatUi
extends Control

## Mobile portrait combat UI (1080x1920).
## Layout: enemy panel (top 35%) / round log (mid 25%) / player panel + skills (bottom 40%).

@onready var _enemy_name: Label = $EnemyPanel/NameLabel
@onready var _enemy_hp_bar: ProgressBar = $EnemyPanel/HpBar
@onready var _player_hp_bar: ProgressBar = $PlayerPanel/HpBar
@onready var _player_energy_bar: ProgressBar = $PlayerPanel/EnergyBar
@onready var _round_log: RichTextLabel = $RoundLog
@onready var _skill_bar: HBoxContainer = $PlayerPanel/SkillBar
@onready var _timer_label: Label = $PlayerPanel/TimerLabel
var _turn_label: Label = null

var _context: CombatContext = null
var _flow_controller: CombatFlowController = null


func initialize(context: CombatContext) -> void:
	_context = context
	_refresh_hp_bars()
	_enemy_name.text = context.enemy_snapshot.display_name
	_build_skill_bar(context.player_snapshot.skill_loadout)
	_create_turn_label()

	var flow: CombatFlowController = get_tree().get_first_node_in_group("combat_flow")
	if flow:
		_flow_controller = flow
		flow.round_started.connect(_on_round_started)
		flow.awaiting_player_action.connect(_on_awaiting_player_action)

	CombatEvents.player_phase_resolved.connect(_on_player_phase_resolved)
	CombatEvents.enemy_phase_resolved.connect(_on_enemy_phase_resolved)
	CombatEvents.round_completed.connect(_on_round_completed)


func _create_turn_label() -> void:
	_turn_label = Label.new()
	_turn_label.text = "Turn 1"
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var enemy_panel: Control = $EnemyPanel
	if enemy_panel:
		enemy_panel.add_child(_turn_label)


func _on_round_started(turn_number: int) -> void:
	_round_log.append_text("\n--- Turn %d ---" % turn_number)
	_timer_label.text = "20s"


func _on_awaiting_player_action() -> void:
	_set_skill_bar_enabled(true)


func _on_player_phase_resolved(result: CombatPhaseResult) -> void:
	_set_skill_bar_enabled(false)
	_refresh_hp_bars()
	_append_phase_log_player(result)


func _on_enemy_phase_resolved(result: CombatPhaseResult) -> void:
	_refresh_hp_bars()
	_append_phase_log_enemy(result)


func _on_round_completed(turn_number: int, _player_phase: CombatPhaseResult, _enemy_phase: CombatPhaseResult) -> void:
	if _turn_label:
		_turn_label.text = "Turn %d" % (turn_number + 1)


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


func _append_phase_log_player(result: CombatPhaseResult) -> void:
	if result.defender_hp_delta < 0:
		_round_log.append_text("\nYou dealt %d damage." % abs(result.defender_hp_delta))
	if result.attacker_hp_delta > 0:
		_round_log.append_text("\nYou healed %d HP." % result.attacker_hp_delta)
	if result.combat_ended:
		_round_log.append_text("\n[b]Victory![/b]")


func _append_phase_log_enemy(result: CombatPhaseResult) -> void:
	if result.defender_hp_delta < 0:
		_round_log.append_text("\nEnemy dealt %d damage to you." % abs(result.defender_hp_delta))
	if result.attacker_hp_delta > 0:
		_round_log.append_text("\nEnemy healed %d HP." % result.attacker_hp_delta)
	if result.combat_ended:
		_round_log.append_text("\n[b]Defeated![/b]")
