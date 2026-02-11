# Implementation Plan: Player Pipeline Phase 1 Refactor

Branch: refactor-player-pipeline-phase1
Created: 2026-02-11

## Settings
- Testing: yes
- Logging: verbose

## Commit Plan
- Commit 1 (after tasks 1-3): `refactor: add player context and remove state lookup duplication`
- Commit 2 (after tasks 4-6): `refactor: split player move target blocking from input component`

## Tasks

### Phase 1: Player State Wiring
- [x] Task 1: Add `PlayerContext` component to centralize typed references to player runtime components and common states.
- [x] Task 2: Update `PlayerIdleState` to read dependencies from `PlayerContext` instead of repetitive `get_node_or_null` lookups.
- [x] Task 3: Update `PlayerPathMoveState` to read dependencies from `PlayerContext` and keep transition logic unchanged.

### Phase 2: Input Responsibility Split
- [x] Task 4: Add `PlayerMoveTargetBlockerComponent` responsible for nav-polygon blocker cache and world-position block checks.
- [x] Task 5: Refactor `PlayerInputComponent` to delegate blocker checks to the new component and remove local blocker cache logic.
- [x] Task 6: Wire new components in `player.tscn`, validate script references, and run lightweight regression checks.

### Phase 3: Overworld Session Orchestration
- [x] Task 7: Add `OverworldPlayerSpawner` to own player spawn + registration flow.
- [x] Task 8: Add `OverworldSessionController` to own startup state transition + initial spawn orchestration.
- [x] Task 9: Refactor `overworld.gd` to stage-only responsibilities and wire new components in `overworld.tscn`.

### Phase 4: Chunk Manager Responsibility Split
- [x] Task 10: Extract editor preview build logic from `chunk_manager.gd` into `ChunkManagerEditorPreview`.
- [x] Task 11: Extract runtime border stitching logic from `chunk_manager.gd` into `ChunkBorderStitcher`.
- [x] Task 12: Keep `chunk_manager.gd` focused on runtime loading orchestration and delegate preview/stitching helpers.

### Phase 5: OverworldChunk Responsibility Split (Incremental)
- [x] Task 13: Extract chunk editor-neighbor preview orchestration from `chunk.gd` into `OverworldChunkEditorPreview`.
- [x] Task 14: Extract shared water shader assignment from `chunk.gd` into `OverworldChunkWaterShader`.

### Phase 6: Project Config Foundation
- [x] Task 15: Add a global `ProjectConfig` resource and autoload service to centralize runtime-tunable values.
- [x] Task 16: Add explicit `desktop` and `mobile` platform profiles and resolve one active profile at startup.
- [x] Task 17: Wire player input, camera zoom, and navigation components to consume config from the shared service.

### Phase 7: Composition Root + State/Event Boundaries
- [x] Task 18: Use `Overworld` as composition root to inject player/chunk/debug/blocker dependencies and remove runtime group discovery in core loops.
- [x] Task 19: Split global event channels into bounded-context buses (`PlayerEvents`, `WorldEvents`, `UIEvents`) and migrate player event emitters.
- [x] Task 20: Harden `GameManager` with explicit transition-map validation and `game_state_changed` signal.

## Logging Requirements
- Log warnings for missing critical runtime nodes (`PlayerContext` or blocker component) in debug builds.
- Keep logs behind debug checks where possible to avoid noisy release output.
- Include clear component names in warnings for quick traceability.
