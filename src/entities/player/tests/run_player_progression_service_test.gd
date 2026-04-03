extends SceneTree

## Headless runner for player progression service tests.
## Usage:
##   Godot --headless --path <project> \
##     --script res://src/entities/player/tests/run_player_progression_service_test.gd

const TEST_SCRIPT: Script = preload(
	"res://src/entities/player/tests/player_progression_service_test.gd"
)


func _initialize() -> void:
	var test := TEST_SCRIPT.new()
	var passed: bool = test.run()
	quit(0 if passed else 1)
