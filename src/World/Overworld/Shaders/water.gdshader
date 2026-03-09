shader_type canvas_item;

// ── Tuning knobs ──────────────────────────────────────────────
// Color detection – which pixels count as "water"
uniform float hue_center : hint_range(0.0, 1.0) = 0.52;       // teal/cyan center
uniform float hue_range  : hint_range(0.0, 0.5) = 0.14;       // how wide the hue band is
uniform float sat_min    : hint_range(0.0, 1.0) = 0.10;       // minimum saturation to count
uniform float val_min    : hint_range(0.0, 1.0) = 0.10;       // minimum brightness to count

// Wave distortion
uniform float wave_speed    : hint_range(0.0, 4.0) = 2.0;     // how fast waves scroll
uniform float wave_strength : hint_range(0.0, 8.0) = 0.8;     // distortion in pixels
uniform float wave_scale    : hint_range(0.001, 0.2) = 0.06;  // wave frequency (world-space)

// Shimmer / sparkle
uniform float shimmer_speed    : hint_range(0.0, 4.0) = 3.0;
uniform float shimmer_strength : hint_range(0.0, 0.15) = 0.01;
uniform float shimmer_scale    : hint_range(0.001, 0.2) = 0.09;

// Tint overlay (subtle color shift to make water pop)
uniform vec4 water_tint : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.20;

// World-space position passed from vertex shader
varying vec2 world_pos;


// ── Vertex ────────────────────────────────────────────────────
void vertex() {
    // VERTEX is in local/world space for canvas items on a TileMapLayer.
    // Pass it to fragment so wave math is seamless across tile boundaries.
    world_pos = VERTEX;
}


// ── Helpers ───────────────────────────────────────────────────
vec3 rgb_to_hsv(vec3 c) {
    float cmax  = max(c.r, max(c.g, c.b));
    float cmin  = min(c.r, min(c.g, c.b));
    float delta = cmax - cmin;
    float h = 0.0;
    if (delta > 0.0001) {
        if (cmax == c.r)      h = mod((c.g - c.b) / delta, 6.0);
        else if (cmax == c.g) h = (c.b - c.r) / delta + 2.0;
        else                  h = (c.r - c.g) / delta + 4.0;
        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }
    float s = (cmax > 0.0001) ? delta / cmax : 0.0;
    return vec3(h, s, cmax);
}

float water_mask(vec3 col) {
    // Returns 0.0..1.0 – how "watery" this pixel is
    vec3 hsv = rgb_to_hsv(col);
    float hue_dist = min(abs(hsv.x - hue_center), 1.0 - abs(hsv.x - hue_center));
    float hue_ok = smoothstep(hue_range, hue_range * 0.4, hue_dist);
    float sat_ok = smoothstep(sat_min * 0.3, sat_min, hsv.y);
    float val_ok = smoothstep(val_min * 0.3, val_min, hsv.z);
    return hue_ok * sat_ok * val_ok;
}


// ── Main ──────────────────────────────────────────────────────
void fragment() {
    // Sample the original pixel first (for masking)
    vec4 orig = texture(TEXTURE, UV);
    float mask = water_mask(orig.rgb);

    if (mask < 0.01) {
        // Not water – pass through untouched
        COLOR = orig;
    } else {
        // Use world-space position for seamless waves across tiles
        float t = TIME * wave_speed;
        vec2 px = TEXTURE_PIXEL_SIZE;
        vec2 wp = world_pos * wave_scale;

        // ---- Wave distortion ----
        vec2 wave_uv = UV;
        wave_uv.x += sin(wp.y * 6.2832 + t * 1.3) * wave_strength * px.x * mask;
        wave_uv.y += cos(wp.x * 6.2832 + t)        * wave_strength * px.y * mask * 0.6;

        vec4 col = texture(TEXTURE, wave_uv);

        // ---- Shimmer (brightness ripple, also world-space) ----
        vec2 sp = world_pos * shimmer_scale;
        float shimmer = sin(sp.x * 6.2832 + sp.y * 3.0 + TIME * shimmer_speed) * 0.5 + 0.5;
        shimmer *= sin(sp.x * 10.0 - sp.y * 4.0 - TIME * shimmer_speed * 0.7) * 0.5 + 0.5;
        col.rgb += shimmer * shimmer_strength * mask;

        // ---- Subtle tint ----
        col.rgb = mix(col.rgb, col.rgb * water_tint.rgb, tint_strength * mask);

        // Preserve original alpha
        col.a = orig.a;
        COLOR = col;
    }
}
