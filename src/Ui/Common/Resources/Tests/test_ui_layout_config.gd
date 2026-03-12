extends SceneTree

const UiLayoutConfigClass := preload("res://src/Ui/Common/Resources/ui_layout_config.gd")

func _init() -> void:
	var config: UiLayoutConfigClass = UiLayoutConfigClass.new()
	config.slots = {
		&"system_hud": {
			&"windows": "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn",
			&"macos":   "res://src/Ui/MacOS/Hud/SystemHud/system_hud_macos.tscn",
			&"mobile":  "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn",
		}
	}

	# exact match
	assert(config.get_scene_path(&"system_hud", &"windows") == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "windows path")
	assert(config.get_scene_path(&"system_hud", &"mobile")  == "res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn", "mobile path")
	assert(config.get_scene_path(&"system_hud", &"macos")   == "res://src/Ui/MacOS/Hud/SystemHud/system_hud_macos.tscn", "macos path")
	# fallback to windows when platform key missing
	assert(config.get_scene_path(&"system_hud", &"unknown") == "res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn", "fallback")
	# missing slot returns empty string
	assert(config.get_scene_path(&"missing_slot", &"windows") == "", "missing slot")

	print("[PASS] UiLayoutConfig tests")
	quit(0)
