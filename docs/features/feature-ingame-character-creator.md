# Implementation Plan: In-Game Character Creator

Branch: feature/ui
Created: 2026-03-25

## Settings
- Testing: no
- Logging: minimal

## Scope
Replace the menu-embedded CharacterCreatorPanel with an in-world customization HUD. On first Play, the player spawns in the overworld with default appearance, a side panel lets them cycle Head/Body/Legs with live preview, and "Begin Adventure" saves the choice and unlocks movement. Subsequent launches skip the creator entirely.

## Tasks

### Phase 1: Profile persistence
- [x] Task 1: Implement `has_completed_setup()` / `set_appearance(mark_complete)` in `player_profile_service.gd`
  Files: `src/Core/player_profile_service.gd`

### Phase 2: In-world creator HUD
- [x] Task 2: Create `OverworldCreatorHud` (procedural CanvasLayer, layer 28, right-side panel)
  Files: `src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd`

### Phase 3: Controller rewire
- [x] Task 3: Rewrite `OverworldCharacterCreatorController` to use PlayerEvents.player_spawned flow
  Files: `src/World/Overworld/overworld_character_creator_controller.gd`

### Phase 4: Overworld integration
- [x] Task 4: Update `overworld.gd` — remove should_open gate, begin_adventure wiring, fix initialize call
  Files: `src/World/Overworld/overworld.gd`

### Phase 5: Main screen cleanup
- [x] Task 5: Strip all CharacterCreatorPanel wiring from `main_screen.gd` and `main_screen.tscn`
  Files: `src/Ui/Desktop/Gui/MainScreen/main_screen.gd`, `src/Ui/Desktop/Gui/MainScreen/main_screen.tscn`

### Phase 6: Delete legacy files
- [x] Task 6: Delete `character_creator_panel.gd`, `.gd.uid`, `.tscn` from `src/Ui/Desktop/CharacterCreator/`

## Acceptance Criteria
- First Play: menu hides → player spawns → creator HUD fades in → cycling slots updates sprite live → "Begin Adventure" saves + unlocks movement
- Subsequent Play: creator is skipped, session starts immediately
- No remaining references to CharacterCreatorPanel in source code

## Risks / Notes
- OverworldCreatorHud is built procedurally (no .tscn) — created as child of controller in `_ready()`
- Mobile UI path is unaffected (desktop-only feature)
