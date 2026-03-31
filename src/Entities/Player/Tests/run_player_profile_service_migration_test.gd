extends SceneTree

## Headless runner for player profile service migration validation.
## Usage:
##   Godot --headless --path <project> --script res://src/Entities/Player/Tests/run_player_profile_service_migration_test.gd

const VALIDATION_TEST_SCRIPT: Script = preload(
	"res://src/Entities/Player/Tests/player_profile_service_migration_test.gd"
)


func _initialize() -> void:
	var validation_test = VALIDATION_TEST_SCRIPT.new()
	var passed: bool = validation_test.run()
	quit(0 if passed else 1)
