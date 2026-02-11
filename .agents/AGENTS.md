# Copilot Instructions for 2D RPG Project

## Project Overview

You are assisting with a 2D pixel-art RPG built in Godot 4.6 featuring:
- **Overworld**: Strategic layer with chunking system and simplified combat
- **Locations**: Tactical layer with full real-time combat and active pause
- **Multiplayer**: Party system, guilds, PvP arenas
- **Progression**: Equipment-based builds, skill trees, crafting

**Key Inspiration**: Albion Online, Warspear, Heroes of Aethric

---

## Project Structure Philosophy

**CRITICAL**: This project uses **functionality-first organization**, NOT file-type organization.

### Core Principles
1. **Organize by what it does**, not by file extension
2. **Keep related files together** - sprites live with the entity that uses them
3. **Use folder hierarchies for inheritance** - base classes at top, implementations nested
4. **Minimize root clutter** - keep top-level folders focused
5. **Entities live inside stages**, not vice versa

### Top-Level Folders
```
Assets/       # Global assets (music, fonts, credits)
Common/       # Reusable, portable systems (state machines, shaders)
Config/       # Game settings and configuration
Core/         # Game-specific managers (mostly autoloaded)
Entities/     # LARGEST - everything in the game world
Localization/ # Translations
Multiplayer/  # Networking and multiplayer code
Map, World/   # Playable areas (overworld, dungeons, towns)
```

---

## Where Files Go - Quick Reference

**When creating new code, ask yourself:**

### Is it a thing that exists in the game world?
→ **`Entities/`**
- Player, enemies, NPCs
- Items, weapons, armor
- Skills, projectiles
- Trees, rocks, resources
- Chests, doors, interactables
- UI elements (they exist in scene tree)

### Is it a place where things happen?
→ **`Stages/`**
- Overworld and chunk system
- Dungeons and caves
- Towns and cities
- Arenas

### Is it a background System/manager?
→ **`Core/`**
- Game manager, save system
- Event bus, audio manager
- Quest manager, party manager

### Is it multiplayer/networking?
→ **`Multiplayer/`**
- Network manager
- Client/server sync

### Is it a debug or dev tool?
→ **`Utilities/`**
- Debug overlay, profiling tools
- Dev-only UI helpers

### Is it reusable across projects?
→ **`Common/`**
- State machines
- Generic shaders
- Resolution scaling
- Pathfinding utilities

### Is it global media used everywhere?
→ **`Assets/`**
- Background music
- UI fonts
- Credits

---

## File Organization Pattern

### Entity Organization (Most Common)

Every entity folder contains **all** related files:

```
Entities/Organisms/Mammals/Wolf/
├── wolf.gd              # Logic/behavior
├── wolf.tscn            # Scene
├── wolf_data.tres       # Stats/configuration
├── Sprites/             # Graphics
│   ├── idle.png
│   ├── walk.png
│   └── attack.png
├── Sounds/              # Audio
│   └── growl.wav
└── Vfx/                 # Visual effects
    └── bite_spark.tscn
```

**Rule**: If it's only used by wolf, it goes in `Wolf/` folder.

### Inheritance Organization

Base classes at folder root, specializations nested:

```
Entities/Items/
├── item.gd              # Base class for ALL items
├── item_data.gd         # Base resource
│
├── Weapons/
│   ├── weapon.gd        # Extends item.gd
│   ├── weapon_data.gd   # Extends item_data.gd
│   │
│   ├── Swords/
│   │   ├── sword.gd     # Extends weapon.gd
│   │   └── Iron_Sword/
│   │       ├── iron_sword_data.tres  # Instance of weapon_data.gd
│   │       └── icon.png
│   │
│   └── Axes/
│       └── Battle_Axe/
│
└── Consumables/
    ├── consumable.gd
    └── Potions/
        └── Health_Potion/
```

**Pattern**: 
1. Base class at top level
2. Type-specific classes in subfolders
3. Final implementations at deepest level

---

## Code Style Requirements

### Static Typing (REQUIRED)
```gdscript
# Good ✅
var health: float = 100.0
var target: Enemy = null
@export var speed: float = 200.0
func calculate_damage(attacker: Character, defender: Character) -> float:

# Bad ❌
var health = 100.0
var target = null
func calculate_damage(attacker, defender):
```

### Class Names
Define `class_name` for all reusable classes:
```gdscript
class_name Wolf
extends Organism
```

### Documentation
Add docstrings for public functions:
```gdscript
## Calculates damage after armor reduction
## Returns final damage value
func calculate_damage(base_damage: float, armor: float) -> float:
    return max(1.0, base_damage - armor)
```

### Signals
Declare at top of script:
```gdscript
signal health_changed(new_value: float)
signal died()
signal skill_used(skill: Skill)
```

---

## Naming Conventions

### Files
- Scripts: `snake_case.gd` → `player_movement.gd`
- Scenes: `snake_case.tscn` → `goblin_cave.tscn`
- Resources: `snake_case.tres` → `iron_sword_data.tres`
- Images: `snake_case.png` → `player_idle.png`

### Code
- Classes: `PascalCase` → `class_name PlayerMovement`
- Variables: `snake_case` → `var current_health`
- Constants: `SCREAMING_SNAKE_CASE` → `const MAX_SPEED = 200`
- Functions: `snake_case` → `func take_damage()`
- Private: `_prefix` → `var _internal_cache`

---

## Architecture Patterns

### Event Bus Communication
Use EventBus for cross-system events:
```gdscript
# Emit
EventBus.enemy_died.emit(self)
EventBus.item_picked_up.emit(item_id, amount)

# Listen
func _ready():
    EventBus.enemy_died.connect(_on_enemy_died)
    EventBus.item_picked_up.connect(_on_item_picked_up)
```

**EventBus location**: `Core/event_bus.gd`

### Inheritance Hierarchy
```
Node2D
└─ Entity (Entities/Base/)
   └─ Organism (Entities/Organisms/)
      ├─ Player (Entities/Player/)
      ├─ Enemy (Entities/Organisms/[category]/)
      └─ NPC (Entities/Npcs/)
```

### Resource-Based Data
Use Resources for data, not scripts:
```gdscript
# Entities/Items/item_data.gd
class_name ItemData
extends Resource

@export var item_id: String
@export var display_name: String
@export var icon: Texture2D
@export var stack_size: int = 1
```

Create instances as `.tres` files in same folder as entity.

### Manager Pattern
Managers live in `Core/` and are typically autoloaded:
```gdscript
# Core/Quest/quest_manager.gd
extends Node

var active_quests: Dictionary = {}

func start_quest(quest_id: String):
    # Implementation
```

---

## System-Specific Guidelines

### Chunking System (Overworld)

**Location**: `Stages/Overworld/Chunks/`

Files needed:
- `chunk.gd` - Visual chunk representation
- `chunk_manager.gd` - Loads/unloads chunks
- `chunk_data.gd` - Stores chunk tile data

Key concepts:
- Server has master chunk data
- Clients load chunks on demand
- Chunks are 32x32 tiles
- Load radius: 2-3 chunks

### Combat System

**Two separate systems:**

1. **Overworld Combat** (`Entities/Combat/Overworld/`)
   - Pop-up window based
   - Auto-battle with manual skills
   - Fast (15-30 seconds)

2. **Location Combat** (`Entities/Combat/Location/`)
   - On-screen, real-time
   - Active pause (Spacebar)
   - Full tactical control

**Shared code**: `Entities/Combat/Shared/`
- `damage_calculator.gd`
- `status_effect.gd`
- `combat_stats.gd`

### Multiplayer

**Server**: `Multiplayer/Server/`
- `world_manager.gd` - Manages all chunks
- Authority over game state

**Client**: `Multiplayer/Client/`
- `client_sync.gd` - Syncs with server
- Presentation layer only

**Network Manager**: `Multiplayer/network_manager.gd` (autoloaded)

### UI System

**Location**: `Entities/Ui/`

Why in entities? Because UI exists in the scene tree and interacts with gameplay.

Structure:
```
Entities/Ui/
├── Hud/           # Health, mana, hotbar
├── Inventory/     # Inventory screen
├── Quest_Log/     # Quest interface
└── Dialogue/      # Dialogue boxes
```

---

## Common Implementation Patterns

### Creating a New Enemy

1. **Determine category**: mammal, bird, reptile, etc.
2. **Create folder**: `Entities/Organisms/Mammals/Wolf/`
3. **Create files**:
   ```
   Wolf/
   ├── wolf.gd          # extends Organism
   ├── wolf.tscn
   ├── wolf_data.tres   # stats
   └── Sprites/
       └── idle.png
   ```
4. **Implement behavior** in `wolf.gd`
5. **Add to spawner** or place in stage

### Creating a New Item

1. **Determine type**: weapon, armor, consumable, material
2. **Create folder**: `Entities/Items/Weapons/Swords/Iron_Sword/`
3. **Create data**: `iron_sword_data.tres` (instance of `weapon_data.gd`)
4. **Add icon**: `icon.png` in same folder
5. **Register** in data manager if needed

### Creating a New Skill

1. **Create folder**: `Entities/Skills/Combat/Fireball/`
2. **Create files**:
   ```
   Fireball/
   ├── fireball.gd        # extends Skill
   ├── fireball.tscn      # visual representation
   ├── fireball_data.tres # cooldown, cost, etc.
   ├── icon.png
   └── Vfx/
       └── explosion.tscn
   ```
3. **Implement** `execute()` method
4. **Add to** skill tree or class

### Creating a New Stage

1. **Location**: `Stages/Locations/Dungeons/Goblin_Cave/`
2. **Create**:
   ```
   Goblin_Cave/
   ├── goblin_cave.tscn   # main scene
   ├── goblin_cave.gd     # stage logic
   └── Encounters/        # enemy placements
   ```
3. **Design** layout in TileMap
4. **Add** NavigationRegion2D
5. **Place** enemies, chests, exits

---

## Error Handling

Always validate critical operations:
```gdscript
func use_skill(skill_index: int) -> void:
    if skill_index < 0 or skill_index >= skills.size():
        push_error("Invalid skill index: %d" % skill_index)
        return
    
    var skill = skills[skill_index]
    if not skill:
        push_error("Skill at index %d is null" % skill_index)
        return
    
    if not skill.can_use(self):
        push_warning("Cannot use skill %s" % skill.skill_name)
        return
    
    skill.execute(self, current_target)
```

---

## Performance Considerations

### Object Pooling
For frequently spawned objects (projectiles, damage numbers):
```gdscript
# Entities/Projectiles/projectile_pool.gd
var pool: Array[Projectile] = []

func get_projectile() -> Projectile:
    for proj in pool:
        if not proj.is_active:
            return proj
    
    var new_proj = projectile_scene.instantiate()
    pool.append(new_proj)
    return new_proj
```

### Signals Over Polling
```gdscript
# Good ✅
signal health_changed(new_value: float)

func take_damage(amount: float):
    current_health -= amount
    health_changed.emit(current_health)

# Bad ❌
func _process(_delta):
    if current_health != last_health:
        update_ui()
        last_health = current_health
```

---

## Testing Approach

Create test scenes in `Stages/` or entity folder:
```
Entities/Player/
├── player.gd
├── player.tscn
└── player_test.tscn  # Isolated test environment
```

For system testing:
```
Core/Quest/
├── quest_manager.gd
└── test_quest_scene.tscn
```

---

## What NOT to Do

❌ **Don't** separate by file type:
```
Bad:
res://Scripts/player.gd
res://Scenes/player.tscn
res://Sprites/player.png

Good:
Entities/Player/
├── player.gd
├── player.tscn
└── Sprites/player.png
```

❌ **Don't** use hardcoded paths - use relative or typed references:
```
# Bad ❌
var player = get_node("/Root/Game/Player")

# Good ✅
var player: Player = PlayerManager.get_player()
```

❌ **Don't** put game logic in UI:
```
# Bad ❌ - in inventory_ui.gd
func use_item(item):
    player.health += item.heal_amount  # Logic in UI!

# Good ✅ - in inventory_ui.gd
func use_item(item):
    EventBus.item_used.emit(item)  # UI just emits event

# In player.gd
func _on_item_used(item):
    health += item.heal_amount  # Logic where it belongs
```

❌ **Don't** create circular dependencies:
```
# Bad ❌
# player.gd imports enemy.gd
# enemy.gd imports player.gd

# Good ✅
# Both extend Entity
# Communication via signals
```

❌ **Don't** ignore the inheritance hierarchy:
```
# Bad ❌
Entities/wolf.gd  # Flat structure

# Good ✅
Entities/Organisms/Mammals/Wolf/wolf.gd  # Proper categorization
```

---

## Special Considerations

### Multiplayer Code
- Server authority for all game state
- Client code in `Multiplayer/Client/`
- Server code in `Multiplayer/Server/`
- Never trust client input - always validate on server

### Localization
- All user-facing text goes through translation system
- Keys in `Localization/translation_keys.csv`
- Use `tr("key")` in code

### Save System
- Save only essential data
- Use `Core/save_manager.gd`
- Validate before loading
- Auto-save on important events

---

## Code Review Checklist

Before considering code complete:

✅ Files in correct folders (entities, stages, or utilities)
✅ Related assets co-located with scripts
✅ Static typing used throughout
✅ Class name defined (if reusable)
✅ Signals properly Connected/disconnected
✅ Null checks for critical references
✅ Error handling for edge cases
✅ Documentation for public functions
✅ Follows inheritance hierarchy
✅ No circular dependencies
✅ Communication via EventBus for cross-system
✅ Resources used for data
✅ Tested in isolation

---

## Questions to Ask

When implementing a feature:

1. **Where does this belong?**
   - Is it an entity, a stage, or a utility?
   - Is it game-specific or reusable?

2. **How should it communicate?**
   - Direct reference? (parent-child only)
   - EventBus? (cross-system)
   - Manager? (centralized logic)

3. **What's the inheritance?**
   - Does a base class exist?
   - Should this be a base class?
   - Where in the hierarchy?

4. **Is data separate from logic?**
   - Create a Resource for configuration
   - Script has behavior, Resource has data

5. **Will this work in multiplayer?**
   - Does server need to validate?
   - Should this sync?

---

## Quick Decision Tree

**New code to write:**

```
Is it Visible/interactive in game?
├─ Yes → Entities/
│  ├─ Is it a character?
│  │  └─ Entities/Player/ or Entities/Organisms/ or Entities/Npcs/
│  ├─ Is it an object?
│  │  └─ Entities/Items/ or Entities/Environment/ or Entities/Interactables/
│  └─ Is it UI?
│     └─ Entities/Ui/
│
├─ No → Is it a place?
│  ├─ Yes → Stages/
│  │  ├─ Overworld? → Stages/Overworld/
│  │  └─ Instanced? → Stages/Locations/
│  │
│  └─ No → Is it a system?
│     ├─ Game-specific? → Core/
│     └─ Reusable? → Common/
```

---

## When in Doubt

1. Check `project-structure.md` for detailed layout
2. Look at similar existing code
3. Follow the **functionality-first** principle
4. Keep related things together
5. Ask: "Where would I look for this naturally?"

This structure makes your codebase **intuitive, scalable, and maintainable**! 🚀
