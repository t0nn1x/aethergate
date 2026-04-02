# Src Structure Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize `src/` into a predictable feature-first layout with normalized `snake_case` runtime paths while preserving behavior and keeping shared asset roots such as `src/ui/assets` in place.

**Architecture:** Execute the refactor as a sequence of small rename-and-reference-update passes. Each pass updates moved paths atomically across scripts, scenes, resources, docs, and generated catalogs, then verifies both stale-path removal and project loadability before moving on. Because this repository is on Windows, case-only renames must use temporary intermediate folder names instead of direct `PascalCase` to `snake_case` renames.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` scenes, `.tres` resources, PowerShell, `rg`, git

---

## File Map

### Shared infrastructure paths

- `project.godot`
- `src/common/Navigation/`
- `src/common/Shaders/`
- `src/common/StateMachine/`
- `src/core/Events/`
- `src/config/Platform/`
- `src/localization/Translations/`
- `src/localization/localization_service.gd`
- `src/localization/README.md`

### UI runtime paths

- `src/ui/common/ui_manager.gd`
- `src/ui/common/startup_splash_screen.tscn`
- `src/ui/common/CombatPreviewPanel/combat_preview_panel.tscn`
- `src/ui/common/CombatResultPanel/combat_result_panel.tscn`
- `src/ui/common/Debug/debug_panel.gd`
- `src/ui/common/Styles/Profiles/*.tres`
- `src/ui/common/inventory_screen.tscn`
- `src/ui/desktop/main_screen/main_screen.gd`
- `src/ui/desktop/main_screen/main_screen.tscn`
- `src/ui/desktop/main_screen/main_screen_desktop.gd`
- `src/ui/desktop/main_screen/background_controller.gd`
- `src/ui/desktop/main_screen/main_screen_theme.tres`
- `src/ui/desktop/character_creator/character_creator_panel.tscn`
- `src/ui/desktop/Combat/desktop_combat_ui.tscn`
- `src/ui/desktop/Debug/debug_overlay.tscn`
- `src/ui/desktop/hud/system_hud/system_hud.tscn`
- `src/ui/desktop/inventory/inventory_panel.gd`
- `src/ui/desktop/inventory/inventory_panel.tscn`
- `src/ui/desktop/inventory/inventory_screen.tscn`
- `src/ui/mobile/main_screen/main_screen_mobile.gd`
- `src/ui/mobile/main_screen/main_screen_mobile.tscn`
- `src/ui/mobile/character_creator/character_creator_panel_mobile.tscn`
- `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn`
- `src/ui/mobile/inventory/inventory_panel_mobile.tscn`
- `src/ui/hud/creature_action_hud.tscn`

### World runtime paths

- `src/world/main.gd`
- `src/world/main.tscn`
- `src/world/combat/combat_scene.tscn`
- `src/world/overworld/overworld.gd`
- `src/world/overworld/overworld.tscn`
- `src/world/overworld/overworld_player_spawner.gd`
- `src/world/overworld/overworld_creature_spawner.gd`
- `src/world/overworld/overworld_character_creator_controller.gd`
- `src/world/overworld/overworld_creature_selection_controller.gd`
- `src/world/overworld/overworld_session_controller.gd`
- `src/world/overworld/navigation_blocker_registry.gd`
- `src/world/overworld/chunks/chunk.gd`
- `src/world/streaming/chunk_manager.gd`
- `src/world/streaming/overworld_chunk_water_shader.gd`
- `src/world/locations/dungeons/ancient_ruins/`
- `src/world/locations/dungeons/goblin_cave/`
- `src/world/locations/dungeons/goblin_cave/Encounters/`
- `src/world/locations/interiors/house_interior/`
- `src/world/locations/interiors/shop_interior/`
- `src/world/locations/towns/capital_city/`
- `src/world/locations/towns/starting_village/`
- `src/world/locations/towns/starting_village/npcs/`

### Entities runtime and generated content

- `src/entities/Creatures/creature.gd`
- `src/entities/Creatures/creature.tscn`
- `src/entities/Creatures/creature_catalog.gd`
- `src/entities/Creatures/creature_catalog_service.gd`
- `src/entities/Creatures/creature_data.gd`
- `src/entities/Creatures/creature_factory.gd`
- `src/entities/Creatures/README.md`
- `src/entities/Creatures/Tools/creature_catalog_builder.gd`
- `src/entities/Creatures/Tools/creature_catalog_builder_runner.gd`
- `src/entities/Creatures/Tools/creature_catalog_builder_runner.tscn`
- `src/entities/Creatures/Resources/creature_catalog.tres`
- `src/entities/Creatures/Types/*/*/Data/*.tres` via catalog regeneration
- `src/entities/Items/item_data.gd`
- `src/entities/Items/README.md`
- `src/entities/Items/Types/*/*/*/Data/*.tres`
- `src/entities/Player/player.gd`
- `src/entities/Player/player.tscn`
- `src/entities/Player/Config/player_input_config.tres`
- `src/entities/Player/Config/player_movement_config.tres`
- `src/entities/Player/Tools/player_cosmetic_catalog_builder.gd`
- `src/entities/Player/Tools/player_cosmetic_catalog_builder_runner.gd`
- `src/entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn`
- `src/entities/Player/Tools/README.md`
- `src/entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- `src/entities/Systems/Combat/Tests/run_combat_tests.gd`

### Documentation paths

- `docs/DESCRIPTION.md`
- `docs/features/feature-creature-system-foundation.md`
- `docs/features/feature-creature-wander-nav-respect.md`
- `docs/features/feature-item-system-combat-inventory.md`
- `docs/features/feature-main-screen-ui.md`
- `docs/features/feature-player-appearance-customization.md`
- `docs/features/feature-tappable-overworld-creatures.md`

### Rename conventions to apply

- `src/common/Navigation` -> `src/common/navigation`
- `src/common/Shaders` -> `src/common/shaders`
- `src/common/StateMachine` -> `src/common/state_machine`
- `src/core/Events` -> `src/core/events`
- `src/config/Platform` -> `src/config/platform`
- `src/localization/Translations` -> `src/localization/translations`
- `src/ui/common` -> `src/ui/common`
- `src/ui/desktop` -> `src/ui/desktop`
- `src/ui/mobile` -> `src/ui/mobile`
- `src/ui/common/CombatPreviewPanel` -> `src/ui/common/combat_preview_panel`
- `src/ui/common/CombatResultPanel` -> `src/ui/common/combat_result_panel`
- `src/ui/common/Debug` -> `src/ui/common/debug`
- `src/ui/common/Styles` -> `src/ui/common/styles`
- `src/ui/common/Styles/Profiles` -> `src/ui/common/styles/profiles`
- `src/ui/desktop/main_screen` -> `src/ui/desktop/main_screen`
- `src/ui/mobile/main_screen` -> `src/ui/mobile/main_screen`
- `src/ui/desktop/CharacterCreator` -> `src/ui/desktop/character_creator`
- `src/ui/desktop/Combat` -> `src/ui/desktop/combat`
- `src/ui/desktop/Debug` -> `src/ui/desktop/debug`
- `src/ui/desktop/Hud` -> `src/ui/desktop/hud`
- `src/ui/desktop/Hud/SystemHud` -> `src/ui/desktop/hud/system_hud`
- `src/ui/desktop/Inventory` -> `src/ui/desktop/inventory`
- `src/ui/mobile/CharacterCreator` -> `src/ui/mobile/character_creator`
- `src/ui/mobile/Combat` -> `src/ui/mobile/combat`
- `src/ui/mobile/Hud` -> `src/ui/mobile/hud`
- `src/ui/mobile/Hud/SystemHud` -> `src/ui/mobile/hud/system_hud`
- `src/ui/mobile/Inventory` -> `src/ui/mobile/inventory`
- `src/ui/hud` -> `src/ui/hud`
- `src/world/combat` -> `src/world/combat`
- `src/world/locations` -> `src/world/locations`
- `src/world/overworld` -> `src/world/overworld`
- `src/world/streaming` -> `src/world/streaming`
- `src/world/locations/Arenas` -> `src/world/locations/arenas`
- `src/world/locations/Dungeons` -> `src/world/locations/dungeons`
- `src/world/locations/Interiors` -> `src/world/locations/interiors`
- `src/world/locations/Towns` -> `src/world/locations/towns`
- `src/world/overworld/chunks` -> `src/world/overworld/chunks`
- `src/world/overworld/shaders` -> `src/world/overworld/shaders`
- `src/world/overworld/tilesets` -> `src/world/overworld/tilesets`
- `src/entities/Creatures` -> `src/entities/creatures`
- `src/entities/Creatures/Types` -> `src/entities/creatures/catalog`
- `src/entities/creatures/Components` -> `src/entities/creatures/components`
- `src/entities/creatures/Effects` -> `src/entities/creatures/effects`
- `src/entities/creatures/Resources` -> `src/entities/creatures/resources`
- `src/entities/creatures/Spawning` -> `src/entities/creatures/spawning`
- `src/entities/creatures/Tests` -> `src/entities/creatures/tests`
- `src/entities/creatures/Tools` -> `src/entities/creatures/tools`
- `src/entities/creatures/catalog/*/*/Data` -> `src/entities/creatures/catalog/*/*/data`
- `src/entities/creatures/catalog/*/*/Sprites` -> `src/entities/creatures/catalog/*/*/sprites`
- `src/entities/Player` -> `src/entities/player`
- `src/entities/player/Assets` -> `src/entities/player/assets`
- `src/entities/player/Components` -> `src/entities/player/components`
- `src/entities/player/Config` -> `src/entities/player/config`
- `src/entities/player/Input` -> `src/entities/player/input`
- `src/entities/player/Resources` -> `src/entities/player/resources`
- `src/entities/player/Services` -> `src/entities/player/services`
- `src/entities/player/Sounds` -> `src/entities/player/sounds`
- `src/entities/player/States` -> `src/entities/player/states`
- `src/entities/player/Tests` -> `src/entities/player/tests`
- `src/entities/player/Tools` -> `src/entities/player/tools`
- `src/entities/Items` -> `src/entities/items`
- `src/entities/Items/Types` -> `src/entities/items/catalog`
- `src/entities/items/catalog/*/*/*/Data` -> `src/entities/items/catalog/*/*/*/data`
- `src/entities/items/catalog/*/*/*/Sprites` -> `src/entities/items/catalog/*/*/*/sprites`
- `src/entities/Interactables` -> `src/entities/interactables`
- `src/entities/Skills` -> `src/entities/skills`
- `src/entities/Systems` -> `src/entities/systems`
- `src/entities/systems/Combat` -> `src/entities/systems/combat`
- `src/entities/systems/Inventory` -> `src/entities/systems/inventory`

### Windows rename note

Use temporary names for case-only renames:

```powershell
Rename-Item src/ui/desktop src/ui/__desktop_tmp
Rename-Item src/ui/__desktop_tmp src/ui/desktop
```

Use the same pattern for every case-only rename in this plan.

### Task 1: Normalize Shared Infrastructure Paths

**Files:**
- Modify: `project.godot`
- Modify: `src/config/aether_project_config.gd`
- Modify: `src/config/project_config.tres`
- Modify: `src/config/Platform/desktop_platform_profile.tres`
- Modify: `src/config/Platform/mobile_platform_profile.tres`
- Modify: `src/localization/localization_service.gd`
- Modify: `src/localization/README.md`
- Modify: `src/entities/Creatures/creature.tscn`
- Modify: `src/entities/Player/player.tscn`
- Rename: `src/common/Navigation/` -> `src/common/navigation/`
- Rename: `src/common/Shaders/` -> `src/common/shaders/`
- Rename: `src/common/StateMachine/` -> `src/common/state_machine/`
- Rename: `src/core/Events/` -> `src/core/events/`
- Rename: `src/config/Platform/` -> `src/config/platform/`
- Rename: `src/localization/Translations/` -> `src/localization/translations/`

- [ ] **Step 1: Record the current reference surface**

```powershell
rg -n "src/common/Navigation|src/common/Shaders|src/common/StateMachine|src/core/Events|src/config/Platform|src/localization/Translations" src project.godot
```

Expected: matches in `project.godot`, config resources, localization files, and any scene/script that still references the old directories.

- [ ] **Step 2: Rename the shared folders with Windows-safe temporary names**

```powershell
Rename-Item src/common/Navigation src/common/__navigation_tmp
Rename-Item src/common/__navigation_tmp src/common/navigation
Rename-Item src/common/Shaders src/common/__shaders_tmp
Rename-Item src/common/__shaders_tmp src/common/shaders
Rename-Item src/common/StateMachine src/common/__state_machine_tmp
Rename-Item src/common/__state_machine_tmp src/common/state_machine
Rename-Item src/core/Events src/core/__events_tmp
Rename-Item src/core/__events_tmp src/core/events
Rename-Item src/config/Platform src/config/__platform_tmp
Rename-Item src/config/__platform_tmp src/config/platform
Rename-Item src/localization/Translations src/localization/__translations_tmp
Rename-Item src/localization/__translations_tmp src/localization/translations
```

- [ ] **Step 3: Update autoload, config, and localization references**

```ini
; project.godot
run/main_scene="res://src/ui/common/startup_splash_screen.tscn"
ProjectConfig="*res://src/config/project_config_service.gd"
LocalizationService="*res://src/localization/localization_service.gd"
PlayerEvents="*res://src/core/events/player_events.gd"
WorldEvents="*res://src/core/events/world_events.gd"
UIEvents="*res://src/core/events/ui_events.gd"
CreatureEvents="*res://src/core/events/creature_events.gd"
CombatEvents="*res://src/core/events/combat_events.gd"
locale/translations=PackedStringArray("res://src/localization/translations/ui_en.tres", "res://src/localization/translations/ui_uk.tres")
```

```gdscript
# src/localization/localization_service.gd
const DEFAULT_TRANSLATIONS: PackedStringArray = [
	"res://src/localization/translations/ui_en.tres",
	"res://src/localization/translations/ui_uk.tres",
]
```

- [ ] **Step 4: Update remaining explicit path strings**

```powershell
rg -l "src/common/Navigation|src/common/Shaders|src/common/StateMachine|src/core/Events|src/config/Platform|src/localization/Translations" src project.godot |
ForEach-Object { $_ }
```

Then update every returned file so the old path fragments become:

```text
src/common/navigation
src/common/shaders
src/common/state_machine
src/core/events
src/config/platform
src/localization/translations
```

- [ ] **Step 5: Verify the old shared paths are gone**

```powershell
rg -n "src/common/Navigation|src/common/Shaders|src/common/StateMachine|src/core/Events|src/config/Platform|src/localization/Translations" src project.godot
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add project.godot src/common src/core src/config src/localization src/entities/Creatures/creature.tscn src/entities/Player/player.tscn
git commit -m "refactor: normalize shared runtime folder names"
```

### Task 2: Normalize UI Runtime Layout

**Files:**
- Modify: `project.godot`
- Modify: `src/ui/common/ui_manager.gd`
- Modify: `src/ui/common/startup_splash_screen.tscn`
- Modify: `src/ui/common/CombatPreviewPanel/combat_preview_panel.tscn`
- Modify: `src/ui/common/CombatResultPanel/combat_result_panel.tscn`
- Modify: `src/ui/common/Debug/debug_panel.gd`
- Modify: `src/ui/common/Styles/Profiles/inventory_board_style.tres`
- Modify: `src/ui/common/Styles/Profiles/inventory_section_style.tres`
- Modify: `src/ui/common/Styles/Profiles/inventory_title_style.tres`
- Modify: `src/ui/common/inventory_screen.tscn`
- Modify: `src/ui/desktop/main_screen/main_screen.gd`
- Modify: `src/ui/desktop/main_screen/main_screen.tscn`
- Modify: `src/ui/desktop/main_screen/main_screen_desktop.gd`
- Modify: `src/ui/desktop/main_screen/background_controller.gd`
- Modify: `src/ui/desktop/main_screen/main_screen_theme.tres`
- Modify: `src/ui/desktop/character_creator/character_creator_panel.tscn`
- Modify: `src/ui/desktop/Combat/desktop_combat_ui.tscn`
- Modify: `src/ui/desktop/Debug/debug_overlay.tscn`
- Modify: `src/ui/desktop/hud/system_hud/system_hud.tscn`
- Modify: `src/ui/desktop/inventory/inventory_panel.gd`
- Modify: `src/ui/desktop/inventory/inventory_panel.tscn`
- Modify: `src/ui/desktop/inventory/inventory_screen.tscn`
- Modify: `src/ui/mobile/main_screen/main_screen_mobile.gd`
- Modify: `src/ui/mobile/main_screen/main_screen_mobile.tscn`
- Modify: `src/ui/mobile/character_creator/character_creator_panel_mobile.tscn`
- Modify: `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn`
- Modify: `src/ui/mobile/inventory/inventory_panel_mobile.tscn`
- Modify: `src/ui/hud/creature_action_hud.tscn`
- Modify: `src/world/overworld/overworld.tscn`
- Modify: `src/world/combat/combat_scene.tscn`
- Rename: `src/ui/common/` -> `src/ui/common/`
- Rename: `src/ui/desktop/` -> `src/ui/desktop/`
- Rename: `src/ui/mobile/` -> `src/ui/mobile/`
- Rename: `src/ui/hud/` -> `src/ui/hud/`
- Rename: `src/ui/common/CombatPreviewPanel/` -> `src/ui/common/combat_preview_panel/`
- Rename: `src/ui/common/CombatResultPanel/` -> `src/ui/common/combat_result_panel/`
- Rename: `src/ui/common/Debug/` -> `src/ui/common/debug/`
- Rename: `src/ui/common/Styles/` -> `src/ui/common/styles/`
- Rename: `src/ui/common/styles/Profiles/` -> `src/ui/common/styles/profiles/`
- Rename: `src/ui/desktop/CharacterCreator/` -> `src/ui/desktop/character_creator/`
- Rename: `src/ui/desktop/Combat/` -> `src/ui/desktop/combat/`
- Rename: `src/ui/desktop/Debug/` -> `src/ui/desktop/debug/`
- Rename: `src/ui/desktop/Hud/` -> `src/ui/desktop/hud/`
- Rename: `src/ui/desktop/hud/SystemHud/` -> `src/ui/desktop/hud/system_hud/`
- Rename: `src/ui/desktop/Inventory/` -> `src/ui/desktop/inventory/`
- Rename: `src/ui/mobile/CharacterCreator/` -> `src/ui/mobile/character_creator/`
- Rename: `src/ui/mobile/Combat/` -> `src/ui/mobile/combat/`
- Rename: `src/ui/mobile/Hud/` -> `src/ui/mobile/hud/`
- Rename: `src/ui/mobile/hud/SystemHud/` -> `src/ui/mobile/hud/system_hud/`
- Rename: `src/ui/mobile/Inventory/` -> `src/ui/mobile/inventory/`
- Move: `src/ui/desktop/Gui/MainScreen/` -> `src/ui/desktop/main_screen/`
- Move: `src/ui/mobile/Gui/MainScreen/` -> `src/ui/mobile/main_screen/`

- [ ] **Step 1: Capture the UI stale-path baseline**

```powershell
rg -n "src/ui/common|src/ui/desktop|src/ui/mobile|src/ui/hud|src/ui/desktop/main_screen|src/ui/mobile/main_screen" src project.godot
```

Expected: matches in `ui_manager.gd`, the main screen scenes, `overworld.tscn`, inventory scenes, combat scenes, and the startup splash scene.

- [ ] **Step 2: Rename the main UI folders**

```powershell
Rename-Item src/ui/common src/ui/__common_tmp
Rename-Item src/ui/__common_tmp src/ui/common
Rename-Item src/ui/desktop src/ui/__desktop_tmp
Rename-Item src/ui/__desktop_tmp src/ui/desktop
Rename-Item src/ui/mobile src/ui/__mobile_tmp
Rename-Item src/ui/__mobile_tmp src/ui/mobile
Rename-Item src/ui/hud src/ui/__hud_tmp
Rename-Item src/ui/__hud_tmp src/ui/hud
Rename-Item src/ui/common/CombatPreviewPanel src/ui/common/combat_preview_panel
Rename-Item src/ui/common/CombatResultPanel src/ui/common/combat_result_panel
Rename-Item src/ui/common/Debug src/ui/common/debug
Rename-Item src/ui/common/Styles src/ui/common/styles
Rename-Item src/ui/common/styles/Profiles src/ui/common/styles/profiles
Rename-Item src/ui/desktop/CharacterCreator src/ui/desktop/character_creator
Rename-Item src/ui/desktop/Combat src/ui/desktop/combat
Rename-Item src/ui/desktop/Debug src/ui/desktop/debug
Rename-Item src/ui/desktop/Hud src/ui/desktop/hud
Rename-Item src/ui/desktop/hud/SystemHud src/ui/desktop/hud/system_hud
Rename-Item src/ui/desktop/Inventory src/ui/desktop/inventory
Rename-Item src/ui/mobile/CharacterCreator src/ui/mobile/character_creator
Rename-Item src/ui/mobile/Combat src/ui/mobile/combat
Rename-Item src/ui/mobile/Hud src/ui/mobile/hud
Rename-Item src/ui/mobile/hud/SystemHud src/ui/mobile/hud/system_hud
Rename-Item src/ui/mobile/Inventory src/ui/mobile/inventory
```

- [ ] **Step 3: Flatten the `Gui/MainScreen` feature into `main_screen`**

```powershell
New-Item -ItemType Directory -Force -Path src/ui/desktop/main_screen | Out-Null
Move-Item src/ui/desktop/Gui/MainScreen/* src/ui/desktop/main_screen/
Remove-Item src/ui/desktop/Gui/MainScreen -Force
Remove-Item src/ui/desktop/Gui -Force
New-Item -ItemType Directory -Force -Path src/ui/mobile/main_screen | Out-Null
Move-Item src/ui/mobile/Gui/MainScreen/* src/ui/mobile/main_screen/
Remove-Item src/ui/mobile/Gui/MainScreen -Force
Remove-Item src/ui/mobile/Gui -Force
```

- [ ] **Step 4: Update `UiManager` preload constants to the new runtime layout**

```gdscript
const SYSTEM_HUD_DESKTOP_SCENE: PackedScene = preload("res://src/ui/desktop/hud/system_hud/system_hud.tscn")
const SYSTEM_HUD_MOBILE_SCENE: PackedScene = preload("res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn")
const DEBUG_OVERLAY_DESKTOP_SCENE: PackedScene = preload("res://src/ui/desktop/debug/debug_overlay.tscn")
const MAIN_SCREEN_DESKTOP_SCENE: PackedScene = preload("res://src/ui/desktop/main_screen/main_screen.tscn")
const MAIN_SCREEN_MOBILE_SCENE: PackedScene = preload("res://src/ui/mobile/main_screen/main_screen_mobile.tscn")
const INVENTORY_PANEL_DESKTOP_SCENE: PackedScene = preload("res://src/ui/desktop/inventory/inventory_panel.tscn")
const INVENTORY_PANEL_MOBILE_SCENE: PackedScene = preload("res://src/ui/mobile/inventory/inventory_panel_mobile.tscn")
```

- [ ] **Step 5: Update `overworld.tscn` and the UI scenes to the new paths**

```gdresource
[ext_resource type="PackedScene" path="res://src/ui/desktop/debug/debug_overlay.tscn" id="4"]
[ext_resource type="PackedScene" path="res://src/ui/desktop/main_screen/main_screen.tscn" id="8_main_screen"]
[ext_resource type="PackedScene" path="res://src/ui/desktop/hud/system_hud/system_hud.tscn" id="11_system_hud"]
[ext_resource type="PackedScene" path="res://src/ui/desktop/inventory/inventory_panel.tscn" id="12_inventory_panel"]
[ext_resource type="Script" path="res://src/ui/common/ui_manager.gd" id="13_ui_manager"]
[ext_resource type="PackedScene" path="res://src/ui/hud/creature_action_hud.tscn" id="14_creature_action_hud"]
[ext_resource type="PackedScene" path="res://src/ui/common/combat_preview_panel/combat_preview_panel.tscn" id="18_combat_preview"]
```

Also update every `.tscn` / `.tres` listed above so `common`, `desktop`, `mobile`, `hud`, the nested feature folders, and `main_screen` references point at the normalized locations.

- [ ] **Step 6: Verify UI stale paths are gone**

```powershell
rg -n "src/ui/common|src/ui/desktop|src/ui/mobile|src/ui/hud|src/ui/desktop/main_screen|src/ui/mobile/main_screen" src project.godot
```

Expected: no output.

- [ ] **Step 7: Smoke-test the project entry scene**

```bash
godot4 --headless --path . --scene res://src/world/main.tscn --quit-after 10
```

Expected: exit code `0` with no missing-resource errors for `Ui` paths.

- [ ] **Step 8: Commit**

```bash
git add project.godot src/ui src/world/overworld/overworld.tscn src/world/combat/combat_scene.tscn
git commit -m "refactor: normalize ui runtime layout"
```

### Task 3: Normalize World Runtime Layout And Location Names

**Files:**
- Modify: `src/world/main.gd`
- Modify: `src/world/main.tscn`
- Modify: `src/world/combat/combat_scene.tscn`
- Modify: `src/world/overworld/overworld.gd`
- Modify: `src/world/overworld/overworld.tscn`
- Modify: `src/world/overworld/overworld_player_spawner.gd`
- Modify: `src/world/overworld/overworld_creature_spawner.gd`
- Modify: `src/world/overworld/overworld_character_creator_controller.gd`
- Modify: `src/world/overworld/overworld_creature_selection_controller.gd`
- Modify: `src/world/overworld/overworld_session_controller.gd`
- Modify: `src/world/overworld/navigation_blocker_registry.gd`
- Modify: `src/world/overworld/chunks/chunk.gd`
- Modify: `src/world/streaming/chunk_manager.gd`
- Modify: `src/world/streaming/overworld_chunk_water_shader.gd`
- Modify: `src/world/locations/towns/starting_village/npcs/.gitkeep`
- Rename: `src/world/combat/` -> `src/world/combat/`
- Rename: `src/world/locations/` -> `src/world/locations/`
- Rename: `src/world/overworld/` -> `src/world/overworld/`
- Rename: `src/world/streaming/` -> `src/world/streaming/`
- Rename: `src/world/locations/Arenas/` -> `src/world/locations/arenas/`
- Rename: `src/world/locations/dungeons/` -> `src/world/locations/dungeons/`
- Rename: `src/world/locations/interiors/` -> `src/world/locations/interiors/`
- Rename: `src/world/locations/towns/` -> `src/world/locations/towns/`
- Rename: `src/world/overworld/chunks/` -> `src/world/overworld/chunks/`
- Rename: `src/world/overworld/Shaders/` -> `src/world/overworld/shaders/`
- Rename: `src/world/overworld/tilesets/` -> `src/world/overworld/tilesets/`
- Rename: `src/world/locations/dungeons/ancient_ruins/` -> `src/world/locations/dungeons/ancient_ruins/`
- Rename: `src/world/locations/dungeons/goblin_cave/` -> `src/world/locations/dungeons/goblin_cave/`
- Rename: `src/world/locations/dungeons/goblin_cave/Encounters/` -> `src/world/locations/dungeons/goblin_cave/encounters/`
- Rename: `src/world/locations/interiors/house_interior/` -> `src/world/locations/interiors/house_interior/`
- Rename: `src/world/locations/interiors/shop_interior/` -> `src/world/locations/interiors/shop_interior/`
- Rename: `src/world/locations/towns/capital_city/` -> `src/world/locations/towns/capital_city/`
- Rename: `src/world/locations/towns/starting_village/` -> `src/world/locations/towns/starting_village/`
- Rename: `src/world/locations/towns/starting_village/npcs/` -> `src/world/locations/towns/starting_village/npcs/`

- [ ] **Step 1: Capture the current world path surface**

```powershell
rg -n "src/world/combat|src/world/overworld|src/world/streaming|ancient_ruins|goblin_cave|house_interior|shop_interior|capital_city|starting_village|/npcs/" src docs project.godot
```

Expected: matches in `src/world` scenes/scripts plus documentation files that mention location paths.

- [ ] **Step 2: Rename the world runtime folders**

```powershell
Rename-Item src/world/combat src/world/__combat_tmp
Rename-Item src/world/__combat_tmp src/world/combat
Rename-Item src/world/locations src/world/__locations_tmp
Rename-Item src/world/__locations_tmp src/world/locations
Rename-Item src/world/overworld src/world/__overworld_tmp
Rename-Item src/world/__overworld_tmp src/world/overworld
Rename-Item src/world/streaming src/world/__streaming_tmp
Rename-Item src/world/__streaming_tmp src/world/streaming
Rename-Item src/world/locations/Arenas src/world/locations/arenas
Rename-Item src/world/locations/Dungeons src/world/locations/dungeons
Rename-Item src/world/locations/Interiors src/world/locations/interiors
Rename-Item src/world/locations/Towns src/world/locations/towns
Rename-Item src/world/overworld/chunks src/world/overworld/__chunks_tmp
Rename-Item src/world/overworld/__chunks_tmp src/world/overworld/chunks
Rename-Item src/world/overworld/Shaders src/world/overworld/__shaders_tmp
Rename-Item src/world/overworld/__shaders_tmp src/world/overworld/shaders
Rename-Item src/world/overworld/tilesets src/world/overworld/__tilesets_tmp
Rename-Item src/world/overworld/__tilesets_tmp src/world/overworld/tilesets
```

- [ ] **Step 3: Rename location folders to `snake_case`**

```powershell
Rename-Item 'src/world/locations/dungeons/ancient_ruins' 'ancient_ruins'
Rename-Item 'src/world/locations/dungeons/goblin_cave' 'goblin_cave'
Rename-Item 'src/world/locations/dungeons/goblin_cave/Encounters' 'encounters'
Rename-Item 'src/world/locations/interiors/house_interior' 'house_interior'
Rename-Item 'src/world/locations/interiors/shop_interior' 'shop_interior'
Rename-Item 'src/world/locations/towns/capital_city' 'capital_city'
Rename-Item 'src/world/locations/towns/starting_village' 'starting_village'
Rename-Item 'src/world/locations/towns/starting_village/Npcs' 'npcs'
```

- [ ] **Step 4: Update world scene and script references**

```gdresource
[ext_resource type="Script" path="res://src/world/overworld/overworld.gd" id="1"]
[ext_resource type="Script" path="res://src/world/streaming/chunk_manager.gd" id="3"]
[ext_resource type="Script" path="res://src/world/overworld/overworld_player_spawner.gd" id="5_spawner"]
[ext_resource type="Script" path="res://src/world/overworld/overworld_session_controller.gd" id="6_session"]
[ext_resource type="Script" path="res://src/world/overworld/navigation_blocker_registry.gd" id="7_registry"]
[ext_resource type="Script" path="res://src/world/overworld/overworld_creature_spawner.gd" id="10_creature_spawner"]
[ext_resource type="Script" path="res://src/world/overworld/overworld_creature_selection_controller.gd" id="16_creature_selection_ctrl"]
[ext_resource type="Script" path="res://src/world/overworld/overworld_character_creator_controller.gd" id="17_character_creator_ctrl"]
```

Update `src/world/main.tscn`, `src/world/main.gd`, `src/world/combat/combat_scene.tscn`, `src/world/streaming/chunk_manager.gd`, and any world chunk scenes so they reference the normalized paths.

- [ ] **Step 5: Verify the old world paths are gone**

```powershell
rg -n "src/world/combat|src/world/overworld|src/world/streaming|ancient_ruins|goblin_cave|house_interior|shop_interior|capital_city|starting_village|/npcs/" src docs project.godot
```

Expected: no output in `src/`; only historical docs are allowed if they are intentionally left unchanged.

- [ ] **Step 6: Load the main world scene**

```bash
godot4 --headless --path . --scene res://src/world/main.tscn --quit-after 10
```

Expected: exit code `0` with no missing-resource errors for `World` paths.

- [ ] **Step 7: Commit**

```bash
git add src/world docs
git commit -m "refactor: normalize world runtime folders"
```

### Task 4: Normalize Entity Runtime Layout, Creature Catalog, And Item Catalog Paths

**Files:**
- Modify: `src/entities/Creatures/creature.gd`
- Modify: `src/entities/Creatures/creature.tscn`
- Modify: `src/entities/Creatures/creature_catalog.gd`
- Modify: `src/entities/Creatures/creature_catalog_service.gd`
- Modify: `src/entities/Creatures/creature_data.gd`
- Modify: `src/entities/Creatures/creature_factory.gd`
- Modify: `src/entities/Creatures/README.md`
- Modify: `src/entities/Creatures/Tools/creature_catalog_builder.gd`
- Modify: `src/entities/Creatures/Tools/creature_catalog_builder_runner.gd`
- Modify: `src/entities/Creatures/Tools/creature_catalog_builder_runner.tscn`
- Modify: `src/entities/Items/item_data.gd`
- Modify: `src/entities/Items/README.md`
- Modify: `src/entities/Player/player.gd`
- Modify: `src/entities/Player/player.tscn`
- Modify: `src/entities/Player/Config/player_input_config.tres`
- Modify: `src/entities/Player/Config/player_movement_config.tres`
- Modify: `src/entities/Player/Tools/player_cosmetic_catalog_builder.gd`
- Modify: `src/entities/Player/Tools/player_cosmetic_catalog_builder_runner.gd`
- Modify: `src/entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn`
- Modify: `src/entities/Player/Tools/README.md`
- Modify: `src/entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- Modify: `src/entities/Systems/Combat/Tests/run_combat_tests.gd`
- Modify: `src/world/overworld/overworld.tscn`
- Rename: `src/entities/Creatures/` -> `src/entities/creatures/`
- Move: `src/entities/creatures/creature.gd` -> `src/entities/creatures/base/creature.gd`
- Move: `src/entities/creatures/creature.tscn` -> `src/entities/creatures/base/creature.tscn`
- Move: `src/entities/creatures/creature_catalog.gd` -> `src/entities/creatures/base/creature_catalog.gd`
- Move: `src/entities/creatures/creature_catalog_service.gd` -> `src/entities/creatures/base/creature_catalog_service.gd`
- Move: `src/entities/creatures/creature_data.gd` -> `src/entities/creatures/base/creature_data.gd`
- Move: `src/entities/creatures/creature_factory.gd` -> `src/entities/creatures/base/creature_factory.gd`
- Rename: `src/entities/creatures/Types/` -> `src/entities/creatures/catalog/`
- Rename: `src/entities/Player/` -> `src/entities/player/`
- Rename: `src/entities/creatures/Components/` -> `src/entities/creatures/components/`
- Rename: `src/entities/creatures/Effects/` -> `src/entities/creatures/effects/`
- Rename: `src/entities/creatures/Resources/` -> `src/entities/creatures/resources/`
- Rename: `src/entities/creatures/Spawning/` -> `src/entities/creatures/spawning/`
- Rename: `src/entities/creatures/Tests/` -> `src/entities/creatures/tests/`
- Rename: `src/entities/creatures/Tools/` -> `src/entities/creatures/tools/`
- Rename: `src/entities/Items/` -> `src/entities/items/`
- Rename: `src/entities/items/Types/` -> `src/entities/items/catalog/`
- Rename: `src/entities/player/Assets/` -> `src/entities/player/assets/`
- Rename: `src/entities/player/Components/` -> `src/entities/player/components/`
- Rename: `src/entities/player/Config/` -> `src/entities/player/config/`
- Rename: `src/entities/player/Input/` -> `src/entities/player/input/`
- Rename: `src/entities/player/Resources/` -> `src/entities/player/resources/`
- Rename: `src/entities/player/Services/` -> `src/entities/player/services/`
- Rename: `src/entities/player/Sounds/` -> `src/entities/player/sounds/`
- Rename: `src/entities/player/States/` -> `src/entities/player/states/`
- Rename: `src/entities/player/Tests/` -> `src/entities/player/tests/`
- Rename: `src/entities/player/Tools/` -> `src/entities/player/tools/`
- Rename: `src/entities/Interactables/` -> `src/entities/interactables/`
- Rename: `src/entities/Skills/` -> `src/entities/skills/`
- Rename: `src/entities/Systems/` -> `src/entities/systems/`
- Rename: `src/entities/systems/Combat/` -> `src/entities/systems/combat/`
- Rename: `src/entities/systems/Inventory/` -> `src/entities/systems/inventory/`

- [ ] **Step 1: Capture entity path hot spots before moving anything**

```powershell
rg -n "src/entities/Creatures|src/entities/Creatures/Types|src/entities/Items|src/entities/Items/Types|src/entities/Player|src/entities/Interactables|src/entities/Skills|src/entities/Systems" src docs project.godot
```

Expected: many matches, especially in the creature builder, creature catalog resources, item inventory resources, player tools, and docs.

- [ ] **Step 2: Rename the entity root folders**

```powershell
Rename-Item src/entities/Creatures src/entities/__creatures_tmp
Rename-Item src/entities/__creatures_tmp src/entities/creatures
Rename-Item src/entities/Player src/entities/__player_tmp
Rename-Item src/entities/__player_tmp src/entities/player
Rename-Item src/entities/Items src/entities/__items_tmp
Rename-Item src/entities/__items_tmp src/entities/items
Rename-Item src/entities/Interactables src/entities/__interactables_tmp
Rename-Item src/entities/__interactables_tmp src/entities/interactables
Rename-Item src/entities/Skills src/entities/__skills_tmp
Rename-Item src/entities/__skills_tmp src/entities/skills
Rename-Item src/entities/Systems src/entities/__systems_tmp
Rename-Item src/entities/__systems_tmp src/entities/systems
Rename-Item src/entities/creatures/Components src/entities/creatures/components
Rename-Item src/entities/creatures/Effects src/entities/creatures/effects
Rename-Item src/entities/creatures/Resources src/entities/creatures/resources
Rename-Item src/entities/creatures/Spawning src/entities/creatures/spawning
Rename-Item src/entities/creatures/Tests src/entities/creatures/tests
Rename-Item src/entities/creatures/Tools src/entities/creatures/tools
Rename-Item src/entities/player/Assets src/entities/player/assets
Rename-Item src/entities/player/Components src/entities/player/components
Rename-Item src/entities/player/Config src/entities/player/config
Rename-Item src/entities/player/Input src/entities/player/input
Rename-Item src/entities/player/Resources src/entities/player/resources
Rename-Item src/entities/player/Services src/entities/player/services
Rename-Item src/entities/player/Sounds src/entities/player/sounds
Rename-Item src/entities/player/States src/entities/player/states
Rename-Item src/entities/player/Tests src/entities/player/tests
Rename-Item src/entities/player/Tools src/entities/player/tools
Rename-Item src/entities/systems/Combat src/entities/systems/combat
Rename-Item src/entities/systems/Inventory src/entities/systems/inventory
```

- [ ] **Step 3: Create `base/` and `catalog/` inside creatures and move the root runtime files**

```powershell
New-Item -ItemType Directory -Force -Path src/entities/creatures/base | Out-Null
Move-Item src/entities/creatures/creature.gd src/entities/creatures/base/creature.gd
Move-Item src/entities/creatures/creature.tscn src/entities/creatures/base/creature.tscn
Move-Item src/entities/creatures/creature_catalog.gd src/entities/creatures/base/creature_catalog.gd
Move-Item src/entities/creatures/creature_catalog_service.gd src/entities/creatures/base/creature_catalog_service.gd
Move-Item src/entities/creatures/creature_data.gd src/entities/creatures/base/creature_data.gd
Move-Item src/entities/creatures/creature_factory.gd src/entities/creatures/base/creature_factory.gd
Rename-Item src/entities/creatures/Types catalog
Rename-Item src/entities/items/Types catalog
```

- [ ] **Step 4: Update the creature builder to write into `catalog/` and `base/`**

```gdscript
const TYPES_ROOT: String = "res://src/entities/creatures/catalog"
const CATALOG_PATH: String = "res://src/entities/creatures/resources/creature_catalog.tres"
const CREATURE_CATALOG_SCRIPT: Script = preload("res://src/entities/creatures/base/creature_catalog.gd")
```

```gdscript
# src/entities/creatures/base/creature_data.gd
## Top-level folder under catalog (humanoids, animals, ...).
```

Also update the builder path parser and emitted paths so they use lowercase entry folders:

```gdscript
if parts[2].to_lower() != "sprites":
	push_warning("CreatureCatalogBuilder: sprite must be under 'sprites/' in '%s'." % sprite_path)

return TYPES_ROOT.path_join("%s/%s/data/%s.tres" % [category, creature_folder, String(entry["creature_id"])])
```

Update all explicit `res://src/entities/Creatures/...` and `res://src/entities/Items/Types/...` strings in the listed files so they point to the normalized runtime layout.

- [ ] **Step 5: Rename creature category folders and then normalize creature entry folder names in one scripted sweep**

```powershell
Rename-Item src/entities/creatures/catalog/Animals animals
Rename-Item src/entities/creatures/catalog/Demons demons
Rename-Item src/entities/creatures/catalog/Dragons dragons
Rename-Item src/entities/creatures/catalog/Holy holy
Rename-Item src/entities/creatures/catalog/Humanoids humanoids
Rename-Item src/entities/creatures/catalog/Magical magical
Rename-Item src/entities/creatures/catalog/Monsters monsters
Rename-Item src/entities/creatures/catalog/Undead undead
Rename-Item src/entities/creatures/catalog/Vermin vermin
```

```powershell
$script = @'
function To-SnakeCase([string]$Name) {
  return ($Name.ToLower() -replace "[^a-z0-9]+", "_").Trim("_")
}

Get-ChildItem src/entities/creatures/catalog -Directory | ForEach-Object {
  Get-ChildItem $_.FullName -Directory | ForEach-Object {
    $target = Join-Path $_.Parent.FullName (To-SnakeCase $_.Name)
    if ($_.FullName -ne $target) { Rename-Item $_.FullName $target }
  }
}
'@
$script | Set-Content .git\codex_tmp_creature_rename.ps1
powershell -ExecutionPolicy Bypass -File .git\codex_tmp_creature_rename.ps1
Remove-Item .git\codex_tmp_creature_rename.ps1 -Force
```

This step is intentionally narrow: rename creature entry folders only after the category folders and builder constants already point at `catalog/`.

- [ ] **Step 5a: Rename per-entry `Data` and `Sprites` folders in creatures and items**

```powershell
Get-ChildItem src/entities/creatures/catalog -Directory | ForEach-Object {
  Get-ChildItem $_.FullName -Directory | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName 'Data')) { Rename-Item (Join-Path $_.FullName 'Data') 'data' }
    if (Test-Path (Join-Path $_.FullName 'Sprites')) { Rename-Item (Join-Path $_.FullName 'Sprites') 'sprites' }
  }
}

Get-ChildItem src/entities/items/catalog -Directory | ForEach-Object {
  Get-ChildItem $_.FullName -Directory | ForEach-Object {
    Get-ChildItem $_.FullName -Directory | ForEach-Object {
      if (Test-Path (Join-Path $_.FullName 'Data')) { Rename-Item (Join-Path $_.FullName 'Data') 'data' }
      if (Test-Path (Join-Path $_.FullName 'Sprites')) { Rename-Item (Join-Path $_.FullName 'Sprites') 'sprites' }
    }
  }
}
```

- [ ] **Step 6: Regenerate creature data and catalog resources**

```bash
godot4 --headless --path . --scene res://src/entities/creatures/tools/creature_catalog_builder_runner.tscn --quit
```

Expected:

```text
CreatureCatalogBuilder summary line ends with `errors=0`
CreatureCatalogBuilder runner completed line contains `"errors": 0`
```

- [ ] **Step 7: Verify the creature and item catalogs still validate**

```bash
godot4 --headless --path . --script res://src/entities/creatures/tests/run_creature_catalog_validation.gd
godot4 --headless --path . --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200
godot4 --headless --path . --script res://src/entities/systems/combat/tests/run_combat_tests.gd
```

Expected: all commands exit `0`, and the creature runtime smoke test reports no missing script/resource paths.

- [ ] **Step 8: Verify stale entity paths are gone**

```powershell
rg -n "src/entities/Creatures|src/entities/Creatures/Types|src/entities/Items/Types|src/entities/Player|src/entities/Interactables|src/entities/Skills|src/entities/Systems" src project.godot
```

Expected: no output in `src/`; documentation can be updated in the next task if historical notes still mention old paths.

- [ ] **Step 9: Commit**

```bash
git add src/entities src/world/overworld/overworld.tscn
git commit -m "refactor: normalize entity runtime folders"
```

### Task 5: Sweep Docs, Finish Remaining Path Updates, And Run Final Verification

**Files:**
- Modify: `docs/DESCRIPTION.md`
- Modify: `docs/features/feature-creature-system-foundation.md`
- Modify: `docs/features/feature-creature-wander-nav-respect.md`
- Modify: `docs/features/feature-item-system-combat-inventory.md`
- Modify: `docs/features/feature-main-screen-ui.md`
- Modify: `docs/features/feature-player-appearance-customization.md`
- Modify: `docs/features/feature-tappable-overworld-creatures.md`
- Modify: `src/entities/Creatures/README.md`
- Modify: `src/entities/Items/README.md`
- Modify: `src/entities/Player/Tools/README.md`

- [ ] **Step 1: Sweep docs and README files for stale paths**

```powershell
rg -n "src/ui/common|src/ui/desktop|src/ui/mobile|src/ui/hud|src/world/overworld|src/world/streaming|src/world/combat|src/entities/Creatures|src/entities/Items/Types|src/entities/Player|src/entities/Systems|src/entities/Interactables|src/entities/Skills" docs src/entities/*/README.md src/localization/README.md
```

Expected: matches only in docs and README files at this point.

- [ ] **Step 2: Update the creature, item, player, and project docs**

```markdown
- `res://src/entities/creatures/catalog/animals/agitated_orangutan/sprites/AgitatedOrangutan_128x32.png`
- `res://src/entities/items/catalog/consumables/potions/health_potion/data/consumable_health_potion.tres`
- `res://src/ui/desktop/main_screen/main_screen.tscn`
- `res://src/world/overworld/overworld.tscn`
```

Replace every old runtime path example in the listed docs with the normalized path that now exists in `src/`.

- [ ] **Step 3: Run the final stale-path audit**

```powershell
rg -n "src/ui/common|src/ui/desktop|src/ui/mobile|src/ui/hud|src/world/overworld|src/world/streaming|src/world/combat|src/entities/Creatures|src/entities/Items/Types|src/entities/Player|src/entities/Systems|src/entities/Interactables|src/entities/Skills|ancient_ruins|goblin_cave|house_interior|shop_interior|capital_city|starting_village|/npcs/" src project.godot
```

Expected: no output.

- [ ] **Step 4: Run final project verification**

```bash
godot4 --headless --path . --scene res://src/world/main.tscn --quit-after 10
godot4 --headless --path . --script res://src/entities/creatures/tests/run_creature_catalog_validation.gd
godot4 --headless --path . --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200
godot4 --headless --path . --script res://src/entities/systems/combat/tests/run_combat_tests.gd
```

Expected: all commands exit `0`.

- [ ] **Step 5: Commit**

```bash
git add docs src
git commit -m "docs: update runtime structure references"
```
