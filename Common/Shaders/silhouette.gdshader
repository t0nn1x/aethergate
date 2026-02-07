shader_type canvas_item;

/// Silhouette shader for showing entity outlines behind occluding objects.
/// Renders as an outline with a semi-transparent shade inside instead of
/// a solid color fill. Apply to a duplicate sprite with high z_index.
///
/// Samples a 3x3 neighborhood of the screen texture to find the best color
/// match with the sprite's own texture. This eliminates false positives
/// caused by sub-pixel misalignment at non-integer parent scales.

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shade_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
uniform float outline_thickness : hint_range(1.0, 4.0) = 1.0;
uniform float occlusion_threshold : hint_range(0.05, 1.0) = 0.3;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		discard;
	}

	// Sample a 3x3 neighborhood around this pixel on the screen texture.
	// Use the minimum color difference to handle sub-pixel misalignment
	// between the main sprite and the silhouette.
	float min_diff = 999.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE;
			vec4 s = texture(screen_texture, SCREEN_UV + offset);
			float d = length(s.rgb - tex.rgb);
			min_diff = min(min_diff, d);
		}
	}

	// Only show the silhouette when the color difference is significant.
	float occlusion = smoothstep(occlusion_threshold * 0.5, occlusion_threshold, min_diff);

	// Detect edges by checking neighboring pixels in the sprite texture.
	float edge = 0.0;
	int radius = int(outline_thickness);
	for (int x = -radius; x <= radius; x++) {
		for (int y = -radius; y <= radius; y++) {
			if (x == 0 && y == 0) continue;
			vec2 offset = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
			vec4 neighbor = texture(TEXTURE, UV + offset);
			// Edge if any neighbor has low alpha (sprite boundary).
			if (neighbor.a < 0.5) {
				edge = 1.0;
				break;
			}
		}
		if (edge > 0.5) break;
	}

	// Mix outline and shade based on edge detection.
	vec4 final_color = mix(shade_color, outline_color, edge);
	COLOR = vec4(final_color.rgb, tex.a * final_color.a * occlusion);
}
