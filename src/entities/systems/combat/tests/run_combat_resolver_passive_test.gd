extends SceneTree

const TEST_SCRIPT: Script = preload(
	"res://src/entities/systems/combat/tests/combat_resolver_passive_test.gd"
)

func _initialize() -> void:
	var test = TEST_SCRIPT.new()
	quit(0 if test.run() else 1)
