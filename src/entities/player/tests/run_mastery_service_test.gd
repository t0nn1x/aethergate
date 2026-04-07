extends SceneTree

const TEST_SCRIPT: Script = preload(
	"res://src/entities/player/tests/mastery_service_test.gd"
)

func _initialize() -> void:
	var test = TEST_SCRIPT.new()
	quit(0 if test.run() else 1)
