extends SceneTree

## Headless runner for player skin catalog validation.
## Usage:
##   Godot --headless --path <project> --script res://src/Entities/player/tests/run_player_skin_catalog_validation.gd

const VALIDATION_TEST_SCRIPT: Script = preload(
	"res://src/Entities/player/tests/player_skin_catalog_validation_test.gd"
)


func _initialize() -> void:
	var validation_test = VALIDATION_TEST_SCRIPT.new()
	var passed: bool = validation_test.run()
	quit(0 if passed else 1)
