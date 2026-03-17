# Implementation Plan: Main Screen UI (Ocean Variants + 9-Slice Menu)

Branch: feature/main-screen-ui
Created: 2026-02-11

## Settings
- Testing: no (assumed; not specified)
- Logging: verbose

## Scope
- Build a main in-game screen with `Play`, `Settings`, and `Quit` buttons.
- Use font from `res://Assets/Fonts/compass/Compass 9.ttf`.
- On each game start, pick one ocean background folder (`Ocean_1`..`Ocean_8`) and use only that folder's layers for the full parallax stack.
- Implement a reusable 9-slice button system where button sizes are manually configurable in the Godot editor.

## Commit Plan
- Commit 1 (after tasks 1-3): `feat(ui): add main screen scene shell with ocean background selector`
- Commit 2 (after tasks 4-6): `feat(ui): add nine-slice theme and interactive main menu controls`
- Commit 3 (after tasks 7-8): `feat(ui): integrate main screen flow with overworld bootstrap`

## Tasks

### Phase 1: Scene Skeleton + Background System
- [x] Task 1: Create `src/Entities/Ui/GUI/MainScreen/main_screen.tscn` as a `CanvasLayer`-based UI root with full-rect anchors and a dedicated `ParallaxBackground`/`Parallax2D` stack for ocean layers.
  Files: `src/Entities/Ui/GUI/MainScreen/main_screen.tscn`
  Logging: log selected ocean set id and loaded layer count at startup; warn if expected layers are missing.

- [x] Task 2: Add `src/Entities/Ui/GUI/MainScreen/ocean_background_controller.gd` that enumerates `res://src/Entities/Ui/Assets/Parallax-Backgrounds`, randomly selects one folder per run, sorts layer files numerically, and applies textures so all layers come from the same folder.
  Files: `src/Entities/Ui/GUI/MainScreen/ocean_background_controller.gd`
  Logging: log folder discovery results, chosen folder, and per-layer assignment; emit error logs if folder is unreadable.

- [x] Task 3: Wire the background controller into `main_screen.tscn` with exported controls for scroll speed multipliers and deterministic debug seed override.
  Files: `src/Entities/Ui/GUI/MainScreen/main_screen.tscn`, `src/Entities/Ui/GUI/MainScreen/ocean_background_controller.gd`
  Logging: log effective seed and speed profile so visual issues can be reproduced.

### Phase 2: 9-Slice Theme + Menu Layout
- [x] Task 4: Create a dedicated main screen theme resource that binds `Compass 9.ttf` and centralizes color/font sizing for header and menu buttons.
  Files: `src/Entities/Ui/GUI/MainScreen/main_screen_theme.tres`
  Logging: log theme/font fallback path when font load fails.

- [x] Task 5: Implement a reusable 9-slice button style using `StyleBoxTexture` resources and expose editor-friendly size knobs (`custom_minimum_size` and optional per-button width/height exports) so `Play`, `Settings`, and `Quit` can be resized manually in Inspector.
  Files: `src/Entities/Ui/GUI/MainScreen/styles/button_normal_9slice.tres`, `src/Entities/Ui/GUI/MainScreen/styles/button_hover_9slice.tres`, `src/Entities/Ui/GUI/MainScreen/styles/button_pressed_9slice.tres`, `src/Entities/Ui/GUI/MainScreen/main_screen.tscn`
  Logging: log applied margins/sizes at `_ready()` for quick inspection while tuning 9-slice behavior.

- [x] Task 6: Build the vertical menu container with three buttons (`Play`, `Settings`, `Quit`), proper focus chain for keyboard/gamepad navigation, and safe responsive anchors for mobile + desktop aspect ratios.
  Files: `src/Entities/Ui/GUI/MainScreen/main_screen.tscn`
  Logging: log focus initialization and any missing neighbor paths.

### Phase 3: Interaction Flow + Game Integration
- [x] Task 7: Add `src/Entities/Ui/GUI/MainScreen/main_screen.gd` to handle button signals: `Play` hides menu and unblocks gameplay, `Settings` opens a simple placeholder panel, `Quit` exits app (desktop-safe behavior).
  Files: `src/Entities/Ui/GUI/MainScreen/main_screen.gd`, `src/Entities/Ui/GUI/MainScreen/main_screen.tscn`
  Logging: log button actions and state transitions (`menu_open`, `menu_closed`, `settings_opened`, `quit_requested`).

- [x] Task 8: Integrate `main_screen.tscn` into startup flow (prefer attaching to `src/Map/Overworld/overworld.tscn` as a UI overlay) and ensure overworld input/movement remains blocked until `Play` is pressed.
  Files: `src/Map/Overworld/overworld.tscn`, `src/World/Overworld/overworld.gd`, `src/Entities/Ui/GUI/MainScreen/main_screen.tscn`
  Logging: log lifecycle hooks (`overworld_ready`, `menu_attached`, `play_started`) and any gating failures.

## Acceptance Criteria
- Menu appears on game start with `Play`, `Settings`, `Quit`.
- Text uses `res://Assets/Fonts/compass/Compass 9.ttf`.
- Background ocean set is randomized per startup and all layers come from one folder only.
- 9-slice button visuals scale cleanly when button sizes are changed in Inspector.
- Keyboard/gamepad focus works in button order and starts on `Play`.
- Pressing `Play` cleanly transitions from menu overlay to active gameplay.

## Risks / Notes
- Some UI textures may not be authored for ideal 9-slice margins; reserve a quick calibration pass for `StyleBoxTexture.texture_margin_*` values.
- If gameplay input gating is already managed elsewhere, reuse existing hooks instead of adding duplicate pause logic.
