# Tap-to-Move Navigation Setup

## Creature Integration Recipe

1. Add `NavigationAgent2D` as a child of the creature root (`CharacterBody2D`).
2. Add `CreatureNavigationComponent` (`res://Entities/Creatures/Components/creature_navigation_component.gd`) as a child of the same creature.
3. For AI/state scripts, call:
   - `set_target_position(world_pos: Vector2) -> bool`
   - `clear_target()`
   - `has_active_target() -> bool`
   - `is_navigation_finished() -> bool`
   - `get_navigation_direction(current_pos: Vector2) -> Vector2`

## Player Setup (Implemented)

- `PlayerInputComponent` queues click/tap targets and exposes manual input vector.
- `PlayerMovementComponent` only executes movement (manual/path) when requested by states.
- `StateMachine` on player owns:
  - `IdleState`
  - `ManualMoveState`
  - `PathMoveState`

## Manual Nav Painting

This project uses chunk-local `NavigationRegion2D`.

### Example chunk already prepared
- `res://Map/Overworld/Chunks/Midra/chunk_-2_-2.tscn`
  - Added `Navigation/NavigationRegion2D` nodes.
  - You need to assign and draw the `NavigationPolygon` in the editor.

### Painting rules
1. Draw polygons only over walkable land.
2. Exclude water and blocked obstacles.
3. Include bridge walkable strips so paths can cross bridges.
4. Ensure neighboring chunk polygons slightly overlap/connect at chunk edges.
