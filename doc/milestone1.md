# Milestone 1: Overworld Foundation

## Goal
Create the basic overworld with a playable character, collision system, and click-to-move functionality. This establishes the core foundation for all future development.

---

## Deliverables

### 1. Project Setup

#### 1.1 Folder Structure
Create the following folders:

```
res://
├── Assets/
│   └── Audio/
│       ├── Music/
│       └── Sfx/
├── Common/
├── Config/
├── Entities/
│   ├── Player/
│   ├── Camera/
│   └── Ui/
│       └── Hud/
├── Localization/
├── Stages/
│   └── Overworld/
│       ├── Chunks/
│       └── Tilesets/
└── Utilities/
```

**Task**: Create this folder structure in your project.

---

#### 1.2 Project Settings Configuration

**Display Settings** (`Project → Project Settings → Display`):

```
Window/Size/Viewport Width: 1920
Window/Size/Viewport Height: 1080
Window/Size/Mode: Windowed
Window/Size/Resizable: On

Window/Stretch/Mode: canvas_items
Window/Stretch/Aspect: keep
Window/Stretch/Scale: 1.0
Window/Stretch/Scale Mode: integer  ⚠️ CRITICAL for pixel art!
```

**Rendering Settings** (`Project → Project Settings → Rendering`):

```
Textures/Canvas Textures/Default Texture Filter: Nearest  ⚠️ CRITICAL!
2D/Snap/Snap 2D Transforms to Pixel: On
2D/Snap/Snap 2D Vertices to Pixel: On
```

**Physics Layers** (`Project → Project Settings → Layer Names → 2D Physics`):

```
Layer 1: World           (terrain, walls, static obstacles)
Layer 2: Player          (player character)
Layer 3: Enemies         (enemy characters)
Layer 4: Projectiles     (arrows, fireballs)
Layer 5: Interactables   (chests, doors, NPCs)
Layer 6: Triggers        (zone triggers)
Layer 7: Resources       (trees, ore nodes)
Layer 8: PvP             (PvP-specific)
```

**Input Map** (`Project → Project Settings → Input Map`):

Add these actions:
```
interact    → E
inventory   → I
pause       → Escape

skill_1     → 1
skill_2     → 2
skill_3     → 3
```

---

#### 1.3 Create Autoload Singletons

**File**: `Utilities/event_bus.gd`
```gdscript
extends Node

# Combat events
signal enemy_died(enemy: Node)
signal player_damaged(damage: int)
signal skill_used(skill_id: String, caster: Node)

# World events
signal location_entered(location_name: String)
signal chunk_loaded(chunk_pos: Vector2i)

# UI events
signal inventory_opened()
signal item_picked_up(item_id: String, amount: int)

# Player events
signal player_spawned(player: Node)
signal player_moved(position: Vector2)
```

**File**: `Utilities/game_manager.gd`
```gdscript
extends Node

enum GameState { MAIN_MENU, LOADING, OVERWORLD, LOCATION, COMBAT, PAUSED }

var current_state: GameState = GameState.MAIN_MENU
var current_location: String = ""

func _ready():
    print("GameManager initialized")

func change_state(new_state: GameState) -> void:
    var old_state = current_state
    current_state = new_state
    print("Game state: %s → %s" % [
        GameState.keys()[old_state],
        GameState.keys()[new_state]
    ])

func is_in_overworld() -> bool:
    return current_state == GameState.OVERWORLD

func is_in_combat() -> bool:
    return current_state == GameState.COMBAT
```

**Configure Autoload** (`Project → Project Settings → Autoload`):
```
EventBus      → res://Utilities/event_bus.gd
GameManager   → res://Utilities/game_manager.gd
```

---

### 2. Base Entity System

#### 2.1 Create Base Entity Class

**File**: `Entities/organism.gd`

This is the base class for all living things (player, enemies, NPCs).

```gdscript
class_name Organism
extends CharacterBody2D

## Base class for all living entities in the game
## Provides health, stats, and basic functionality

@export_group("Stats")
@export var organism_name: String = "Organism"
@export var max_health: float = 100.0
@export var movement_speed: float = 200.0

var current_health: float = 100.0
var is_alive: bool = true

signal health_changed(new_health: float, max_health: float)
signal died()

func _ready():
    current_health = max_health
    add_to_group("organisms")

## Deals damage to this organism
func take_damage(amount: float) -> void:
    if not is_alive:
        return
    
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        die()

## Heals this organism
func heal(amount: float) -> void:
    if not is_alive:
        return
    
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

## Called when organism health reaches zero
func die() -> void:
    if not is_alive:
        return
    
    is_alive = false
    died.emit()
    
    # Override in derived classes
    _on_death()

## Override this in derived classes for custom death behavior
func _on_death() -> void:
    queue_free()

## Returns health as percentage (0.0 to 1.0)
func get_health_percentage() -> float:
    return current_health / max_health if max_health > 0 else 0.0
```

---

### 3. Player Entity

#### 3.1 Create Player Scene

**File**: `Entities/Player/player.tscn`

**Node Structure**:
```
Player (CharacterBody2D)
├─ CollisionShape2D
├─ Sprite2D (or AnimatedSprite2D)
├─ PlayerMovement (Node)
├─ Camera2D
└─ DebugLabel (Label) [optional]
```

**Setup Instructions**:
1. Create new scene with CharacterBody2D as root
2. Name it "Player"
3. Add CollisionShape2D → set shape (CircleShape2D or RectangleShape2D)
4. Add Sprite2D → assign placeholder texture
5. Add Camera2D as child
6. Save to `Entities/Player/player.tscn`

**CollisionShape2D Settings**:
- Collision Layer: Layer 2 (Player)
- Collision Mask: Layer 1 (World)

**Camera2D Settings**:
```
Enabled: true
Zoom: Vector2(2, 2)  # Adjust for your pixel art scale
Position Smoothing Enabled: true
Position Smoothing Speed: 5.0
```

---

#### 3.2 Player Script

**File**: `Entities/Player/player.gd`

```gdscript
class_name Player
extends Organism

## The player character
## Handles player-specific initialization and references

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var movement: PlayerMovement = $PlayerMovement

func _ready():
    super._ready()
    
    organism_name = "Player"
    max_health = 100.0
    movement_speed = 200.0
    current_health = max_health
    
    setup_camera()
    
    # Register with game systems
    add_to_group("player")
    EventBus.player_spawned.emit(self)

func setup_camera():
    camera.enabled = true
    camera.zoom = Vector2(2, 2)  # Adjust based on your tile size
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0

func _on_death() -> void:
    print("Player died!")
    # Don't queue_free - handle respawn instead
    GameManager.change_state(GameManager.GameState.PAUSED)
```

---

#### 3.3 Player Movement Component

**File**: `Entities/Player/player_movement.gd`

This handles the click-to-move system.

```gdscript
class_name PlayerMovement
extends Node

## Handles player movement using click-to-move with NavigationAgent2D

@export var stopping_distance: float = 5.0

@onready var player: Player = get_parent()

var navigation_agent: NavigationAgent2D
var is_moving: bool = false

func _ready():
    # NavigationAgent2D will be added when overworld is set up
    call_deferred("setup_navigation")

func setup_navigation():
    # Create NavigationAgent2D
    navigation_agent = NavigationAgent2D.new()
    player.add_child(navigation_agent)
    
    # Configure
    navigation_agent.path_desired_distance = 4.0
    navigation_agent.target_desired_distance = stopping_distance
    navigation_agent.avoidance_enabled = true
    navigation_agent.radius = 16.0  # Adjust based on player size

func _input(event: InputEvent) -> void:
    if not navigation_agent:
        return
    
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            # Check if clicking on UI
            if is_clicking_ui():
                return
            
            # Set target
            var target_pos = get_global_mouse_position()
            set_target(target_pos)

func _physics_process(_delta: float) -> void:
    if not navigation_agent or not is_moving:
        return
    
    # Check if reached destination
    if navigation_agent.is_navigation_finished():
        stop_movement()
        return
    
    # Get next position
    var next_position = navigation_agent.get_next_path_position()
    var direction = (next_position - player.global_position).normalized()
    
    # Move
    player.velocity = direction * player.movement_speed
    player.move_and_slide()
    
    # Emit position updates (for Multiplayer/chunking)
    EventBus.player_moved.emit(player.global_position)
    
    # Optional: Update sprite direction
    update_sprite_direction(direction)

func set_target(target_pos: Vector2) -> void:
    if not navigation_agent:
        return
    
    navigation_agent.target_position = target_pos
    is_moving = true

func stop_movement() -> void:
    is_moving = false
    player.velocity = Vector2.ZERO

func is_clicking_ui() -> bool:
    # Check if mouse is over UI elements
    # For now, simple check - expand when UI is added
    var mouse_pos = player.get_viewport().get_mouse_position()
    
    # Check if any UI control has focus or is under mouse
    # This is a placeholder - proper implementation when UI exists
    return false

func update_sprite_direction(direction: Vector2) -> void:
    # Optional: Flip sprite or change animation based on direction
    # Implement in Milestone 2 when animations are added
    
    # Example for simple Left/right flip:
    if direction.x < 0:
        player.sprite.flip_h = true
    elif direction.x > 0:
        player.sprite.flip_h = false
```

---

### 4. Overworld Stage

#### 4.1 Create Overworld Scene

**File**: `Stages/Overworld/overworld.tscn`

**Node Structure**:
```
Overworld (Node2D)
├─ Terrain (Node2D)
│  ├─ Ground (TileMapLayer)
│  ├─ Objects (TileMapLayer)
│  └─ Overlay (TileMapLayer)
├─ Navigation (Node2D)
│  └─ NavigationRegion2D
├─ SpawnPoints (Node2D)
│  └─ PlayerSpawnPoint (Marker2D)
└─ Entities (Node2D)
```

**Setup Instructions**:
1. Create new 2D Scene
2. Rename root to "Overworld"
3. Add child Node2D named "Terrain"
4. Inside Terrain, add TileMapLayer nodes (Ground, Objects, Overlay)
5. Add Navigation group with NavigationRegion2D
6. Add SpawnPoints group with Marker2D for player
7. Add Entities group (where player will be spawned)

**TileMapLayer Configuration** (for each layer):
```
Rendering Quadrant Size: 16
Collision Animatable: false
Collision Visibility Mode: Show When Selected
```

**Set Z-index for layers**:
- Ground: 0
- Objects: 1
- Overlay: 2

---

#### 4.2 Overworld Script

**File**: `Stages/Overworld/overworld.gd`

```gdscript
class_name Overworld
extends Node2D

## Main overworld stage
## Handles player spawning and overworld management

@onready var terrain: Node2D = $Terrain
@onready var navigation_region: NavigationRegion2D = $Navigation/NavigationRegion2D
@onready var player_spawn: Marker2D = $SpawnPoints/PlayerSpawnPoint
@onready var entities: Node2D = $Entities

var player: Player = null

func _ready():
    print("Overworld loaded")
    GameManager.change_state(GameManager.GameState.OVERWORLD)
    
    # Spawn player
    call_deferred("spawn_player")

func spawn_player() -> void:
    # Load player scene
    var player_scene = preload("res://Entities/Player/player.tscn")
    player = player_scene.instantiate()
    
    # Add to entities
    entities.add_child(player)
    
    # Position at spawn point
    player.global_position = player_spawn.global_position
    
    print("Player spawned at: ", player.global_position)

func get_navigation_region() -> NavigationRegion2D:
    return navigation_region
```

---

### 5. Main Scene Setup

#### 5.1 Create Main Scene

**File**: `Stages/main.tscn`

Simple scene that loads overworld:

**Node Structure**:
```
Main (Node)
└─ Overworld (instance of overworld.tscn)
```

**Instructions**:
1. Create new scene (Other Node → Node)
2. Name it "Main"
3. Right-click → Instantiate Child Scene → select `overworld.tscn`
4. Save as `Stages/main.tscn`

---

#### 5.2 Set as Main Scene

Go to: **Project → Project Settings → Application → Run**
- Set **Main Scene** to: `res://Stages/main.tscn`

---

### 6. Testing & Validation

#### 6.1 Create Placeholder Assets

**Player Sprite** (`Entities/Player/Sprites/`):
- Create or use a simple colored rectangle (32x32 pixels)
- Name it `player_placeholder.png`
- Assign to Player's Sprite2D

**Overworld Tileset** (`Stages/Overworld/Tilesets/`):
- Create simple tileset with grass, dirt, water tiles
- Or use your purchased tileset
- Create TileSet resource
- Assign to Ground TileMapLayer

---

#### 6.2 Manual Configuration Tasks

**⚠️ YOU MUST DO THESE MANUALLY**:

1. **Paint TileMap**:
   - Select Ground layer in Overworld
   - Use TileMap editor to paint terrain
   - Create a small test area (32x32 tiles minimum)

2. **Set up Navigation**:
   - Select NavigationRegion2D
   - Create NavigationPolygon
   - Draw polygon over walkable areas
   - Click "Bake NavigationPolygon"

3. **Configure Collisions**:
   - Add collision shapes to tileset for Walls/obstacles
   - Or add StaticBody2D nodes as obstacles
   - Ensure collision layers match (Layer 1: World)

4. **Position Spawn Point**:
   - Move PlayerSpawnPoint Marker2D to desired location
   - Should be in open area, not blocked

---

#### 6.3 Test Checklist

Run the project (F5) and verify:

- [ ] Project launches without errors
- [ ] Player appears at spawn point
- [ ] Camera follows player smoothly
- [ ] Clicking on walkable area makes player move there
- [ ] Player navigates around obstacles (if collisions set up)
- [ ] Player stops at click destination
- [ ] Multiple clicks update the destination
- [ ] Console shows "Overworld loaded" and "Player spawned at: ..."
- [ ] No errors in console

---

### 7. Debug Features (Optional but Recommended)

#### 7.1 Debug Label

Add to Player scene:

**Node**: Label (as child of Player)
**Name**: DebugLabel
**Settings**:
- Position: Above player sprite
- Text: "Player"

**Script addition** to `player.gd`:
```gdscript
@onready var debug_label: Label = $DebugLabel

func _process(_delta):
    if debug_label and OS.is_debug_build():
        debug_label.text = "Pos: (%.0f, %.0f)\nHealth: %.0f" % [
            global_position.x,
            global_position.y,
            current_health
        ]
```

---

## File Checklist

### Scripts to Create
- [ ] `Utilities/event_bus.gd`
- [ ] `Utilities/game_manager.gd`
- [ ] `Entities/organism.gd`
- [ ] `Entities/Player/player.gd`
- [ ] `Entities/Player/player_movement.gd`
- [ ] `Stages/Overworld/overworld.gd`

### Scenes to Create
- [ ] `Entities/Player/player.tscn`
- [ ] `Stages/Overworld/overworld.tscn`
- [ ] `Stages/main.tscn`

### Folders to Create
```
res://
├── Assets/
│   └── Audio/
├── Common/
├── Config/
├── Entities/
│   ├── Player/
│   │   └── Sprites/
│   ├── Camera/
│   └── Ui/
├── Localization/
├── Stages/
│   └── Overworld/
│       ├── Chunks/
│       └── Tilesets/
└── Utilities/
```

---

## Success Criteria

✅ Milestone 1 is complete when:

1. Project structure follows functionality-first organization
2. Player spawns in overworld at designated spawn point
3. Click-to-move works smoothly with navigation
4. Player navigates around obstacles
5. Camera follows player smoothly
6. No console errors during gameplay
7. Code follows naming conventions
8. Static typing used throughout
9. EventBus and GameManager properly autoloaded
10. Organism base class works correctly

---

## Next Steps

After Milestone 1, future milestones will include:

- **Milestone 2**: Player animations, HUD (health bar), basic interactions
- **Milestone 3**: Entity system (enemies, NPCs, items)
- **Milestone 4**: Overworld combat system (pop-up window)
- **Milestone 5**: Chunking system for large world
- **Milestone 6**: Locations and location-based combat
- And more...

---

## Common Issues & Solutions

### Issue: Player doesn't move
**Solution**: 
- Check NavigationRegion2D is baked
- Verify NavigationAgent2D is created in player
- Check collision layers

### Issue: Player moves through obstacles
**Solution**:
- Add collision shapes to TileSet
- Set correct collision layers (World on Layer 1)
- Ensure player mask includes Layer 1

### Issue: Camera doesn't follow
**Solution**:
- Check Camera2D is enabled
- Verify camera is child of Player
- Check zoom level isn't 0

### Issue: Click doesn't register
**Solution**:
- Verify input event in _input()
- Check is_clicking_ui() isn't blocking
- Debug print mouse position

---

## Notes

- Keep code simple and clean for this milestone
- Use placeholder graphics - polish later
- Focus on getting core systems working
- Navigation is critical - take time to set it up properly
- Test frequently as you implement each part

**Estimated Time**: 2-4 hours (excluding manual tilemap painting)

Good luck! 🎮
