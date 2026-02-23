shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 6.0, 0.1) = 2.4;
uniform float blur_mix : hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	vec3 sharp = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 blurred = textureLod(screen_texture, SCREEN_UV, blur_lod).rgb;
	vec3 mixed = mix(sharp, blurred, blur_mix);

	// Use the ColorRect's color as a lightweight tint/dimmer on top of blur.
	vec3 tinted = mix(mixed, COLOR.rgb, COLOR.a);
	COLOR = vec4(tinted, 1.0);
}
