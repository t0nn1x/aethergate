class_name Player
extends Creature

## The player character.
## A thin shell that extends Creature. All behavior lives in child components:
## - PlayerInputComponent: tap/click target queue
## - PlayerMovementComponent: movement executor
## - CreatureNavigationComponent: pathfinding target/direction provider
## - PlayerVisualComponent: overworld sprite bob, flip, silhouette sync
## - PlayerCameraComponent: zoom controls
## - StateMachine + movement states: mode switching (idle/path)

@export var player_id: int = 1
@export var owner_peer_id: int = 1
@export var is_local_player: bool = true

@onready var visual_component: PlayerVisualComponent = $PlayerVisualComponent

var _primed_spawn_appearance: PlayerAppearanceData
var _primed_spawn_skin_catalog: PlayerSkinCatalog


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
	PlayerEvents.player_spawned.emit(self)


func apply_appearance(
	appearance_data: PlayerAppearanceData,
	skin_catalog_resource: PlayerSkinCatalog
) -> void:
	if visual_component == null or not visual_component.has_method("apply_appearance"):
		push_warning("Player: PlayerVisualComponent missing, cannot apply appearance.")
		return
	visual_component.apply_appearance(appearance_data, skin_catalog_resource)


func prime_spawn_appearance(
	appearance_data: PlayerAppearanceData,
	skin_catalog_resource: PlayerSkinCatalog
) -> void:
	_primed_spawn_skin_catalog = skin_catalog_resource
	_primed_spawn_appearance = _duplicate_appearance(appearance_data)

	if not is_node_ready() or visual_component == null:
		return
	if _primed_spawn_appearance == null:
		return
	var effective_skin_catalog: PlayerSkinCatalog = _primed_spawn_skin_catalog
	if effective_skin_catalog == null and visual_component != null:
		effective_skin_catalog = visual_component.skin_catalog
	if effective_skin_catalog == null:
		return
	visual_component.apply_appearance(_primed_spawn_appearance, effective_skin_catalog)


func consume_primed_spawn_appearance() -> PlayerAppearanceData:
	var primed_appearance: PlayerAppearanceData = _duplicate_appearance(_primed_spawn_appearance)
	_primed_spawn_appearance = null
	return primed_appearance


func consume_primed_spawn_skin_catalog() -> PlayerSkinCatalog:
	var primed_skin_catalog: PlayerSkinCatalog = _primed_spawn_skin_catalog
	_primed_spawn_skin_catalog = null
	return primed_skin_catalog


func set_weapon_visual(weapon_visual_id: StringName) -> void:
	if visual_component == null or not visual_component.has_method("set_weapon_visual"):
		return
	visual_component.set_weapon_visual(weapon_visual_id)


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


func _duplicate_appearance(source: PlayerAppearanceData) -> PlayerAppearanceData:
	if source == null:
		return null
	var duplicated: Resource = source.duplicate_data()
	return duplicated as PlayerAppearanceData
