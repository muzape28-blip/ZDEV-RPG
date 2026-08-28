extends Node3D

# S1 — sabana berbukit: heightmap deterministik, pusat DATAR (readability
# combat), collision trimesh. Pelajaran: OpenMW (culling jarak), Nimian
# (stability > detail), Wilderless (variasi regional).
@export var size := 300.0
@export var resolution := 64
@export var amplitude := 2.6
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


func _ground_color(h: float) -> Color:
	# sabana HIJAU terang (permintaan UAT: tanah jangan gelap)
	var base := Color(0.36, 0.42, 0.22)
	var low := Color(0.24, 0.33, 0.16)
	var high := Color(0.48, 0.55, 0.28)
	var t := clampf((h + amplitude) / (2.0 * amplitude), 0.0, 1.0)
	var c := low.lerp(high, t)
	# sedikit variasi regional biar nggak rata-membosankan
	var v := noise.get_noise_2d(h * 13.7, t * 31.1) * 0.04
	c.r = clampf(c.r + v, 0.0, 1.0)
	c.g = clampf(c.g + v, 0.0, 1.0)
	c.b = clampf(c.b + v * 0.7, 0.0, 1.0)
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
			verts.append(Vector3(x, h, z))
			var hl: float = heights[iz][maxi(ix - 1, 0)]
			var hr: float = heights[iz][mini(ix + 1, n)]
			var hd: float = heights[maxi(iz - 1, 0)][ix]
			var hu: float = heights[mini(iz + 1, n)][ix]
			nrms.append(Vector3(hl - hr, 2.0 * step, hd - hu).normalized())
			cols.append(_ground_color(h))

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

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = nrms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	mi.cast_shadow = 0  # OFF: tanah menerima bayangan saja, tak casting (hemat)
	add_child(mi)

	# collision terrain: HeightMapShape3D (tool resmi — concave trimesh
	# bikin CharacterBody nyangkut di internal edges, pelajaran UAT #9).
	# API resmi 4.7: property map_data + spacing WAJIB 1 unit (docs).
	var w := int(size) + 1
	var hshape := HeightMapShape3D.new()
	hshape.map_width = w
	hshape.map_depth = w
	var data := PackedFloat32Array()
	for iz in range(w):
		for ix in range(w):
			data.append(get_height_at(-size * 0.5 + float(ix), -size * 0.5 + float(iz)))
	hshape.map_data = data
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = hshape
	body.add_child(col)
	add_child(body)
