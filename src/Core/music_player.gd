class_name MusicPlayerService
extends Node

## Global audio service for UI SFX and looping menu music.
## Register as an autoload for one-line usage from any scene.

const SFX_POOL_SIZE: int = 4
const SUPPORTED_AUDIO_EXTENSIONS: PackedStringArray = [".mp3", ".ogg", ".wav"]

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

var _menu_track_streams: Array[AudioStream] = []
var _menu_music_folder_path: String = ""
var _current_music_index: int = -1
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


func configure_menu_music(
	track_streams: Array[AudioStream],
	volume_db: float = -14.0,
	bus_name: String = "Music",
	loop: bool = true
) -> void:
	_ensure_music_player()
	_menu_track_streams = _filter_valid_menu_tracks(track_streams)
	_music_volume_db = volume_db
	_music_bus_name = bus_name
	_music_loop_enabled = loop
	_music_player.volume_db = _music_volume_db
	_music_player.bus = _resolve_bus_name(_music_bus_name)
	_current_music_index = -1

	if _menu_track_streams.is_empty():
		push_warning("MusicPlayer: menu music track list is empty.")
		return

	print(
		"[FIX][MusicPlayer] configured menu music playlist with %d tracks."
		% _menu_track_streams.size()
	)


func configure_menu_music_from_folder(
	folder_path: String,
	volume_db: float = -14.0,
	bus_name: String = "Music",
	loop: bool = true
) -> void:
	_menu_music_folder_path = folder_path
	var discovered_streams: Array[AudioStream] = _load_tracks_from_folder(folder_path)
	configure_menu_music(discovered_streams, volume_db, bus_name, loop)


func play_menu_music(force_new_selection: bool = false) -> void:
	_ensure_music_player()
	_music_player.volume_db = _music_volume_db
	_music_player.bus = _resolve_bus_name(_music_bus_name)

	if _menu_track_streams.is_empty():
		if not _menu_music_folder_path.is_empty():
			_menu_track_streams = _load_tracks_from_folder(_menu_music_folder_path)
			_current_music_index = -1
		if _menu_track_streams.is_empty():
			push_warning("MusicPlayer: no menu music tracks available.")
			_music_player.stop()
			_music_player.stream = null
			return

	if force_new_selection or _music_player.stream == null:
		var selected_index: int = _pick_random_track_index(_menu_track_streams.size(), _current_music_index)
		var stream: AudioStream = _menu_track_streams[selected_index]
		if stream == null:
			push_warning("MusicPlayer: selected menu track stream is null at index %d." % selected_index)
			return

		_apply_stream_loop(stream, _music_loop_enabled)
		_current_music_index = selected_index
		_music_player.stream = stream
		print("[FIX][MusicPlayer] selected menu track: %s" % _describe_stream(stream))

	if not _music_player.playing:
		_music_player.play()
		print("[FIX][MusicPlayer] menu music started.")


func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()


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


func _resolve_bus_name(preferred_bus: String) -> String:
	if preferred_bus.is_empty():
		return "Master"
	if AudioServer.get_bus_index(preferred_bus) == -1:
		if not _missing_bus_warned.has(preferred_bus):
			_missing_bus_warned[preferred_bus] = true
			print("[MusicPlayer] bus '%s' not found, using Master." % preferred_bus)
		return "Master"
	return preferred_bus


func _filter_valid_menu_tracks(track_streams: Array[AudioStream]) -> Array[AudioStream]:
	var tracks: Array[AudioStream] = []
	for stream in track_streams:
		if stream == null:
			print("[FIX][MusicPlayer] skipped null menu track entry.")
			continue
		tracks.append(stream)
	return tracks


func _load_tracks_from_folder(folder_path: String) -> Array[AudioStream]:
	var tracks: Array[AudioStream] = []
	if folder_path.is_empty():
		print("[FIX][MusicPlayer] menu music folder path is empty.")
		return tracks

	var unique_paths: Dictionary = {}
	_collect_diraccess_paths(folder_path, unique_paths)
	_collect_resource_loader_paths(folder_path, unique_paths)

	var discovered_paths: PackedStringArray = PackedStringArray(unique_paths.keys())
	discovered_paths.sort()
	for path in discovered_paths:
		var stream: AudioStream = _get_cached_stream(path)
		if stream == null:
			print("[FIX][MusicPlayer] failed to load discovered track: %s" % path)
			continue
		tracks.append(stream)

	print(
		"[FIX][MusicPlayer] discovered %d tracks in '%s'."
		% [tracks.size(), folder_path]
	)
	return tracks


func _collect_diraccess_paths(folder_path: String, unique_paths: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var entry: String = dir.get_next()
		if entry.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not _is_supported_audio_file(entry):
			continue
		unique_paths["%s/%s" % [folder_path, entry]] = true
	dir.list_dir_end()


func _collect_resource_loader_paths(folder_path: String, unique_paths: Dictionary) -> void:
	if not ResourceLoader.has_method("list_directory"):
		return

	var entries: PackedStringArray = ResourceLoader.list_directory(folder_path)
	for entry in entries:
		if not _is_supported_audio_file(entry):
			continue
		var path: String = "%s/%s" % [folder_path, entry]
		if ResourceLoader.exists(path):
			unique_paths[path] = true


func _is_supported_audio_file(file_name: String) -> bool:
	var lower_name: String = file_name.to_lower()
	for extension in SUPPORTED_AUDIO_EXTENSIONS:
		if lower_name.ends_with(extension):
			return true
	return false


func _pick_random_track_index(track_count: int, previous_index: int) -> int:
	if track_count <= 1:
		return 0

	var selected_index: int = previous_index
	var attempts: int = 0
	while selected_index == previous_index and attempts < 8:
		selected_index = _rng.randi_range(0, track_count - 1)
		attempts += 1
	return selected_index


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
	if not ResourceLoader.exists(path):
		return null

	return load(path) as AudioStream


func _apply_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if enabled else AudioStreamWAV.LOOP_DISABLED


func _describe_stream(stream: AudioStream) -> String:
	if stream == null:
		return "<null>"
	if not stream.resource_path.is_empty():
		return stream.resource_path
	if not stream.resource_name.is_empty():
		return stream.resource_name
	return stream.get_class()
