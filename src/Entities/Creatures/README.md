# Creature Workflow

This project uses a data-driven creature pipeline built around `*_128x32.png` sheets.

## 1. Add New Creature Art

1. Place each sprite sheet under `src/Entities/Creatures/Types/<Category>/<Creature Name>/`.
2. File name must end with `_128x32.png`.
3. Expected sheet layout:
   - Full sheet: `128x32`
   - Frames: `4x1`
   - Frame size: `32x32`

Example:
- `src/Entities/Creatures/Types/Humanoids/Adventurous Adolescent/AdventurousAdolescent_128x32.png`

## 2. Rebuild Creature Data + Catalog

Run the builder runner scene:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://src/Entities/Creatures/Tools/creature_catalog_builder_runner.tscn --quit
```

This updates:
- `src/Entities/Creatures/Resources/Data/*.tres`
- `src/Entities/Creatures/Resources/creature_catalog.tres`

Notes:
- IDs are deterministic (`<category>_<creature-folder>` sanitized to snake_case).
- Duplicate IDs are skipped with a warning.

## 3. Spawn Configuration in Chunks

Creature spawns are chunk-driven.

For each chunk scene that should spawn creatures:

1. Add a `Node2D` named `CreatureSpawnPoints`.
2. Add `Marker2D` children for spawn points.
3. Define creature ID by one of:
   - Marker metadata key `creature_id` (recommended), or
   - Marker name prefix: `Spawn_<creature_id>`

`creature_id` must match `CreatureData.creature_id` from the catalog.

## 4. Runtime Integration

- `OverworldCreatureSpawner` listens to `ChunkManager.chunk_loaded/chunk_unloaded`.
- On chunk load: spawns chunk markers into `WorldYSort`.
- On chunk unload: despawns only creatures owned by that chunk.
- Creature events are emitted via `CreatureEvents` autoload with legacy bridge through `EventBus`.

## 5. Validation Commands

Catalog validation:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
```

Runtime smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://src/Entities/Creatures/Tests/creature_runtime_smoke_test.tscn --quit-after 200
```

## Troubleshooting

- `missing creature_id` warning:
  - Marker has no `creature_id` meta and does not follow `Spawn_<id>` naming.
- `missing creature_id '<id>'` warning:
  - Spawn marker ID is not present in `creature_catalog.tres`.
  - Re-run builder and verify ID spelling.
- Creature appears but does not move/chase:
  - Ensure creature scene has `CreatureNavigationComponent`, `CreatureMovementComponent`, `CreatureBrainComponent`, and state machine states.
  - Verify behavior profile is not `PASSIVE` if combat behavior is expected.
- Duplicate catalog IDs:
  - Two folders normalize to the same slug. Rename one folder and rebuild.
