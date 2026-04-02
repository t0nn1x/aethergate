# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Running the game
```bash
# Open in Godot editor
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/antonkhrobust/User/aethergate

# Run headless (no display)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path .
```

### Tests
```bash
# Creature catalog validation
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/entities/creatures/tests/run_creature_catalog_validation.gd

# Creature runtime smoke test
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200

# Creature spawn zone validation
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/entities/creatures/tests/run_creature_spawn_zone_test.gd

# Player profile migration test
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/entities/player/tests/run_player_profile_migration_test.gd
```

### Creature content pipeline
When new creature art is added, rebuild the catalog:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://src/entities/creatures/tools/creature_catalog_builder_runner.tscn --quit
```

### iOS build
```bash
bash scripts/build-ios.sh
```

## Architecture

### Composition root
`src/world/main.tscn` / `main.gd` is the runtime root. It listens to `GameManager.game_state_changed` and swaps Overworld ↔ CombatScene. Startup is via `src/ui/common/startup_splash_screen.tscn`.

### Autoloaded services (singletons)
Registered in `project.godot` `[autoload]`:

| Autoload | File | Role |
|---|---|---|
| `ProjectConfig` | `src/config/project_config_service.gd` | Runtime config & platform profile |
| `GameManager` | `src/core/game_manager.gd` | Global state machine (see below) |
| `PlayerProfileService` | `src/core/player_profile_service.gd` | Persistent player data → `user://player_profile.cfg` |
| `LocalizationService` | `src/localization/localization_service.gd` | Runtime locale switching |
| `PlatformDisplaySettings` | `src/core/platform_display_settings.gd` | Viewport/display tuning per platform |
| `MusicPlayer` | `src/core/music_player.gd` | Music and UI sound playback |
| `PlayerEvents` | `src/core/events/player_events.gd` | Domain event hub |
| `WorldEvents` | `src/core/events/world_events.gd` | Domain event hub |
| `UIEvents` | `src/core/events/ui_events.gd` | Domain event hub |
| `CreatureEvents` | `src/core/events/creature_events.gd` | Domain event hub |
| `CombatEvents` | `src/core/events/combat_events.gd` | Domain event hub |

### Game state machine
`GameManager` enforces allowed transitions between `MAIN_MENU → LOADING → OVERWORLD ↔ LOCATION ↔ COMBAT`. Invalid transitions are rejected with a push_error. `PAUSED` can be entered from any in-game state.

### Event-driven communication
Use the typed domain event hubs (e.g. `CreatureEvents.creature_selected.emit(creature)`), not a global EventBus. Direct node references are only for parent→child relationships.

### Creature content pipeline
Creatures are data-driven: art goes in `src/entities/creatures/catalog/<category>/<creature_name>/sprites/<name>_128x32.png` (4-frame, 32×32 each). The builder tool generates `creature_data.tres` and updates `creature_catalog.tres` automatically. Do not edit the catalog resource by hand.

### Platform-split UI
`src/ui/common/ui_manager.gd` swaps platform scene variants at runtime. Platform is resolved: mobile → macOS → Windows. Mobile scenes extend their desktop counterpart and override layout before `super._ready()`. `AdaptiveOverlayPanel` (`src/ui/common/overlay/`) is the base class for all overlay panels — it handles safe-area margins and viewport-resize signals.

### Component pattern
Player (`src/entities/player/`) and Creatures (`src/entities/creatures/`) use typed component nodes (`PlayerMovementComponent`, `CreatureNavigationComponent`, etc.) wired via `@onready`. State machines live in `states/` subdirectories.

### Localization
`LocalizationService.translate_key(&"ui.some.key")`. Keys must be defined in both `src/localization/translations/ui_en.tres` and `ui_uk.tres`. Save translation files as UTF-8 without BOM.

### Chunked overworld
`ChunkManager` (`src/world/streaming/`) loads/unloads world chunks dynamically. Creatures register with ChunkManager and despawn on chunk unload. `NavigationBlockerRegistry` maintains pathfinding exclusion zones.

## Code conventions

- **Static typing everywhere:** `var x: float`, `func foo(a: int) -> void`
- **`class_name` on all reusable classes**
- **Signals declared at top of file**
- **Naming:** `snake_case` files/vars/funcs, `PascalCase` classes, `SCREAMING_SNAKE_CASE` constants
- **No global EventBus** — use domain-specific event hub autoloads
- **No `get_node()` in hot paths** — use `@onready` typed references

## Folder conventions

Structure is functionality-first:
- `src/core/` — app-level services and event hubs
- `src/config/` — configuration resources and services
- `src/entities/` — all game-world actors (player, creatures, items, systems)
- `src/ui/` — UI only; split into `common/`, `desktop/`, `mobile/`, `hud/`
- `src/world/` — scenes and controllers (overworld, combat, locations, streaming)
- `src/common/` — truly reusable runtime utilities (state machine, shaders, navigation)
- `src/localization/` — localization service and translation resources

Each domain folder follows: root scripts + `.tscn`, `components/`, `states/`, `resources/`, `tests/`, `tools/`.
