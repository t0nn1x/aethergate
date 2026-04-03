# XP HUD Indicator Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a minimal XP progress indicator above SystemHud action buttons showing current level and smart-scaled XP progress.

**Architecture:** New XpIndicator component integrates into existing SystemHud VBox layout, connects to PlayerProgressionService for real-time updates, uses responsive scaling system.

**Tech Stack:** GDScript 4.6, Godot 4.6, existing AdaptiveOverlayPanel patterns, PlayerProgressionService integration

**Godot executable:** `C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe`

---

## File Structure Analysis

**New files:**
- `src/ui/common/xp_indicator/xp_indicator.gd` — XP indicator component logic
- `src/ui/common/xp_indicator/xp_indicator.tscn` — XP indicator scene layout

**Modified files:**
- `src/ui/desktop/hud/system_hud/system_hud.tscn` — Add XpIndicator to desktop HUD
- `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn` — Add XpIndicator to mobile HUD

**Key dependencies:**
- PlayerProgressionService (existing autoload)
- SystemHud responsive layout system (existing)
- Control/VBox layout patterns (Godot built-in)

---

## Chunk 1: Core XP Indicator Component

### Task 1: Create XpIndicator component structure

**Files:**
- Create: `src/ui/common/xp_indicator/xp_indicator.gd`
- Create: `src/ui/common/xp_indicator/xp_indicator.tscn`

- [ ] **Step 1: Create XP indicator script**

Create `src/ui/common/xp_indicator/xp_indicator.gd`:

```gdscript
class_name XpIndicator
extends Control

## Displays current level and XP progress with smart number scaling.
## Integrates with PlayerProgressionService for real-time updates.

# Smart scaling thresholds
const K_THRESHOLD: int = 1000
const BIG_K_THRESHOLD: int = 10000

@onready var _level_label: Label = $VBoxContainer/LevelLabel
@onready var _xp_container: Control = $VBoxContainer/XpContainer
@onready var _progress_bar: ProgressBar = $VBoxContainer/XpContainer/ProgressBar
@onready var _xp_label: Label = $VBoxContainer/XpContainer/XpLabel

var _current_level: int = 1
var _current_xp: int = 0
var _xp_needed: int = 1000


func _ready() -> void:
	_connect_progression_signals()
	_update_display()


func _connect_progression_signals() -> void:
	if not PlayerProgressionService.xp_gained.is_connected(_on_xp_gained):
		PlayerProgressionService.xp_gained.connect(_on_xp_gained)
	if not PlayerProgressionService.level_up.is_connected(_on_level_up):
		PlayerProgressionService.level_up.connect(_on_level_up)


func _on_xp_gained(amount: int, new_xp: int, xp_needed: int) -> void:
	_current_xp = new_xp
	_xp_needed = xp_needed
	_update_display()


func _on_level_up(new_level: int, _stats: CombatStats, _bonus_pts: int) -> void:
	_current_level = new_level
	_update_display()


func _update_display() -> void:
	# Update level text
	_level_label.text = "Level %d" % _current_level

	# Update progress bar
	var progress: float = _calculate_progress()
	_progress_bar.value = progress * 100.0

	# Update XP text with smart scaling
	_xp_label.text = _format_xp_text(_current_xp, _xp_needed)


func _calculate_progress() -> float:
	if _xp_needed <= 0:
		return 1.0
	return clampf(float(_current_xp) / float(_xp_needed), 0.0, 1.0)


func _format_xp_text(current: int, needed: int) -> String:
	var current_text: String = _format_number(current)
	var needed_text: String = _format_number(needed)
	return "%s / %s XP" % [current_text, needed_text]


func _format_number(value: int) -> String:
	if value < K_THRESHOLD:
		return str(value)
	elif value < BIG_K_THRESHOLD:
		var k_value: float = float(value) / 1000.0
		return "%.1fk" % k_value
	else:
		var k_value: int = int(round(float(value) / 1000.0))
		return "%dk" % k_value
```

- [ ] **Step 2: Create XP indicator scene**

Create `src/ui/common/xp_indicator/xp_indicator.tscn`:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://src/ui/common/xp_indicator/xp_indicator.gd" id="1_script"]

[node name="XpIndicator" type="Control"]
layout_mode = 3
anchors_preset = 10
anchor_right = 1.0
size_flags_horizontal = 3
size_flags_vertical = 0
script = ExtResource("1_script")

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 2

[node name="LevelLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
size_flags_horizontal = 4
text = "Level 1"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 14

[node name="XpContainer" type="Control" parent="VBoxContainer"]
custom_minimum_size = Vector2(200, 16)
layout_mode = 2
size_flags_horizontal = 4

[node name="ProgressBar" type="ProgressBar" parent="VBoxContainer/XpContainer"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
max_value = 100.0
value = 50.0
show_percentage = false

[node name="XpLabel" type="Label" parent="VBoxContainer/XpContainer"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -50.0
offset_top = -8.0
offset_right = 50.0
offset_bottom = 8.0
grow_horizontal = 2
grow_vertical = 2
text = "0 / 1000 XP"
horizontal_alignment = 1
vertical_alignment = 1
theme_override_font_sizes/font_size = 10
```

- [ ] **Step 3: Test basic scene loading**

Load the scene in Godot editor to verify it parses correctly:
1. Open Godot editor
2. Navigate to `res://src/ui/common/xp_indicator/xp_indicator.tscn`
3. Verify the scene loads without errors
4. Check the visual layout in the editor

Expected: Scene loads successfully with level label and progress bar visible

- [ ] **Step 4: Commit core component**

```bash
git add src/ui/common/xp_indicator/
git status --short
git commit -m "feat: create XpIndicator component with smart number scaling"
```

---

### Task 2: Add initialization and edge case handling

**Files:**
- Modify: `src/ui/common/xp_indicator/xp_indicator.gd`

- [ ] **Step 1: Add initialization from PlayerProfileService**

Add initialization method to `xp_indicator.gd` after `_ready()`:

```gdscript
func _initialize_from_profile() -> void:
	_current_level = PlayerProfileService.get_player_level()
	_current_xp = PlayerProfileService.get_player_xp()
	_xp_needed = PlayerProgressionService.xp_needed_for_level(_current_level)
```

- [ ] **Step 2: Update _ready() to call initialization**

Replace the `_update_display()` call in `_ready()` with:

```gdscript
func _ready() -> void:
	_connect_progression_signals()
	_initialize_from_profile()
	_update_display()
```

- [ ] **Step 3: Add max level handling**

Add max level check to `_calculate_progress()`:

```gdscript
func _calculate_progress() -> float:
	# Handle max level case
	if _current_level >= PlayerProgressionService._config.max_level:
		return 1.0
	if _xp_needed <= 0:
		return 1.0
	return clampf(float(_current_xp) / float(_xp_needed), 0.0, 1.0)
```

- [ ] **Step 4: Add max level text formatting**

Update `_format_xp_text()` to handle max level:

```gdscript
func _format_xp_text(current: int, needed: int) -> String:
	# Handle max level display
	if _current_level >= PlayerProgressionService._config.max_level:
		return "MAX LEVEL"

	var current_text: String = _format_number(current)
	var needed_text: String = _format_number(needed)
	return "%s / %s XP" % [current_text, needed_text]
```

- [ ] **Step 5: Test edge cases in editor**

1. Open the XpIndicator scene in Godot
2. Temporarily modify the script to test with mock data:
   - Set `_current_level = 100` in `_ready()`
   - Set `_current_xp = 15000` and `_xp_needed = 0`
3. Run the scene and verify "MAX LEVEL" displays correctly
4. Test large number formatting with values like 25000, 1500

Expected: MAX LEVEL displays at level 100, large numbers show as "25k", "1.5k" format

- [ ] **Step 6: Revert test changes and commit**

```bash
git add src/ui/common/xp_indicator/xp_indicator.gd
git commit -m "feat: add XpIndicator initialization and max level handling"
```

---

## Chunk 2: SystemHud Integration

### Task 3: Integrate XpIndicator into desktop SystemHud

**Files:**
- Modify: `src/ui/desktop/hud/system_hud/system_hud.tscn`

- [ ] **Step 1: Add XpIndicator to desktop SystemHud scene**

Open `src/ui/desktop/hud/system_hud/system_hud.tscn` and add XpIndicator:

1. Navigate to Root/SafeAreaMargin/BottomAlign in the scene tree
2. Right-click BottomAlign and select "Change Script"
3. Verify it's a VBoxContainer with children: Spacer, SlotRow
4. Right-click BottomAlign and select "Instance Child Scene"
5. Choose `res://src/ui/common/xp_indicator/xp_indicator.tscn`
6. Move the XpIndicator node between Spacer and SlotRow in the tree
7. Set XpIndicator's size_flags_vertical to 0 (SIZE_FILL is not needed)

The VBoxContainer structure should now be:
```
BottomAlign (VBoxContainer)
├── Spacer (Control)
├── XpIndicator (instanced scene)
└── SlotRow (HBoxContainer)
```

- [ ] **Step 2: Configure XpIndicator properties**

Select the XpIndicator node and configure:
- `custom_minimum_size.y = 40` (ensure minimum height)
- `size_flags_horizontal = 4` (SIZE_SHRINK_CENTER)
- `size_flags_vertical = 0` (SIZE_FILL off)

- [ ] **Step 3: Test desktop HUD layout**

1. Open the desktop SystemHud scene
2. Adjust the viewport size to test responsive behavior
3. Verify XpIndicator appears above the button row
4. Check that buttons are not pushed off screen

Expected: XpIndicator displays centered above buttons, layout remains responsive

- [ ] **Step 4: Save and test in overworld context**

1. Save the scene
2. Open the main game scene
3. Enter the overworld to see the desktop HUD
4. Verify the XpIndicator shows current level and XP

Expected: Level and XP display correctly with real PlayerProgressionService data

- [ ] **Step 5: Commit desktop integration**

```bash
git add src/ui/desktop/hud/system_hud/system_hud.tscn
git status --short
git commit -m "feat: integrate XpIndicator into desktop SystemHud"
```

---

### Task 4: Integrate XpIndicator into mobile SystemHud

**Files:**
- Modify: `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn`

- [ ] **Step 1: Add XpIndicator to mobile SystemHud scene**

Open `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn` and add XpIndicator:

1. Navigate to Root/SafeAreaMargin/BottomAlign in the scene tree
2. Right-click BottomAlign and select "Instance Child Scene"
3. Choose `res://src/ui/common/xp_indicator/xp_indicator.tscn`
4. Move the XpIndicator node between Spacer and SlotRow
5. Configure same properties as desktop version

- [ ] **Step 2: Test mobile scaling behavior**

1. In SystemHud script, find the `mobile_scale_multiplier` property (line 26)
2. Verify it's set to 1.3 for mobile
3. Test the scene at different viewport sizes (mobile portrait/landscape)
4. Ensure XpIndicator text scales appropriately

Expected: Text scales with mobile multiplier, remains readable on small screens

- [ ] **Step 3: Check button interference**

1. Verify XpIndicator doesn't push buttons off-screen on small viewports
2. Test with minimum mobile screen size (360x640)
3. Adjust XpIndicator minimum height if needed

Expected: All 5 action buttons remain accessible with XpIndicator visible

- [ ] **Step 4: Test mobile platform switching**

1. In project settings, test with different mobile device profiles
2. Verify XpIndicator responds to safe area margins
3. Check landscape and portrait orientations

Expected: XpIndicator respects mobile safe areas, proper margins maintained

- [ ] **Step 5: Commit mobile integration**

```bash
git add src/ui/mobile/hud/system_hud/system_hud_mobile.tscn
git commit -m "feat: integrate XpIndicator into mobile SystemHud"
```

---

## Chunk 3: Polish and Testing

### Task 5: Style progress bar to match UI aesthetic

**Files:**
- Modify: `src/ui/common/xp_indicator/xp_indicator.tscn`

- [ ] **Step 1: Research existing UI color scheme**

1. Check SystemHud button colors in scene
2. Look at combat result panel colors (level-up notification uses light blue)
3. Examine `src/ui/assets/` for consistent color palette
4. Note: Level-up label uses `Color(0.4, 0.9, 1.0, 1.0)` light blue

- [ ] **Step 2: Style progress bar background**

Configure ProgressBar node in XpIndicator scene:
- Add theme override for background color: `Color(0.2, 0.2, 0.2, 0.8)`
- Add theme override for fill color: `Color(0.4, 0.9, 1.0, 1.0)` (matches level-up)
- Ensure bar has subtle visual definition

- [ ] **Step 3: Improve XP label readability**

Update XpLabel styling:
- Add theme override for font color: `Color(1.0, 1.0, 1.0, 0.9)` (light text)
- Optionally add subtle shadow for readability over progress bar

- [ ] **Step 4: Test visual harmony**

1. Load the scene in context of the full SystemHud
2. Compare colors with existing UI elements
3. Verify text remains readable at various progress percentages
4. Test with both light and dark backgrounds

Expected: Progress bar integrates visually with existing UI, text always readable

- [ ] **Step 5: Commit styling improvements**

```bash
git add src/ui/common/xp_indicator/xp_indicator.tscn
git commit -m "style: improve XpIndicator visual integration with UI theme"
```

---

### Task 6: Comprehensive testing and edge case verification

**Files:**
- Test: Manual verification across scenarios

- [ ] **Step 1: Test XP gain scenarios**

1. Start a fresh game (Level 1, 0 XP)
2. Enter combat and defeat an enemy
3. Verify XP indicator updates immediately
4. Check progress bar fills correctly
5. Test multiple combats to verify cumulative updates

Expected: Real-time updates, accurate progress bar progression

- [ ] **Step 2: Test level-up scenarios**

1. Use debug panel to award large XP amounts
2. Test single level-up: verify level text updates
3. Test multi-level-up: verify indicator handles rapid changes
4. Check level 100 edge case shows "MAX LEVEL"

Expected: Level text updates correctly, max level handled gracefully

- [ ] **Step 3: Test number formatting edge cases**

Test with debug panel XP amounts:
- 999 XP (should show "999")
- 1000 XP (should show "1.0k")
- 1500 XP (should show "1.5k")
- 15000 XP (should show "15k")

Expected: Smart scaling works correctly at all thresholds

- [ ] **Step 4: Test responsive behavior**

1. Test desktop: resize window, verify indicator scales properly
2. Test mobile: switch orientations, check safe area margins
3. Verify indicator doesn't interfere with button interactions
4. Test extreme aspect ratios (very wide, very narrow)

Expected: Responsive behavior maintained, no button interference

- [ ] **Step 5: Test signal disconnection/reconnection**

1. Test entering/exiting combat scenes
2. Verify XP indicator continues working after scene transitions
3. Check for any signal connection leaks or errors

Expected: Indicator remains functional across scene transitions

- [ ] **Step 6: Document any issues found**

If any issues discovered during testing:
1. Note specific reproduction steps
2. Assess severity (blocking vs. polish)
3. Log issues for future improvement tasks

- [ ] **Step 7: Final verification commit**

```bash
# No files to commit, but verify clean working tree
git status --short
# Should show only untracked docs files, which is expected
```

---

### Task 7: Final integration verification

**Files:**
- Test: End-to-end integration testing

- [ ] **Step 1: Test complete XP progression flow**

1. Start new game
2. Check initial display: "Level 1" with appropriate XP display
3. Complete several combats to gain XP
4. Verify smooth progress bar animation
5. Achieve a level-up and verify immediate indicator update

Expected: Complete flow works smoothly from level 1 through level-ups

- [ ] **Step 2: Test platform switching**

If possible, test game on both desktop and mobile:
1. Verify indicators look consistent between platforms
2. Check mobile scaling and touch accessibility
3. Ensure proper integration with existing HUD functionality

Expected: Consistent experience across platforms

- [ ] **Step 3: Verify no performance impact**

1. Monitor frame rate with XP indicator active
2. Test rapid XP gains (multiple level-ups)
3. Ensure no lag or visual stuttering

Expected: No noticeable performance impact

- [ ] **Step 4: Test with existing player save**

If testing with existing save:
1. Verify indicator correctly shows current level/XP
2. Test that progression continues normally
3. Check compatibility with existing progression data

Expected: Seamless integration with existing saves

- [ ] **Step 5: Verify all commit messages follow conventions**

Review commit history:
```bash
git log --oneline -8
```

Ensure all messages follow "feat:", "style:", "fix:" prefixes as appropriate

- [ ] **Step 6: Final status confirmation**

```bash
git status --short
```

Expected: Clean working tree except for untracked docs files (which is normal)

The XP HUD indicator implementation should now be complete and fully integrated!