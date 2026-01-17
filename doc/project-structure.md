# Project Structure (Functionality-First Architecture)

## Overview
This project follows a **functionality-first** organization philosophy. Files are grouped by **what they do in the game**, not by file type. All folder names use capitalized words with underscores.

## Core Principles

1. **Organize by gameplay purpose**, not file extension
2. **Keep related resources together** in the same feature folder
3. **Use inheritance hierarchies** for scalable systems
4. **Minimize root-level folders** to avoid clutter
5. **Entities live inside stages**, not the other way around

---

## Directory Structure

```
res://
├── Assets/                         # Global assets used across entire game
│   ├── Audio/
│   │   ├── Music/                  # Background music, themes
│   │   └── Sfx/                    # Global sound effects
│   ├── Fonts/                      # UI fonts
│   └── Credits/                    # Credits, licenses
│
├── Common/                         # Reusable, game-agnostic systems
│   ├── State_Machine/              # Generic state machine
│   │   ├── state.gd
│   │   ├── state_machine.gd
│   │   └── readme.md
│   ├── Resolution/                 # Resolution/scaling system
│   │   └── viewport_scaler.gd
│   ├── Shaders/                    # Reusable shaders
│   │   ├── outline.gdshader
│   │   ├── palette_swap.gdshader
│   │   └── water.gdshader
│   ├── Time/                       # In-game time system
│   │   └── time_manager.gd
│   └── Pathfinding/                # Custom pathfinding utilities
│       └── pathfinding_utils.gd
│
├── Config/                         # Game configuration
│   ├── settings.gd                 # Settings data structure
│   ├── default_settings.tres       # Default configuration
│   └── input_actions.gd            # Input mapping configuration
│
├── Core/                           # Core game systems (AUTOLOADED)
│   ├── game_manager.gd             # Main game state manager
│   ├── event_bus.gd                # Global signal bus
│   ├── save_manager.gd             # Save/load system
│   ├── audio_manager.gd            # Audio control
│   ├── scene_manager.gd            # Scene transitions
│   ├── input_manager.gd            # Input handling
│   ├── data_manager.gd             # Data loading (items, skills, etc.)
│   │
│   ├── Progression/                # Player progression systems
│   │   ├── level_system.gd
│   │   ├── experience_manager.gd
│   │   └── stat_calculator.gd
│   │
│   ├── Quest/                      # Quest system
│   │   ├── quest_manager.gd
│   │   ├── quest.gd
│   │   ├── quest_tracker.gd
│   │   └── Objectives/
│   │
│   ├── Party/                      # Party system
│   │   ├── party_manager.gd
│   │   ├── party_ui.gd
│   │   └── party_member.gd
│   │
│   ├── Guild/                      # Guild system
│   │   ├── guild_manager.gd
│   │   ├── guild_ui.gd
│   │   └── guild_territory.gd
│   │
│   └── Debug/                      # Debug tools
│       ├── debug_overlay.gd
│       └── console.gd
│
├── Multiplayer/                    # All Multiplayer/networking code
│   ├── network_manager.gd          # Main network manager (AUTOLOAD)
│   │
│   ├── Server/                     # Server-side logic
│   │   ├── world_manager.gd        # Server world state
│   │   ├── player_sync.gd          # Player synchronization
│   │   ├── combat_authority.gd     # Combat validation
│   │   └── chunk_sync.gd           # Chunk synchronization
│   │
│   ├── Client/                     # Client-side logic
│   │   ├── client_sync.gd          # Client synchronization
│   │   ├── prediction.gd           # Client-side prediction
│   │   └── interpolation.gd        # Movement interpolation
│   │
│   ├── Shared/                     # Shared networking code
│   │   ├── protocol.gd             # Network protocol definitions
│   │   ├── packet.gd               # Packet structures
│   │   └── compression.gd          # Data compression
│   │
│   └── Lobby/                      # Lobby and matchmaking
│       ├── lobby_manager.gd
│       ├── lobby_ui.gd
│       └── matchmaking.gd
│
├── Entities/                       # LARGEST FOLDER - Everything in the game
│   │
│   ├── Player/                     # Player character
│   │   ├── player.gd               # Player base class
│   │   ├── player.tscn
│   │   ├── player_controller.gd    # Input handling
│   │   ├── player_movement.gd      # Movement logic
│   │   ├── player_combat.gd        # Combat abilities
│   │   ├── Sprites/                # Player graphics
│   │   │   ├── idle.png
│   │   │   ├── walk.png
│   │   │   └── attack.png
│   │   └── Sounds/                 # Player-specific sounds
│   │       ├── footstep.wav
│   │       └── jump.wav
│   │
│   ├── Npcs/                       # Non-player characters
│   │   ├── npc.gd                  # Base NPC class
│   │   ├── npc.tscn
│   │   ├── Merchant/
│   │   │   ├── merchant.gd
│   │   │   ├── merchant.tscn
│   │   │   ├── merchant_ui.tscn
│   │   │   └── Sprites/
│   │   ├── Quest_Giver/
│   │   │   ├── quest_giver.gd
│   │   │   └── quest_giver.tscn
│   │   └── Villager/
│   │       └── villager.tscn
│   │
│   ├── Organisms/                  # Living creatures (non-NPC)
│   │   ├── organism.gd             # Base organism class
│   │   ├── organism_data.gd        # Resource for organism stats
│   │   │
│   │   ├── Mammals/
│   │   │   ├── Wolf/
│   │   │   │   ├── wolf.gd
│   │   │   │   ├── wolf.tscn
│   │   │   │   ├── wolf_data.tres
│   │   │   │   └── Sprites/
│   │   │   └── Bear/
│   │   │
│   │   ├── Birds/
│   │   │   └── Eagle/
│   │   │
│   │   ├── Reptiles/
│   │   │   └── Snake/
│   │   │
│   │   ├── Fish/
│   │   │   └── Salmon/
│   │   │
│   │   ├── Invertebrates/
│   │   │   └── Spider/
│   │   │
│   │   └── Plants/
│   │       ├── Tree/
│   │       └── Bush/
│   │
│   ├── Bosses/                     # Boss enemies
│   │   ├── boss.gd                 # Base boss class
│   │   ├── Forest_Guardian/
│   │   │   ├── forest_guardian.gd
│   │   │   ├── forest_guardian.tscn
│   │   │   └── Sprites/
│   │   └── Dragon/
│   │
│   ├── Items/                      # All items
│   │   ├── item.gd                 # Base item class
│   │   ├── item_data.gd            # Item resource
│   │   │
│   │   ├── Weapons/
│   │   │   ├── weapon.gd
│   │   │   ├── weapon_data.gd
│   │   │   ├── Swords/
│   │   │   │   ├── Iron_Sword/
│   │   │   │   │   ├── iron_sword_data.tres
│   │   │   │   │   └── icon.png
│   │   │   │   └── Steel_Sword/
│   │   │   ├── Axes/
│   │   │   └── Bows/
│   │   │
│   │   ├── Armor/
│   │   │   ├── armor.gd
│   │   │   ├── Helmets/
│   │   │   ├── Chestplates/
│   │   │   └── Boots/
│   │   │
│   │   ├── Consumables/
│   │   │   ├── consumable.gd
│   │   │   ├── Potions/
│   │   │   │   ├── Health_Potion/
│   │   │   │   └── Mana_Potion/
│   │   │   └── Food/
│   │   │
│   │   └── Materials/
│   │       ├── Wood/
│   │       ├── Ore/
│   │       └── Herbs/
│   │
│   ├── Skills/                     # All player abilities
│   │   ├── skill.gd                # Base skill class
│   │   ├── skill_data.gd           # Skill resource
│   │   │
│   │   ├── Combat/
│   │   │   ├── Fireball/
│   │   │   │   ├── fireball.gd
│   │   │   │   ├── fireball.tscn
│   │   │   │   ├── fireball_data.tres
│   │   │   │   ├── icon.png
│   │   │   │   └── Vfx/
│   │   │   ├── Slash/
│   │   │   └── Heal/
│   │   │
│   │   ├── Movement/
│   │   │   ├── Dash/
│   │   │   └── Teleport/
│   │   │
│   │   └── Utility/
│   │       ├── Detect_Enemies/
│   │       └── Light/
│   │
│   ├── Environment/                # Environmental objects
│   │   ├── Trees/
│   │   │   ├── tree.gd             # Harvestable tree
│   │   │   ├── Oak_Tree/
│   │   │   │   ├── oak_tree.tscn
│   │   │   │   └── Sprites/
│   │   │   └── Pine_Tree/
│   │   │
│   │   ├── Rocks/
│   │   │   ├── rock.gd             # Mineable rock
│   │   │   └── Iron_Deposit/
│   │   │
│   │   ├── Plants/
│   │   │   └── Herb_Node/
│   │   │
│   │   └── Decorations/
│   │       ├── Flowers/
│   │       └── Grass_Tufts/
│   │
│   ├── Structures/                 # Buildings and constructions
│   │   ├── Houses/
│   │   │   ├── house.tscn
│   │   │   └── Sprites/
│   │   ├── Shops/
│   │   │   └── blacksmith.tscn
│   │   ├── Dungeons/
│   │   │   └── cave_entrance.tscn
│   │   └── Landmarks/
│   │       ├── statue.tscn
│   │       └── shrine.tscn
│   │
│   ├── Interactables/              # Interactive objects
│   │   ├── interactable.gd         # Base class
│   │   ├── Chest/
│   │   │   ├── chest.gd
│   │   │   ├── chest.tscn
│   │   │   └── Sprites/
│   │   ├── Door/
│   │   ├── Lever/
│   │   └── Sign/
│   │
│   ├── Projectiles/                # Projectiles and thrown objects
│   │   ├── projectile.gd
│   │   ├── Arrow/
│   │   │   ├── arrow.gd
│   │   │   └── arrow.tscn
│   │   └── Magic_Bolt/
│   │
│   ├── Effects/                    # Visual and particle effects
│   │   ├── Damage_Number/
│   │   │   ├── damage_number.gd
│   │   │   └── damage_number.tscn
│   │   ├── Hit_Spark/
│   │   ├── Explosion/
│   │   └── Heal_Aura/
│   │
│   ├── Weather/                    # Weather systems
│   │   ├── Rain/
│   │   │   ├── rain.gd
│   │   │   └── rain.tscn
│   │   ├── Snow/
│   │   └── Fog/
│   │
│   ├── Ui/                         # In-game UI (exists in scene tree)
│   │   ├── Hud/
│   │   │   ├── hud.gd
│   │   │   ├── hud.tscn
│   │   │   ├── health_bar.gd
│   │   │   ├── mana_bar.gd
│   │   │   └── hotbar.gd
│   │   │
│   │   ├── Inventory/
│   │   │   ├── inventory_ui.gd
│   │   │   ├── inventory_ui.tscn
│   │   │   ├── item_slot.gd
│   │   │   └── drag_preview.gd
│   │   │
│   │   ├── Character_Sheet/
│   │   ├── Quest_Log/
│   │   ├── Crafting/
│   │   ├── Dialogue/
│   │   ├── Minimap/
│   │   └── Menus/
│   │       ├── main_menu.tscn
│   │       ├── pause_menu.tscn
│   │       └── settings_menu.tscn
│   │
│   ├── Camera/                     # Camera systems
│   │   ├── player_camera.gd
│   │   ├── cutscene_camera.gd
│   │   └── camera_shake.gd
│   │
│   ├── Combat/                     # Combat-specific systems
│   │   ├── Overworld/              # Overworld combat (popup window)
│   │   │   ├── overworld_combat_manager.gd
│   │   │   ├── overworld_combat_window.gd
│   │   │   └── overworld_combat_window.tscn
│   │   │
│   │   ├── Location/               # Location combat (on-screen)
│   │   │   ├── location_combat_manager.gd
│   │   │   ├── combat_ui.gd
│   │   │   └── combat_ui.tscn
│   │   │
│   │   ├── Shared/                 # Shared combat systems
│   │   │   ├── damage_calculator.gd
│   │   │   ├── status_effect.gd
│   │   │   ├── aggro_system.gd
│   │   │   └── combat_stats.gd
│   │   │
│   │   ├── Ai/                     # Enemy AI
│   │   │   ├── enemy_ai.gd
│   │   │   └── Behaviors/
│   │   │       ├── melee_behavior.gd
│   │   │       ├── ranged_behavior.gd
│   │   │       └── caster_behavior.gd
│   │   │
│   │   └── Hitbox/                 # Hitbox/Hurtbox system
│   │       ├── hitbox.gd
│   │       └── hurtbox.gd
│   │
│   ├── Systems/                    # Entity-related systems
│   │   ├── Inventory/
│   │   │   ├── inventory.gd
│   │   │   └── item_container.gd
│   │   │
│   │   ├── Equipment/
│   │   │   ├── equipment_manager.gd
│   │   │   └── equipment_slot.gd
│   │   │
│   │   ├── Crafting/
│   │   │   ├── crafting_station.gd
│   │   │   ├── recipe.gd
│   │   │   └── recipe_book.gd
│   │   │
│   │   └── Loot/
│   │       ├── loot_table.gd
│   │       ├── loot_drop.gd
│   │       └── loot_ui.gd
│   │
│   └── Spawner/                    # Entity spawning systems
│       ├── enemy_spawner.gd
│       ├── resource_spawner.gd
│       └── wave_spawner.gd
│
├── Localization/                   # All translations
│   ├── en.po
│   ├── uk.po
│   └── translation_keys.csv
│
└── Stages/                         # All playable areas
    ├── Overworld/
    │   ├── overworld.gd
    │   ├── overworld.tscn
    │   ├── Chunks/                 # Chunk system
    │   │   ├── chunk.gd
    │   │   ├── chunk_manager.gd
    │   │   ├── chunk_data.gd
    │   │   └── fog_of_war.gd
    │   ├── Tilesets/               # Shared tilesets
    │   │   ├── grass_tileset.tres
    │   │   ├── snow_tileset.tres
    │   │   └── desert_tileset.tres
    │   ├── Regions/                # Specific regions
    │   │   ├── Starting_Plains/
    │   │   ├── Frozen_North/
    │   │   └── Volcanic_Waste/
    │   └── Navigation/
    │       └── overworld_navigation.gd
    │
    ├── Locations/                  # Instanced locations
    │   ├── location.gd             # Base location class
    │   │
    │   ├── Dungeons/
    │   │   ├── Goblin_Cave/
    │   │   │   ├── goblin_cave.tscn
    │   │   │   └── Encounters/
    │   │   └── Ancient_Ruins/
    │   │
    │   ├── Towns/
    │   │   ├── Starting_Village/
    │   │   │   ├── starting_village.tscn
    │   │   │   └── Npcs/
    │   │   └── Capital_City/
    │   │
    │   ├── Arenas/
    │   │   ├── pvp_arena_2v2.tscn
    │   │   └── pvp_arena_3v3.tscn
    │   │
    │   └── Interiors/
    │       ├── House_Interior/
    │       └── Shop_Interior/
    │
    ├── Shared/                     # Shared stage resources
    │   ├── Transitions/
    │   │   └── fade_transition.tscn
    │   └── Boundaries/
    │       └── zone_boundary.gd
    │
    └── main.tscn                   # Main entry point scene
```

---

## Autoload Configuration

Configure in **Project Settings → Autoload**:

**Core Systems:**
```
EventBus          → res://Core/event_bus.gd
GameManager       → res://Core/game_manager.gd
SaveManager       → res://Core/save_manager.gd
AudioManager      → res://Core/audio_manager.gd
SceneManager      → res://Core/scene_manager.gd
InputManager      → res://Core/input_manager.gd
DataManager       → res://Core/data_manager.gd
QuestManager      → res://Core/Quest/quest_manager.gd
PartyManager      → res://Core/Party/party_manager.gd
GuildManager      → res://Core/Guild/guild_manager.gd
```

**Multiplayer:**
```
NetworkManager    → res://Multiplayer/network_manager.gd
```

---

## Naming Conventions

### Files
- **Scripts**: `snake_case.gd` (e.g., `player_movement.gd`)
- **Scenes**: `snake_case.tscn` (e.g., `goblin_cave.tscn`)
- **Resources**: `snake_case.tres` (e.g., `iron_sword_data.tres`)
- **Images**: `snake_case.png` (e.g., `player_idle.png`)

### Folders
- **Capitalized words** with underscores: `Entities/`, `Multiplayer/`, `Core/`

### Classes
- **Class names**: `PascalCase` (e.g., `class_name PlayerMovement`)
- **Always use** `class_name` for reusable classes

### Variables & Functions
- **Variables**: `snake_case` (e.g., `var current_health`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `const MAX_SPEED = 200`)
- **Functions**: `snake_case` (e.g., `func calculate_damage()`)
- **Signals**: `snake_case` (e.g., `signal health_changed`)
- **Private**: prefix with `_` (e.g., `var _internal_state`)

---

## Organization Patterns

### Entity Pattern
Each entity folder contains **everything** related to that entity:
```
Wolf/
├── wolf.gd              # Logic
├── wolf.tscn            # Scene
├── wolf_data.tres       # Data/stats
├── Sprites/             # Graphics
│   ├── idle.png
│   └── attack.png
├── Sounds/              # Audio
│   └── howl.wav
└── Vfx/                 # Effects
    └── bite_effect.tscn
```

### Inheritance Pattern
Base classes at folder root, specializations in subfolders:
```
Items/
├── item.gd              # Base item class
├── item_data.gd         # Base data resource
├── Weapons/
│   ├── weapon.gd        # Extends item.gd
│   └── Swords/
│       └── Iron_Sword/  # Final implementation
└── Consumables/
    └── consumable.gd
```

---

## Folder Purposes

### Assets/
Global resources used across the entire game:
- Background music
- UI fonts  
- Credits and licenses

### Common/
Reusable, portable systems with no game-specific dependencies:
- Can be copied to other projects
- Generic utilities like state machines, shaders
- No references to game entities or systems

### Config/
Game configuration and settings:
- Player preferences
- Input mappings
- Default values

### Core/
Core game systems and managers (mostly autoloaded):
- Game state management
- Save/load system
- Quest and progression systems
- Party and guild management
- Audio and scene management

### Multiplayer/
All networking and multiplayer code:
- Server-side authority logic
- Client-side prediction
- Network synchronization
- Lobby and matchmaking

### Entities/
Everything that exists in the game world:
- Characters (player, enemies, NPCs)
- Items and equipment
- Skills and abilities
- Environmental objects
- UI elements
- Combat systems

### Stages/
Playable areas and locations:
- Overworld with chunking system
- Dungeons and instances
- Towns and cities
- Arenas

### Localization/
Translation files for all languages

---

## Key Differences from Traditional Structure

| Traditional | This Structure |
|------------|---------------|
| `res://Scripts/`, `res://Scenes/` | Everything in feature folders |
| `res://Art/`, `res://Audio/` | Assets with their entities |
| `res://Autoload/` | Split between `Core/` and `Multiplayer/` |
| Flat enemy folder | `Organisms/` with biological categories |
| Separate UI folder | `Entities/Ui/` (UI is part of gameplay) |
| Everything in utilities | Split: `Core/`, `Multiplayer/`, `Common/` |

---

## Migration Guide

If you need to reorganize from old structure:

**Old → New:**
- `Src/Autoload/` → `Core/` (mark as autoload)
- `Src/Entities/` → `Entities/`
- `Src/World/` → `Stages/`
- `Src/Multiplayer/` → `Multiplayer/`
- `Src/Systems/` → split between `Entities/Systems/` and `Core/`
- `Assets/` → keep global, move specific to entities

---

## Best Practices

1. **Keep folders focused** - one clear purpose per folder
2. **Use inheritance** - don't duplicate code
3. **Co-locate resources** - sprites go with the entity
4. **Common/ vs Core/** - common is portable, core is game-specific
5. **Separate multiplayer** - easier to maintain and scale
6. **Document complex systems** - add readme.md files

---

## Quick Reference

**Where does X go?**

- **New enemy?** → `Entities/Organisms/[category]/[name]/`
- **New item?** → `Entities/Items/[type]/[name]/`
- **New skill?** → `Entities/Skills/[category]/[name]/`
- **New UI?** → `Entities/Ui/[ui_name]/`
- **New location?** → `Stages/Locations/[type]/[name]/`
- **New game system?** → `Core/[system_name]/`
- **Network code?** → `Multiplayer/[server or client]/`
- **Reusable tool?** → `Common/[tool_name]/`

---

## Scalability Benefits

This structure scales because:
- ✅ Clear separation: core game logic vs networking
- ✅ Multiplayer code isolated and manageable  
- ✅ Core systems grouped logically
- ✅ Adding features = create focused folders
- ✅ Finding code is intuitive
- ✅ Teams can work on separate areas

This structure makes your project **intuitive, maintainable, and ready for multiplayer**! 🎯
