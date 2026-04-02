# Src Filesystem Normalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Normalize every directory and file basename under `src/` to lowercase `snake_case`, while updating all dependent references in runtime files, generated resources, and docs without introducing new path-related breakage.

**Architecture:** Execute the rename as layered filesystem passes rather than a single global sweep. Each pass renames one bounded slice of the tree, updates all affected references immediately, and runs a stale-path audit plus headless verification before moving on. Windows case-only renames must always use temporary intermediate names.

**Tech Stack:** Godot 4.6, GDScript, `.tscn`, `.tres`, `.import`, PowerShell, `rg`, git

---

## File Map

- `src/Common/`, `src/Config/`, `src/Core/`, `src/Entities/`, `src/Localization/`, `src/Ui/`, `src/Utils/`, `src/World/`
- `project.godot`
- `docs/**` that point at runtime paths
- high-churn content roots:
  - `src/Ui/Assets/**`
  - `src/World/Overworld/Tilesets/**`
  - `src/Entities/Creatures/Types/**`
  - `src/Entities/Items/Types/**`
  - `src/Entities/**/Tools/**`
  - `src/Entities/**/Resources/**`
  - `src/Entities/**/Tests/**`

### Task 1: Audit The Current Rename Surface

**Files:**
- Read: `src/**`
- Read: `project.godot`
- Read: `docs/**`

- [ ] **Step 1: Snapshot top-level `src` roots**

Run:

```powershell
Get-ChildItem src -Force | Select-Object Mode,Name,FullName
```

Expected: mixed-case roots such as `Common`, `Core`, `Entities`, `Ui`, and `World`.

- [ ] **Step 2: Snapshot mixed-case directories and basenames under `src`**

Run:

```powershell
Get-ChildItem src -Directory -Recurse | Where-Object { $_.Name -cmatch '[A-Z]' } | Select-Object FullName
Get-ChildItem src -File -Recurse | Where-Object { $_.BaseName -cmatch '[A-Z ]' } | Select-Object FullName
```

Expected: mixed-case structural folders, creature content folders, UI asset-pack folders, and many file basenames.

- [ ] **Step 3: Record the baseline path-reference surface**

Run:

```powershell
rg -n "src/Common|src/Config|src/Core|src/Entities|src/Localization|src/Ui|src/Utils|src/World" src project.godot docs
```

Expected: many matches across scripts, scenes, resources, and docs.

- [ ] **Step 4: Commit the audit checkpoint**

```bash
git add docs/superpowers/plans/2026-04-02-src-filesystem-normalization.md
git commit -m "docs: add src filesystem normalization plan"
```

### Task 2: Normalize Top-Level `src` Domain Directories

**Files:**
- Modify: `project.godot`
- Modify: `src/**`
- Modify: `docs/**`
- Rename: `src/Common/` -> `src/common/`
- Rename: `src/Config/` -> `src/config/`
- Rename: `src/Core/` -> `src/core/`
- Rename: `src/Entities/` -> `src/entities/`
- Rename: `src/Localization/` -> `src/localization/`
- Rename: `src/Ui/` -> `src/ui/`
- Rename: `src/Utils/` -> `src/utils/`
- Rename: `src/World/` -> `src/world/`

- [ ] **Step 1: Verify the current top-level path references**

Run:

```powershell
rg -n "src/Common|src/Config|src/Core|src/Entities|src/Localization|src/Ui|src/Utils|src/World" src project.godot docs
```

Expected: matches in serialized resources, scripts, project config, and docs.

- [ ] **Step 2: Perform Windows-safe temporary renames**

Run:

```powershell
Rename-Item src/Common src/__common_tmp; Rename-Item src/__common_tmp src/common
Rename-Item src/Config src/__config_tmp; Rename-Item src/__config_tmp src/config
Rename-Item src/Core src/__core_tmp; Rename-Item src/__core_tmp src/core
Rename-Item src/Entities src/__entities_tmp; Rename-Item src/__entities_tmp src/entities
Rename-Item src/Localization src/__localization_tmp; Rename-Item src/__localization_tmp src/localization
Rename-Item src/Ui src/__ui_tmp; Rename-Item src/__ui_tmp src/ui
Rename-Item src/Utils src/__utils_tmp; Rename-Item src/__utils_tmp src/utils
Rename-Item src/World src/__world_tmp; Rename-Item src/__world_tmp src/world
```

- [ ] **Step 3: Rewrite top-level path references**

Run:

```powershell
rg -l "src/Common|src/Config|src/Core|src/Entities|src/Localization|src/Ui|src/Utils|src/World" src project.godot docs |
  ForEach-Object {
    (Get-Content $_ -Raw).
      Replace('src/Common','src/common').
      Replace('src/Config','src/config').
      Replace('src/Core','src/core').
      Replace('src/Entities','src/entities').
      Replace('src/Localization','src/localization').
      Replace('src/Ui','src/ui').
      Replace('src/Utils','src/utils').
      Replace('src/World','src/world') |
      Set-Content $_
  }
```

- [ ] **Step 4: Verify and commit**

Run:

```powershell
rg -n "src/Common|src/Config|src/Core|src/Entities|src/Localization|src/Ui|src/Utils|src/World" src project.godot
git diff --check
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/world/main.tscn --quit-after 10
```

Expected: stale-path audit clean; diff clean; Godot exit `0` with only known baseline debt.

```bash
git add project.godot src docs
git commit -m "refactor: normalize top-level src domain paths"
```

### Task 3: Normalize Shared Structural Subdirectories

**Files:**
- Modify: `src/common/**`
- Modify: `src/config/**`
- Modify: `src/core/**`
- Modify: `src/localization/**`
- Modify: `project.godot`
- Rename: `src/common/Navigation/` -> `src/common/navigation/`
- Rename: `src/common/Shaders/` -> `src/common/shaders/`
- Rename: `src/common/StateMachine/` -> `src/common/state_machine/`
- Rename: `src/common/Navigation/Policies/` -> `src/common/navigation/policies/`
- Rename: `src/config/Platform/` -> `src/config/platform/`
- Rename: `src/core/Events/` -> `src/core/events/`
- Rename: `src/localization/Translations/` -> `src/localization/translations/`

- [ ] **Step 1: Audit the shared structural paths**

Run:

```powershell
rg -n "src/common/Navigation|src/common/Shaders|src/common/StateMachine|src/common/Navigation/Policies|src/config/Platform|src/core/Events|src/localization/Translations" src project.godot docs
```

- [ ] **Step 2: Rename the shared subdirectories**

Run:

```powershell
Rename-Item src/common/Navigation src/common/__navigation_tmp; Rename-Item src/common/__navigation_tmp src/common/navigation
Rename-Item src/common/Shaders src/common/__shaders_tmp; Rename-Item src/common/__shaders_tmp src/common/shaders
Rename-Item src/common/StateMachine src/common/__state_machine_tmp; Rename-Item src/common/__state_machine_tmp src/common/state_machine
Rename-Item src/common/navigation/Policies src/common/navigation/__policies_tmp; Rename-Item src/common/navigation/__policies_tmp src/common/navigation/policies
Rename-Item src/config/Platform src/config/__platform_tmp; Rename-Item src/config/__platform_tmp src/config/platform
Rename-Item src/core/Events src/core/__events_tmp; Rename-Item src/core/__events_tmp src/core/events
Rename-Item src/localization/Translations src/localization/__translations_tmp; Rename-Item src/localization/__translations_tmp src/localization/translations
```

- [ ] **Step 3: Rewrite shared subdirectory references**

Run:

```powershell
rg -l "src/common/Navigation|src/common/Shaders|src/common/StateMachine|src/common/Navigation/Policies|src/config/Platform|src/core/Events|src/localization/Translations" src project.godot docs |
  ForEach-Object {
    (Get-Content $_ -Raw).
      Replace('src/common/Navigation','src/common/navigation').
      Replace('src/common/Shaders','src/common/shaders').
      Replace('src/common/StateMachine','src/common/state_machine').
      Replace('src/common/Navigation/Policies','src/common/navigation/policies').
      Replace('src/config/Platform','src/config/platform').
      Replace('src/core/Events','src/core/events').
      Replace('src/localization/Translations','src/localization/translations') |
      Set-Content $_
  }
```

- [ ] **Step 4: Verify and commit**

Run:

```powershell
rg -n "src/common/Navigation|src/common/Shaders|src/common/StateMachine|src/common/Navigation/Policies|src/config/Platform|src/core/Events|src/localization/Translations" src project.godot
git diff --check
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/world/main.tscn --quit-after 10
```

Expected: stale-path audit clean; diff clean; Godot exit `0` with no new path errors.

```bash
git add project.godot src docs
git commit -m "refactor: normalize shared src subdirectories"
```

### Task 4: Normalize `src/ui` And `src/world` Structural Paths

**Files:**
- Modify: `src/ui/**`
- Modify: `src/world/**`
- Modify: `project.godot`
- Modify: `docs/**`
- Rename: `src/ui/Assets/`, `src/ui/Common/`, `src/ui/Desktop/`, `src/ui/Hud/`, `src/ui/Mobile/`
- Rename: `src/world/Combat/`, `src/world/Locations/`, `src/world/Overworld/`, `src/world/Streaming/`
- Rename: structural subfolders such as `MainScreen`, `CharacterCreator`, `Inventory`, `SystemHud`, `Chunks`, `Shaders`, `Tilesets`
- Rename: project-owned world content folders such as `Ancient_Ruins`, `Goblin_Cave`, `Encounters`, `House_Interior`, `Shop_Interior`, `Capital_City`, `Starting_Village`, `Npcs`, `Cities`, `Clouds`, `Mountains`, `Objects`, `Terrains`

- [ ] **Step 1: Audit the UI and world path surface**

Run:

```powershell
rg -n "src/ui/Assets|src/ui/Common|src/ui/Desktop|src/ui/Hud|src/ui/Mobile|src/world/Combat|src/world/Locations|src/world/Overworld|src/world/Streaming|Ancient_Ruins|Goblin_Cave|House_Interior|Shop_Interior|Capital_City|Starting_Village|/Npcs/" src project.godot docs
```

- [ ] **Step 2: Rename the UI and world structural folders**

Run:

```powershell
Rename-Item src/ui/Assets src/ui/__assets_tmp; Rename-Item src/ui/__assets_tmp src/ui/assets
Rename-Item src/ui/Common src/ui/__common_tmp; Rename-Item src/ui/__common_tmp src/ui/common
Rename-Item src/ui/Desktop src/ui/__desktop_tmp; Rename-Item src/ui/__desktop_tmp src/ui/desktop
Rename-Item src/ui/Hud src/ui/__hud_tmp; Rename-Item src/ui/__hud_tmp src/ui/hud
Rename-Item src/ui/Mobile src/ui/__mobile_tmp; Rename-Item src/ui/__mobile_tmp src/ui/mobile
Rename-Item src/world/Combat src/world/__combat_tmp; Rename-Item src/world/__combat_tmp src/world/combat
Rename-Item src/world/Locations src/world/__locations_tmp; Rename-Item src/world/__locations_tmp src/world/locations
Rename-Item src/world/Overworld src/world/__overworld_tmp; Rename-Item src/world/__overworld_tmp src/world/overworld
Rename-Item src/world/Streaming src/world/__streaming_tmp; Rename-Item src/world/__streaming_tmp src/world/streaming
```

- [ ] **Step 3: Rename the known project-owned world location folders**

Run:

```powershell
Rename-Item src/world/locations/Dungeons src/world/locations/__dungeons_tmp; Rename-Item src/world/locations/__dungeons_tmp src/world/locations/dungeons
Rename-Item src/world/locations/Interiors src/world/locations/__interiors_tmp; Rename-Item src/world/locations/__interiors_tmp src/world/locations/interiors
Rename-Item src/world/locations/Towns src/world/locations/__towns_tmp; Rename-Item src/world/locations/__towns_tmp src/world/locations/towns
Rename-Item src/world/locations/dungeons/Ancient_Ruins src/world/locations/dungeons/__ancient_ruins_tmp; Rename-Item src/world/locations/dungeons/__ancient_ruins_tmp src/world/locations/dungeons/ancient_ruins
Rename-Item src/world/locations/dungeons/Goblin_Cave src/world/locations/dungeons/__goblin_cave_tmp; Rename-Item src/world/locations/dungeons/__goblin_cave_tmp src/world/locations/dungeons/goblin_cave
Rename-Item src/world/locations/interiors/House_Interior src/world/locations/interiors/__house_interior_tmp; Rename-Item src/world/locations/interiors/__house_interior_tmp src/world/locations/interiors/house_interior
Rename-Item src/world/locations/interiors/Shop_Interior src/world/locations/interiors/__shop_interior_tmp; Rename-Item src/world/locations/interiors/__shop_interior_tmp src/world/locations/interiors/shop_interior
Rename-Item src/world/locations/towns/Capital_City src/world/locations/towns/__capital_city_tmp; Rename-Item src/world/locations/towns/__capital_city_tmp src/world/locations/towns/capital_city
Rename-Item src/world/locations/towns/Starting_Village src/world/locations/towns/__starting_village_tmp; Rename-Item src/world/locations/towns/__starting_village_tmp src/world/locations/towns/starting_village
Rename-Item src/world/locations/towns/starting_village/Npcs src/world/locations/towns/starting_village/__npcs_tmp; Rename-Item src/world/locations/towns/starting_village/__npcs_tmp src/world/locations/towns/starting_village/npcs
Rename-Item src/world/overworld/Tilesets src/world/overworld/__tilesets_tmp; Rename-Item src/world/overworld/__tilesets_tmp src/world/overworld/tilesets
Rename-Item src/world/overworld/tilesets/Cities src/world/overworld/tilesets/__cities_tmp; Rename-Item src/world/overworld/tilesets/__cities_tmp src/world/overworld/tilesets/cities
Rename-Item src/world/overworld/tilesets/Clouds src/world/overworld/tilesets/__clouds_tmp; Rename-Item src/world/overworld/tilesets/__clouds_tmp src/world/overworld/tilesets/clouds
Rename-Item src/world/overworld/tilesets/Mountains src/world/overworld/tilesets/__mountains_tmp; Rename-Item src/world/overworld/tilesets/__mountains_tmp src/world/overworld/tilesets/mountains
Rename-Item src/world/overworld/tilesets/Objects src/world/overworld/tilesets/__objects_tmp; Rename-Item src/world/overworld/tilesets/__objects_tmp src/world/overworld/tilesets/objects
Rename-Item src/world/overworld/tilesets/Terrains src/world/overworld/tilesets/__terrains_tmp; Rename-Item src/world/overworld/tilesets/__terrains_tmp src/world/overworld/tilesets/terrains
```

- [ ] **Step 4: Rewrite references, verify, and commit**

Run:

```powershell
rg -l "src/ui/Assets|src/ui/Common|src/ui/Desktop|src/ui/Hud|src/ui/Mobile|src/world/Combat|src/world/Locations|src/world/Overworld|src/world/Streaming|Ancient_Ruins|Goblin_Cave|House_Interior|Shop_Interior|Capital_City|Starting_Village|/Npcs/|/Tilesets/|/Cities/|/Clouds/|/Mountains/|/Objects/|/Terrains/" src project.godot docs |
  ForEach-Object {
    (Get-Content $_ -Raw).
      Replace('src/ui/Assets','src/ui/assets').
      Replace('src/ui/Common','src/ui/common').
      Replace('src/ui/Desktop','src/ui/desktop').
      Replace('src/ui/Hud','src/ui/hud').
      Replace('src/ui/Mobile','src/ui/mobile').
      Replace('src/world/Combat','src/world/combat').
      Replace('src/world/Locations','src/world/locations').
      Replace('src/world/Overworld','src/world/overworld').
      Replace('src/world/Streaming','src/world/streaming').
      Replace('Ancient_Ruins','ancient_ruins').
      Replace('Goblin_Cave','goblin_cave').
      Replace('House_Interior','house_interior').
      Replace('Shop_Interior','shop_interior').
      Replace('Capital_City','capital_city').
      Replace('Starting_Village','starting_village').
      Replace('/Npcs/','/npcs/').
      Replace('/Tilesets/','/tilesets/').
      Replace('/Cities/','/cities/').
      Replace('/Clouds/','/clouds/').
      Replace('/Mountains/','/mountains/').
      Replace('/Objects/','/objects/').
      Replace('/Terrains/','/terrains/') |
      Set-Content $_
  }
git diff --check
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/world/main.tscn --quit-after 10
```

Expected: UI/world stale-path audit clean; diff clean; Godot exit `0`.

```bash
git add project.godot src docs
git commit -m "refactor: normalize ui and world filesystem paths"
```

### Task 5: Normalize `src/entities` Structural Paths

**Files:**
- Modify: `src/entities/**`
- Modify: `src/world/**`
- Modify: `project.godot`
- Modify: `docs/**`
- Rename: `Creatures`, `Interactables`, `Items`, `Player`, `Skills`, `Systems`
- Rename: `Components`, `Effects`, `Resources`, `Spawning`, `Tests`, `Tools`, `Types`, `Assets`, `Config`, `Input`, `Services`, `Sounds`, `States`, `Inventory`, `Combat`

- [ ] **Step 1: Audit the entity structural path surface**

Run:

```powershell
rg -n "src/entities/Creatures|src/entities/Interactables|src/entities/Items|src/entities/Player|src/entities/Skills|src/entities/Systems|/Components/|/Resources/|/Spawning/|/Tests/|/Tools/|/Types/|/Assets/|/Config/|/Input/|/Services/|/Sounds/|/States/|/Inventory/|/Combat/" src project.godot docs
```

- [ ] **Step 2: Rename entity roots and structural subfolders**

Run:

```powershell
Rename-Item src/entities/Creatures src/entities/__creatures_tmp; Rename-Item src/entities/__creatures_tmp src/entities/creatures
Rename-Item src/entities/Interactables src/entities/__interactables_tmp; Rename-Item src/entities/__interactables_tmp src/entities/interactables
Rename-Item src/entities/Items src/entities/__items_tmp; Rename-Item src/entities/__items_tmp src/entities/items
Rename-Item src/entities/Player src/entities/__player_tmp; Rename-Item src/entities/__player_tmp src/entities/player
Rename-Item src/entities/Skills src/entities/__skills_tmp; Rename-Item src/entities/__skills_tmp src/entities/skills
Rename-Item src/entities/Systems src/entities/__systems_tmp; Rename-Item src/entities/__systems_tmp src/entities/systems
Rename-Item src/entities/creatures/Components src/entities/creatures/__components_tmp; Rename-Item src/entities/creatures/__components_tmp src/entities/creatures/components
Rename-Item src/entities/creatures/Effects src/entities/creatures/__effects_tmp; Rename-Item src/entities/creatures/__effects_tmp src/entities/creatures/effects
Rename-Item src/entities/creatures/Resources src/entities/creatures/__resources_tmp; Rename-Item src/entities/creatures/__resources_tmp src/entities/creatures/resources
Rename-Item src/entities/creatures/Spawning src/entities/creatures/__spawning_tmp; Rename-Item src/entities/creatures/__spawning_tmp src/entities/creatures/spawning
Rename-Item src/entities/creatures/Tests src/entities/creatures/__tests_tmp; Rename-Item src/entities/creatures/__tests_tmp src/entities/creatures/tests
Rename-Item src/entities/creatures/Tools src/entities/creatures/__tools_tmp; Rename-Item src/entities/creatures/__tools_tmp src/entities/creatures/tools
Rename-Item src/entities/creatures/Types src/entities/creatures/__types_tmp; Rename-Item src/entities/creatures/__types_tmp src/entities/creatures/types
Rename-Item src/entities/player/Assets src/entities/player/__assets_tmp; Rename-Item src/entities/player/__assets_tmp src/entities/player/assets
Rename-Item src/entities/player/Components src/entities/player/__components_tmp; Rename-Item src/entities/player/__components_tmp src/entities/player/components
Rename-Item src/entities/player/Config src/entities/player/__config_tmp; Rename-Item src/entities/player/__config_tmp src/entities/player/config
Rename-Item src/entities/player/Input src/entities/player/__input_tmp; Rename-Item src/entities/player/__input_tmp src/entities/player/input
Rename-Item src/entities/player/Resources src/entities/player/__resources_tmp; Rename-Item src/entities/player/__resources_tmp src/entities/player/resources
Rename-Item src/entities/player/Services src/entities/player/__services_tmp; Rename-Item src/entities/player/__services_tmp src/entities/player/services
Rename-Item src/entities/player/Sounds src/entities/player/__sounds_tmp; Rename-Item src/entities/player/__sounds_tmp src/entities/player/sounds
Rename-Item src/entities/player/States src/entities/player/__states_tmp; Rename-Item src/entities/player/__states_tmp src/entities/player/states
Rename-Item src/entities/player/Tests src/entities/player/__tests_tmp; Rename-Item src/entities/player/__tests_tmp src/entities/player/tests
Rename-Item src/entities/player/Tools src/entities/player/__tools_tmp; Rename-Item src/entities/player/__tools_tmp src/entities/player/tools
Rename-Item src/entities/items/Types src/entities/items/__types_tmp; Rename-Item src/entities/items/__types_tmp src/entities/items/types
Rename-Item src/entities/systems/Inventory src/entities/systems/__inventory_tmp; Rename-Item src/entities/systems/__inventory_tmp src/entities/systems/inventory
Rename-Item src/entities/systems/Combat src/entities/systems/__combat_tmp; Rename-Item src/entities/systems/__combat_tmp src/entities/systems/combat
```

- [ ] **Step 3: Rewrite structural references, verify, and commit**

Run:

```powershell
rg -l "src/entities/Creatures|src/entities/Interactables|src/entities/Items|src/entities/Player|src/entities/Skills|src/entities/Systems|/Components/|/Resources/|/Spawning/|/Tests/|/Tools/|/Types/|/Assets/|/Config/|/Input/|/Services/|/Sounds/|/States/|/Inventory/|/Combat/" src project.godot docs |
  ForEach-Object {
    (Get-Content $_ -Raw).
      Replace('src/entities/Creatures','src/entities/creatures').
      Replace('src/entities/Interactables','src/entities/interactables').
      Replace('src/entities/Items','src/entities/items').
      Replace('src/entities/Player','src/entities/player').
      Replace('src/entities/Skills','src/entities/skills').
      Replace('src/entities/Systems','src/entities/systems').
      Replace('/Components/','/components/').
      Replace('/Effects/','/effects/').
      Replace('/Resources/','/resources/').
      Replace('/Spawning/','/spawning/').
      Replace('/Tests/','/tests/').
      Replace('/Tools/','/tools/').
      Replace('/Types/','/types/').
      Replace('/Assets/','/assets/').
      Replace('/Config/','/config/').
      Replace('/Input/','/input/').
      Replace('/Services/','/services/').
      Replace('/Sounds/','/sounds/').
      Replace('/States/','/states/').
      Replace('/Inventory/','/inventory/').
      Replace('/Combat/','/combat/') |
      Set-Content $_
  }
git diff --check
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/world/main.tscn --quit-after 10
```

Expected: structural entity stale paths removed; diff clean; Godot exit `0`.

```bash
git add project.godot src docs
git commit -m "refactor: normalize entity structural paths"
```

### Task 6: Normalize Deep Project-Owned Content Folders And File Basenames

**Files:**
- Modify: `src/entities/creatures/types/**`
- Modify: `src/entities/items/types/**`
- Modify: project-owned basenames under `src/**`
- Modify: generated builder outputs under `src/entities/**`

- [ ] **Step 1: Separate project-owned deep content from vendor/import boundaries**

Run:

```powershell
Get-ChildItem src/entities/creatures/types -Directory -Recurse | Select-Object FullName
Get-ChildItem src/entities/items/types -Directory -Recurse | Select-Object FullName
Get-ChildItem src/ui/assets -Directory -Recurse | Select-Object FullName
```

Expected: actionable project-owned content under `types/**`; UI asset-pack vendor folders may remain unchanged if they are true import boundaries.

- [ ] **Step 2: Normalize project-owned deep directories**

Run:

```powershell
Get-ChildItem src/entities/creatures/types -Directory -Recurse |
  Sort-Object FullName -Descending |
  Where-Object { $_.Name -cmatch '[A-Z ]' } |
  ForEach-Object {
    $newName = ($_.Name -replace ' ','_').ToLowerInvariant()
    if ($newName -ne $_.Name) {
      Rename-Item $_.FullName "$($_.Parent.FullName)\__tmp__$newName"
      Rename-Item "$($_.Parent.FullName)\__tmp__$newName" "$($_.Parent.FullName)\$newName"
    }
  }
Get-ChildItem src/entities/items/types -Directory -Recurse |
  Sort-Object FullName -Descending |
  Where-Object { $_.Name -cmatch '[A-Z ]' } |
  ForEach-Object {
    $newName = ($_.Name -replace ' ','_').ToLowerInvariant()
    if ($newName -ne $_.Name) {
      Rename-Item $_.FullName "$($_.Parent.FullName)\__tmp__$newName"
      Rename-Item "$($_.Parent.FullName)\__tmp__$newName" "$($_.Parent.FullName)\$newName"
    }
  }
```

- [ ] **Step 3: Normalize project-owned file basenames in batches**

Run:

```powershell
Get-ChildItem src -File -Recurse |
  Where-Object { $_.BaseName -cmatch '[A-Z ]' } |
  Where-Object { $_.FullName -notmatch '\\src\\ui\\assets\\' } |
  Select-Object FullName
```

Expected: the actionable file-basename list. Rename in bounded batches, then rewrite references for that batch before continuing.

- [ ] **Step 4: Regenerate owned catalogs and verify**

Run:

```powershell
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/entities/creatures/tools/creature_catalog_builder_runner.tscn --quit
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/entities/player/tools/player_cosmetic_catalog_builder_runner.tscn --quit
git diff --check
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --script res://src/entities/creatures/tests/run_creature_catalog_validation.gd
```

Expected: diff clean; creature catalog validation exit `0`; existing baseline debt may still appear in logs.

```bash
git add project.godot src docs
git commit -m "refactor: normalize deep src content paths"
```

### Task 7: Final Docs Sweep And Full Verification

**Files:**
- Modify: `docs/**`
- Modify: `project.godot` if any remaining stale `src` path survives

- [ ] **Step 1: Run the final stale-path audit**

Run:

```powershell
rg -n "src/Common|src/Config|src/Core|src/Entities|src/Localization|src/Ui|src/Utils|src/World|src/.*/Assets|src/.*/Components|src/.*/Resources|src/.*/Spawning|src/.*/Tests|src/.*/Tools|src/.*/Types|src/world/.*/Tilesets|Ancient_Ruins|Goblin_Cave|House_Interior|Shop_Interior|Capital_City|Starting_Village|/Npcs/" src project.godot docs
```

Expected: no output for the fully normalized tree.

- [ ] **Step 2: Run full verification**

Run:

```powershell
git diff --check
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/world/main.tscn --quit-after 10
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --script res://src/entities/creatures/tests/run_creature_catalog_validation.gd
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200
& 'C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe' --headless --path . --script res://src/entities/systems/combat/tests/run_combat_tests.gd
```

Expected: all commands exit `0`; logs may still include the same known baseline parser/import/UID debt, but no new path-related regressions should appear.

- [ ] **Step 3: Commit the final normalization sweep**

```bash
git add project.godot src docs
git commit -m "refactor: normalize filesystem paths under src"
```
