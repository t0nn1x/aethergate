# Src Structure Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize `src/` into a predictable feature-first layout with normalized `snake_case` runtime paths while preserving behavior and keeping shared asset roots such as `src/Ui/Assets` in place.

**Architecture:** Execute the refactor as a sequence of small rename-and-reference-update passes. Each pass updates moved paths atomically across scripts, scenes, resources, docs, and generated catalogs, then verifies both stale-path removal and project loadability before moving on. Because this repository is on Windows, case-only renames must use temporary intermediate folder names instead of direct `PascalCase` to `snake_case` renames.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` scenes, `.tres` resources, PowerShell, `rg`, git

---

## File Map

### Shared infrastructure paths

- `project.godot`
- `src/Common/Navigation/`
- `src/Common/Shaders/`
- `src/Common/StateMachine/`
- `src/Core/Events/`
- `src/Config/Platform/`
- `src/Localization/Translations/`
- `src/Localization/localization_service.gd`
- `src/Localization/README.md`

### UI runtime paths

- `src/Ui/Common/ui_manager.gd`
- `src/Ui/Common/startup_splash_screen.tscn`
- `src/Ui/Common/CombatPreviewPanel/combat_preview_panel.tscn`
- `src/Ui/Common/CombatResultPanel/combat_result_panel.tscn`
- `src/Ui/Common/Debug/debug_panel.gd`
- `src/Ui/Common/Styles/Profiles/*.tres`
- `src/Ui/Common/inventory_screen.tscn`
- `src/Ui/Desktop/Gui/MainScreen/main_screen.gd`
- `src/Ui/Desktop/Gui/MainScreen/main_screen.tscn`
- `src/Ui/Desktop/Gui/MainScreen/main_screen_desktop.gd`
- `src/Ui/Desktop/Gui/MainScreen/background_controller.gd`
- `src/Ui/Desktop/Gui/MainScreen/main_screen_theme.tres`
- `src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn`
- `src/Ui/Desktop/Combat/desktop_combat_ui.tscn`
- `src/Ui/Desktop/Debug/debug_overlay.tscn`
- `src/Ui/Desktop/Hud/SystemHud/system_hud.tscn`
- `src/Ui/Desktop/Inventory/inventory_panel.gd`
- `src/Ui/Desktop/Inventory/inventory_panel.tscn`
- `src/Ui/Desktop/Inventory/inventory_screen.tscn`
- `src/Ui/Mobile/Gui/MainScreen/main_screen_mobile.gd`
- `src/Ui/Mobile/Gui/MainScreen/main_screen_mobile.tscn`
- `src/Ui/Mobile/CharacterCreator/character_creator_panel_mobile.tscn`
- `src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn`
- `src/Ui/Mobile/Inventory/inventory_panel_mobile.tscn`
- `src/Ui/Hud/creature_action_hud.tscn`

### World runtime paths

- `src/World/main.gd`
- `src/World/main.tscn`
- `src/World/Combat/combat_scene.tscn`
- `src/World/Overworld/overworld.gd`
- `src/World/Overworld/overworld.tscn`
- `src/World/Overworld/overworld_player_spawner.gd`
- `src/World/Overworld/overworld_creature_spawner.gd`
- `src/World/Overworld/overworld_character_creator_controller.gd`
- `src/World/Overworld/overworld_creature_selection_controller.gd`
- `src/World/Overworld/overworld_session_controller.gd`
- `src/World/Overworld/navigation_blocker_registry.gd`
- `src/World/Overworld/Chunks/chunk.gd`
- `src/World/Streaming/chunk_manager.gd`
- `src/World/Streaming/overworld_chunk_water_shader.gd`
- `src/World/Locations/Dungeons/Ancient_Ruins/`
- `src/World/Locations/Dungeons/Goblin_Cave/`
- `src/World/Locations/Dungeons/Goblin_Cave/Encounters/`
- `src/World/Locations/Interiors/House_Interior/`
- `src/World/Locations/Interiors/Shop_Interior/`
- `src/World/Locations/Towns/Capital_City/`
- `src/World/Locations/Towns/Starting_Village/`
- `src/World/Locations/Towns/Starting_Village/Npcs/`

### Entities runtime and generated content

- `src/Entities/Creatures/creature.gd`
- `src/Entities/Creatures/creature.tscn`
- `src/Entities/Creatures/creature_catalog.gd`
- `src/Entities/Creatures/creature_catalog_service.gd`
- `src/Entities/Creatures/creature_data.gd`
- `src/Entities/Creatures/creature_factory.gd`
- `src/Entities/Creatures/README.md`
- `src/Entities/Creatures/Tools/creature_catalog_builder.gd`
- `src/Entities/Creatures/Tools/creature_catalog_builder_runner.gd`
- `src/Entities/Creatures/Tools/creature_catalog_builder_runner.tscn`
- `src/Entities/Creatures/Resources/creature_catalog.tres`
- `src/Entities/Creatures/Types/*/*/Data/*.tres` via catalog regeneration
- `src/Entities/Items/item_data.gd`
- `src/Entities/Items/README.md`
- `src/Entities/Items/Types/*/*/*/Data/*.tres`
- `src/Entities/Player/player.gd`
- `src/Entities/Player/player.tscn`
- `src/Entities/Player/Config/player_input_config.tres`
- `src/Entities/Player/Config/player_movement_config.tres`
- `src/Entities/Player/Tools/player_cosmetic_catalog_builder.gd`
- `src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.gd`
- `src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn`
- `src/Entities/Player/Tools/README.md`
- `src/Entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- `src/Entities/Systems/Combat/Tests/run_combat_tests.gd`

### Documentation paths

- `docs/DESCRIPTION.md`
- `docs/features/feature-creature-system-foundation.md`
- `docs/features/feature-creature-wander-nav-respect.md`
- `docs/features/feature-item-system-combat-inventory.md`
- `docs/features/feature-main-screen-ui.md`
- `docs/features/feature-player-appearance-customization.md`
- `docs/features/feature-tappable-overworld-creatures.md`

### Rename conventions to apply

- `src/Common/Navigation` -> `src/Common/navigation`
- `src/Common/Shaders` -> `src/Common/shaders`
- `src/Common/StateMachine` -> `src/Common/state_machine`
- `src/Core/Events` -> `src/Core/events`
- `src/Config/Platform` -> `src/Config/platform`
- `src/Localization/Translations` -> `src/Localization/translations`
- `src/Ui/Common` -> `src/Ui/common`
- `src/Ui/Desktop` -> `src/Ui/desktop`
- `src/Ui/Mobile` -> `src/Ui/mobile`
- `src/Ui/common/CombatPreviewPanel` -> `src/Ui/common/combat_preview_panel`
- `src/Ui/common/CombatResultPanel` -> `src/Ui/common/combat_result_panel`
- `src/Ui/common/Debug` -> `src/Ui/common/debug`
- `src/Ui/common/Styles` -> `src/Ui/common/styles`
- `src/Ui/common/Styles/Profiles` -> `src/Ui/common/styles/profiles`
- `src/Ui/Desktop/Gui/MainScreen` -> `src/Ui/desktop/main_screen`
- `src/Ui/Mobile/Gui/MainScreen` -> `src/Ui/mobile/main_screen`
- `src/Ui/desktop/CharacterCreator` -> `src/Ui/desktop/character_creator`
- `src/Ui/desktop/Combat` -> `src/Ui/desktop/combat`
- `src/Ui/desktop/Debug` -> `src/Ui/desktop/debug`
- `src/Ui/desktop/Hud` -> `src/Ui/desktop/hud`
- `src/Ui/desktop/Hud/SystemHud` -> `src/Ui/desktop/hud/system_hud`
- `src/Ui/desktop/Inventory` -> `src/Ui/desktop/inventory`
- `src/Ui/mobile/CharacterCreator` -> `src/Ui/mobile/character_creator`
- `src/Ui/mobile/Combat` -> `src/Ui/mobile/combat`
- `src/Ui/mobile/Hud` -> `src/Ui/mobile/hud`
- `src/Ui/mobile/Hud/SystemHud` -> `src/Ui/mobile/hud/system_hud`
- `src/Ui/mobile/Inventory` -> `src/Ui/mobile/inventory`
- `src/Ui/Hud` -> `src/Ui/hud`
- `src/World/Combat` -> `src/World/combat`
- `src/World/Locations` -> `src/World/locations`
- `src/World/Overworld` -> `src/World/overworld`
- `src/World/Streaming` -> `src/World/streaming`
- `src/World/locations/Arenas` -> `src/World/locations/arenas`
- `src/World/locations/Dungeons` -> `src/World/locations/dungeons`
- `src/World/locations/Interiors` -> `src/World/locations/interiors`
- `src/World/locations/Towns` -> `src/World/locations/towns`
- `src/World/Overworld/Chunks` -> `src/World/overworld/chunks`
- `src/World/Overworld/Shaders` -> `src/World/overworld/shaders`
- `src/World/Overworld/Tilesets` -> `src/World/overworld/tilesets`
- `src/Entities/Creatures` -> `src/Entities/creatures`
- `src/Entities/Creatures/Types` -> `src/Entities/creatures/catalog`
- `src/Entities/creatures/Components` -> `src/Entities/creatures/components`
- `src/Entities/creatures/Effects` -> `src/Entities/creatures/effects`
- `src/Entities/creatures/Resources` -> `src/Entities/creatures/resources`
- `src/Entities/creatures/Spawning` -> `src/Entities/creatures/spawning`
- `src/Entities/creatures/Tests` -> `src/Entities/creatures/tests`
- `src/Entities/creatures/Tools` -> `src/Entities/creatures/tools`
- `src/Entities/creatures/catalog/*/*/Data` -> `src/Entities/creatures/catalog/*/*/data`
- `src/Entities/creatures/catalog/*/*/Sprites` -> `src/Entities/creatures/catalog/*/*/sprites`
- `src/Entities/Player` -> `src/Entities/player`
- `src/Entities/player/Assets` -> `src/Entities/player/assets`
- `src/Entities/player/Components` -> `src/Entities/player/components`
- `src/Entities/player/Config` -> `src/Entities/player/config`
- `src/Entities/player/Input` -> `src/Entities/player/input`
- `src/Entities/player/Resources` -> `src/Entities/player/resources`
- `src/Entities/player/Services` -> `src/Entities/player/services`
- `src/Entities/player/Sounds` -> `src/Entities/player/sounds`
- `src/Entities/player/States` -> `src/Entities/player/states`
- `src/Entities/player/Tests` -> `src/Entities/player/tests`
- `src/Entities/player/Tools` -> `src/Entities/player/tools`
- `src/Entities/Items` -> `src/Entities/items`
- `src/Entities/Items/Types` -> `src/Entities/items/catalog`
- `src/Entities/items/catalog/*/*/*/Data` -> `src/Entities/items/catalog/*/*/*/data`
- `src/Entities/items/catalog/*/*/*/Sprites` -> `src/Entities/items/catalog/*/*/*/sprites`
- `src/Entities/Interactables` -> `src/Entities/interactables`
- `src/Entities/Skills` -> `src/Entities/skills`
- `src/Entities/Systems` -> `src/Entities/systems`
- `src/Entities/systems/Combat` -> `src/Entities/systems/combat`
- `src/Entities/systems/Inventory` -> `src/Entities/systems/inventory`

### Windows rename note

Use temporary names for case-only renames:

```powershell
Rename-Item src/Ui/Desktop src/Ui/__desktop_tmp
Rename-Item src/Ui/__desktop_tmp src/Ui/desktop
```

Use the same pattern for every case-only rename in this plan.

### Task 1: Normalize Shared Infrastructure Paths

**Files:**
- Modify: `project.godot`
- Modify: `src/Config/aether_project_config.gd`
- Modify: `src/Config/project_config.tres`
- Modify: `src/Config/Platform/desktop_platform_profile.tres`
- Modify: `src/Config/Platform/mobile_platform_profile.tres`
- Modify: `src/Localization/localization_service.gd`
- Modify: `src/Localization/README.md`
- Modify: `src/Entities/Creatures/creature.tscn`
- Modify: `src/Entities/Player/player.tscn`
- Rename: `src/Common/Navigation/` -> `src/Common/navigation/`
- Rename: `src/Common/Shaders/` -> `src/Common/shaders/`
- Rename: `src/Common/StateMachine/` -> `src/Common/state_machine/`
- Rename: `src/Core/Events/` -> `src/Core/events/`
- Rename: `src/Config/Platform/` -> `src/Config/platform/`
- Rename: `src/Localization/Translations/` -> `src/Localization/translations/`

- [ ] **Step 1: Record the current reference surface**

```powershell
rg -n "src/Common/Navigation|src/Common/Shaders|src/Common/StateMachine|src/Core/Events|src/Config/Platform|src/Localization/Translations" src project.godot
```

Expected: matches in `project.godot`, config resources, localization files, and any scene/script that still references the old directories.

- [ ] **Step 2: Rename the shared folders with Windows-safe temporary names**

```powershell
Rename-Item src/Common/Navigation src/Common/__navigation_tmp
Rename-Item src/Common/__navigation_tmp src/Common/navigation
Rename-Item src/Common/Shaders src/Common/__shaders_tmp
Rename-Item src/Common/__shaders_tmp src/Common/shaders
Rename-Item src/Common/StateMachine src/Common/__state_machine_tmp
Rename-Item src/Common/__state_machine_tmp src/Common/state_machine
Rename-Item src/Core/Events src/Core/__events_tmp
Rename-Item src/Core/__events_tmp src/Core/events
Rename-Item src/Config/Platform src/Config/__platform_tmp
Rename-Item src/Config/__platform_tmp src/Config/platform
Rename-Item src/Localization/Translations src/Localization/__translations_tmp
Rename-Item src/Localization/__translations_tmp src/Localization/translations
```

- [ ] **Step 3: Update autoload, config, and localization references**

```ini
; project.godot
run/main_scene="res://src/Ui/common/startup_splash_screen.tscn"
ProjectConfig="*res://src/Config/project_config_service.gd"
LocalizationService="*res://src/Localization/localization_service.gd"
PlayerEvents="*res://src/Core/events/player_events.gd"
WorldEvents="*res://src/Core/events/world_events.gd"
UIEvents="*res://src/Core/events/ui_events.gd"
CreatureEvents="*res://src/Core/events/creature_events.gd"
CombatEvents="*res://src/Core/events/combat_events.gd"
locale/translations=PackedStringArray("res://src/Localization/translations/ui_en.tres", "res://src/Localization/translations/ui_uk.tres")
```

```gdscript
# src/Localization/localization_service.gd
const DEFAULT_TRANSLATIONS: PackedStringArray = [
	"res://src/Localization/translations/ui_en.tres",
	"res://src/Localization/translations/ui_uk.tres",
]
```

- [ ] **Step 4: Update remaining explicit path strings**

```powershell
rg -l "src/Common/Navigation|src/Common/Shaders|src/Common/StateMachine|src/Core/Events|src/Config/Platform|src/Localization/Translations" src project.godot |
ForEach-Object { $_ }
```

Then update every returned file so the old path fragments become:

```text
src/Common/navigation
src/Common/shaders
src/Common/state_machine
src/Core/events
src/Config/platform
src/Localization/translations
```

- [ ] **Step 5: Verify the old shared paths are gone**

```powershell
rg -n "src/Common/Navigation|src/Common/Shaders|src/Common/StateMachine|src/Core/Events|src/Config/Platform|src/Localization/Translations" src project.godot
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add project.godot src/Common src/Core src/Config src/Localization src/Entities/Creatures/creature.tscn src/Entities/Player/player.tscn
git commit -m "refactor: normalize shared runtime folder names"
```

### Task 2: Normalize UI Runtime Layout

**Files:**
- Modify: `project.godot`
- Modify: `src/Ui/Common/ui_manager.gd`
- Modify: `src/Ui/Common/startup_splash_screen.tscn`
- Modify: `src/Ui/Common/CombatPreviewPanel/combat_preview_panel.tscn`
- Modify: `src/Ui/Common/CombatResultPanel/combat_result_panel.tscn`
- Modify: `src/Ui/Common/Debug/debug_panel.gd`
- Modify: `src/Ui/Common/Styles/Profiles/inventory_board_style.tres`
- Modify: `src/Ui/Common/Styles/Profiles/inventory_section_style.tres`
- Modify: `src/Ui/Common/Styles/Profiles/inventory_title_style.tres`
- Modify: `src/Ui/Common/inventory_screen.tscn`
- Modify: `src/Ui/Desktop/Gui/MainScreen/main_screen.gd`
- Modify: `src/Ui/Desktop/Gui/MainScreen/main_screen.tscn`
- Modify: `src/Ui/Desktop/Gui/MainScreen/main_screen_desktop.gd`
- Modify: `src/Ui/Desktop/Gui/MainScreen/background_controller.gd`
- Modify: `src/Ui/Desktop/Gui/MainScreen/main_screen_theme.tres`
- Modify: `src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn`
- Modify: `src/Ui/Desktop/Combat/desktop_combat_ui.tscn`
- Modify: `src/Ui/Desktop/Debug/debug_overlay.tscn`
- Modify: `src/Ui/Desktop/Hud/SystemHud/system_hud.tscn`
- Modify: `src/Ui/Desktop/Inventory/inventory_panel.gd`
- Modify: `src/Ui/Desktop/Inventory/inventory_panel.tscn`
- Modify: `src/Ui/Desktop/Inventory/inventory_screen.tscn`
- Modify: `src/Ui/Mobile/Gui/MainScreen/main_screen_mobile.gd`
- Modify: `src/Ui/Mobile/Gui/MainScreen/main_screen_mobile.tscn`
- Modify: `src/Ui/Mobile/CharacterCreator/character_creator_panel_mobile.tscn`
- Modify: `src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn`
- Modify: `src/Ui/Mobile/Inventory/inventory_panel_mobile.tscn`
- Modify: `src/Ui/Hud/creature_action_hud.tscn`
- Modify: `src/World/Overworld/overworld.tscn`
- Modify: `src/World/Combat/combat_scene.tscn`
- Rename: `src/Ui/Common/` -> `src/Ui/common/`
- Rename: `src/Ui/Desktop/` -> `src/Ui/desktop/`
- Rename: `src/Ui/Mobile/` -> `src/Ui/mobile/`
- Rename: `src/Ui/Hud/` -> `src/Ui/hud/`
- Rename: `src/Ui/common/CombatPreviewPanel/` -> `src/Ui/common/combat_preview_panel/`
- Rename: `src/Ui/common/CombatResultPanel/` -> `src/Ui/common/combat_result_panel/`
- Rename: `src/Ui/common/Debug/` -> `src/Ui/common/debug/`
- Rename: `src/Ui/common/Styles/` -> `src/Ui/common/styles/`
- Rename: `src/Ui/common/styles/Profiles/` -> `src/Ui/common/styles/profiles/`
- Rename: `src/Ui/desktop/CharacterCreator/` -> `src/Ui/desktop/character_creator/`
- Rename: `src/Ui/desktop/Combat/` -> `src/Ui/desktop/combat/`
- Rename: `src/Ui/desktop/Debug/` -> `src/Ui/desktop/debug/`
- Rename: `src/Ui/desktop/Hud/` -> `src/Ui/desktop/hud/`
- Rename: `src/Ui/desktop/hud/SystemHud/` -> `src/Ui/desktop/hud/system_hud/`
- Rename: `src/Ui/desktop/Inventory/` -> `src/Ui/desktop/inventory/`
- Rename: `src/Ui/mobile/CharacterCreator/` -> `src/Ui/mobile/character_creator/`
- Rename: `src/Ui/mobile/Combat/` -> `src/Ui/mobile/combat/`
- Rename: `src/Ui/mobile/Hud/` -> `src/Ui/mobile/hud/`
- Rename: `src/Ui/mobile/hud/SystemHud/` -> `src/Ui/mobile/hud/system_hud/`
- Rename: `src/Ui/mobile/Inventory/` -> `src/Ui/mobile/inventory/`
- Move: `src/Ui/desktop/Gui/MainScreen/` -> `src/Ui/desktop/main_screen/`
- Move: `src/Ui/mobile/Gui/MainScreen/` -> `src/Ui/mobile/main_screen/`

- [ ] **Step 1: Capture the UI stale-path baseline**

```powershell
rg -n "src/Ui/Common|src/Ui/Desktop|src/Ui/Mobile|src/Ui/Hud|src/Ui/Desktop/Gui/MainScreen|src/Ui/Mobile/Gui/MainScreen" src project.godot
```

Expected: matches in `ui_manager.gd`, the main screen scenes, `overworld.tscn`, inventory scenes, combat scenes, and the startup splash scene.

- [ ] **Step 2: Rename the main UI folders**

```powershell
Rename-Item src/Ui/Common src/Ui/__common_tmp
Rename-Item src/Ui/__common_tmp src/Ui/common
Rename-Item src/Ui/Desktop src/Ui/__desktop_tmp
Rename-Item src/Ui/__desktop_tmp src/Ui/desktop
Rename-Item src/Ui/Mobile src/Ui/__mobile_tmp
Rename-Item src/Ui/__mobile_tmp src/Ui/mobile
Rename-Item src/Ui/Hud src/Ui/__hud_tmp
Rename-Item src/Ui/__hud_tmp src/Ui/hud
Rename-Item src/Ui/common/CombatPreviewPanel src/Ui/common/combat_preview_panel
Rename-Item src/Ui/common/CombatResultPanel src/Ui/common/combat_result_panel
Rename-Item src/Ui/common/Debug src/Ui/common/debug
Rename-Item src/Ui/common/Styles src/Ui/common/styles
Rename-Item src/Ui/common/styles/Profiles src/Ui/common/styles/profiles
Rename-Item src/Ui/desktop/CharacterCreator src/Ui/desktop/character_creator
Rename-Item src/Ui/desktop/Combat src/Ui/desktop/combat
Rename-Item src/Ui/desktop/Debug src/Ui/desktop/debug
Rename-Item src/Ui/desktop/Hud src/Ui/desktop/hud
Rename-Item src/Ui/desktop/hud/SystemHud src/Ui/desktop/hud/system_hud
Rename-Item src/Ui/desktop/Inventory src/Ui/desktop/inventory
Rename-Item src/Ui/mobile/CharacterCreator src/Ui/mobile/character_creator
Rename-Item src/Ui/mobile/Combat src/Ui/mobile/combat
Rename-Item src/Ui/mobile/Hud src/Ui/mobile/hud
Rename-Item src/Ui/mobile/hud/SystemHud src/Ui/mobile/hud/system_hud
Rename-Item src/Ui/mobile/Inventory src/Ui/mobile/inventory
```

- [ ] **Step 3: Flatten the `Gui/MainScreen` feature into `main_screen`**

```powershell
New-Item -ItemType Directory -Force -Path src/Ui/desktop/main_screen | Out-Null
Move-Item src/Ui/desktop/Gui/MainScreen/* src/Ui/desktop/main_screen/
Remove-Item src/Ui/desktop/Gui/MainScreen -Force
Remove-Item src/Ui/desktop/Gui -Force
New-Item -ItemType Directory -Force -Path src/Ui/mobile/main_screen | Out-Null
Move-Item src/Ui/mobile/Gui/MainScreen/* src/Ui/mobile/main_screen/
Remove-Item src/Ui/mobile/Gui/MainScreen -Force
Remove-Item src/Ui/mobile/Gui -Force
```

- [ ] **Step 4: Update `UiManager` preload constants to the new runtime layout**

```gdscript
const SYSTEM_HUD_DESKTOP_SCENE: PackedScene = preload("res://src/Ui/desktop/hud/system_hud/system_hud.tscn")
const SYSTEM_HUD_MOBILE_SCENE: PackedScene = preload("res://src/Ui/mobile/hud/system_hud/system_hud_mobile.tscn")
const DEBUG_OVERLAY_DESKTOP_SCENE: PackedScene = preload("res://src/Ui/desktop/debug/debug_overlay.tscn")
const MAIN_SCREEN_DESKTOP_SCENE: PackedScene = preload("res://src/Ui/desktop/main_screen/main_screen.tscn")
const MAIN_SCREEN_MOBILE_SCENE: PackedScene = preload("res://src/Ui/mobile/main_screen/main_screen_mobile.tscn")
const INVENTORY_PANEL_DESKTOP_SCENE: PackedScene = preload("res://src/Ui/desktop/inventory/inventory_panel.tscn")
const INVENTORY_PANEL_MOBILE_SCENE: PackedScene = preload("res://src/Ui/mobile/inventory/inventory_panel_mobile.tscn")
```

- [ ] **Step 5: Update `overworld.tscn` and the UI scenes to the new paths**

```gdresource
[ext_resource type="PackedScene" path="res://src/Ui/desktop/debug/debug_overlay.tscn" id="4"]
[ext_resource type="PackedScene" path="res://src/Ui/desktop/main_screen/main_screen.tscn" id="8_main_screen"]
[ext_resource type="PackedScene" path="res://src/Ui/desktop/hud/system_hud/system_hud.tscn" id="11_system_hud"]
[ext_resource type="PackedScene" path="res://src/Ui/desktop/inventory/inventory_panel.tscn" id="12_inventory_panel"]
[ext_resource type="Script" path="res://src/Ui/common/ui_manager.gd" id="13_ui_manager"]
[ext_resource type="PackedScene" path="res://src/Ui/hud/creature_action_hud.tscn" id="14_creature_action_hud"]
[ext_resource type="PackedScene" path="res://src/Ui/common/combat_preview_panel/combat_preview_panel.tscn" id="18_combat_preview"]
```

Also update every `.tscn` / `.tres` listed above so `common`, `desktop`, `mobile`, `hud`, the nested feature folders, and `main_screen` references point at the normalized locations.

- [ ] **Step 6: Verify UI stale paths are gone**

```powershell
rg -n "src/Ui/Common|src/Ui/Desktop|src/Ui/Mobile|src/Ui/Hud|src/Ui/Desktop/Gui/MainScreen|src/Ui/Mobile/Gui/MainScreen" src project.godot
```

Expected: no output.

- [ ] **Step 7: Smoke-test the project entry scene**

```bash
godot4 --headless --path . --scene res://src/World/main.tscn --quit-after 10
```

Expected: exit code `0` with no missing-resource errors for `Ui` paths.

- [ ] **Step 8: Commit**

```bash
git add project.godot src/Ui src/World/Overworld/overworld.tscn src/World/Combat/combat_scene.tscn
git commit -m "refactor: normalize ui runtime layout"
```

### Task 3: Normalize World Runtime Layout And Location Names

**Files:**
- Modify: `src/World/main.gd`
- Modify: `src/World/main.tscn`
- Modify: `src/World/Combat/combat_scene.tscn`
- Modify: `src/World/Overworld/overworld.gd`
- Modify: `src/World/Overworld/overworld.tscn`
- Modify: `src/World/Overworld/overworld_player_spawner.gd`
- Modify: `src/World/Overworld/overworld_creature_spawner.gd`
- Modify: `src/World/Overworld/overworld_character_creator_controller.gd`
- Modify: `src/World/Overworld/overworld_creature_selection_controller.gd`
- Modify: `src/World/Overworld/overworld_session_controller.gd`
- Modify: `src/World/Overworld/navigation_blocker_registry.gd`
- Modify: `src/World/Overworld/Chunks/chunk.gd`
- Modify: `src/World/Streaming/chunk_manager.gd`
- Modify: `src/World/Streaming/overworld_chunk_water_shader.gd`
- Modify: `src/World/Locations/Towns/Starting_Village/Npcs/.gitkeep`
- Rename: `src/World/Combat/` -> `src/World/combat/`
- Rename: `src/World/Locations/` -> `src/World/locations/`
- Rename: `src/World/Overworld/` -> `src/World/overworld/`
- Rename: `src/World/Streaming/` -> `src/World/streaming/`
- Rename: `src/World/locations/Arenas/` -> `src/World/locations/arenas/`
- Rename: `src/World/locations/Dungeons/` -> `src/World/locations/dungeons/`
- Rename: `src/World/locations/Interiors/` -> `src/World/locations/interiors/`
- Rename: `src/World/locations/Towns/` -> `src/World/locations/towns/`
- Rename: `src/World/overworld/Chunks/` -> `src/World/overworld/chunks/`
- Rename: `src/World/overworld/Shaders/` -> `src/World/overworld/shaders/`
- Rename: `src/World/overworld/Tilesets/` -> `src/World/overworld/tilesets/`
- Rename: `src/World/locations/dungeons/Ancient_Ruins/` -> `src/World/locations/dungeons/ancient_ruins/`
- Rename: `src/World/locations/dungeons/Goblin_Cave/` -> `src/World/locations/dungeons/goblin_cave/`
- Rename: `src/World/locations/dungeons/goblin_cave/Encounters/` -> `src/World/locations/dungeons/goblin_cave/encounters/`
- Rename: `src/World/locations/interiors/House_Interior/` -> `src/World/locations/interiors/house_interior/`
- Rename: `src/World/locations/interiors/Shop_Interior/` -> `src/World/locations/interiors/shop_interior/`
- Rename: `src/World/locations/towns/Capital_City/` -> `src/World/locations/towns/capital_city/`
- Rename: `src/World/locations/towns/Starting_Village/` -> `src/World/locations/towns/starting_village/`
- Rename: `src/World/locations/towns/starting_village/Npcs/` -> `src/World/locations/towns/starting_village/npcs/`

- [ ] **Step 1: Capture the current world path surface**

```powershell
rg -n "src/World/Combat|src/World/Overworld|src/World/Streaming|Ancient_Ruins|Goblin_Cave|House_Interior|Shop_Interior|Capital_City|Starting_Village|/Npcs/" src docs project.godot
```

Expected: matches in `src/World` scenes/scripts plus documentation files that mention location paths.

- [ ] **Step 2: Rename the world runtime folders**

```powershell
Rename-Item src/World/Combat src/World/__combat_tmp
Rename-Item src/World/__combat_tmp src/World/combat
Rename-Item src/World/Locations src/World/__locations_tmp
Rename-Item src/World/__locations_tmp src/World/locations
Rename-Item src/World/Overworld src/World/__overworld_tmp
Rename-Item src/World/__overworld_tmp src/World/overworld
Rename-Item src/World/Streaming src/World/__streaming_tmp
Rename-Item src/World/__streaming_tmp src/World/streaming
Rename-Item src/World/locations/Arenas src/World/locations/arenas
Rename-Item src/World/locations/Dungeons src/World/locations/dungeons
Rename-Item src/World/locations/Interiors src/World/locations/interiors
Rename-Item src/World/locations/Towns src/World/locations/towns
Rename-Item src/World/overworld/Chunks src/World/overworld/__chunks_tmp
Rename-Item src/World/overworld/__chunks_tmp src/World/overworld/chunks
Rename-Item src/World/overworld/Shaders src/World/overworld/__shaders_tmp
Rename-Item src/World/overworld/__shaders_tmp src/World/overworld/shaders
Rename-Item src/World/overworld/Tilesets src/World/overworld/__tilesets_tmp
Rename-Item src/World/overworld/__tilesets_tmp src/World/overworld/tilesets
```

- [ ] **Step 3: Rename location folders to `snake_case`**

```powershell
Rename-Item 'src/World/locations/dungeons/Ancient_Ruins' 'ancient_ruins'
Rename-Item 'src/World/locations/dungeons/Goblin_Cave' 'goblin_cave'
Rename-Item 'src/World/locations/dungeons/goblin_cave/Encounters' 'encounters'
Rename-Item 'src/World/locations/interiors/House_Interior' 'house_interior'
Rename-Item 'src/World/locations/interiors/Shop_Interior' 'shop_interior'
Rename-Item 'src/World/locations/towns/Capital_City' 'capital_city'
Rename-Item 'src/World/locations/towns/Starting_Village' 'starting_village'
Rename-Item 'src/World/locations/towns/starting_village/Npcs' 'npcs'
```

- [ ] **Step 4: Update world scene and script references**

```gdresource
[ext_resource type="Script" path="res://src/World/overworld/overworld.gd" id="1"]
[ext_resource type="Script" path="res://src/World/streaming/chunk_manager.gd" id="3"]
[ext_resource type="Script" path="res://src/World/overworld/overworld_player_spawner.gd" id="5_spawner"]
[ext_resource type="Script" path="res://src/World/overworld/overworld_session_controller.gd" id="6_session"]
[ext_resource type="Script" path="res://src/World/overworld/navigation_blocker_registry.gd" id="7_registry"]
[ext_resource type="Script" path="res://src/World/overworld/overworld_creature_spawner.gd" id="10_creature_spawner"]
[ext_resource type="Script" path="res://src/World/overworld/overworld_creature_selection_controller.gd" id="16_creature_selection_ctrl"]
[ext_resource type="Script" path="res://src/World/overworld/overworld_character_creator_controller.gd" id="17_character_creator_ctrl"]
```

Update `src/World/main.tscn`, `src/World/main.gd`, `src/World/combat/combat_scene.tscn`, `src/World/streaming/chunk_manager.gd`, and any world chunk scenes so they reference the normalized paths.

- [ ] **Step 5: Verify the old world paths are gone**

```powershell
rg -n "src/World/Combat|src/World/Overworld|src/World/Streaming|Ancient_Ruins|Goblin_Cave|House_Interior|Shop_Interior|Capital_City|Starting_Village|/Npcs/" src docs project.godot
```

Expected: no output in `src/`; only historical docs are allowed if they are intentionally left unchanged.

- [ ] **Step 6: Load the main world scene**

```bash
godot4 --headless --path . --scene res://src/World/main.tscn --quit-after 10
```

Expected: exit code `0` with no missing-resource errors for `World` paths.

- [ ] **Step 7: Commit**

```bash
git add src/World docs
git commit -m "refactor: normalize world runtime folders"
```

### Task 4: Normalize Entity Runtime Layout, Creature Catalog, And Item Catalog Paths

**Files:**
- Modify: `src/Entities/Creatures/creature.gd`
- Modify: `src/Entities/Creatures/creature.tscn`
- Modify: `src/Entities/Creatures/creature_catalog.gd`
- Modify: `src/Entities/Creatures/creature_catalog_service.gd`
- Modify: `src/Entities/Creatures/creature_data.gd`
- Modify: `src/Entities/Creatures/creature_factory.gd`
- Modify: `src/Entities/Creatures/README.md`
- Modify: `src/Entities/Creatures/Tools/creature_catalog_builder.gd`
- Modify: `src/Entities/Creatures/Tools/creature_catalog_builder_runner.gd`
- Modify: `src/Entities/Creatures/Tools/creature_catalog_builder_runner.tscn`
- Modify: `src/Entities/Items/item_data.gd`
- Modify: `src/Entities/Items/README.md`
- Modify: `src/Entities/Player/player.gd`
- Modify: `src/Entities/Player/player.tscn`
- Modify: `src/Entities/Player/Config/player_input_config.tres`
- Modify: `src/Entities/Player/Config/player_movement_config.tres`
- Modify: `src/Entities/Player/Tools/player_cosmetic_catalog_builder.gd`
- Modify: `src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.gd`
- Modify: `src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn`
- Modify: `src/Entities/Player/Tools/README.md`
- Modify: `src/Entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- Modify: `src/Entities/Systems/Combat/Tests/run_combat_tests.gd`
- Modify: `src/World/overworld/overworld.tscn`
- Rename: `src/Entities/Creatures/` -> `src/Entities/creatures/`
- Move: `src/Entities/creatures/creature.gd` -> `src/Entities/creatures/base/creature.gd`
- Move: `src/Entities/creatures/creature.tscn` -> `src/Entities/creatures/base/creature.tscn`
- Move: `src/Entities/creatures/creature_catalog.gd` -> `src/Entities/creatures/base/creature_catalog.gd`
- Move: `src/Entities/creatures/creature_catalog_service.gd` -> `src/Entities/creatures/base/creature_catalog_service.gd`
- Move: `src/Entities/creatures/creature_data.gd` -> `src/Entities/creatures/base/creature_data.gd`
- Move: `src/Entities/creatures/creature_factory.gd` -> `src/Entities/creatures/base/creature_factory.gd`
- Rename: `src/Entities/creatures/Types/` -> `src/Entities/creatures/catalog/`
- Rename: `src/Entities/Player/` -> `src/Entities/player/`
- Rename: `src/Entities/creatures/Components/` -> `src/Entities/creatures/components/`
- Rename: `src/Entities/creatures/Effects/` -> `src/Entities/creatures/effects/`
- Rename: `src/Entities/creatures/Resources/` -> `src/Entities/creatures/resources/`
- Rename: `src/Entities/creatures/Spawning/` -> `src/Entities/creatures/spawning/`
- Rename: `src/Entities/creatures/Tests/` -> `src/Entities/creatures/tests/`
- Rename: `src/Entities/creatures/Tools/` -> `src/Entities/creatures/tools/`
- Rename: `src/Entities/Items/` -> `src/Entities/items/`
- Rename: `src/Entities/items/Types/` -> `src/Entities/items/catalog/`
- Rename: `src/Entities/player/Assets/` -> `src/Entities/player/assets/`
- Rename: `src/Entities/player/Components/` -> `src/Entities/player/components/`
- Rename: `src/Entities/player/Config/` -> `src/Entities/player/config/`
- Rename: `src/Entities/player/Input/` -> `src/Entities/player/input/`
- Rename: `src/Entities/player/Resources/` -> `src/Entities/player/resources/`
- Rename: `src/Entities/player/Services/` -> `src/Entities/player/services/`
- Rename: `src/Entities/player/Sounds/` -> `src/Entities/player/sounds/`
- Rename: `src/Entities/player/States/` -> `src/Entities/player/states/`
- Rename: `src/Entities/player/Tests/` -> `src/Entities/player/tests/`
- Rename: `src/Entities/player/Tools/` -> `src/Entities/player/tools/`
- Rename: `src/Entities/Interactables/` -> `src/Entities/interactables/`
- Rename: `src/Entities/Skills/` -> `src/Entities/skills/`
- Rename: `src/Entities/Systems/` -> `src/Entities/systems/`
- Rename: `src/Entities/systems/Combat/` -> `src/Entities/systems/combat/`
- Rename: `src/Entities/systems/Inventory/` -> `src/Entities/systems/inventory/`

- [ ] **Step 1: Capture entity path hot spots before moving anything**

```powershell
rg -n "src/Entities/Creatures|src/Entities/Creatures/Types|src/Entities/Items|src/Entities/Items/Types|src/Entities/Player|src/Entities/Interactables|src/Entities/Skills|src/Entities/Systems" src docs project.godot
```

Expected: many matches, especially in the creature builder, creature catalog resources, item inventory resources, player tools, and docs.

- [ ] **Step 2: Rename the entity root folders**

```powershell
Rename-Item src/Entities/Creatures src/Entities/__creatures_tmp
Rename-Item src/Entities/__creatures_tmp src/Entities/creatures
Rename-Item src/Entities/Player src/Entities/__player_tmp
Rename-Item src/Entities/__player_tmp src/Entities/player
Rename-Item src/Entities/Items src/Entities/__items_tmp
Rename-Item src/Entities/__items_tmp src/Entities/items
Rename-Item src/Entities/Interactables src/Entities/__interactables_tmp
Rename-Item src/Entities/__interactables_tmp src/Entities/interactables
Rename-Item src/Entities/Skills src/Entities/__skills_tmp
Rename-Item src/Entities/__skills_tmp src/Entities/skills
Rename-Item src/Entities/Systems src/Entities/__systems_tmp
Rename-Item src/Entities/__systems_tmp src/Entities/systems
Rename-Item src/Entities/creatures/Components src/Entities/creatures/components
Rename-Item src/Entities/creatures/Effects src/Entities/creatures/effects
Rename-Item src/Entities/creatures/Resources src/Entities/creatures/resources
Rename-Item src/Entities/creatures/Spawning src/Entities/creatures/spawning
Rename-Item src/Entities/creatures/Tests src/Entities/creatures/tests
Rename-Item src/Entities/creatures/Tools src/Entities/creatures/tools
Rename-Item src/Entities/player/Assets src/Entities/player/assets
Rename-Item src/Entities/player/Components src/Entities/player/components
Rename-Item src/Entities/player/Config src/Entities/player/config
Rename-Item src/Entities/player/Input src/Entities/player/input
Rename-Item src/Entities/player/Resources src/Entities/player/resources
Rename-Item src/Entities/player/Services src/Entities/player/services
Rename-Item src/Entities/player/Sounds src/Entities/player/sounds
Rename-Item src/Entities/player/States src/Entities/player/states
Rename-Item src/Entities/player/Tests src/Entities/player/tests
Rename-Item src/Entities/player/Tools src/Entities/player/tools
Rename-Item src/Entities/systems/Combat src/Entities/systems/combat
Rename-Item src/Entities/systems/Inventory src/Entities/systems/inventory
```

- [ ] **Step 3: Create `base/` and `catalog/` inside creatures and move the root runtime files**

```powershell
New-Item -ItemType Directory -Force -Path src/Entities/creatures/base | Out-Null
Move-Item src/Entities/creatures/creature.gd src/Entities/creatures/base/creature.gd
Move-Item src/Entities/creatures/creature.tscn src/Entities/creatures/base/creature.tscn
Move-Item src/Entities/creatures/creature_catalog.gd src/Entities/creatures/base/creature_catalog.gd
Move-Item src/Entities/creatures/creature_catalog_service.gd src/Entities/creatures/base/creature_catalog_service.gd
Move-Item src/Entities/creatures/creature_data.gd src/Entities/creatures/base/creature_data.gd
Move-Item src/Entities/creatures/creature_factory.gd src/Entities/creatures/base/creature_factory.gd
Rename-Item src/Entities/creatures/Types catalog
Rename-Item src/Entities/items/Types catalog
```

- [ ] **Step 4: Update the creature builder to write into `catalog/` and `base/`**

```gdscript
const TYPES_ROOT: String = "res://src/Entities/creatures/catalog"
const CATALOG_PATH: String = "res://src/Entities/creatures/resources/creature_catalog.tres"
const CREATURE_CATALOG_SCRIPT: Script = preload("res://src/Entities/creatures/base/creature_catalog.gd")
```

```gdscript
# src/Entities/creatures/base/creature_data.gd
## Top-level folder under catalog (humanoids, animals, ...).
```

Also update the builder path parser and emitted paths so they use lowercase entry folders:

```gdscript
if parts[2].to_lower() != "sprites":
	push_warning("CreatureCatalogBuilder: sprite must be under 'sprites/' in '%s'." % sprite_path)

return TYPES_ROOT.path_join("%s/%s/data/%s.tres" % [category, creature_folder, String(entry["creature_id"])])
```

Update all explicit `res://src/Entities/Creatures/...` and `res://src/Entities/Items/Types/...` strings in the listed files so they point to the normalized runtime layout.

- [ ] **Step 5: Rename creature category folders and then normalize creature entry folder names in one scripted sweep**

```powershell
Rename-Item src/Entities/creatures/catalog/Animals animals
Rename-Item src/Entities/creatures/catalog/Demons demons
Rename-Item src/Entities/creatures/catalog/Dragons dragons
Rename-Item src/Entities/creatures/catalog/Holy holy
Rename-Item src/Entities/creatures/catalog/Humanoids humanoids
Rename-Item src/Entities/creatures/catalog/Magical magical
Rename-Item src/Entities/creatures/catalog/Monsters monsters
Rename-Item src/Entities/creatures/catalog/Undead undead
Rename-Item src/Entities/creatures/catalog/Vermin vermin
```

```powershell
$script = @'
function To-SnakeCase([string]$Name) {
  return ($Name.ToLower() -replace "[^a-z0-9]+", "_").Trim("_")
}

Get-ChildItem src/Entities/creatures/catalog -Directory | ForEach-Object {
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
Get-ChildItem src/Entities/creatures/catalog -Directory | ForEach-Object {
  Get-ChildItem $_.FullName -Directory | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName 'Data')) { Rename-Item (Join-Path $_.FullName 'Data') 'data' }
    if (Test-Path (Join-Path $_.FullName 'Sprites')) { Rename-Item (Join-Path $_.FullName 'Sprites') 'sprites' }
  }
}

Get-ChildItem src/Entities/items/catalog -Directory | ForEach-Object {
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
godot4 --headless --path . --scene res://src/Entities/creatures/tools/creature_catalog_builder_runner.tscn --quit
```

Expected:

```text
CreatureCatalogBuilder summary line ends with `errors=0`
CreatureCatalogBuilder runner completed line contains `"errors": 0`
```

- [ ] **Step 7: Verify the creature and item catalogs still validate**

```bash
godot4 --headless --path . --script res://src/Entities/creatures/tests/run_creature_catalog_validation.gd
godot4 --headless --path . --scene res://src/Entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200
godot4 --headless --path . --script res://src/Entities/systems/combat/tests/run_combat_tests.gd
```

Expected: all commands exit `0`, and the creature runtime smoke test reports no missing script/resource paths.

- [ ] **Step 8: Verify stale entity paths are gone**

```powershell
rg -n "src/Entities/Creatures|src/Entities/Creatures/Types|src/Entities/Items/Types|src/Entities/Player|src/Entities/Interactables|src/Entities/Skills|src/Entities/Systems" src project.godot
```

Expected: no output in `src/`; documentation can be updated in the next task if historical notes still mention old paths.

- [ ] **Step 9: Commit**

```bash
git add src/Entities src/World/overworld/overworld.tscn
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
- Modify: `src/Entities/Creatures/README.md`
- Modify: `src/Entities/Items/README.md`
- Modify: `src/Entities/Player/Tools/README.md`

- [ ] **Step 1: Sweep docs and README files for stale paths**

```powershell
rg -n "src/Ui/Common|src/Ui/Desktop|src/Ui/Mobile|src/Ui/Hud|src/World/Overworld|src/World/Streaming|src/World/Combat|src/Entities/Creatures|src/Entities/Items/Types|src/Entities/Player|src/Entities/Systems|src/Entities/Interactables|src/Entities/Skills" docs src/Entities/*/README.md src/Localization/README.md
```

Expected: matches only in docs and README files at this point.

- [ ] **Step 2: Update the creature, item, player, and project docs**

```markdown
- `res://src/Entities/creatures/catalog/animals/agitated_orangutan/sprites/AgitatedOrangutan_128x32.png`
- `res://src/Entities/items/catalog/consumables/potions/health_potion/data/consumable_health_potion.tres`
- `res://src/Ui/desktop/main_screen/main_screen.tscn`
- `res://src/World/overworld/overworld.tscn`
```

Replace every old runtime path example in the listed docs with the normalized path that now exists in `src/`.

- [ ] **Step 3: Run the final stale-path audit**

```powershell
rg -n "src/Ui/Common|src/Ui/Desktop|src/Ui/Mobile|src/Ui/Hud|src/World/Overworld|src/World/Streaming|src/World/Combat|src/Entities/Creatures|src/Entities/Items/Types|src/Entities/Player|src/Entities/Systems|src/Entities/Interactables|src/Entities/Skills|Ancient_Ruins|Goblin_Cave|House_Interior|Shop_Interior|Capital_City|Starting_Village|/Npcs/" src project.godot
```

Expected: no output.

- [ ] **Step 4: Run final project verification**

```bash
godot4 --headless --path . --scene res://src/World/main.tscn --quit-after 10
godot4 --headless --path . --script res://src/Entities/creatures/tests/run_creature_catalog_validation.gd
godot4 --headless --path . --scene res://src/Entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200
godot4 --headless --path . --script res://src/Entities/systems/combat/tests/run_combat_tests.gd
```

Expected: all commands exit `0`.

- [ ] **Step 5: Commit**

```bash
git add docs src
git commit -m "docs: update runtime structure references"
```
