shader_type spatial;

// Medan sabana senja: variasi material murah berbasis vertex color + posisi dunia.
// Opaque + fake diffuse: Compatibility/mobile tidak mendapat lighting hitam
// ketika directional light scene belum tersedia pada frame pertama. Model
// tetap directional secara visual, tetapi hanya memakai dot product murah.
render_mode unshaded, cull_disabled;

uniform vec3 warm_sand : source_color = vec3(0.62, 0.50, 0.34);
uniform vec3 cool_sand : source_color = vec3(0.38, 0.33, 0.27);
uniform vec3 dry_sand : source_color = vec3(0.76, 0.64, 0.43);
uniform vec3 sun_dir = vec3(0.0, 0.85, 0.45);
uniform float ambient_strength = 0.52;
uniform float sun_strength = 0.62;
uniform float detail_scale = 0.085;
uniform float detail_strength = 0.08;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    float height_band = smoothstep(-0.25, 1.8, world_position.y);
    float macro = sin(world_position.x * detail_scale) * sin(world_position.z * detail_scale * 0.77);
    float micro = sin(world_position.x * 0.43 + world_position.z * 0.17) * 0.5 + 0.5;
    float variation = clamp(macro * detail_strength + micro * 0.035, -0.12, 0.12);

    vec3 base = mix(cool_sand, warm_sand, height_band);
    base = mix(base, dry_sand, clamp(height_band * 0.35 + variation, 0.0, 1.0));
    base *= 1.0 + variation;
    base *= mix(vec3(0.92), vec3(1.06), COLOR.g);

    float diffuse = max(dot(normalize(world_normal), normalize(sun_dir)), 0.0);
    float lighting = ambient_strength + diffuse * sun_strength;
    ALBEDO = base * lighting;
}
