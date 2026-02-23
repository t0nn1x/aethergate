class_name ProjectConfigService
extends Node

## Central access point for project-wide runtime config.

const MOBILE_FEATURES: PackedStringArray = ["android", "ios"]

@export var project_config: AetherProjectConfig = preload("res://src/Config/project_config.tres")

var _is_mobile_runtime: bool = false
var _active_platform_profile: GamePlatformProfile


func _ready() -> void:
	reload()


func reload() -> void:
	_is_mobile_runtime = _detect_mobile_runtime()
	_active_platform_profile = null
	if project_config == null:
		if OS.is_debug_build():
			push_warning("ProjectConfigService: project_config resource is missing.")
		return

	_active_platform_profile = project_config.get_platform_profile(_is_mobile_runtime)
	if _active_platform_profile == null and OS.is_debug_build():
		push_warning("ProjectConfigService: active platform profile is missing.")


func get_project_config() -> AetherProjectConfig:
	return project_config


func get_platform_profile() -> GamePlatformProfile:
	if _active_platform_profile == null and project_config != null:
		_active_platform_profile = project_config.get_platform_profile(_is_mobile_runtime)
	return _active_platform_profile


func get_player_input_config():
	if project_config == null:
		return null
	return project_config.player_input_config


func get_player_movement_config():
	if project_config == null:
		return null
	return project_config.player_movement_config


func is_mobile_runtime() -> bool:
	return _is_mobile_runtime


func _detect_mobile_runtime() -> bool:
	for feature in MOBILE_FEATURES:
		if OS.has_feature(feature):
			return true
	return false
