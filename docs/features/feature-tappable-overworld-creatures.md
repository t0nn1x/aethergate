# Implementation Plan: Tappable Overworld Creatures

Branch: feature/tappable-overworld-creatures
Created: 2026-02-19

## Settings
- Testing: no (default from `/ai-factory.feature`)
- Logging: no (default from `/ai-factory.feature`)

## Scope
- Make runtime-spawned overworld creatures tappable/clickable.
- When a creature is tapped, show a contextual `Fight` button.
- Prevent tap-to-move from firing on the same tap used to select a creature.
- Keep behavior consistent for desktop mouse and mobile touch input.

## Commit Plan
- Commit 1 (after tasks 1-3): `feat(input): add creature tap selection flow and input routing`
- Commit 2 (after tasks 4-6): `feat(ui): add creature action hud and overworld wiring`
- Commit 3 (after tasks 7-8): `feat(overworld): harden selection lifecycle and document interaction flow`

## Tasks

### Phase 1: Input Selection Contract
- [x] Task 1: Extend bounded creature events with selection/action signals so tap interactions are exposed through the existing event channel.
  Files: `src/core/events/creature_events.gd`
  Logging: none.

- [x] Task 2: Add creature hit-test support to `PlayerInputComponent` (screen-to-world query + creature filtering), including configurable interaction toggles and collision mask defaults for creature layer.
  Files: `src/entities/player/components/input/player_input_component.gd`, `src/entities/player/config/player_input_config.gd`, `src/entities/player/config/player_input_config.tres`
  Logging: none.

- [x] Task 3: Update mouse/touch adapters to prioritize creature selection over move-target queueing, so tapping a creature emits selection and does not issue a move command.
  Files: `src/entities/player/input/player_mouse_input_adapter.gd`, `src/entities/player/input/player_touch_input_adapter.gd`
  Logging: none.

### Phase 2: Overworld UI Integration
- [x] Task 4: Create a lightweight HUD widget scene for selected-creature actions with a single `Fight` button and show/hide API.
  Files: `src/ui/hud/creature_action_hud.tscn`, `src/ui/hud/creature_action_hud.gd`
  Logging: none.

- [x] Task 5: Add the action HUD instance into overworld composition and expose references from `Overworld` for runtime wiring.
  Files: `src/world/overworld/overworld.tscn`, `src/world/overworld/overworld.gd`
  Logging: none.

- [x] Task 6: Wire event flow end-to-end: creature tap -> HUD show, fight pressed -> placeholder action event, empty-world tap/deselect -> HUD hide.
  Files: `src/world/overworld/overworld.gd`, `src/core/events/creature_events.gd`
  Logging: none.

### Phase 3: Lifecycle and UX Hardening
- [x] Task 7: Handle selection lifecycle edge cases (selected creature dies/despawns/chunk unloads, menu overlays, inventory toggles) and ensure stale references auto-clear.
  Files: `src/world/overworld/overworld.gd`, `src/world/overworld/overworld_creature_spawner.gd`, `src/world/overworld/overworld_creature_selection_controller.gd`
  Logging: none.

- [x] Task 8: Update creature workflow docs with interaction authoring/runtime notes and add a manual validation checklist for desktop + mobile tap behavior.
  Files: `src/entities/creatures/README.md`
  Logging: none.

## Acceptance Criteria
- Tapping/clicking a spawned creature shows a visible `Fight` button.
- Tapping/clicking empty ground hides the `Fight` button.
- Selecting a creature does not also trigger move-to-target on that same input.
- Touch and mouse paths both work with existing hold/drag and pinch-zoom behavior.
- If the selected creature dies or despawns, the action UI closes automatically.
- Fight button currently triggers a placeholder action path (event/signal) without combat implementation.

## Risks / Notes
- Current move input runs through `_unhandled_input`; event ordering must be validated so creature selection consistently wins over movement.
- Creature picking should rely on collision-mask filtering to avoid selecting non-creature colliders in world/navigation layers.
- Because chunk streaming despawns entities dynamically, UI must guard against invalid creature references every frame-independent transition.
