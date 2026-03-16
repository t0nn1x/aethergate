class_name CombatVfxPlayer
extends Control

## Plays a sprite-sheet VFX animation centered over the parent sprite container.
## Add as a child of the target combatant TextureRect; call play() to start.
##
## Timing model:
##   - Frame 0 is shown immediately on play().
##   - Each subsequent frame is shown after 1/fps seconds (via Timer).
##   - impact_hit fires when config.impact_frame is first displayed.
##   - finished fires after the last frame is shown.
##   - If config.texture is null, impact_hit fires immediately (graceful no-op).

signal impact_hit
signal finished

var _config: CombatVfxConfig = null
var _current_frame: int = 0
var _texture_rect: TextureRect = null
var _atlas: AtlasTexture = null
var _timer: Timer = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

	_atlas = AtlasTexture.new()

	_texture_rect = TextureRect.new()
	_texture_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.texture = _atlas
	add_child(_texture_rect)

	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	hide()


func play(config: CombatVfxConfig) -> void:
	_timer.stop()
	_config = config
	_current_frame = 0

	if config.texture == null:
		impact_hit.emit()
		return

	_atlas.atlas = config.texture
	_apply_scale(config.scale)
	_update_atlas_frame(0)
	show()

	if config.impact_frame == 0:
		impact_hit.emit()

	_timer.wait_time = 1.0 / maxf(config.fps, 0.1)
	_timer.start()


func stop() -> void:
	_timer.stop()
	hide()


# ── Internal ──────────────────────────────────────────────────────────────────

func _on_timer_timeout() -> void:
	_current_frame += 1

	if _current_frame >= _config.hframes:
		_timer.stop()
		hide()
		finished.emit()
		return

	_update_atlas_frame(_current_frame)

	if _current_frame == _config.impact_frame:
		impact_hit.emit()


func _update_atlas_frame(frame: int) -> void:
	var frame_w: int = _config.texture.get_width() / _config.hframes
	var frame_h: int = _config.texture.get_height()
	_atlas.region = Rect2(frame * frame_w, 0, frame_w, frame_h)


func _apply_scale(scale: float) -> void:
	var m: float = (1.0 - scale) * 0.5
	_texture_rect.anchor_left = m
	_texture_rect.anchor_top = m
	_texture_rect.anchor_right = 1.0 - m
	_texture_rect.anchor_bottom = 1.0 - m
	_texture_rect.offset_left = 0.0
	_texture_rect.offset_top = 0.0
	_texture_rect.offset_right = 0.0
	_texture_rect.offset_bottom = 0.0
