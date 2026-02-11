# Project: Aethergate

## Overview
Aethergate is a Godot game project with core runtime services, entity systems, and an overworld map pipeline organized by gameplay domain.

## Detected Stack
- **Engine:** Godot 4.6 (`project.godot`)
- **Language:** GDScript (`src/**/*.gd`)
- **Assets/Resources:** `.tscn`, `.tres`, `.gdshader`, imported sprites and tilesets
- **Repository:** Git initialized (`.git`)

## Identified Patterns
- **Feature-oriented structure:** `src/Core`, `src/Entities`, `src/Map`, `src/Common`
- **Autoload orchestration:** `PlatformDisplaySettings`, `EventBus`, `GameManager`
- **Componentized player architecture:** `src/Entities/Player/Components`
- **Reusable state machine layer:** `src/Common/State_Machine`
- **Chunked overworld content:** `src/Map/Overworld/Chunks`

## Architecture Notes
- Main entry scene: `res://src/Map/main.tscn`
- Rendering mode is mobile-focused with platform-specific viewport settings.
- Event-driven coordination is centralized through autoload singletons.
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
