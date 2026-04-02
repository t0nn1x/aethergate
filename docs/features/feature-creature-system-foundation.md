# Implementation Plan: Creature System Foundation

Branch: feature/creature-system-foundation
Created: 2026-02-15

## Settings
- Testing: yes
- Logging: minimal

## Scope
- Build a scalable, data-driven creature pipeline for hundreds of variants.
- Use only `*_128x32.png` creature sheets as the default visual source.
- Reuse the existing component + state-machine patterns used by `Player`.
- Integrate creature spawning into overworld/chunk lifecycle without group polling in hot loops.

## Commit Plan
- Commit 1 (after tasks 1-3): `feat(creatures): add data model and catalog for creature definitions`
- Commit 2 (after tasks 4-6): `feat(creatures): add runtime creature components and ai states`
- Commit 3 (after tasks 7-9): `feat(overworld): add creature spawning integration with chunk lifecycle`
- Commit 4 (after tasks 10-12): `test(creatures): add data validation and runtime smoke coverage`
- Commit 5 (after tasks 13-16): `feat(overworld): add zone-based runtime creature spawning`
- Commit 6 (after tasks 17-18): `test(creatures): add spawn-zone validation and authoring docs`

## Tasks

### Phase 1: Data Model and Content Pipeline
- [x] Task 1: Extend `CreatureData` with stable identity and visual metadata (`creature_id`, source category, sprite frame config defaults for 128x32 sheets, optional behavior tuning fields) while preserving existing fields.
  Files: `src/entities/creatures/base/creature_data.gd`
  Logging (minimal): warn/error only for invalid exported values detected at runtime (empty id, invalid frame counts).

- [x] Task 2: Add a `CreatureCatalog` resource and loader service that provide `get_by_id()` and lightweight lookup indices (by type/category) for runtime spawners.
  Files: `src/entities/creatures/base/creature_catalog.gd`, `src/entities/creatures/base/creature_catalog_service.gd`, `src/entities/creatures/resources/creature_catalog.tres`
  Logging (minimal): log only missing ID lookups and duplicate ID detection during catalog load.

- [x] Task 3: Create an editor tool to scan `src/entities/creatures/catalog/**/sprites/*_128x32.png` and generate/update `CreatureData` resources + catalog entries deterministically.
  Files: `src/entities/creatures/tools/creature_catalog_builder.gd`, `src/entities/creatures/catalog/**/data/*.tres`, `src/entities/creatures/resources/creature_catalog.tres`
  Logging (minimal): summary output + error lines for skipped/broken assets; no per-file verbose traces.

### Phase 2: Runtime Creature Stack
- [x] Task 4: Upgrade base `Creature` apply flow so it fully consumes `CreatureData` (stats + sprite defaults + silhouette), and add explicit hooks for component-driven runtime behavior.
  Files: `src/entities/creatures/base/creature.gd`
  Logging (minimal): only warnings when required nodes/resources are missing or invalid.

- [x] Task 5: Add reusable creature runtime components (`CreatureVisualComponent`, `CreatureMovementComponent`) modeled after player component style, with typed references and no repeated `get_node()` in hot paths.
  Files: `src/entities/creatures/components/Visual/creature_visual_component.gd`, `src/entities/creatures/components/Movement/creature_movement_component.gd`, `src/entities/creatures/base/creature.tscn`
  Logging (minimal): one warning per missing dependency node; suppress frame-level logs.

- [x] Task 6: Add first-pass navigation-aware ambient wander behavior using `CreatureNavigationComponent` and behavior tuning from `CreatureData`.
  Files: `src/common/navigation/creature_navigation_component.gd`, `src/entities/creatures/components/Wander/creature_wander_component.gd`, `src/entities/creatures/base/creature.tscn`
  Logging (minimal): state-transition warnings/errors only; no per-frame behavior logs.

### Phase 3: Spawning and World Integration
- [x] Task 7: Add `OverworldCreatureSpawner` to instantiate creatures via catalog + factory and parent them under `WorldYSort`, mirroring existing player spawner ownership patterns.
  Files: `src/world/overworld/overworld_creature_spawner.gd`, `src/world/overworld/overworld.tscn`, `src/world/overworld/overworld.gd`
  Logging (minimal): spawn failures and missing spawn dependencies only.

- [x] Task 8: Add chunk-aware creature lifecycle hooks so creature spawn/despawn follows chunk load/unload boundaries instead of global scans.
  Files: `src/world/streaming/chunk_manager.gd`, `src/world/overworld/overworld_creature_spawner.gd`, `src/world/overworld/chunks/chunk.gd`
  Logging (minimal): log chunk-spawn summary counts and errors, skip per-entity spam.

- [x] Task 9: Introduce bounded creature event channel (`CreatureEvents` autoload) for runtime creature signals.
  Files: `src/core/events/creature_events.gd`, `project.godot`, `src/entities/creatures/base/creature.gd`
  Logging (minimal): only log missing autoload wiring or invalid creature signal payloads.

### Phase 4: Testing and Validation
- [x] Task 10: Add data validation test script to assert catalog integrity (unique IDs, valid resources, valid 128x32 frame assumptions) and make it runnable headless.
  Files: `src/entities/creatures/tests/creature_catalog_validation_test.gd`, `src/entities/creatures/tests/run_creature_catalog_validation.gd`
  Logging (minimal): print only failures and final pass/fail summary.

- [x] Task 11: Add runtime smoke test scene/script that spawns sample creatures from multiple categories and validates basic lifecycle transitions (spawn, move/chase, damage, death cleanup).
  Files: `src/entities/creatures/tests/creature_runtime_smoke_test.tscn`, `src/entities/creatures/tests/creature_runtime_smoke_test.gd`
  Logging (minimal): only assert failures and terminal summary.

- [x] Task 12: Document creature authoring workflow for new assets (`*_128x32.png` import, builder execution, catalog refresh, spawn config) and add troubleshooting notes.
  Files: `src/entities/creatures/README.md`
  Logging (minimal): not applicable.

### Phase 5: Zone-Based Spawn System
- [x] Task 13: Add `CreatureSpawnZone2D` scene helper node (`Polygon2D`) with exported spawn rules (rates, caps, filters, player-distance constraints) and helper methods for point sampling + polygon containment checks.
  Files: `src/entities/creatures/spawning/creature_spawn_zone.gd`
  Logging (minimal): warn only on invalid polygon/filter configuration.

- [x] Task 14: Extend chunk + spawner runtime to support zone-based spawning per loaded chunk (zone registry, spawn budget ticking, candidate resolution from catalog, max-alive enforcement, zone/chunk despawn cleanup), while preserving marker fallback for chunks without zones.
  Files: `src/world/overworld/chunks/chunk.gd`, `src/world/overworld/overworld_creature_spawner.gd`
  Logging (minimal): chunk/zone spawn summaries and warnings for invalid zone configs.

- [x] Task 15: Add a pilot spawn zone in a live chunk scene and validate mixed operation (zone-based spawning + legacy markers compatibility path).
  Files: `src/world/overworld/chunks/Midra/chunk_-2_-2.tscn`
  Logging (minimal): no extra runtime logs beyond Task 14.

- [x] Task 16: Surface zone-spawn runtime counters for debugging (active zones, alive creatures, per-chunk zone counts) through existing debug overlay wiring.
  Files: `src/world/overworld/overworld_creature_spawner.gd`, `src/ui/common/debug/debug_overlay.gd`, `src/ui/common/debug/Providers/chunk_debug_metrics_provider.gd`
  Logging (minimal): none; expose metrics as overlay lines.

- [x] Task 17: Add headless validation for spawn-zone helper behavior (polygon sampling and filter normalization) with deterministic pass/fail output.
  Files: `src/entities/creatures/tests/creature_spawn_zone_test.gd`, `src/entities/creatures/tests/run_creature_spawn_zone_test.gd`
  Logging (minimal): print only failures and pass/fail summary.

- [x] Task 18: Update creature authoring docs to include zone-based workflow (draw polygon, configure filters/rates, migration guidance from markers, troubleshooting invalid zones).
  Files: `src/entities/creatures/README.md`
  Logging (minimal): not applicable.

## Acceptance Criteria
- Catalog-driven creature lookup works for all generated entries from `*_128x32.png` sources.
- A single base creature scene + components can represent many creature variants via `CreatureData`.
- Overworld can spawn/despawn creatures with chunk lifecycle boundaries.
- Creature events are available through the bounded `CreatureEvents` autoload channel.
- Headless data validation and runtime smoke tests are runnable and pass.

## Risks / Notes
- Existing chunk scenes currently do not include creature spawn markers/config; a spawn-source format must be introduced during implementation.
- Minimal logging reduces runtime noise and overhead, but debugging AI/spawn edge cases may require temporary targeted debug logs.
- Zone + marker dual support is transitional; once chunks are migrated, marker fallback can be removed to reduce maintenance overhead.
