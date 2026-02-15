class_name CreatureStateBase
extends State

## Shared state helpers for creature AI states.

var creature: Creature
var brain
var movement_component
var navigation_component


func _cache_context() -> void:
	if creature == null:
		if state_machine and state_machine.get_parent() is Creature:
			creature = state_machine.get_parent() as Creature
		elif get_parent() and get_parent().get_parent() is Creature:
			creature = get_parent().get_parent() as Creature

	if creature == null:
		return

	if brain == null:
		brain = creature.get_node_or_null("CreatureBrainComponent")
	if movement_component == null:
		movement_component = creature.get_node_or_null("CreatureMovementComponent")
	if navigation_component == null:
		navigation_component = creature.get_node_or_null("CreatureNavigationComponent")


func _is_ready() -> bool:
	return (
		creature != null
		and brain != null
		and movement_component != null
		and navigation_component != null
	)
