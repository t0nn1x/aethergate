# Implementation Plan: Codebase Structure Refactor

Branch: refactor/codebase-cleanup
Created: 2026-03-09

## Settings

- Testing: no
- Logging: no

## Scope

Restructure folder layout, remove legacy patterns, and decompose god-classes for a clean, navigable codebase with zero behavior changes.

## Tasks

### Phase 1: Folder consolidation

- [x] Task 1: Merge `src/Map/` into `src/world/` — all scenes, chunks, tilesets, shaders now live under `src/world/`
- [x] Task 2: Rename `src/common/State_Machine/` to `src/common/state_machine/`
- [x] Task 3: Move `src/Utilities/music_player.gd` to `src/core/music_player.gd`
- [x] Task 4: Move `src/Utilities/icon_preview/` to `tools/icon_preview/`
- [x] Task 5: Remove `src/Utilities/` directory
- [x] Task 6: Move `src/entities/Systems/Navigation/` to `src/common/navigation/`
- [x] Task 7: Remove `src/common/Time/` (was empty)

### Phase 2: Legacy pattern removal

- [x] Task 8: Remove `EventBus` autoload — all code uses typed singletons (`PlayerEvents`, `WorldEvents`, `UIEvents`, `CreatureEvents`) directly

### Phase 3: God-class decomposition

- [x] Task 9: Extract creature selection from `overworld.gd` into `OverworldCreatureSelectionController`
- [x] Task 10: Extract character creator flow from `overworld.gd` into `OverworldCharacterCreatorController`

### Phase 4: UI cleanup

- [x] Task 11: Delete empty platform HUD variants (`system_hud_macos.gd`, `system_hud_mobile.gd`)
- [x] Task 12: Consolidate debug overlay to `src/ui/Common/Debug/`

### Phase 5: Code quality

- [x] Task 13: Standardize player component references to `@onready` typed vars

### Phase 6: Documentation

- [x] Task 14: Update `CLAUDE.md` and `DESCRIPTION.md` to reflect the refactored structure

## Acceptance Criteria

- All `src/Map/` references eliminated
- EventBus removed, typed singletons only
- `overworld.gd` decomposed into 3 files (core + 2 controllers)
- Empty UI variants removed
- Debug overlay consolidated
- Player component access uses `@onready` typed vars
- Documentation reflects new structure

## Risks / Notes

- Zero behavior changes intended — this is a pure structural refactor
- All path references in `.tscn`, `.tres`, and `project.godot` must be updated alongside folder moves
