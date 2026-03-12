# src/Ui/Common/Tests/test_ui_manager_resolve.gd
extends SceneTree

func _init() -> void:
	var UiLayoutConfigClass := preload("res://src/Ui/Common/Resources/ui_layout_config.gd")
	var config: Resource = UiLayoutConfigClass.new()
	config.slots = {
		&"system_hud": {
			&"windows": "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn",
			&"mobile":  "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn",
		}
	}

	# windows profile → windows scene path
	var path_w: String = config.get_scene_path(&"system_hud", &"windows")
	assert(path_w == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "windows")

	# mobile profile → mobile scene path
	var path_m: String = config.get_scene_path(&"system_hud", &"mobile")
	assert(path_m == "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn", "mobile")

	# macos profile → fallback to windows (no macos key in this test config)
	var path_mac: String = config.get_scene_path(&"system_hud", &"macos")
	assert(path_mac == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "macos fallback")

	print("[PASS] UiManager resolve tests")
	quit(0)
