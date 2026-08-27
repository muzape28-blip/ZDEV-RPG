shader_type spatial;
render_mode cull_disabled, shadows_disabled;

// Rumput sabana: cutout opaque (bukan transparan — overdraw = musuh Mali),
// sway+gust di vertex, fade jarak lewat uniform cam_pos (dipasang CPU,
// menghindari builtin eksotis).
uniform float sway_strength : hint_range(0.0, 0.2) = 0.06;
uniform float fade_start : hint_range(1.0, 60.0) = 10.0;
uniform float fade_end : hint_range(1.0, 80.0) = 15.0;
uniform vec3 cam_pos = vec3(0.0, 0.0, 0.0);

varying float v_h;
varying float v_fade;

void vertex() {
	v_h = UV.y;
	vec4 wpos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float wind = sin(TIME * 1.7 + wpos.x * 0.35 + wpos.z * 0.27);
	float gust = 0.5 + 0.5 * sin(TIME * 0.6 + wpos.z * 0.08);
	vec2 off = vec2(wind * (0.6 + 0.4 * gust), wind * 0.35 * gust)
			* sway_strength * v_h * v_h;
	VERTEX.xz += off;
	v_fade = 1.0 - smoothstep(fade_start, fade_end, distance(wpos.xyz, cam_pos));
}

void fragment() {
	if (v_fade <= 0.001) {
		discard;
	}
	// mask prosedural 4 helai meruncing
	float x = UV.x;
	float w = 0.10 * (1.0 - v_h * 0.85);
	float m = step(abs(x - 0.18), w) + step(abs(x - 0.45), w * 0.8)
			+ step(abs(x - 0.70), w) + step(abs(x - 0.90), w * 0.7);
	if (m < 0.5) {
		discard;
	}
	ALBEDO = COLOR.rgb * mix(vec3(0.55), vec3(1.15), v_h);
	ROUGHNESS = 1.0;
}
