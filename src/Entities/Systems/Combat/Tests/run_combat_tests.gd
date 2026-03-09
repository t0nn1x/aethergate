extends SceneTree

## Headless runner for combat system tests.
## Usage:
##   godot4 --headless --path . --script res://src/Entities/Systems/Combat/Tests/run_combat_tests.gd

const TEST_SCRIPT: GDScript = preload(
	"res://src/Entities/Systems/Combat/Tests/combat_resolver_test.gd"
)


func _initialize() -> void:
	var test: Object = TEST_SCRIPT.new()
	var passed: bool = test.run()
	quit(0 if passed else 1)
