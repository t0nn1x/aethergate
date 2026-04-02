# Src Structure Refactor

**Date:** 2026-04-01

## Summary

Refactor the `src/` tree for feature discoverability without changing the high-level
root layout or disrupting shared asset pack locations. The goal is to make it obvious
where a feature lives by organizing each domain around purpose-first subfolders and a
consistent naming scheme.

## Constraints

- Keep the current top-level roots: `Common`, `Config`, `Core`, `Entities`,
  `Localization`, `Ui`, `World`
- Keep shared asset roots such as `src/ui/assets` in place
- Prefer structure and naming changes over behavior changes
- Update all references in the same pass as each move or rename
- Avoid large one-shot migrations that make breakage hard to isolate

## Current Problems

- `src/` mixes strong domain roots with vague or historical subfolders such as `Gui`
  and `Types`
- naming is inconsistent across runtime paths: `snake_case`, `PascalCase`, spaces,
  and underscore-heavy names all coexist
- large domains such as `Entities/Creatures` and `Ui` are hard to scan because
  feature content, support code, tests, and tools are not consistently grouped
- parallel feature variants such as desktop and mobile UI do not use the same
  vocabulary, which makes navigation slower

## Design

### Root-level policy

Keep the existing top-level domains because they already provide a workable mental
model:

- `src/common` for reusable runtime building blocks
- `src/config` for configuration data and loaders
- `src/core` for application-level services, autoloads, and global events
- `src/entities` for player-facing gameplay actors and gameplay systems
- `src/localization` for localization data and services
- `src/ui` for runtime UI and shared UI assets
- `src/world` for world scenes, location content, streaming, and map-level controllers

The refactor focuses on making the structure inside these roots predictable.

### Naming rules

Normalize runtime folders and files to `snake_case`.

Rules:

- no spaces in runtime paths
- no mixed naming styles inside the same domain
- plural names for collections such as `components`, `states`, `locations`, `tests`
- singular names only when the folder represents a singular domain concept such as
  `player`, `world`, or `combat`
- replace vague names with intent-revealing names, such as `types` to `catalog` when
  the folder is a library of concrete content definitions

This applies aggressively in the structure pass, including currently inconsistent names
such as creature entries, world locations, and UI subfeatures.

### `src/entities`

Keep the main feature domains:

- `creatures`
- `player`
- `items`
- `interactables`
- `skills`
- `systems`

Refactor each domain so navigation is by feature first, then by responsibility.

#### `creatures`

Target layout:

- `base/` for `creature.gd`, `creature.tscn`, the factory, and core creature data types
- `catalog/` for concrete creature definitions currently under `Types/`
- `components/`
- `effects/`
- `resources/`
- `spawning/`
- `tests/`
- `tools/`

The current `Types/` folder becomes `catalog/` because it is effectively a creature
content library. Category folders under it are normalized to `snake_case`, and creature
entry folders are also normalized to predictable runtime-safe names.

#### `player`

Keep the current responsibility split, but normalize naming and placement:

- `components/`
- `config/`
- `input/`
- `resources/`
- `services/`
- `sounds/`
- `states/`
- `tests/`
- `tools/`

`player.gd` and `player.tscn` remain the entry points for the feature.

#### `systems`, `skills`, `interactables`, `items`

Keep these domains in place, but apply the same naming and subfolder rules. The goal is
to make `combat`, `inventory`, `equipment`, `loot`, and similar systems easy to locate
without also moving their ownership model in this refactor.

### `src/ui`

Keep `assets/` as the shared asset root.

Organize runtime UI around:

- `common/`
- `desktop/`
- `mobile/`

Within `desktop/` and `mobile/`, use parallel feature names whenever the same feature
exists on both platforms:

- `character_creator/`
- `combat/`
- `inventory/`
- `hud/`
- `main_screen/`
- `debug/`

The current `Gui/` grouping is removed because it hides features behind a technical
bucket instead of naming the user-facing surface directly.

Shared reusable runtime pieces stay in `common/` under clear subfeatures such as:

- `combat/`
- `debug/`
- `overlay/`
- `styles/`
- `screen_localization/`
- `ui_sound_player/`

### `src/world`

Keep the existing domain split:

- `combat/`
- `locations/`
- `overworld/`
- `streaming/`

Normalize location and area names to `snake_case`, including nested location content
such as:

- `starting_village`
- `capital_city`
- `ancient_ruins`
- `goblin_cave`
- `house_interior`

Keep the world entry scene and script at the root of `src/world`, since they are the
composition root for this domain.

Within `overworld/`, retain the current controller and spawner decomposition while
normalizing folder names:

- `chunks/`
- `tilesets/`
- `shaders/`

### `src/common`, `src/core`, `src/config`

Keep these roots, but enforce stricter boundaries:

- `common` contains reusable runtime utilities and primitives such as navigation,
  shaders, and the state machine
- `core` contains application-wide services, autoload-style behavior, and event hubs
- `config` contains configuration resources and services for project and platform setup

The refactor does not attempt to re-argue ownership where the current placement is
already coherent enough.

## Migration Strategy

Execute the refactor as small structural passes:

1. Normalize low-risk folder names with shallow reference chains
2. Reorganize `Ui` feature folders and remove `Gui`
3. Reorganize `Entities/Creatures` into `base`, `catalog`, and supporting subdomains
4. Normalize `World` location names and helper folders
5. Sweep remaining inconsistent names and update structure documentation

Each pass must leave the project in a loadable state.

## Safety Rules

- no logic rewrites during the structure pass except minimal changes required for path
  updates
- move and rename references atomically: `.gd`, `.tscn`, `.tres`, `.uid`,
  `project.godot`, and any path strings in scripts must be updated together
- do not leave duplicate temporary paths behind after a pass
- handle high-volume renames, especially creature catalog entries, in a systematic way
  so names follow the same rule set
- if a path is referenced broadly, prefer normalizing deeper content first and delaying
  the higher-level folder rename until the dependency surface is smaller

## Out Of Scope

- redesigning system ownership just because another arrangement could also work
- changing gameplay behavior, feature boundaries, or scene composition beyond what is
  required for structural moves
- relocating shared asset roots such as `src/ui/assets`

## Acceptance Criteria

- every major feature is discoverable from one obvious domain path
- runtime folders and files use consistent `snake_case` naming
- vague buckets such as `Gui` and `Types` are removed or renamed to intent-revealing
  equivalents
- desktop and mobile UI use parallel feature naming where both variants exist
- creature content is organized as a catalog rather than an ad hoc type bucket
- the project remains loadable after each migration pass
