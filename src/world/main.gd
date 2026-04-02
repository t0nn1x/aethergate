class_name MainRoot
extends Node

## Main scene root.
## World is rendered directly (no intermediate SubViewport pipeline).

const COMBAT_SCENE_PATH: String = "res://src/world/combat/combat_scene.tscn"

@onready var _overworld: Overworld = $Overworld

var _combat_scene: CombatScene = null


func _ready() -> void:
	if not GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(_old_state: GameManager.GameState, new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.COMBAT:
		_enter_combat()
	elif new_state == GameManager.GameState.OVERWORLD and _combat_scene != null:
		_exit_combat()


func _enter_combat() -> void:
	if _overworld:
		var local_player: Player = _overworld.get_local_player()
		if local_player:
			local_player.process_mode = Node.PROCESS_MODE_DISABLED
	var packed: PackedScene = load(COMBAT_SCENE_PATH) as PackedScene
	_combat_scene = packed.instantiate() as CombatScene
	add_child(_combat_scene)


func _exit_combat() -> void:
	if _combat_scene and is_instance_valid(_combat_scene):
		_combat_scene.queue_free()
		_combat_scene = null
	if _overworld:
		var local_player: Player = _overworld.get_local_player()
		if local_player:
			local_player.process_mode = Node.PROCESS_MODE_INHERIT
