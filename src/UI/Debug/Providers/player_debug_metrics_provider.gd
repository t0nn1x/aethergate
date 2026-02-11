class_name PlayerDebugMetricsProvider
extends RefCounted

## Collects player-related debug lines for DebugOverlay.


func collect(player_node: Node2D, chunk_manager: ChunkManager) -> Array[String]:
	var lines: Array[String] = []
	if player_node == null:
		return lines

	lines.append("Player: (%.0f, %.0f)" % [player_node.global_position.x, player_node.global_position.y])

	var creature: Creature = player_node as Creature
	if creature:
		lines.append("Speed: %.0f" % creature.movement_speed)

	if player_node is CharacterBody2D:
		var body: CharacterBody2D = player_node as CharacterBody2D
		lines.append("Velocity: (%.1f, %.1f)" % [body.velocity.x, body.velocity.y])

	var state_machine: StateMachine = player_node.get_node_or_null("StateMachine") as StateMachine
	if state_machine and state_machine.current_state:
		lines.append("State: %s" % state_machine.current_state.name)
	elif state_machine:
		lines.append("State: <none>")

	var camera: Camera2D = player_node.get_node_or_null("Camera2D") as Camera2D
	if camera:
		lines.append("Zoom: %.2f" % camera.zoom.x)

	if chunk_manager:
		var chunk: Vector2i = chunk_manager.world_to_chunk(player_node.global_position)
		lines.append("Chunk: (%d, %d)" % [chunk.x, chunk.y])

	return lines
