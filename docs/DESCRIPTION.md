# Project: Aethergate

## Overview

Aethergate is a Godot game project with core runtime services, entity systems, and an overworld map pipeline organized by gameplay domain.

## Detected Stack

- **Engine:** Godot 4.6 (`project.godot`)
- **Language:** GDScript (`src/**/*.gd`)
- **Assets/Resources:** `.tscn`, `.tres`, `.gdshader`, imported sprites and tilesets
- **Repository:** Git initialized (`.git`)

## Identified Patterns

- **Feature-oriented structure:** `src/core/events`, `src/config/platform`, `src/common/navigation`, `src/entities/creatures`, `src/entities/items`, `src/entities/player`, `src/entities/systems`, `src/entities/interactables`, `src/entities/skills`, `src/ui/common`, `src/ui/desktop`, `src/ui/mobile`, `src/ui/hud`, `src/world/overworld`, `src/world/combat`, `src/world/streaming`, `src/world/locations`
- **Autoload orchestration:** `PlatformDisplaySettings`, `GameManager`
- **Profile persistence autoload:** `PlayerProfileService` stores player cosmetic setup (`user://player_profile.cfg`)
- **Typed event singletons:** `PlayerEvents`, `WorldEvents`, `UIEvents`, `CreatureEvents` — no legacy EventBus
- **Centralized project config:** `ProjectConfig` autoload resolves global config + active platform profile
- **Componentized player architecture:** `src/entities/player/components` with `@onready` typed refs
- **Solo-first multiplayer seams:** player identity + authority checks exist even before transport/RPC layer
- **Reusable state machine layer:** `src/common/state_machine`
- **Chunked overworld content:** `src/world/overworld/chunks`

## Architecture Notes

- Main entry scene: `res://src/world/main.tscn`
- Rendering mode is mobile-focused with platform-specific viewport settings.
- Event-driven coordination is centralized through typed event singleton autoloads.
- Runtime tuning now supports one global config resource (`res://src/config/project_config.tres`) with mobile/desktop profile split.
- Overworld acts as composition root for stage wiring (player, chunk manager, blocker registry, debug overlay).
- Overworld is decomposed: creature selection delegated to `OverworldCreatureSelectionController`, character creator flow to `OverworldCharacterCreatorController`.
- Overworld now keeps player registration extensible via `player_id` mapping while preserving local-player compatibility.
- Navigation utilities live under `src/common/navigation/`.
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
