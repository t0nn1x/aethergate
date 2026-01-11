# Milestone 1: Overworld Foundation

## Goal
Create the basic overworld with a playable character, collision system, and click-to-move functionality. This establishes the core foundation for all future development.

## Deliverables

### 1. Project Setup
- [x] Create new Godot 4.x project
- [ ] Set up folder structure according to `project-structure.md`
- [ ] Configure project settings:
  - [ ] Set base resolution (e.g., 1920x1080 with stretch mode)
  - [ ] Configure input map for testing (if needed)
- [ ] Create initial placeholder assets folder structure

### 2. Overworld Scene Creation

#### 2.1 Create Base Overworld Scene
**File**: `src/world/overworld/overworld.tscn`

**Node Structure**:
```
Overworld (Node2D)
├─ TileMap (for terrain)
├─ NavigationRegion2D (for pathfinding)
│  └─ NavigationPolygon (to be configured)
├─ WorldEnvironment (for visual effects if needed)
├─ PlayerSpawnPoint (Marker2D)
└─ Camera2D (will be replaced by player camera)
```

**Tasks**:
- [ ] Create the overworld scene file
- [ ] Add TileMap node (placeholder - you'll configure this)
- [ ] Add NavigationRegion2D for click-to-move pathfinding
- [ ] Add a spawn point marker for the player
- [ ] Set up basic camera (temporary, will move to player later)

#### 2.2 Overworld Manager Script
**File**: `src/world/overworld/overworld.gd`

**Responsibilities**:
- Manage the overworld scene
- Handle player spawning
- Reference to current player instance

**Required Functions**:
```gdscript
class_name Overworld
extends Node2D

@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var spawn_point: Marker2D = $PlayerSpawnPoint

var player: Player = null

func _ready():
    spawn_player()

func spawn_player():
    # Load and instantiate player
    # Position at spawn point
    # Add as child to overworld

func get_navigation_region() -> NavigationRegion2D:
    return navigation_region
```

### 3. Player Entity

#### 3.1 Create Base Entity Class
**File**: `src/entities/base/entity.gd`

This is the foundation for all game entities (player, enemies, NPCs).

**Required Properties**:
- `entity_name: String`
- `max_health: float`
- `current_health: float`

**Required Functions**:
- `_ready()`: Initialize health
- `take_damage(amount: float)`: Damage handling
- `heal(amount: float)`: Healing
- `die()`: Death handling

**Template**:
```gdscript
class_name Entity
extends CharacterBody2D

@export var entity_name: String = "Entity"
@export var max_health: float = 100.0

var current_health: float = 100.0

func _ready():
    current_health = max_health

func take_damage(amount: float) -> void:
    current_health = max(0, current_health - amount)
    if current_health <= 0:
        die()

func heal(amount: float) -> void:
    current_health = min(max_health, current_health + amount)

func die() -> void:
    # Override in derived classes
    queue_free()
```

#### 3.2 Create Player Scene
**File**: `src/entities/player/player.tscn`

**Node Structure**:
```
Player (CharacterBody2D)
├─ CollisionShape2D
├─ AnimatedSprite2D (or Sprite2D for now)
├─ NavigationAgent2D
└─ Camera2D
```

**Tasks**:
- [ ] Create player scene
- [ ] Add CharacterBody2D as root
- [ ] Add CollisionShape2D (use placeholder shape for now)
- [ ] Add AnimatedSprite2D (or simple Sprite2D with placeholder graphic)
- [ ] Add NavigationAgent2D for pathfinding
- [ ] Add Camera2D for following the player
- [ ] Set appropriate collision layers/masks

#### 3.3 Player Script
**File**: `src/entities/player/player.gd`

**Responsibilities**:
- Extend Entity base class
- Handle player-specific initialization
- Reference to player components

**Template**:
```gdscript
class_name Player
extends Entity

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var movement: PlayerMovement = $PlayerMovement

func _ready():
    super._ready()
    entity_name = "Player"
    setup_camera()

func setup_camera():
    camera.enabled = true
    # Configure camera zoom, limits, smoothing, etc.
```

#### 3.4 Player Movement Component
**File**: `src/entities/player/player_movement.gd`

This script handles all click-to-move functionality.

**Required Properties**:
- `speed: float` - Movement speed
- `navigation_agent: NavigationAgent2D` - Reference
- `target_position: Vector2` - Where to move
- `is_moving: bool` - Movement state

**Required Functions**:
- `_ready()`: Setup navigation agent
- `_input(event)`: Handle mouse clicks
- `_physics_process(delta)`: Process movement
- `set_target(pos: Vector2)`: Set movement destination
- `stop_movement()`: Cancel current movement

**Detailed Template**:
```gdscript
class_name PlayerMovement
extends Node

@export var speed: float = 200.0
@export var stopping_distance: float = 5.0

@onready var player: Player = get_parent()
@onready var navigation_agent: NavigationAgent2D = player.get_node("NavigationAgent2D")

var is_moving: bool = false

func _ready():
    # Configure NavigationAgent2D
    navigation_agent.path_desired_distance = 4.0
    navigation_agent.target_desired_distance = stopping_distance
    navigation_agent.avoidance_enabled = true

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            # Check if click is on world (not UI)
            if not is_clicking_ui():
                set_target(get_global_mouse_position())

func _physics_process(delta: float) -> void:
    if is_moving:
        if navigation_agent.is_navigation_finished():
            stop_movement()
            return
        
        var next_position = navigation_agent.get_next_path_position()
        var direction = (next_position - player.global_position).normalized()
        
        player.velocity = direction * speed
        player.move_and_slide()
        
        # Optional: Update sprite direction based on movement
        update_sprite_direction(direction)

func set_target(target_pos: Vector2) -> void:
    navigation_agent.target_position = target_pos
    is_moving = true

func stop_movement() -> void:
    is_moving = false
    player.velocity = Vector2.ZERO

func is_clicking_ui() -> bool:
    # Simple check - will be expanded later when UI is added
    return false

func update_sprite_direction(direction: Vector2) -> void:
    # Optional: Update sprite based on movement direction
    # Can be implemented in Milestone 2 when animations are added
    pass
```

### 4. Basic Camera Setup

**File**: Inside `src/entities/player/player.gd`

**Camera Configuration**:
- [ ] Enable camera on player
- [ ] Set appropriate zoom level (e.g., Vector2(2, 2) for pixel art)
- [ ] Enable position smoothing (smoothing_enabled = true)
- [ ] Set smoothing_speed (e.g., 5.0)
- [ ] Optional: Set camera limits based on overworld size

**Example**:
```gdscript
func setup_camera():
    camera.enabled = true
    camera.zoom = Vector2(2, 2)  # Adjust for your pixel art scale
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    
    # Optional: Set camera limits
    # camera.limit_left = 0
    # camera.limit_top = 0
    # camera.limit_right = 2000
    # camera.limit_bottom = 2000
```

### 5. Integration & Testing

#### 5.1 Main Scene Setup
**File**: `scenes/main.tscn`

Create a simple main scene that loads the overworld:
```
Main (Node)
└─ Overworld (instance of overworld.tscn)
```

#### 5.2 Scene Configuration
- [ ] Set `scenes/main.tscn` as the main scene in project settings
- [ ] Ensure player spawns correctly in overworld
- [ ] Verify camera follows player

#### 5.3 Navigation Setup
**Manual Steps** (you will do these):
- [ ] Create TileMap with terrain tiles
- [ ] Create NavigationPolygon in NavigationRegion2D
- [ ] Bake navigation mesh to match walkable areas
- [ ] Set up collision shapes for impassable terrain

#### 5.4 Testing Checklist
- [ ] Run the scene - player should appear at spawn point
- [ ] Click anywhere on the walkable area - player should move there
- [ ] Player should path around obstacles (if collision set up)
- [ ] Camera should follow the player smoothly
- [ ] Player should stop at the target position
- [ ] Clicking multiple times should update the target
- [ ] Player collision works with world boundaries

## File Checklist

### Scripts to Create
- [ ] `src/entities/base/entity.gd`
- [ ] `src/entities/player/player.gd`
- [ ] `src/entities/player/player_movement.gd`
- [ ] `src/world/overworld/overworld.gd`

### Scenes to Create
- [ ] `src/entities/base/entity.tscn` (optional base scene)
- [ ] `src/entities/player/player.tscn`
- [ ] `src/world/overworld/overworld.tscn`
- [ ] `scenes/main.tscn`

### Folders to Create
```
src/
├── entities/
│   ├── base/
│   └── player/
└── world/
    └── overworld/

scenes/
assets/
└── graphics/
    └── characters/
        └── player/  (placeholder sprite)
```

## Success Criteria

Milestone 1 is complete when:

1. ✅ Player spawns in the overworld at the designated spawn point
2. ✅ Player can move to any clicked position using pathfinding
3. ✅ Player navigates around obstacles (after you set up collisions)
4. ✅ Camera smoothly follows the player
5. ✅ No console errors during gameplay
6. ✅ Code follows the structure defined in `project-structure.md`
7. ✅ Code follows guidelines in `copilot-instructions.md`

## Manual Tasks (You Will Do)

These tasks are not part of the AI-generated code but must be done by you:

1. **Create Overworld Map**:
   - Design the TileMap layout
   - Paint terrain tiles
   - Place obstacles and boundaries

2. **Configure Navigation**:
   - Draw NavigationPolygon to cover walkable areas
   - Bake the navigation mesh
   - Test pathfinding around obstacles

3. **Create Placeholder Graphics**:
   - Add a simple player sprite (can be a colored square for now)
   - Add basic tileset for terrain (if not already available)

4. **Set Up Collisions**:
   - Add StaticBody2D nodes for obstacles
   - Configure collision shapes for impassable areas
   - Ensure collision layers are correct

## Next Steps (Future Milestones)

After Milestone 1 is complete, future milestones might include:

- **Milestone 2**: Player animations, basic UI (health bar), and simple interactions
- **Milestone 3**: Overworld combat system (pop-up window)
- **Milestone 4**: Locations and location-based combat
- **Milestone 5**: Inventory and equipment systems
- And so on...

## Notes

- Keep code simple and clean - we'll expand functionality in future milestones
- Don't worry about animations yet - use placeholder sprites
- Focus on getting the core movement working perfectly
- The navigation system is critical - ensure it works well before moving forward
- All variables should be properly typed
- All nodes should be referenced with `@onready` where possible

## Questions or Issues?

If you encounter problems:
1. Check that NavigationRegion2D is properly configured
2. Verify collision layers are set correctly
3. Ensure the player scene is properly instantiated
4. Test in a simple scene before integrating into the full overworld
