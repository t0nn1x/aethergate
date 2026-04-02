extends SceneTree

## Headless runner for spawn-zone validation.
## Usage:
##   Godot --headless --path <project> --script res://src/entities/creatures/tests/run_creature_spawn_zone_test.gd

const SPAWN_ZONE_TEST_SCRIPT: Script = preload(
	"res://src/entities/creatures/tests/creature_spawn_zone_test.gd"
)


func _initialize() -> void:
	var spawn_zone_test = SPAWN_ZONE_TEST_SCRIPT.new()
	var passed: bool = spawn_zone_test.run()
	quit(0 if passed else 1)
