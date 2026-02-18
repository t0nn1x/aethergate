# UI Common Architecture

Reusable primitives for overlay/panel UI:

## `Overlay/adaptive_overlay_panel.gd`
- Base class for `CanvasLayer` overlays.
- Handles:
  - safe-area aware margins (desktop/mobile),
  - optional world-movement blocking group registration,
  - viewport resize lifecycle (`_on_overlay_viewport_resized`).

### Usage
1. `extends AdaptiveOverlayPanel`
2. Set `content_margin_path` to your root `MarginContainer`.
3. Override `_on_overlay_viewport_resized()` and call your layout method.

## `Styles/*`
- `ui_panel_style_profile.gd`: resource for panel fill/border/radius.
- `ui_text_style_profile.gd`: resource for font/color/mobile+desktop sizes.
- `ui_style_applier.gd`: static helper to apply profiles to controls.

### Usage
1. Export style profile resources on your panel script.
2. Call `UiStyleApplier.apply_panel_style(...)` for reusable panel visuals.
3. Call `UiStyleApplier.apply_label_style(...)` for consistent typography.

