class_name WindowsCombatUi
extends Control

## Desktop landscape combat UI (1920x1080).
## Battleback background, player sprite (left), enemy sprite (right), HP/skill bars.

const BATTLEBACK_DIR: String = "res://src/Ui/Assets/Battlebacks/combined presets/"
const BATTLEBACK_COUNT: int = 27

@onready var _battleback: TextureRect = $Battleback
@onready var _player_sprite: TextureRect = $PlayerSprite
@onready var _enemy_sprite: TextureRect = $EnemySprite
@onready var _enemy_name: Label = $EnemyPanel/NameLabel
@onready var _enemy_hp_bar: ProgressBar = $EnemyPanel/HpBar
@onready var _player_hp_bar: ProgressBar = $PlayerPanel/HpBar
@onready var _player_energy_bar: ProgressBar = $PlayerPanel/EnergyBar
@onready var _round_log: RichTextLabel = $LogPanel/RoundLog
@onready var _skill_bar: HBoxContainer = $SkillBar
@onready var _timer_label: Label = $TimerLabel

var _context: CombatContext = null
var _flow_controller: CombatFlowController = null

var _player_atlas: AtlasTexture = null
var _enemy_atlas: AtlasTexture = null
var _player_anim_time: float = 0.0
var _enemy_anim_time: float = 0.0


func initialize(context: CombatContext) -> void:
	_context = context
	_set_random_battleback()
	_setup_combatant_sprite(_player_sprite, context.player_snapshot, false)
	_setup_combatant_sprite(_enemy_sprite, context.enemy_snapshot, true)
	_refresh_hp_bars()
	_enemy_name.text = context.enemy_snapshot.display_name
	_build_skill_bar(context.player_snapshot.skill_loadout)

	var flow: CombatFlowController = get_tree().get_first_node_in_group("combat_flow")
	if flow:
		_flow_controller = flow
		flow.round_started.connect(_on_round_started)
		flow.round_result_ready.connect(_on_round_result)
		flow.awaiting_player_action.connect(_on_awaiting_player_action)

	CombatEvents.round_resolved.connect(_on_round_resolved)


func _process(delta: float) -> void:
	if _context == null:
		return
	_player_anim_time = _advance_sprite_animation(
		_player_atlas, _context.player_snapshot, _player_anim_time, delta
	)
	_enemy_anim_time = _advance_sprite_animation(
		_enemy_atlas, _context.enemy_snapshot, _enemy_anim_time, delta
	)


func _set_random_battleback() -> void:
	var index: int = randi() % BATTLEBACK_COUNT
	var path: String = BATTLEBACK_DIR + "Low_battleback%d.png" % index
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		_battleback.texture = tex


func _setup_combatant_sprite(
	tex_rect: TextureRect, snapshot: CombatantSnapshot, _flip: bool
) -> void:
	if snapshot.portrait == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = snapshot.portrait
	var fw: int = snapshot.sprite_frame_width
	var fh: int = snapshot.sprite_frame_height
	var start: int = clampi(snapshot.sprite_default_frame, 0, snapshot.sprite_hframes * snapshot.sprite_vframes - 1)
	var col: int = start % snapshot.sprite_hframes
	var row: int = start / snapshot.sprite_hframes
	atlas.region = Rect2(col * fw, row * fh, fw, fh)
	tex_rect.texture = atlas
	if tex_rect == _player_sprite:
		_player_atlas = atlas
	else:
		_enemy_atlas = atlas


func _advance_sprite_animation(
	atlas: AtlasTexture,
	snapshot: CombatantSnapshot,
	anim_time: float,
	delta: float
) -> float:
	if atlas == null or snapshot == null:
		return anim_time

	var frame_count: int = snapshot.sprite_hframes * snapshot.sprite_vframes
	if frame_count <= 1:
		return anim_time

	var fps: float = maxf(snapshot.sprite_idle_fps, 0.1)
	anim_time += delta * fps
	var cycle_index: int = int(floor(anim_time)) % frame_count
	var start_frame: int = clampi(snapshot.sprite_default_frame, 0, frame_count - 1)
	var current_frame: int = (start_frame + cycle_index) % frame_count

	var fw: int = snapshot.sprite_frame_width
	var fh: int = snapshot.sprite_frame_height
	var col: int = current_frame % snapshot.sprite_hframes
	var row: int = current_frame / snapshot.sprite_hframes
	atlas.region = Rect2(col * fw, row * fh, fw, fh)
	return anim_time


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
