class_name Player
extends Creature

## The player character.
## A thin shell that extends Creature. All behavior lives in child components:
## - PlayerInputComponent: tap/click target queue
## - PlayerMovementComponent: movement executor
## - CreatureNavigationComponent: pathfinding target/direction provider
## - PlayerVisualComponent: sprite bob, flip, silhouette sync
## - PlayerCameraComponent: zoom controls
## - StateMachine + movement states: mode switching (idle/path)

@export var player_id: int = 1
@export var owner_peer_id: int = 1
@export var is_local_player: bool = true

func _ready() -> void:
	# Set player stats directly (no creature_data resource for the player).
	creature_name = "Player"
	max_health = 100.0
	movement_speed = 100.0
	current_health = max_health

	super._ready()

	# Register with game systems.
	add_to_group("player")
	_refresh_identity_groups()
	_emit_player_spawned_event()

func _on_death() -> void:
	print("Player died!")
	# Don't queue_free — handle respawn instead.
	GameManager.change_state(GameManager.GameState.PAUSED)


func _emit_player_spawned_event() -> void:
	var player_events: Node = get_node_or_null("/root/PlayerEvents")
	if player_events and player_events.has_signal("player_spawned"):
		player_events.emit_signal("player_spawned", self)
		return
	EventBus.player_spawned.emit(self)


func configure_identity(new_player_id: int, new_owner_peer_id: int, local_player: bool) -> void:
	player_id = max(new_player_id, 1)
	owner_peer_id = max(new_owner_peer_id, 1)
	is_local_player = local_player
	_refresh_identity_groups()


func has_input_authority() -> bool:
	if multiplayer == null or not multiplayer.has_multiplayer_peer():
		return is_local_player
	return multiplayer.get_unique_id() == owner_peer_id


func has_movement_authority() -> bool:
	# Solo-first: movement authority follows input authority.
	return has_input_authority()


func _refresh_identity_groups() -> void:
	if is_local_player:
		if not is_in_group("local_player"):
			add_to_group("local_player")
		return
	if is_in_group("local_player"):
		remove_from_group("local_player")
