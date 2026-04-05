# XP Indicator Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the broken XP indicator (signals never connect due to wrong singleton API) and replace the stacked vertical widget with a ghost/minimal horizontal one (level · thin bar · compact XP fraction).

**Architecture:** `xp_indicator.gd` is rewritten in-place — no new files. The scene `xp_indicator.tscn` is rebuilt from a VBoxContainer to an HBoxContainer. The `run_xp_indicator_validation_test.gd` test expectations are updated to match the extended number formatter. `system_hud.tscn` gets a one-line margin bump.

**Tech Stack:** Godot 4.6, GDScript (static typing), headless Godot test runner via `--script`.

---

## File Map

| File | Action | What changes |
|---|---|---|
| `src/ui/common/xp_indicator/xp_indicator.gd` | Modify | Remove `Engine.has_singleton()` guards; rewrite `_format_number` with kk/kkk; update `@onready` paths for new scene layout |
| `src/ui/common/xp_indicator/xp_indicator.tscn` | Modify | Rebuild as HBoxContainer with ghost style (dark pill, 5 px bar, no percentage label) |
| `src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd` | Modify | Update `_format_number` expectations to include kk/kkk cases; update max-level text expectation to `"MAX"` |
| `src/ui/desktop/hud/system_hud/system_hud.tscn` | Modify | Bump `XpIndicator` `margin_bottom` from `12` to `20` |

---

### Task 1: Update the number-formatter tests to cover kk/kkk, then extend the formatter

**Files:**
- Modify: `src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd`
- Modify: `src/ui/common/xp_indicator/xp_indicator.gd`

- [ ] **Step 1.1 — Update `test_number_formatting` to include kk/kkk cases and fix the boundary expectation**

Replace the `test_cases` array inside `test_number_formatting()` in `run_xp_indicator_validation_test.gd` with:

```gdscript
var test_cases := [
    [0,           "0"],
    [1,           "1"],
    [999,         "999"],
    [1000,        "1k"],
    [1100,        "1.1k"],
    [2500,        "2.5k"],
    [9999,        "10k"],
    [10000,       "10k"],
    [15000,       "15k"],
    [100000,      "100k"],
    [999999,      "999k"],
    [1000000,     "1kk"],
    [1200000,     "1.2kk"],
    [9999999,     "10kk"],
    [10000000,    "10kk"],
    [500000000,   "500kk"],
    [999999999,   "999kk"],
    [1000000000,  "1kkk"],
    [1500000000,  "1.5kkk"],
]
```

- [ ] **Step 1.2 — Run the test to confirm it fails on the new cases**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/antonkhrobust/User/aethergate --script res://src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd
```

Expected: test fails on `1000000` and above (formatter doesn't know kk/kkk yet).

- [ ] **Step 1.3 — Rewrite `_format_number` in `xp_indicator.gd`**

Replace the constants block and `_format_number` function:

```gdscript
const K:   int = 1_000
const KK:  int = 1_000_000
const KKK: int = 1_000_000_000
const BIG_K:   int = 10_000
const BIG_KK:  int = 10_000_000
const BIG_KKK: int = 10_000_000_000

func _format_number(n: int) -> String:
    if n >= BIG_KKK:
        return "%dkkk" % int(round(float(n) / float(KKK)))
    elif n >= KKK:
        return _decimal_suffix(n, KKK, "kkk")
    elif n >= BIG_KK:
        return "%dkk" % int(round(float(n) / float(KK)))
    elif n >= KK:
        return _decimal_suffix(n, KK, "kk")
    elif n >= BIG_K:
        return "%dk" % int(round(float(n) / float(K)))
    elif n >= K:
        return _decimal_suffix(n, K, "k")
    else:
        return str(n)

func _decimal_suffix(n: int, unit: int, suffix: String) -> String:
    # Show one decimal when it's non-zero; strip trailing .0
    var val: float = round(float(n) / float(unit) * 10.0) / 10.0
    if is_equal_approx(val, float(int(val))):
        return "%d%s" % [int(val), suffix]
    return "%.1f%s" % [val, suffix]
```

Also remove the old `K_THRESHOLD` and `BIG_K_THRESHOLD` constants (they are replaced above).

- [ ] **Step 1.4 — Run the test again and confirm it passes**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/antonkhrobust/User/aethergate --script res://src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd
```

Expected output ends with `✓ ALL TESTS PASSED`.

- [ ] **Step 1.5 — Commit**

```bash
git add src/ui/common/xp_indicator/xp_indicator.gd \
        src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd
git commit -m "feat(xp): extend number formatter with kk/kkk suffix support"
```

---

### Task 2: Fix the signal-wiring bug

**Files:**
- Modify: `src/ui/common/xp_indicator/xp_indicator.gd`

The bug: every `Engine.has_singleton("PlayerProgressionService")` and `Engine.has_singleton("PlayerProfileService")` call returns `false` for GDScript autoloads, so signals are never connected and the display never initialises.

- [ ] **Step 2.1 — Remove all `Engine.has_singleton()` guards**

Replace the entire body of `xp_indicator.gd` (keeping the new `_format_number` / `_decimal_suffix` from Task 1) with the version below. The key changes are:
- `_ready()`: always call `_connect_progression_signals()` and `_initialize_from_profile()`
- `_initialize_from_profile()`: access autoloads directly
- `_update_display()`: access autoloads directly
- `_calculate_progress()`: access autoloads directly
- `_format_xp_text()`: `"MAX"` instead of `"MAX LEVEL"` to match design

```gdscript
# xp_indicator.gd
extends Control
class_name XpIndicator

signal clicked()

@onready var _level_label: Label = $HBoxContainer/LevelLabel
@onready var _bar: ProgressBar = $HBoxContainer/Bar
@onready var _xp_label: Label = $HBoxContainer/XpLabel

# --- number formatter constants (from Task 1) ---
const K:   int = 1_000
const KK:  int = 1_000_000
const KKK: int = 1_000_000_000
const BIG_K:   int = 10_000
const BIG_KK:  int = 10_000_000
const BIG_KKK: int = 10_000_000_000


func _ready() -> void:
    _connect_progression_signals()
    _initialize_from_profile()


func _connect_progression_signals() -> void:
    if not PlayerProgressionService.xp_gained.is_connected(_on_xp_gained):
        PlayerProgressionService.xp_gained.connect(_on_xp_gained)
    if not PlayerProgressionService.level_up.is_connected(_on_level_up):
        PlayerProgressionService.level_up.connect(_on_level_up)


func _initialize_from_profile() -> void:
    var level: int = int(PlayerProfileService.get_player_level())
    var xp: int    = int(PlayerProfileService.get_player_xp())
    var max_level: int = int(PlayerProgressionService._config.max_level) \
        if PlayerProgressionService._config != null else 100

    if level >= max_level:
        _update_level(level)
        _bar.value = 100.0
        _xp_label.text = "MAX"
        return

    var needed: int = PlayerProgressionService.xp_needed_for_level(level)
    _update_level(level)
    _update_progress(xp, needed)


func _on_xp_gained(amount: int, new_xp: int, xp_needed: int) -> void:
    _update_progress(new_xp, xp_needed)


func _on_level_up(new_level: int, _new_stats: Variant, _bonus: int) -> void:
    _update_level(new_level)
    _update_progress(0, PlayerProgressionService.xp_needed_for_level(new_level))


func _update_level(level: int) -> void:
    _level_label.text = "Lv %d" % level


func _update_progress(current_xp: int, xp_needed: int) -> void:
    var level: int = int(PlayerProfileService.get_player_level())
    var fraction: float = _calculate_progress(current_xp, level)
    _bar.value = clampf(fraction * 100.0, 0.0, 100.0)
    _xp_label.text = _format_xp_text(current_xp, xp_needed, level)


func _calculate_progress(current_xp: int, level: int) -> float:
    var max_level: int = int(PlayerProgressionService._config.max_level) \
        if PlayerProgressionService._config != null else 100
    if level >= max_level:
        return 1.0
    var denom: int = maxi(1, PlayerProgressionService.xp_needed_for_level(level))
    return clampf(float(current_xp) / float(denom), 0.0, 1.0)


func _format_xp_text(current_xp: int, xp_needed: int, level: int) -> String:
    var max_level: int = int(PlayerProgressionService._config.max_level) \
        if PlayerProgressionService._config != null else 100
    if level >= max_level:
        return "MAX"
    return "%s / %s" % [_format_number(current_xp), _format_number(maxi(1, xp_needed))]


# --- number formatter (from Task 1) ---
func _format_number(n: int) -> String:
    if n >= BIG_KKK:
        return "%dkkk" % int(round(float(n) / float(KKK)))
    elif n >= KKK:
        return _decimal_suffix(n, KKK, "kkk")
    elif n >= BIG_KK:
        return "%dkk" % int(round(float(n) / float(KK)))
    elif n >= KK:
        return _decimal_suffix(n, KK, "kk")
    elif n >= BIG_K:
        return "%dk" % int(round(float(n) / float(K)))
    elif n >= K:
        return _decimal_suffix(n, K, "k")
    else:
        return str(n)


func _decimal_suffix(n: int, unit: int, suffix: String) -> String:
    var val: float = round(float(n) / float(unit) * 10.0) / 10.0
    if is_equal_approx(val, float(int(val))):
        return "%d%s" % [int(val), suffix]
    return "%.1f%s" % [val, suffix]


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed \
            and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
        clicked.emit()
```

- [ ] **Step 2.2 — Update max-level text expectation in the test**

In `run_xp_indicator_validation_test.gd`, `test_max_level_behavior()`, change:

```gdscript
# old
if max_level_text != "MAX LEVEL":
    print("✗ FAILED: Max level text expected 'MAX LEVEL', got '%s'" % max_level_text)
```

to:

```gdscript
# new
if max_level_text != "MAX":
    print("✗ FAILED: Max level text expected 'MAX', got '%s'" % max_level_text)
```

Also update the matching `print` line from `"MAX LEVEL"` to `"MAX"`.

Do the same in `run_xp_indicator_comprehensive_test.gd`, `comprehensive_edge_case_testing()`:

```gdscript
# old
if max_level_text == "MAX LEVEL":
    print("  ✅ Max level handling correct")
else:
    print("  ❌ Max level handling incorrect: got '%s'" % max_level_text)
```

```gdscript
# new
if max_level_text == "MAX":
    print("  ✅ Max level handling correct")
else:
    print("  ❌ Max level handling incorrect: got '%s'" % max_level_text)
```

- [ ] **Step 2.3 — Run validation test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/antonkhrobust/User/aethergate --script res://src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd
```

Expected: `✓ ALL TESTS PASSED`

- [ ] **Step 2.4 — Commit**

```bash
git add src/ui/common/xp_indicator/xp_indicator.gd \
        src/ui/common/xp_indicator/tests/run_xp_indicator_validation_test.gd \
        src/ui/common/xp_indicator/tests/run_xp_indicator_comprehensive_test.gd
git commit -m "fix(xp): remove Engine.has_singleton guards — autoloads are directly accessible"
```

---

### Task 3: Rebuild the scene as horizontal ghost/minimal widget

**Files:**
- Modify: `src/ui/common/xp_indicator/xp_indicator.tscn`

The GDScript in Task 2 now expects:
- `$HBoxContainer/LevelLabel` — Label
- `$HBoxContainer/Bar` — ProgressBar
- `$HBoxContainer/XpLabel` — Label

Replace the entire content of `xp_indicator.tscn` with:

```
[gd_scene format=3 uid="uid://xpindicator"]

[ext_resource type="Script" uid="uid://chmetqv5ss6un" path="res://src/ui/common/xp_indicator/xp_indicator.gd" id="1"]

[sub_resource type="StyleBoxFlat" id="bg"]
bg_color = Color(0.039, 0.039, 0.047, 0.82)
corner_radius_top_left = 6
corner_radius_top_right = 6
corner_radius_bottom_left = 6
corner_radius_bottom_right = 6
content_margin_left = 10.0
content_margin_right = 10.0
content_margin_top = 5.0
content_margin_bottom = 5.0

[sub_resource type="StyleBoxFlat" id="bar_bg"]
bg_color = Color(1, 1, 1, 0.1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3

[sub_resource type="StyleBoxFlat" id="bar_fill"]
bg_color = Color(1, 1, 1, 0.65)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3

[node name="XpIndicator" type="PanelContainer" unique_id=1606689384]
layout_mode = 3
anchors_preset = 0
theme_override_styles/panel = SubResource("bg")
script = ExtResource("1")

[node name="HBoxContainer" type="HBoxContainer" parent="." unique_id=100]
layout_mode = 2
theme_override_constants/separation = 10

[node name="LevelLabel" type="Label" parent="HBoxContainer" unique_id=200]
layout_mode = 2
size_flags_vertical = 4
text = "Lv 1"
theme_override_colors/font_color = Color(1, 1, 1, 0.6)
theme_override_font_sizes/font_size = 12

[node name="Bar" type="ProgressBar" parent="HBoxContainer" unique_id=300]
custom_minimum_size = Vector2(0, 5)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
show_percentage = false
theme_override_styles/background = SubResource("bar_bg")
theme_override_styles/fill = SubResource("bar_fill")

[node name="XpLabel" type="Label" parent="HBoxContainer" unique_id=400]
layout_mode = 2
size_flags_vertical = 4
text = "0 / 1k"
theme_override_colors/font_color = Color(1, 1, 1, 0.35)
theme_override_font_sizes/font_size = 10
```

- [ ] **Step 3.1 — Open Godot and verify the scene loads without errors**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/antonkhrobust/User/aethergate --script res://src/ui/common/xp_indicator/tests/run_xp_indicator_comprehensive_test.gd
```

Expected: `✅ XP indicator scene loads and instantiates correctly` + all tests pass.

- [ ] **Step 3.2 — Commit**

```bash
git add src/ui/common/xp_indicator/xp_indicator.tscn
git commit -m "feat(xp): rebuild indicator scene — horizontal ghost pill layout"
```

---

### Task 4: Add spacing between XP bar and action slots

**Files:**
- Modify: `src/ui/desktop/hud/system_hud/system_hud.tscn`

- [ ] **Step 4.1 — Change the `margin_bottom` on the `XpIndicator` node**

In `system_hud.tscn`, find the `[node name="XpIndicator" ...]` block. Change:

```
theme_override_constants/margin_bottom = 12
```

to:

```
theme_override_constants/margin_bottom = 20
```

- [ ] **Step 4.2 — Run comprehensive integration test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/antonkhrobust/User/aethergate --script res://src/ui/common/xp_indicator/tests/run_xp_indicator_comprehensive_test.gd
```

Expected: `✅ Desktop HUD integration successful` + all tests pass.

- [ ] **Step 4.3 — Commit**

```bash
git add src/ui/desktop/hud/system_hud/system_hud.tscn
git commit -m "style(xp): increase spacing between XP bar and action slot row"
```
