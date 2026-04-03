# XP HUD Indicator — Design Spec
_Date: 2026-04-03_

## Overview

Add a minimal XP progress indicator above the SystemHud action buttons that shows current level and XP progress with smart number scaling. Integrates cleanly into the existing responsive HUD layout system.

---

## Goals

- Clean, minimal visual integration above existing HUD buttons
- Real-time XP progress display with level information
- Smart number scaling to prevent UI clutter at high levels
- Responsive layout that works on both desktop and mobile
- Leverages existing SystemHud responsive margin system

## Design Approach

**Single Component Strategy:**
- New `XpIndicator` component extending `Control`
- Drops into both desktop and mobile SystemHud scenes
- Uses existing AdaptiveOverlayPanel responsive behavior patterns
- Direct integration with PlayerProgressionService

---

## Visual Design

### Layout Structure

```
BottomAlign (VBoxContainer) — existing
├── Spacer (Control) — existing, grows to fill space
├── XpIndicator (new) — minimal height, centered
│   ├── LevelLabel — "Level 5"
│   └── XpProgressBar — visual progress with smart-scaled XP text
└── SlotRow (HBoxContainer) — existing buttons
```

### Styling Specifications

**Level Label:**
- Text: "Level {N}"
- Font size: 14px base (scales with mobile multiplier)
- Color: UI primary text color
- Alignment: Center
- Margin: 2px bottom

**Progress Bar:**
- Width: Matches button row effective width
- Height: 6px bar + text
- Background: Semi-transparent dark
- Fill: UI accent color (matches level-up notifications)
- Border: Optional subtle border for definition

**XP Text Display:**
- Position: Overlay on progress bar or below
- Format: "{current} / {needed} XP"
- Font size: 10px base (scales with mobile multiplier)
- Smart scaling rules:
  - 0-999: Exact numbers ("847 / 941 XP")
  - 1000-9999: K notation ("2.1k / 1.8k XP")
  - 10000+: Abbreviated ("15k / 12k XP")

### Responsive Behavior

- Inherits SystemHud margin calculations
- Progress bar width scales with available screen space
- Text size responds to mobile_scale_multiplier
- Minimum height maintained for touch accessibility
- Proper spacing to avoid button interference

---

## Technical Architecture

### Component Structure

**XpIndicator.gd:**
```gdscript
class_name XpIndicator
extends Control

@onready var level_label: Label
@onready var progress_bar: ProgressBar
@onready var xp_label: Label

# Smart scaling thresholds
const K_THRESHOLD = 1000
const BIG_K_THRESHOLD = 10000
```

### Data Integration

**PlayerProgressionService Integration:**
- Connect to `xp_gained(amount, new_xp, xp_needed)` signal
- Connect to `level_up(new_level, new_stats, bonus_points)` signal
- Use `xp_progress()` for progress bar percentage
- Call `get_player_level()` for level display

**Update Logic:**
1. On signals: refresh level text and progress bar
2. Format XP text using smart scaling
3. Update progress bar fill percentage
4. Handle edge case: level 100 (max level)

### SystemHud Integration

**Scene Modification:**
- Add XpIndicator node to BottomAlign VBoxContainer
- Position between Spacer and SlotRow
- Configure proper size flags and margins
- Apply responsive styling

**Both Platforms:**
- Desktop: `src/ui/desktop/hud/system_hud/system_hud.tscn`
- Mobile: `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn`
- Shared component handles platform detection internally

---

## Implementation Tasks

### Core Component
1. Create `XpIndicator.gd` and `.tscn` in `src/ui/common/xp_indicator/`
2. Implement smart number scaling logic
3. Wire PlayerProgressionService signal connections
4. Add responsive layout sizing

### SystemHud Integration
5. Modify desktop SystemHud scene to include XpIndicator
6. Modify mobile SystemHud scene to include XpIndicator
7. Test responsive behavior on both platforms
8. Verify XP updates work during combat

### Polish & Testing
9. Style progress bar to match UI aesthetic
10. Test edge cases (level 1, level 100, large XP amounts)
11. Verify proper spacing and no button interference
12. Test on mobile screen sizes

---

## Future Considerations

- **Customization:** Player preference for showing/hiding XP numbers
- **Animation:** Smooth progress bar transitions on XP gain
- **Styling:** Additional visual polish with UI asset integration
- **Bonus Points:** Optional display of unspent bonus points

This design provides a solid foundation that can be enhanced incrementally while maintaining the clean, minimal aesthetic.