shader_type canvas_item;

/// Silhouette shader for showing entity outlines behind occluding objects.
/// Apply to a duplicate sprite with a high z_index so it renders on top
/// of Y-sorted obstacles (trees, rocks, etc.).
///
/// Samples a 3x3 neighborhood of the screen texture to find the best color
/// match with the sprite's own texture. This eliminates false positives
/// caused by sub-pixel misalignment at non-integer parent scales.

uniform vec4 silhouette_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
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

	// Only show the silhouette when the color difference is significant
	// (i.e. the player is actually behind an occluding object like a tree).
	float occlusion = smoothstep(occlusion_threshold * 0.5, occlusion_threshold, min_diff);

	COLOR = vec4(silhouette_color.rgb, tex.a * silhouette_color.a * occlusion);
}
