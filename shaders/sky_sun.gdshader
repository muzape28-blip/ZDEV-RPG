shader_type sky;

// Matahari sky-shader: disc tajam + halo lembut, arah dikunci ke
// DirectionalLight (single source of truth). Murah: cuma 2 smoothstep
// di atas gradasi langit. Teknik "specular di bola langit" [gamedev.net].
uniform vec3 top_color : source_color = vec3(0.045, 0.075, 0.18);
uniform vec3 horizon_color : source_color = vec3(0.62, 0.24, 0.13);
uniform vec3 ground_color : source_color = vec3(0.10, 0.065, 0.055);
uniform vec3 sun_color : source_color = vec3(1.0, 0.58, 0.28);
uniform float sun_angle : hint_range(0.01, 0.2) = 0.05;
uniform vec3 sun_dir = vec3(0.0, 0.6, -0.75);

void sky() {
	vec3 v = normalize(EYEDIR);
	float h = clamp(v.y, -1.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(max(h, 0.0), 0.6));
	col = mix(col, ground_color, smoothstep(0.0, -0.15, h));
	float d = distance(v, normalize(sun_dir));
	float disc = 1.0 - smoothstep(sun_angle * 0.85, sun_angle, d);
	float halo = (1.0 - smoothstep(0.0, sun_angle * 6.0, d)) * 0.35;
	COLOR = col + sun_color * (disc * 3.0 + halo);
}
