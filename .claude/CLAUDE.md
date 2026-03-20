# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Aethergate** is a Godot 4.6 mobile-first RPG (GDScript only). The viewport defaults to portrait `1080x1920` on mobile and landscape `1920x1080` on desktop. The rendering backend is `mobile`.

Entry scene: `res://src/Ui/Common/startup_splash_screen.tscn`
Gameplay scene: `res://src/World/main.tscn` → loads `Overworld` which is the composition root.

## Running the Game / Headless Commands

Open the project in the Godot 4.6 editor and press F5, or use the CLI:

```bash
# Run the game (GUI)
godot4 --path .

# Rebuild the creature catalog (headless)
godot4 --headless --path . --scene res://src/Entities/Creatures/Tools/creature_catalog_builder_runner.tscn --quit

# Rebuild the player cosmetic catalog (headless)
godot4 --headless --path . --scene res://src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn --quit
```

## Running Tests

All tests are headless Godot scripts/scenes:

```bash
# Creature catalog validation
godot4 --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd

# Creature runtime smoke test (runs for 200 frames)
godot4 --headless --path . --scene res://src/Entities/Creatures/Tests/creature_runtime_smoke_test.tscn --quit-after 200

# Creature spawn zone validation
godot4 --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_spawn_zone_test.gd
```

## Architecture

### Autoloads (global singletons, order matters)

Registered in `project.godot [autoload]`:

| Singleton | Path | Role |
|---|---|---|
| `ProjectConfig` | `src/Config/project_config_service.gd` | Global config + active platform profile (mobile/desktop) |
| `PlayerProfileService` | `src/Core/player_profile_service.gd` | Persists player cosmetics to `user://player_profile.cfg` |
| `LocalizationService` | `src/Localization/localization_service.gd` | Runtime locale switching (en/uk) |
| `PlatformDisplaySettings` | `src/Core/platform_display_settings.gd` | Viewport tweaks per platform |
| `PlayerEvents` | `src/Core/Events/player_events.gd` | Bounded-context events for player |
| `WorldEvents` | `src/Core/Events/world_events.gd` | Bounded-context events for world |
| `UIEvents` | `src/Core/Events/ui_events.gd` | Bounded-context events for UI |
| `CreatureEvents` | `src/Core/Events/creature_events.gd` | Bounded-context events for creatures |
| `GameManager` | `src/Core/game_manager.gd` | Game state machine (MAIN_MENU → OVERWORLD → COMBAT etc.) |
| `MusicPlayer` | `src/Core/music_player.gd` | Background music |

### Scene / Layer Architecture

```
src/World/main.tscn          ← root; loads overworld
  └─ src/World/Overworld/overworld.gd  ← composition root
       ├─ Terrain / Navigation
       ├─ ChunkManager (src/World/Streaming/)   ← streams tilemap chunks by player position
       ├─ OverworldPlayerSpawner                ← spawns player into $Entities
       ├─ OverworldCreatureSpawner              ← zone/marker-driven creature spawning
       ├─ NavigationBlockerRegistry             ← tracks Polygon2D blockers for nav
       ├─ OverworldSessionController            ← orchestrates session start/end
       ├─ OverworldCreatureSelectionController  ← creature tap/selection handling
       ├─ OverworldCharacterCreatorController   ← character creator flow orchestration
       └─ UI nodes (UiManager, MainScreen, CreatureActionHud)
```

### Player Architecture (componentized)

`src/Entities/Player/player.gd` is the root; child components are accessed via `@onready` typed vars (e.g., `@onready var movement: PlayerMovementComponent = $Components/Movement/PlayerMovementComponent`):

- `Components/Input/` — `PlayerInputComponent` + `PlayerMovePointerComponent`
- `Components/Movement/` — `PlayerMovementComponent` (NavigationAgent2D-based click-to-move)
- `Components/Camera/` — `PlayerCameraComponent` + pinch-zoom tracker
- `Components/Visual/` — `PlayerVisualComponent` (cosmetic sprite sheet)
- `Components/Core/` — `PlayerContext` (shared state bag)
- `Components/` (implicit) — `PlayerMoveTargetBlockerComponent` wired via `Overworld`
- `States/` — `PlayerIdleState`, `PlayerPathMoveState` (use `src/Common/StateMachine/`)
- `Services/` — `PlayerMoveRequestService`
- `Input/` — `PlayerMouseInputAdapter`, `PlayerTouchInputAdapter`

### Creature Architecture (data-driven)

- Data resource: `CreatureData` (`.tres`) under `src/Entities/Creatures/Types/<Category>/<Name>/Data/`
- Catalog: `src/Entities/Creatures/Resources/creature_catalog.tres` — rebuilt by headless tool
- Factory: `creature_factory.gd` instantiates creatures from catalog
- Components per creature: `CreatureMovementComponent`, `CreatureWanderComponent`, `CreatureVisualComponent`, `PlayerMoveTargetBlockerComponent`
- Spawning: `OverworldCreatureSpawner` listens to `ChunkManager.chunk_loaded/chunk_unloaded`; spawn rules come from `CreatureSpawnZone` (`Polygon2D` + script) or legacy `Marker2D` fallback

### Item Architecture (data-driven)

- Data resource: `ItemData` (`.tres`) under `src/Entities/Items/Types/<Category>/.../<ItemName>/Data/`
- Starter inventory: `src/Entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- Systems under `src/Entities/Systems/`: Inventory, Equipment, Crafting, Loot
- Navigation utilities: `src/Common/Navigation/`

### UI Architecture (platform-split)

`UiManager` (`src/Ui/Common/ui_manager.gd`) selects scenes at runtime:

- `src/Ui/Desktop/` — desktop HUD, inventory, character creator, main screen (used on Windows and macOS)
- `src/Ui/Mobile/` — mobile HUD, inventory
- `src/Ui/Common/` — shared primitives: `AdaptiveOverlayPanel`, style profiles, `UiManager`
- `src/Ui/Hud/` — shared cross-platform HUD (e.g., `creature_action_hud.tscn`)

All new overlay panels should extend `AdaptiveOverlayPanel` for safe-area-aware margins.

### Configuration

Runtime config is split into two layers:

1. `AetherProjectConfig` resource (`src/Config/project_config.tres`) holds platform profiles + input/movement config resources
2. `ProjectConfigService` autoload selects the active `GamePlatformProfile` based on detected platform (`src/Config/Platform/`)

### Localization

- Keys pattern: `ui.<screen>.<key>` (e.g., `ui.main.play`)
- Locale files: `src/Localization/Translations/ui_en.tres`, `ui_uk.tres`
- **Important:** Save `.tres` files as UTF-8 **without BOM** — BOM causes parse errors
- Access from scripts via `LocalizationService.translate_key(&"ui.main.play")`; UI panels should connect to `LocalizationService.locale_changed` to refresh text

### Chunk / World Streaming

- Chunks live in `src/World/Overworld/Chunks/` (`.tscn` scenes)
- `ChunkManager` (`src/World/Streaming/chunk_manager.gd`) loads/unloads chunks as the player moves
- `NavigationBlockerRegistry` is refreshed whenever chunks change (`Overworld._on_chunks_changed`)
- `ChunkBorderStitcher` (`src/World/Streaming/`) merges nav meshes across chunk seams

### Physics Layers (2D)

| Layer | Name |
|---|---|
| 1 | World |
| 2 | Player |
| 3 | Enemies |
| 4 | Projectiles |
| 5 | Interactables |
| 6 | Triggers |
| 7 | Resources |
| 8 | Pvp |

## Documentation

The `doc/` folder is the project's living knowledge base. **Update or create docs as part of every session where a feature is implemented or a bug is fixed.**

### Folder layout

```
doc/
  DESCRIPTION.md          ← high-level project snapshot (update when architecture changes)
  features/               ← one file per feature, created before/during implementation
  patches/                ← one file per bug fix, created after the fix lands
```

### Feature docs (`doc/features/feature-<slug>.md`)

Create one when starting a new feature. Keep tasks checked off as work progresses. Update the file if scope changes.

Template:
```markdown
# Implementation Plan: <Feature Name>

Branch: feature/<slug>
Created: YYYY-MM-DD

## Settings
- Testing: yes/no
- Logging: yes/no/minimal

## Scope
<short description of what this delivers>

## Commit Plan
- Commit 1 (after tasks 1-N): `feat(<scope>): <message>`

## Tasks

### Phase 1: <Name>
- [ ] Task 1: <description>
  Files: `path/to/file.gd`
  Logging: <none/minimal/verbose>

## Acceptance Criteria
- <observable outcome>

## Risks / Notes
- <anything worth flagging>
```

### Patch docs (`doc/patches/YYYY-MM-DD-HH.mm.md`)

Create one after every bug fix. Use today's date and 24h time (`HH.mm`) in the filename.

Template:
```markdown
# <Short title describing the bug>

**Date:** YYYY-MM-DD HH:MM
**Files:** `path/to/changed_file.gd`, `path/to/other.tscn`
**Severity:** low | medium | high

## Problem
<What the user saw>

## Root Cause
<Why it happened>

## Solution
<What was changed and why>

## Prevention
<How to avoid this class of bug in future>

## Tags
`#godot` `#<domain>` `#<area>`
```

### When to update the `README.md` files inside `src/`

Each major subsystem has its own `README.md` (e.g., `src/Entities/Creatures/README.md`, `src/Localization/README.md`). Update the relevant README whenever:
- A new workflow step is added (e.g., new catalog builder, new test command)
- Runtime behavior of the subsystem changes in a way that affects authoring
- A troubleshooting entry would have saved time during this session

## Key Conventions

- **Event routing:** emit on the typed event singleton (`PlayerEvents`, `WorldEvents`, `UIEvents`, `CreatureEvents`) only — there is no legacy EventBus
- **State machine:** extend `src/Common/StateMachine/state.gd` for entity states
- **Component access:** use `@onready` typed vars for player/entity component references (no runtime `get_node_or_null`)
- **Catalog IDs:** snake_case, deterministic (`<category>_<folder-slug>`); rebuild via headless tool after adding art
- **Creature tap priority:** creature selection input is consumed before move-click on the same event
- **`PlayerMoveTargetBlockerComponent`:** must be present on both player and creature scenes for blocked-polygon nav avoidance to work

### CanvasLayer layer values are always absolute

In Godot 4, `CanvasLayer.layer` is **always absolute** — nesting a CanvasLayer inside another does **not** make the inner layer relative to the outer. A `CombatResultPanel` at `layer = 10` inside a `CombatScene` CanvasLayer at `layer = 50` still renders at absolute layer 10, which is **below** the parent's content.

**Rule of thumb:** assign `layer` values that are self-contained and globally meaningful. Do not assume nesting gives you additive/relative layers. When a scene is a full-screen overlay that gets added on top of the world, make the scene root itself a `CanvasLayer` with an explicit `layer` value, and size any inner CanvasLayers (result panels, HUDs) above it.

**Established layer budget:**

| Range | Owner |
| ----- | ----- |
| 0 | World (Node2D terrain, entities) |
| 20–40 | Overworld HUD (creature HUD 30, system HUD 26, main screen 30, combat preview 35) |
| 50 | Combat scene (`CombatScene` root CanvasLayer) |
| 55 | Combat result panel |
| 90 | Inventory screen |
| 100 | Debug overlay, startup splash |

## Available Skills

Project-specific skills in `.claude/skills/` (invoke with the `Skill` tool):

- `godot-best-practices` — Godot 4 patterns, node communication, project structure
- `godot-development` — general Godot dev workflow
- `godot-gdscript-patterns` — GDScript idioms
- `godot-ui` — UI/UX patterns
- `godot-dialogue-system`, `godot-multiplayer-networking`, `godot-audio-systems`, `godot-adapt-desktop-to-mobile` — domain-specific guides
