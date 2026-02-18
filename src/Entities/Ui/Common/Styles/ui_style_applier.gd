class_name UiStyleApplier
extends RefCounted


static func apply_panel_style(panel: Panel, profile: UiPanelStyleProfile) -> void:
	if panel == null or profile == null:
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = profile.fill_color
	style.border_color = profile.border_color
	style.border_width_left = profile.border_width
	style.border_width_top = profile.border_width
	style.border_width_right = profile.border_width
	style.border_width_bottom = profile.border_width
	style.corner_radius_top_left = profile.corner_radius
	style.corner_radius_top_right = profile.corner_radius
	style.corner_radius_bottom_right = profile.corner_radius
	style.corner_radius_bottom_left = profile.corner_radius
	panel.add_theme_stylebox_override("panel", style)


static func apply_label_style(
	label: Label,
	profile: UiTextStyleProfile,
	is_mobile: bool,
	is_portrait: bool
) -> void:
	if label == null or profile == null:
		return
	if profile.font != null:
		label.add_theme_font_override("font", profile.font)
	label.add_theme_color_override("font_color", profile.font_color)
	label.add_theme_font_size_override(
		"font_size",
		resolve_font_size(profile, is_mobile, is_portrait)
	)


static func resolve_font_size(
	profile: UiTextStyleProfile,
	is_mobile: bool,
	is_portrait: bool
) -> int:
	if profile == null:
		return 16
	var size: int = profile.mobile_font_size if is_mobile else profile.desktop_font_size
	if is_portrait:
		size += profile.portrait_font_size_delta
	return maxi(8, size)

