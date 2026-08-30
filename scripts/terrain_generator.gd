extends Node3D

# S1 — sabana berbukit deterministik, pusat arena datar untuk combat.
# HeightMap mengikuti relief; safety floor tebal menangani jank startup/tunneling.
@export var size := 300.0
@export var resolution := 64
@export var amplitude := 2.4
@export var flat_radius := 12.0
@export var blend_width := 18.0
@export var seed_value := 11

var noise: FastNoiseLite = null


func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = seed_value
	noise.frequency = 0.018
	_build_terrain()


func get_height_at(x: float, z: float) -> float:
	if noise == null:
		return 0.0
	var r := sqrt(x * x + z * z)
	var t := clampf((r - flat_radius) / blend_width, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return amplitude * noise.get_noise_2d(x, z) * t


func _ground_color(h: float, x: float, z: float) -> Color:
	# Linear warm sand palette with regional mottle.
	var low := Color(0.40, 0.26, 0.12)
	var high := Color(0.66, 0.50, 0.28)
	var t := 0.0
	if amplitude > 0.001:
		t = clampf((h + amplitude) / (2.0 * amplitude), 0.0, 1.0)
	var patch := noise.get_noise_2d(x * 0.02, z * 0.02) * 0.5 + 0.5
	t = clampf(0.5 * t + 0.5 * patch, 0.0, 1.0)
	var c := low.lerp(high, t)
	var v := noise.get_noise_2d(x * 0.35, z * 0.35) * 0.03
	var sp := noise.get_noise_2d(x * 1.7 + 40.0, z * 1.7) * 0.02
	c.r = clampf(c.r + v + sp, 0.0, 1.0)
	c.g = clampf(c.g + v + sp * 0.8, 0.0, 1.0)
	c.b = clampf(c.b + v * 0.7 + sp * 0.5, 0.0, 1.0)
	return c


func _build_terrain() -> void:
	var n := resolution
	var step := size / float(n)
	var verts := PackedVector3Array()
	var nrms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var heights: Array = []

	for iz in range(n + 1):
		var row: Array = []
		for ix in range(n + 1):
			var x := -size * 0.5 + ix * step
			var z := -size * 0.5 + iz * step
			row.append(get_height_at(x, z))
		heights.append(row)

	for iz in range(n + 1):
		for ix in range(n + 1):
			var x := -size * 0.5 + ix * step
			var z := -size * 0.5 + iz * step
			var h: float = heights[iz][ix]
			var hl: float = heights[iz][maxi(ix - 1, 0)]
			var hr: float = heights[iz][mini(ix + 1, n)]
			var hd: float = heights[maxi(iz - 1, 0)][ix]
			var hu: float = heights[mini(iz + 1, n)][ix]
			verts.append(Vector3(x, h, z))
			nrms.append(Vector3(hl - hr, 2.0 * step, hd - hu).normalized())
			cols.append(_ground_color(h, x, z))

	for iz in range(n):
		for ix in range(n):
			var a := iz * (n + 1) + ix
			var b := a + 1
			var c := a + (n + 1)
			var d := c + 1
			idx.append(a)
			idx.append(c)
			idx.append(b)
			idx.append(b)
			idx.append(c)
			idx.append(d)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = nrms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var terrain_shader := load("res://shaders/terrain.gdshader") as Shader
	var mat: Material
	if terrain_shader != null:
		var shader_mat := ShaderMaterial.new()
		shader_mat.shader = terrain_shader
		mat = shader_mat
	else:
		var fallback := StandardMaterial3D.new()
		fallback.vertex_color_use_as_albedo = true
		fallback.roughness = 1.0
		mat = fallback
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

	# Relief collider: HeightMap grid uses one-unit spacing before uniform scale.
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = n + 1
	height_shape.map_depth = n + 1
	var map_data := PackedFloat32Array()
	map_data.resize((n + 1) * (n + 1))
	for iz in range(n + 1):
		for ix in range(n + 1):
			map_data[iz * (n + 1) + ix] = heights[iz][ix] / step
	height_shape.map_data = map_data
	collision.shape = height_shape
	collision.scale = Vector3(step, step, step)
	body.add_child(collision)
	add_child(body)

	# Deep primitive safety floor prevents startup delta tunneling through relief.
	var safety_body := StaticBody3D.new()
	var safety_collision := CollisionShape3D.new()
	var safety_box := BoxShape3D.new()
	safety_box.size = Vector3(size, 40.0, size)
	safety_collision.shape = safety_box
	safety_collision.position = Vector3(0.0, -20.0, 0.0)
	safety_body.add_child(safety_collision)
	add_child(safety_body)
