class_name WindowsCombatUi
extends Control

## Desktop landscape combat UI (1920×1080).
## Battleback background, animated combatant sprites, Godot-native styled
## progress bars (StyleBoxFlat), and gold-themed skill buttons.

const BATTLEBACK_DIR: String = "res://src/Ui/Assets/Battlebacks/combined presets/"
const BATTLEBACK_COUNT: int = 27

@onready var _battleback: TextureRect = $Battleback
@onready var _player_sprite: TextureRect = $PlayerSprite
@onready var _enemy_sprite: TextureRect = $EnemySprite
@onready var _enemy_name: Label = $EnemyNameLabel
@onready var _player_hp_frame: TextureRect = $PlayerHpFrame
@onready var _player_energy_frame: TextureRect = $PlayerEnergyFrame
@onready var _enemy_hp_frame: TextureRect = $EnemyHpFrame
@onready var _enemy_hp_bar: ProgressBar = $EnemyHpBar
@onready var _player_hp_bar: ProgressBar = $PlayerHpBar
@onready var _player_energy_bar: ProgressBar = $PlayerEnergyBar
@onready var _round_log: RichTextLabel = $LogPanel/RoundLog
@onready var _skill_bar: HBoxContainer = $SkillsPanel/CenterContainer/SkillBar
@onready var _timer_label: Label = $TimerLabel
@onready var _turn_label: Label = $TurnLabel

var _context: CombatContext = null
var _flow_controller: CombatFlowController = null

var _player_atlas: AtlasTexture = null
var _enemy_atlas: AtlasTexture = null
var _player_anim_time: float = 0.0
var _enemy_anim_time: float = 0.0

var _timer_seconds: float = 0.0
var _timer_running: bool = false

var _player_vfx: CombatVfxPlayer = null
var _enemy_vfx: CombatVfxPlayer = null
var _pending_player_phase: CombatPhaseResult = null
var _pending_enemy_phase: CombatPhaseResult = null


func _ready() -> void:
	var charge := load("res://src/Ui/Assets/Gui-Hud/Charge Bars/Charge Bars A_05.png") as Texture2D
	_player_hp_frame.texture = charge
	_player_energy_frame.texture = charge
	_enemy_hp_frame.texture = charge
	_style_bar(_player_hp_bar, Color(0.78, 0.14, 0.14))
	_style_bar(_enemy_hp_bar, Color(0.78, 0.14, 0.14))
	_style_bar(_player_energy_bar, Color(0.18, 0.42, 0.82))

	_enemy_vfx = CombatVfxPlayer.new()
	_enemy_sprite.add_child(_enemy_vfx)
	_enemy_vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enemy_vfx.impact_hit.connect(_on_enemy_vfx_impact_hit)

	_player_vfx = CombatVfxPlayer.new()
	_player_sprite.add_child(_player_vfx)
	_player_vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player_vfx.impact_hit.connect(_on_player_vfx_impact_hit)


func _style_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_content_margin_all(0.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	fill.set_content_margin_all(0.0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


func initialize(context: CombatContext) -> void:
	_context = context
	_set_random_battleback()
	_setup_combatant_sprite(_player_sprite, context.player_snapshot)
	_setup_combatant_sprite(_enemy_sprite, context.enemy_snapshot)
	_enemy_name.text = context.enemy_snapshot.display_name
	_build_skill_bar(context.player_snapshot.skill_loadout)
	_refresh_bars()
	_turn_label.text = "Turn 1"

	var flow: CombatFlowController = get_tree().get_first_node_in_group("combat_flow")
	if flow:
		_flow_controller = flow
		flow.round_started.connect(_on_round_started)
		flow.awaiting_player_action.connect(_on_awaiting_player_action)

	CombatEvents.player_phase_resolved.connect(_on_player_phase_resolved)
	CombatEvents.enemy_phase_resolved.connect(_on_enemy_phase_resolved)
	CombatEvents.round_completed.connect(_on_round_completed)


func _process(delta: float) -> void:
	if _context == null:
		return
	_player_anim_time = _advance_sprite_animation(
		_player_atlas, _context.player_snapshot, _player_anim_time, delta
	)
	_enemy_anim_time = _advance_sprite_animation(
		_enemy_atlas, _context.enemy_snapshot, _enemy_anim_time, delta
	)
	if _timer_running:
		_timer_seconds = maxf(0.0, _timer_seconds - delta)
		_timer_label.text = str(ceili(_timer_seconds))
		if _timer_seconds <= 0.0:
			_timer_running = false


## ── Battleback ───────────────────────────────────────────────────────────────

func _set_random_battleback() -> void:
	var index: int = randi() % BATTLEBACK_COUNT
	var path: String = BATTLEBACK_DIR + "Low_battleback%d.png" % index
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		_battleback.texture = tex


## ── Sprite setup + animation ─────────────────────────────────────────────────

func _setup_combatant_sprite(tex_rect: TextureRect, snapshot: CombatantSnapshot) -> void:
	if tex_rect == null or snapshot == null or snapshot.portrait == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = snapshot.portrait
	var fw: int = snapshot.sprite_frame_width
	var fh: int = snapshot.sprite_frame_height
	var start: int = clampi(snapshot.sprite_default_frame, 0, snapshot.sprite_hframes * snapshot.sprite_vframes - 1)
	atlas.region = Rect2((start % snapshot.sprite_hframes) * fw, (start / snapshot.sprite_hframes) * fh, fw, fh)
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
	atlas.region = Rect2(current_frame % snapshot.sprite_hframes * fw,
		current_frame / snapshot.sprite_hframes * fh, fw, fh)
	return anim_time


## ── Bar refresh ──────────────────────────────────────────────────────────────

func _refresh_bars() -> void:
	if _context == null:
		return
	_set_bar(_enemy_hp_bar, _context.enemy_current_hp, _context.enemy_snapshot.base_stats.max_hp)
	_set_bar(_player_hp_bar, _context.player_current_hp, _context.player_snapshot.base_stats.max_hp)
	_set_bar(_player_energy_bar, _context.player_current_energy, _context.player_snapshot.base_stats.max_energy)


func _set_bar(bar: ProgressBar, current: float, maximum: float) -> void:
	if bar == null or maximum <= 0.0:
		return
	bar.max_value = maximum
	bar.value = current


## ── Skill bar ────────────────────────────────────────────────────────────────

func _build_skill_bar(skills: Array[SkillData]) -> void:
	for child in _skill_bar.get_children():
		child.free()
	var compass_font := load("res://Assets/Fonts/compass/Compass 9.ttf") as FontFile

	var attack_btn := Button.new()
	attack_btn.text = "Attack"
	attack_btn.tooltip_text = "Basic attack — free, always available"
	attack_btn.custom_minimum_size = Vector2(140, 52)
	_style_skill_button(attack_btn, compass_font)
	attack_btn.pressed.connect(func(): _flow_controller.submit_player_action(null))
	_skill_bar.add_child(attack_btn)

	for skill in skills:
		var btn := Button.new()
		btn.text = skill.display_name
		btn.tooltip_text = "%s\nCost: %d energy" % [skill.display_name, skill.energy_cost]
		btn.custom_minimum_size = Vector2(140, 52)
		_style_skill_button(btn, compass_font)
		btn.pressed.connect(func(): _on_skill_pressed(skill))
		_skill_bar.add_child(btn)


func _style_skill_button(btn: Button, compass_font: FontFile) -> void:
	if compass_font:
		btn.add_theme_font_override("font", compass_font)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.18, 0.88)
	normal.set_corner_radius_all(7)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.62, 0.48, 0.14, 0.72)
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.14, 0.18, 0.32, 0.95)
	hover.border_color = Color(0.92, 0.78, 0.28, 1.0)
	hover.shadow_size = 6
	hover.shadow_color = Color(0.75, 0.55, 0.1, 0.35)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.05, 0.07, 0.13, 0.95)
	pressed.border_color = Color(0.62, 0.48, 0.14, 0.5)

	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.06, 0.07, 0.11, 0.55)
	disabled_style.border_color = Color(0.32, 0.28, 0.13, 0.4)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_color_override("font_color", Color(0.92, 0.82, 0.5, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.65, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.62, 0.35, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.42, 0.4, 0.28, 0.5))
	btn.add_theme_font_size_override("font_size", 18)


func _on_skill_pressed(skill: SkillData) -> void:
	if _flow_controller:
		_flow_controller.submit_player_action(skill)


func _set_skill_bar_enabled(enabled: bool) -> void:
	for child in _skill_bar.get_children():
		if child is Button:
			(child as Button).disabled = not enabled


## ── Flow controller signals ──────────────────────────────────────────────────

func _on_round_started(turn_number: int) -> void:
	_round_log.append_text("\n[color=#c8a84b]── Turn %d ──[/color]" % turn_number)


func _on_awaiting_player_action() -> void:
	_set_skill_bar_enabled(true)
	_timer_seconds = 20.0
	_timer_running = true
	_timer_label.text = "20"


func _on_player_phase_resolved(result: CombatPhaseResult) -> void:
	_timer_running = false
	_set_skill_bar_enabled(false)
	_pending_player_phase = result
	_enemy_vfx.play(_build_vfx_config(result, _context.player_snapshot))


func _on_enemy_vfx_impact_hit() -> void:
	if _pending_player_phase == null:
		return
	_refresh_bars()
	_append_phase_log_player(_pending_player_phase)
	_pending_player_phase = null


func _on_enemy_phase_resolved(result: CombatPhaseResult) -> void:
	_pending_enemy_phase = result
	_player_vfx.play(_build_vfx_config(result, _context.enemy_snapshot))


func _on_player_vfx_impact_hit() -> void:
	if _pending_enemy_phase == null:
		return
	_refresh_bars()
	_append_phase_log_enemy(_pending_enemy_phase)
	_pending_enemy_phase = null


func _on_round_completed(turn_number: int, _player_phase: CombatPhaseResult, _enemy_phase: CombatPhaseResult) -> void:
	_turn_label.text = "Turn %d" % (turn_number + 1)


## ── VFX ──────────────────────────────────────────────────────────────────────

func _build_vfx_config(result: CombatPhaseResult, attacker_snapshot: CombatantSnapshot) -> CombatVfxConfig:
	var cfg := CombatVfxConfig.new()
	var skill: SkillData = result.action.skill_used if result.action else null
	if skill != null and skill.vfx_texture != null:
		cfg.texture = skill.vfx_texture
		cfg.hframes = skill.vfx_hframes
		cfg.fps = skill.vfx_fps
		cfg.impact_frame = skill.vfx_impact_frame
		cfg.scale = skill.vfx_scale
	else:
		cfg.texture = attacker_snapshot.default_attack_vfx_texture
		cfg.hframes = attacker_snapshot.default_attack_vfx_hframes
		cfg.fps = attacker_snapshot.default_attack_vfx_fps
		cfg.impact_frame = attacker_snapshot.default_attack_vfx_impact_frame
		cfg.scale = attacker_snapshot.default_attack_vfx_scale
	return cfg


## ── Round log ────────────────────────────────────────────────────────────────

func _append_phase_log_player(result: CombatPhaseResult) -> void:
	if result.defender_hp_delta < 0:
		_round_log.append_text(
			"\n[color=#4ecfff]You dealt [b]%d[/b] damage.[/color]" % abs(result.defender_hp_delta)
		)
	if result.attacker_hp_delta > 0:
		_round_log.append_text(
			"\n[color=#55ff88]You healed [b]%d[/b] HP.[/color]" % result.attacker_hp_delta
		)
	if result.action and result.action.skill_used \
			and result.action.skill_used.skill_type == SkillData.SkillType.DEFEND:
		_round_log.append_text("\n[color=#aaaaee]You are defending.[/color]")
	if result.combat_ended:
		_round_log.append_text("\n\n[b][color=#ffd700]✦ Victory! ✦[/color][/b]")


func _append_phase_log_enemy(result: CombatPhaseResult) -> void:
	if result.defender_hp_delta < 0:
		_round_log.append_text(
			"\n[color=#ff6060]Enemy dealt [b]%d[/b] damage to you.[/color]" % abs(result.defender_hp_delta)
		)
	if result.attacker_hp_delta > 0:
		_round_log.append_text("\nEnemy healed %d HP." % result.attacker_hp_delta)
	if result.action and result.action.skill_used \
			and result.action.skill_used.skill_type == SkillData.SkillType.DEFEND:
		_round_log.append_text("\nEnemy is defending.")
	if result.combat_ended:
		_round_log.append_text("\n\n[b][color=#ff4444]✦ Defeated! ✦[/color][/b]")
