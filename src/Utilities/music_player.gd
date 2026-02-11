class_name MusicPlayerService
extends Node

## Global audio service for UI SFX and looping menu music.
## Register as an autoload for one-line usage from any scene.

const SFX_POOL_SIZE: int = 4
const SUPPORTED_AUDIO_EXTENSIONS := [".mp3", ".ogg", ".wav"]

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _music_player: AudioStreamPlayer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stream_cache: Dictionary = {}

var _hover_stream: AudioStream
var _click_stream: AudioStream
var _hover_volume_db: float = -10.0
var _click_volume_db: float = -3.0
var _sfx_bus_name: String = "SFX"

var _current_music_path: String = ""
var _current_music_folder: String = ""
var _current_music_playlist: Array[String] = []
var _music_volume_db: float = -14.0
var _music_bus_name: String = "Music"
var _music_loop_enabled: bool = true
var _missing_bus_warned: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_ensure_sfx_pool()
	_ensure_music_player()


func configure_ui_sounds(
	hover_path: String,
	hover_db: float,
	click_path: String,
	click_db: float,
	sfx_bus_name: String = "SFX"
) -> void:
	_sfx_bus_name = sfx_bus_name
	_hover_volume_db = hover_db
	_click_volume_db = click_db
	_hover_stream = _get_cached_stream(hover_path)
	_click_stream = _get_cached_stream(click_path)

	if _hover_stream == null:
		push_warning("MusicPlayer: failed to load hover sound '%s'." % hover_path)
	if _click_stream == null:
		push_warning("MusicPlayer: failed to load click sound '%s'." % click_path)


func play_ui_hover() -> void:
	_play_sfx_stream(_hover_stream, _hover_volume_db)


func play_ui_click() -> void:
	_play_sfx_stream(_click_stream, _click_volume_db)


func play_sfx(path: String, volume_db: float = 0.0, bus_name: String = "SFX") -> void:
	var stream: AudioStream = _get_cached_stream(path)
	if stream == null:
		push_warning("MusicPlayer: failed to load SFX '%s'." % path)
		return
	_play_sfx_stream(stream, volume_db, bus_name)


func play_random_music_from_folder(
	folder_path: String,
	volume_db: float = -14.0,
	bus_name: String = "Music",
	loop: bool = true,
	force_new_selection: bool = false
) -> void:
	_ensure_music_player()

	_music_volume_db = volume_db
	_music_bus_name = bus_name
	_music_loop_enabled = loop
	_music_player.volume_db = _music_volume_db
	_music_player.bus = _resolve_bus_name(_music_bus_name)

	var should_refresh_playlist: bool = (
		force_new_selection
		or folder_path != _current_music_folder
		or _current_music_playlist.is_empty()
	)
	if should_refresh_playlist:
		_current_music_folder = folder_path
		_current_music_playlist = _collect_audio_paths_in_folder(folder_path)
		_current_music_path = ""

	if _current_music_playlist.is_empty():
		push_warning("MusicPlayer: no music tracks found in '%s'." % folder_path)
		_music_player.stop()
		_music_player.stream = null
		return

	if force_new_selection or _music_player.stream == null:
		var selected_path: String = _pick_random_track(_current_music_playlist, _current_music_path)
		var stream: AudioStream = _get_cached_stream(selected_path)
		if stream == null:
			push_warning("MusicPlayer: failed to load selected music '%s'." % selected_path)
			return

		_current_music_path = selected_path
		_music_player.stream = stream
		print("[MusicPlayer] selected music: %s" % selected_path)

	if not _music_player.playing:
		_music_player.play()
		print("[MusicPlayer] music started.")


func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()


func _on_music_finished() -> void:
	if not _music_loop_enabled:
		return
	if _music_player == null or _music_player.stream == null:
		return
	_music_player.play()


func _play_sfx_stream(stream: AudioStream, volume_db: float, bus_name: String = "") -> void:
	if stream == null:
		return

	var player: AudioStreamPlayer = _next_sfx_player()
	if player == null:
		return

	var resolved_bus_name: String = _sfx_bus_name if bus_name.is_empty() else bus_name
	player.bus = _resolve_bus_name(resolved_bus_name)
	player.volume_db = volume_db
	player.stream = stream
	player.play()


func _next_sfx_player() -> AudioStreamPlayer:
	if _sfx_pool.is_empty():
		_ensure_sfx_pool()
	if _sfx_pool.is_empty():
		return null

	var player: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	return player


func _ensure_sfx_pool() -> void:
	if not _sfx_pool.is_empty():
		return

	for index in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPoolPlayer%d" % index
		player.autoplay = false
		player.bus = _resolve_bus_name(_sfx_bus_name)
		add_child(player)
		_sfx_pool.append(player)


func _ensure_music_player() -> void:
	if _music_player != null:
		return

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.autoplay = false
	_music_player.bus = _resolve_bus_name(_music_bus_name)
	_music_player.volume_db = _music_volume_db
	add_child(_music_player)

	if not _music_player.finished.is_connected(_on_music_finished):
		_music_player.finished.connect(_on_music_finished)


func _resolve_bus_name(preferred_bus: String) -> String:
	if preferred_bus.is_empty():
		return "Master"
	if AudioServer.get_bus_index(preferred_bus) == -1:
		if not _missing_bus_warned.has(preferred_bus):
			_missing_bus_warned[preferred_bus] = true
			print("[MusicPlayer] bus '%s' not found, using Master." % preferred_bus)
		return "Master"
	return preferred_bus


func _collect_audio_paths_in_folder(folder_path: String) -> Array[String]:
	var tracks: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir == null:
		return tracks

	dir.list_dir_begin()
	while true:
		var entry: String = dir.get_next()
		if entry.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not _is_supported_audio_file(entry):
			continue

		var path: String = "%s/%s" % [folder_path, entry]
		if _audio_path_exists(path):
			tracks.append(path)
	dir.list_dir_end()

	tracks.sort()
	return tracks


func _is_supported_audio_file(file_name: String) -> bool:
	var lower_name: String = file_name.to_lower()
	for extension in SUPPORTED_AUDIO_EXTENSIONS:
		if lower_name.ends_with(extension):
			return true
	return false


func _pick_random_track(track_paths: Array[String], previous_path: String) -> String:
	if track_paths.is_empty():
		return ""
	if track_paths.size() == 1:
		return track_paths[0]

	var selected_path: String = previous_path
	var attempts: int = 0
	while selected_path == previous_path and attempts < 8:
		selected_path = track_paths[_rng.randi_range(0, track_paths.size() - 1)]
		attempts += 1
	return selected_path


func _audio_path_exists(path: String) -> bool:
	return ResourceLoader.exists(path, "AudioStream") or FileAccess.file_exists(path)


func _get_cached_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _stream_cache.has(path):
		return _stream_cache[path] as AudioStream

	var stream: AudioStream = _load_audio_stream_from_path(path)
	if stream != null:
		_stream_cache[path] = stream
	return stream


func _load_audio_stream_from_path(path: String) -> AudioStream:
	var lower_path: String = path.to_lower()
	if lower_path.ends_with(".mp3"):
		return _load_mp3_stream(path)

	if ResourceLoader.exists(path, "AudioStream"):
		return load(path) as AudioStream

	return null


func _load_mp3_stream(path: String) -> AudioStreamMP3:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var data: PackedByteArray = file.get_buffer(file.get_length())
	if data.is_empty():
		return null

	var stream: AudioStreamMP3 = AudioStreamMP3.new()
	stream.data = data
	return stream
