# Project Structure

## Directory Structure

```
res://
├── addons/                          # Plugins and third-party tools
│
├── assets/                          # All game assets
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   │   ├── combat/
│   │   │   ├── ui/
│   │   │   └── ambient/
│   │   └── voice/
│   │
│   ├── graphics/
│   │   ├── characters/
│   │   │   ├── player/
│   │   │   │   ├── warrior/
│   │   │   │   ├── mage/
│   │   │   │   └── rogue/
│   │   │   ├── enemies/
│   │   │   └── npcs/
│   │   │
│   │   ├── items/
│   │   │   ├── weapons/
│   │   │   ├── armor/
│   │   │   ├── consumables/
│   │   │   └── materials/
│   │   │
│   │   ├── tilesets/
│   │   │   ├── overworld/
│   │   │   └── locations/
│   │   │       ├── dungeon/
│   │   │       ├── forest/
│   │   │       └── town/
│   │   │
│   │   ├── ui/
│   │   │   ├── icons/
│   │   │   ├── buttons/
│   │   │   ├── panels/
│   │   │   └── cursors/
│   │   │
│   │   ├── vfx/                    # Visual effects
│   │   │   ├── skills/
│   │   │   ├── hits/
│   │   │   └── environment/
│   │   │
│   │   └── fonts/
│   │
│   └── data/                        # JSON/CSV data files
│       ├── items/
│       ├── skills/
│       ├── enemies/
│       ├── quests/
│       └── dialogues/
│
├── src/                             # All source code
│   ├── autoload/                    # Singleton scripts (Autoload)
│   │   ├── game_manager.gd         # Main game manager
│   │   ├── event_bus.gd            # Global event system
│   │   ├── audio_manager.gd        # Audio management
│   │   ├── save_manager.gd         # Save/load system
│   │   ├── network_manager.gd      # Multiplayer networking
│   │   ├── player_manager.gd       # Player data management
│   │   └── data_manager.gd         # Data loading (items, skills, etc.)
│   │
│   ├── combat/                      # Combat systems
│   │   ├── overworld/
│   │   │   ├── overworld_combat_manager.gd
│   │   │   ├── overworld_combat_window.gd
│   │   │   └── overworld_combat_window.tscn
│   │   │
│   │   ├── location/
│   │   │   ├── location_combat_manager.gd
│   │   │   ├── combat_ui.gd
│   │   │   └── combat_ui.tscn
│   │   │
│   │   ├── shared/                 # Shared code for both systems
│   │   │   ├── damage_calculator.gd
│   │   │   ├── status_effect.gd
│   │   │   ├── aggro_system.gd
│   │   │   └── combat_stats.gd
│   │   │
│   │   └── ai/
│   │       ├── enemy_ai.gd
│   │       ├── behaviors/
│   │       │   ├── melee_behavior.gd
│   │       │   ├── ranged_behavior.gd
│   │       │   └── caster_behavior.gd
│   │       └── ai_states/
│   │
│   ├── entities/                    # All game entities
│   │   ├── base/
│   │   │   ├── entity.gd           # Base class for all entities
│   │   │   ├── entity.tscn
│   │   │   ├── character.gd        # Base for all characters
│   │   │   └── character.tscn
│   │   │
│   │   ├── player/
│   │   │   ├── player.gd
│   │   │   ├── player.tscn
│   │   │   ├── player_controller.gd    # Input handling
│   │   │   ├── player_movement.gd      # Click-to-move implementation
│   │   │   └── player_stats.gd
│   │   │
│   │   ├── enemies/
│   │   │   ├── enemy.gd            # Base enemy class
│   │   │   ├── enemy.tscn
│   │   │   ├── types/
│   │   │   │   ├── goblin.gd
│   │   │   │   ├── wolf.gd
│   │   │   │   └── boss_bear.gd
│   │   │   └── spawner.gd          # Enemy spawning system
│   │   │
│   │   ├── npcs/
│   │   │   ├── npc.gd
│   │   │   ├── npc.tscn
│   │   │   ├── vendor.gd
│   │   │   └── quest_giver.gd
│   │   │
│   │   └── projectiles/
│   │       ├── projectile.gd
│   │       └── arrow.gd
│   │
│   ├── systems/                     # Game systems
│   │   ├── inventory/
│   │   │   ├── inventory.gd
│   │   │   ├── inventory_ui.gd
│   │   │   ├── inventory_ui.tscn
│   │   │   └── item_slot.gd
│   │   │
│   │   ├── equipment/
│   │   │   ├── equipment_manager.gd
│   │   │   ├── equipment_ui.gd
│   │   │   └── equipment_slot.gd
│   │   │
│   │   ├── skills/
│   │   │   ├── skill.gd            # Base skill class
│   │   │   ├── skill_manager.gd
│   │   │   ├── skill_tree.gd
│   │   │   ├── skill_ui.gd
│   │   │   └── types/              # Specific skills
│   │   │       ├── fireball.gd
│   │   │       ├── backstab.gd
│   │   │       └── shield_bash.gd
│   │   │
│   │   ├── crafting/
│   │   │   ├── crafting_manager.gd
│   │   │   ├── recipe.gd
│   │   │   └── crafting_ui.gd
│   │   │
│   │   ├── quest/
│   │   │   ├── quest.gd
│   │   │   ├── quest_manager.gd
│   │   │   ├── quest_tracker.gd
│   │   │   └── objectives/
│   │   │
│   │   ├── dialogue/
│   │   │   ├── dialogue_manager.gd
│   │   │   ├── dialogue_ui.gd
│   │   │   └── dialogue_parser.gd
│   │   │
│   │   ├── party/                  # Party/group system
│   │   │   ├── party_manager.gd
│   │   │   ├── party_ui.gd
│   │   │   └── party_member.gd
│   │   │
│   │   ├── guild/
│   │   │   ├── guild_manager.gd
│   │   │   ├── guild_ui.gd
│   │   │   └── guild_territory.gd
│   │   │
│   │   ├── loot/
│   │   │   ├── loot_table.gd
│   │   │   ├── loot_drop.gd
│   │   │   └── loot_ui.gd
│   │   │
│   │   └── progression/
│   │       ├── level_system.gd
│   │       ├── experience_manager.gd
│   │       └── stat_calculator.gd
│   │
│   ├── world/                       # Game world
│   │   ├── overworld/
│   │   │   ├── overworld.gd
│   │   │   ├── overworld.tscn
│   │   │   ├── overworld_camera.gd
│   │   │   ├── location_entrance.gd    # Entrances to locations
│   │   │   └── resource_node.gd        # Trees, ore, etc.
│   │   │
│   │   ├── locations/
│   │   │   ├── location.gd         # Base location class
│   │   │   ├── location.tscn
│   │   │   ├── dungeon/
│   │   │   │   ├── goblin_cave.tscn
│   │   │   │   └── ancient_ruins.tscn
│   │   │   ├── town/
│   │   │   │   └── starting_village.tscn
│   │   │   └── arena/
│   │   │       ├── arena_2v2.tscn
│   │   │       └── arena_3v3.tscn
│   │   │
│   │   ├── environment/
│   │   │   ├── interactive_object.gd   # Doors, chests, levers
│   │   │   ├── chest.gd
│   │   │   ├── door.gd
│   │   │   └── trap.gd
│   │   │
│   │   └── weather/
│   │       ├── weather_system.gd
│   │       └── effects/
│   │
│   ├── ui/                          # UI components
│   │   ├── common/
│   │   │   ├── button.gd
│   │   │   ├── panel.gd
│   │   │   ├── tooltip.gd
│   │   │   └── notification.gd
│   │   │
│   │   ├── hud/
│   │   │   ├── hud.gd
│   │   │   ├── hud.tscn
│   │   │   ├── health_bar.gd
│   │   │   ├── mana_bar.gd
│   │   │   ├── hotbar.gd
│   │   │   └── minimap.gd
│   │   │
│   │   ├── menus/
│   │   │   ├── main_menu.tscn
│   │   │   ├── pause_menu.tscn
│   │   │   ├── settings_menu.tscn
│   │   │   └── character_sheet.tscn
│   │   │
│   │   └── screens/
│   │       ├── loading_screen.tscn
│   │       ├── death_screen.tscn
│   │       └── victory_screen.tscn
│   │
│   ├── multiplayer/                 # Multiplayer code
│   │   ├── network_player.gd
│   │   ├── sync_manager.gd
│   │   ├── lobby.gd
│   │   └── chat_system.gd
│   │
│   ├── utils/                       # Utility scripts
│   │   ├── math_utils.gd
│   │   ├── string_utils.gd
│   │   ├── animation_helper.gd
│   │   ├── timer_manager.gd
│   │   └── debug_tools.gd
│   │
│   └── resources/                   # Custom Resource types
│       ├── item_resource.gd
│       ├── skill_resource.gd
│       ├── enemy_resource.gd
│       └── quest_resource.gd
│
├── scenes/                          # Complete scenes
│   ├── main.tscn                   # Main scene
│   ├── game.tscn                   # Game scene
│   └── test/                       # Test scenes
│       ├── combat_test.tscn
│       └── ui_test.tscn
│
└── tests/                           # Unit tests (optional)
    └── unit/
```

## Architecture Principles

### 1. Autoload System (Singletons)

Configure in Project Settings → Autoload:

```
EventBus         → res://src/autoload/event_bus.gd
GameManager      → res://src/autoload/game_manager.gd
PlayerManager    → res://src/autoload/player_manager.gd
DataManager      → res://src/autoload/data_manager.gd
SaveManager      → res://src/autoload/save_manager.gd
AudioManager     → res://src/autoload/audio_manager.gd
NetworkManager   → res://src/autoload/network_manager.gd
```

### 2. Inheritance Hierarchy

```
Node2D
  └─ Entity (base class)
      ├─ Character (adds combat stats, skills)
      │   ├─ Player
      │   ├─ Enemy
      │   └─ NPC
      └─ Projectile
```

### 3. Event Bus Pattern

All major game events should be routed through the EventBus singleton to maintain loose coupling between systems.

### 4. Resource-Based Data

Use Godot Resources (.tres files) for:
- Items
- Skills
- Enemy definitions
- Quests
- Recipes

This allows easy editing in the Godot editor and separation of data from logic.

### 5. Separation of Concerns

- **Entities**: Define what things ARE
- **Systems**: Define what things DO
- **Managers**: Coordinate between systems
- **UI**: Display information and handle user input

## Naming Conventions

- **Files**: snake_case (e.g., `player_movement.gd`)
- **Classes**: PascalCase (e.g., `class_name PlayerMovement`)
- **Variables**: snake_case (e.g., `var current_health`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `const MAX_SPEED = 200`)
- **Signals**: snake_case (e.g., `signal enemy_died`)
- **Functions**: snake_case (e.g., `func calculate_damage()`)

## File Organization Rules

1. Each major feature should have its own folder
2. Related files stay together (script + scene + resources)
3. Shared/common code goes in appropriate base folders
4. Test scenes separate from production scenes
5. Assets organized by type first, then by feature
