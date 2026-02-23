# Creature Workflow

This project uses a data-driven creature pipeline built around `*_128x32.png` sheets.

## 1. Add New Creature Art

1. Place each sprite sheet under `src/Entities/Creatures/Types/<Category>/<Creature Name>/Sprites/`.
2. File name must end with `_128x32.png`.
3. Expected sheet layout:
   - Full sheet: `128x32`
   - Frames: `4x1`
   - Frame size: `32x32`

Example:
- `src/Entities/Creatures/Types/Humanoids/Adventurous Adolescent/Sprites/AdventurousAdolescent_128x32.png`

## 2. Rebuild Creature Data + Catalog

Run the builder runner scene:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://src/Entities/Creatures/Tools/creature_catalog_builder_runner.tscn --quit
```

This updates:
- `src/Entities/Creatures/Types/<Category>/<Creature Name>/Data/*.tres`
- `src/Entities/Creatures/Resources/creature_catalog.tres`

Notes:
- IDs are deterministic (`<category>_<creature-folder>` sanitized to snake_case).
- Duplicate IDs are skipped with a warning.

## 3. Spawn Configuration in Chunks

Creature spawns are chunk-driven.

For each chunk scene that should spawn creatures:

1. Add a `Node2D` named `CreatureSpawnZones`.
2. Add `Polygon2D` children and attach `res://src/Entities/Creatures/Spawning/creature_spawn_zone.gd`.
3. Configure zone rules:
   - `spawn_rate_per_minute`
   - `max_alive`
   - `initial_spawn_count`
   - one or more filters (`allowed_creature_ids`, `allowed_creature_types`, `allowed_source_categories`)
   - optional player distance gates (`min_distance_to_player`, `max_distance_to_player`)
4. Draw the zone polygon points directly on each zone node.

Legacy marker fallback is still supported:

1. Add a `Node2D` named `CreatureSpawnPoints`.
2. Add `Marker2D` children for static spawn points.
3. Define creature ID by one of:
   - Marker metadata key `creature_id` (recommended), or
   - Marker name prefix: `Spawn_<creature_id>`

`creature_id` must match `CreatureData.creature_id` from the catalog.

## 4. Runtime Integration

- `OverworldCreatureSpawner` listens to `ChunkManager.chunk_loaded/chunk_unloaded`.
- On chunk load:
  - if zones exist, registers zone state and spawns initial zone population;
  - otherwise (or when zone spawning is disabled), falls back to marker spawns.
- During runtime: zone spawns tick by spawn budget (`spawn_rate_per_minute`) and enforce `max_alive`.
- On chunk unload: despawns only creatures owned by that chunk.
- Creatures use ambient wander only (roam near spawn point), but movement now routes through `CreatureNavigationComponent` pathing when available.
- Wander target picks are resolved through `PlayerMoveTargetBlockerComponent`, so blocked `Polygon2D` areas under `NavigationRegion2D` are avoided using the same blocker policies as player click-to-move.
- Combat AI remains disabled (no chase/attack state logic).
- Creature events are emitted via `CreatureEvents` autoload with legacy bridge through `EventBus`.

## 4.1 Creature Tap Interaction (Overworld)

- Runtime spawned creatures are tappable/clickable from player input.
- Input selection is emitted through `CreatureEvents.creature_selected`.
- Tapping/clicking empty world emits `CreatureEvents.creature_deselected`.
- A contextual `Fight` button is shown through `res://src/Ui/Hud/creature_action_hud.tscn` when a creature is selected.
- Pressing `Fight` emits `CreatureEvents.creature_fight_requested` (placeholder action path only; combat is still not implemented here).
- Creature taps take priority over move requests, so selecting a creature does not queue click-to-move on that same input.
- Selection is auto-cleared when the selected creature dies, exits tree, despawns with chunk unload, or when inventory is opened.

Input config knobs:
- `res://src/Entities/Player/Config/player_input_config.tres`
  - `enable_creature_tap_selection`
  - `creature_tap_collision_mask`
  - `creature_tap_max_results`

## 5. Validation Commands

Catalog validation:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
```

Runtime smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://src/Entities/Creatures/Tests/creature_runtime_smoke_test.tscn --quit-after 200
```

Spawn-zone helper validation:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_spawn_zone_test.gd
```

Manual interaction validation (desktop + mobile):
1. Start overworld session and ensure creatures are visible.
2. Click/tap a creature -> `Fight` button appears.
3. Click/tap empty ground -> `Fight` button hides and player move still works.
4. Click/tap a creature -> player should not move on that same selection input.
5. Open inventory (`inventory` action), confirm action button hides.
6. Select creature, then unload/despawn chunk (or let creature die), confirm action button auto-hides.
7. On mobile/touch, verify tap-select still works without breaking hold-drag movement and pinch zoom.

## Troubleshooting

- `missing creature_id` warning:
  - Marker has no `creature_id` meta and does not follow `Spawn_<id>` naming.
- `missing creature_id '<id>'` warning:
  - Spawn marker ID is not present in `creature_catalog.tres`.
  - Re-run builder and verify ID spelling.
- Creature never wanders:
  - Ensure creature scene has `CreatureMovementComponent` and `CreatureWanderComponent`.
  - Check `CreatureData.enable_ambient_wander = true`, `wander_radius > 0`, `wander_interval_seconds > 0`.
- Creature wanders too far:
  - Lower `wander_radius` in that creature's `.tres` data.
- Creature still enters blocked polygons:
  - Verify creature scene still has `PlayerMoveTargetBlockerComponent`.
  - Verify `OverworldCreatureSpawner` logs blocker-registry wiring in debug (`[CreatureSpawner] blocker registry wired ...`).
  - Verify `NavigationBlockerRegistry` is refreshed after chunk/nav-region changes.
- Duplicate catalog IDs:
  - Two folders normalize to the same slug. Rename one folder and rebuild.
- `zone '<name>' has no creature filters configured` warning:
  - Add at least one filter list entry (ID, type, or source category).
- Zone never spawns creatures:
  - Verify polygon has 3+ points and `max_alive > 0`.
  - Verify filters resolve to actual catalog entries.
  - Check player-distance gates are not too strict for your test position.
