# Implementation Plan: Player Appearance Customization + Character Creator

Branch: feature/player-appearance-customization
Created: 2026-02-23

## Settings
- Testing: no
- Logging: no (minimal/no extra runtime logs)

## Commit Plan
- Commit 1 (after tasks 1-3): `feat(player): add appearance resources and layered player scene`
- Commit 2 (after tasks 4-7): `feat(ui): add character creator flow and session gating`
- Commit 3 (after tasks 8-10): `feat(player): apply profile on spawn and add weapon visual seam`

## Tasks

### Phase 1: Appearance Data + Scene Foundation
- [x] Task 1: Create appearance resource models and catalog
  Description:
  - Add resource scripts for player appearance and cosmetic catalogs.
  - Define stable IDs for `head`, `body`, `legs`, and `weapon_visual`.
  - Include default/fallback appearance entry for safe startup.
  Files:
  - `src/Entities/player/resources/player_appearance_data.gd` (new)
  - `src/Entities/player/resources/player_cosmetic_catalog.gd` (new)
  - `src/Entities/player/resources/player_cosmetic_catalog.tres` (new)
  Logging requirements:
  - Keep logging minimal; only `push_warning` on invalid IDs or missing fallback entries.

- [x] Task 2: Organize layered sprite assets and register initial variants
  Description:
  - Create folder structure for layered sprites and weapon visuals.
  - Register current testing sprites (head/body/legs) in catalog entries with aligned frame strip assumptions.
  - Ensure import settings are consistent for pixel art and animation strips.
  Files:
  - `src/Entities/player/assets/<skin_id>/32x32/normal_body_idle.png` (new/moved)
  - `src/Entities/player/resources/player_cosmetic_catalog.tres`
  Logging requirements:
  - No new runtime logs; use editor-time warnings only when catalog paths are invalid.

- [x] Task 3: Refactor player scene to layered visual nodes
  Description:
  - Replace single `Sprite2D` visual dependency with layered sprite nodes under a dedicated visual root.
  - Keep compatibility with current collision, state machine, and animation flow.
  - Preserve silhouette behavior using layered silhouette or a single composed proxy strategy.
  Files:
  - `src/Entities/player/player.tscn`
  Logging requirements:
  - No extra logs unless a required visual node is missing; then warn once in debug builds.

### Phase 2: Visual Runtime + Profile Persistence
- [x] Task 4: Update `PlayerVisualComponent` for layered rendering
  Description:
  - Refactor visual component to cache typed references to layered sprite nodes.
  - Apply appearance data to textures, keep frame/flip/bob synchronized across all layers.
  - Add APIs for runtime updates: `apply_appearance(...)` and `set_weapon_visual(...)`.
  Files:
  - `src/Entities/player/components/Visual/player_visual_component.gd`
  Logging requirements:
  - Minimal warnings for missing nodes/resources; avoid frame-by-frame logging.
  Depends on: Task 3

- [x] Task 5: Add player profile persistence service
  Description:
  - Create a lightweight autoload service to load/save selected appearance to `user://`.
  - Track first-run completion flag for character setup gate.
  - Keep API simple: `get_appearance()`, `set_appearance(...)`, `has_completed_setup()`.
  Files:
  - `src/Core/player_profile_service.gd` (new)
  - `project.godot` (autoload entry)
  Logging requirements:
  - Minimal startup/save/load warnings on failure paths only.
  Depends on: Task 1

- [x] Task 6: Apply profile appearance when player spawns
  Description:
  - Read appearance from profile service during spawn/session start.
  - Inject appearance into player visual component after instantiation.
  - Keep fallback to default appearance when profile is absent/corrupt.
  Files:
  - `src/World/overworld/overworld_player_spawner.gd`
  - `src/Entities/player/player.gd` (if setup hook is needed)
  Logging requirements:
  - Single warning on fallback usage; no per-frame logs.
  Depends on: Task 4, Task 5

### Phase 3: Character Creator Flow
- [x] Task 7: Create character creator UI panel (desktop first, adaptive layout)
  Description:
  - Build a creator panel with controls to cycle `head/body/legs`, preview result, randomize, confirm, cancel.
  - Use current UI conventions and responsive behavior compatible with mobile safe areas.
  - Expose signals for confirm/cancel and selected appearance payload.
  Files:
  - `src/Ui/desktop/character_creator/character_creator_panel.tscn` (new)
  - `src/Ui/desktop/character_creator/character_creator_panel.gd` (new)
  - `src/Ui/common/ui_manager.gd` (if scene replacement/profile variant handling is required)
  Logging requirements:
  - No extra interaction logs; warn only on missing preview dependencies.
  Depends on: Task 1, Task 4

- [x] Task 8: Gate session start with creator flow on first launch
  Description:
  - Integrate creator panel into overworld startup flow.
  - On Play: if setup incomplete, show creator and defer `start_session()`.
  - On confirm: save profile, hide creator, then start session.
  - On cancel: return to main menu state without starting session.
  Files:
  - `src/World/overworld/overworld.tscn`
  - `src/World/overworld/overworld.gd`
  - `src/World/overworld/overworld_session_controller.gd` (if guard is needed)
  - `src/Ui/desktop/main_screen/main_screen.gd` (only if signal flow needs adjustment)
  Logging requirements:
  - Keep minimal lifecycle logs for session gate transitions in debug only.
  Depends on: Task 5, Task 7

### Phase 4: Weapon Visual Seam + Validation
- [x] Task 9: Add weapon visual seam for future equipment integration
  Description:
  - Define weapon visual mapping strategy (`weapon_visual_id`) and apply via `PlayerVisualComponent` front/back weapon layers.
  - Add a temporary update hook so weapon visuals can be switched dynamically at runtime.
  - Keep this decoupled from full equipment logic to enable later integration.
  Files:
  - `src/Entities/player/components/Visual/player_visual_component.gd`
  - `src/Entities/player/resources/player_cosmetic_catalog.gd`
  - `src/Entities/items/item_data.gd` (optional prop key convention)
  Logging requirements:
  - Warn on unknown weapon visual IDs; no repeated logs.
  Depends on: Task 4

- [ ] Task 10: Manual runtime validation (desktop + mobile parity)
  Description:
  - Validate full flow on desktop and mobile-oriented runtime configuration:
    - Splash -> Main Menu -> Character Creator -> Session Start
    - Appearance persistence across restart
    - Layer animation sync (idle/move/flip/bob)
    - Weapon layer visibility switching
    - UI interaction parity for mouse and touch
  - Fix any discovered regressions in startup/UI/session wiring.
  Files:
  - `src/World/overworld/overworld.gd`
  - `src/World/overworld/overworld.tscn`
  - `src/Ui/desktop/character_creator/*`
  - `src/Ui/mobile/character_creator/*`
  - `src/Entities/player/*`
  Logging requirements:
  - No permanent extra logs; temporary debug logs allowed and removed before completion.
  Depends on: Task 6, Task 8, Task 9
