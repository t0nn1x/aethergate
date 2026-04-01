# Project: Aethergate

## Overview

Aethergate is a Godot game project with core runtime services, entity systems, and an overworld map pipeline organized by gameplay domain.

## Detected Stack

- **Engine:** Godot 4.6 (`project.godot`)
- **Language:** GDScript (`src/**/*.gd`)
- **Assets/Resources:** `.tscn`, `.tres`, `.gdshader`, imported sprites and tilesets
- **Repository:** Git initialized (`.git`)

## Identified Patterns

- **Feature-oriented structure:** `src/Core/events`, `src/Config/platform`, `src/Common/navigation`, `src/Entities/creatures`, `src/Entities/items`, `src/Entities/player`, `src/Entities/systems`, `src/Entities/interactables`, `src/Entities/skills`, `src/Ui/common`, `src/Ui/desktop`, `src/Ui/mobile`, `src/Ui/hud`, `src/World/overworld`, `src/World/combat`, `src/World/streaming`, `src/World/locations`
- **Autoload orchestration:** `PlatformDisplaySettings`, `GameManager`
- **Profile persistence autoload:** `PlayerProfileService` stores player cosmetic setup (`user://player_profile.cfg`)
- **Typed event singletons:** `PlayerEvents`, `WorldEvents`, `UIEvents`, `CreatureEvents` — no legacy EventBus
- **Centralized project config:** `ProjectConfig` autoload resolves global config + active platform profile
- **Componentized player architecture:** `src/Entities/player/components` with `@onready` typed refs
- **Solo-first multiplayer seams:** player identity + authority checks exist even before transport/RPC layer
- **Reusable state machine layer:** `src/Common/state_machine`
- **Chunked overworld content:** `src/World/overworld/chunks`

## Architecture Notes

- Main entry scene: `res://src/World/main.tscn`
- Rendering mode is mobile-focused with platform-specific viewport settings.
- Event-driven coordination is centralized through typed event singleton autoloads.
- Runtime tuning now supports one global config resource (`res://src/Config/project_config.tres`) with mobile/desktop profile split.
- Overworld acts as composition root for stage wiring (player, chunk manager, blocker registry, debug overlay).
- Overworld is decomposed: creature selection delegated to `OverworldCreatureSelectionController`, character creator flow to `OverworldCharacterCreatorController`.
- Overworld now keeps player registration extensible via `player_id` mapping while preserving local-player compatibility.
- Navigation utilities live under `src/Common/navigation/`.
- Multiplayer structure appears scaffolded and ready for expansion.

## AI Context Status

- Installed skills already include:
  - `godot-best-practices`
  - `godot-development`
  - `godot-gdscript-patterns`
  - `godot-ui`
- MCP currently configured in `.claude/settings.local.json`:
  - `github`
  - `filesystem`

## skills.sh Search Notes

- Search executed for `godot` and returned matches, including:
  - `jwynia/agent-skills@godot-best-practices`
  - `zate/cc-godot@godot-development`
  - `wshobson/agents@godot-gdscript-patterns`
  - `zate/cc-godot@godot-ui`
  - `jwynia/agent-skills@godot-asset-generator`
- Most core Godot skills are already present in this project.
