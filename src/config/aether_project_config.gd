class_name AetherProjectConfig
extends Resource

## Global project-level gameplay and platform config.

@export var desktop_platform_profile: GamePlatformProfile = preload("res://src/config/platform/desktop_platform_profile.tres")
@export var mobile_platform_profile: GamePlatformProfile = preload("res://src/config/platform/mobile_platform_profile.tres")
@export var player_input_config = preload("res://src/entities/player/config/player_input_config.tres")
@export var player_movement_config = preload("res://src/entities/player/config/player_movement_config.tres")


func get_platform_profile(is_mobile_runtime: bool) -> GamePlatformProfile:
	if is_mobile_runtime and mobile_platform_profile != null:
		return mobile_platform_profile
	return desktop_platform_profile
