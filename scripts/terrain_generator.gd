extends Node3D

# S1 — sabana berbukit: heightmap deterministik, pusat DATAR (readability
# combat), collision trimesh. Pelajaran: OpenMW (culling jarak), Nimian
# (stability > detail), Wilderless (variasi regional).
@export var size := 300.0
@export var resolution := 64
@export var amplitude := 0.0  # PADANG BASIC: datar total; bukit = fase nanti
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
	# PALET PASIR v5 (riset albedo: desert sand ~0.4 linear, polycount PBR list).
	# Nilai LINEAR (konversi dari sRGB): jangan tebak hex langsung.
	var low := Color(0.40, 0.26, 0.12)   # trough antar-dune  (#A98B62 sRGB)
	var high := Color(0.66, 0.50, 0.28)  # crest kena matahari (#D4BC90 sRGB)
	# GUARD NaN (pelajaran UAT padang hitam): amplitude=0 => 0/0 = NaN yang
	# menyebar ke lerp warna => vertex hitam. Flat = t tinggi dinetralkan.
	var t := 0.0
	if amplitude > 0.001:
		t = clampf((h + amplitude) / (2.0 * amplitude), 0.0, 1.0)
	# padang datar: patch noise skala BESAR menggantikan tinggi sbg driver,
	# setengah-setengah biar fase bukit nanti nyambung mulus.
	var patch := noise.get_noise_2d(x * 0.02, z * 0.02) * 0.5 + 0.5
	t = clampf(0.5 * t + 0.5 * patch, 0.0, 1.0)
	var c := low.lerp(high, t)
	# mottle frekuensi sedang + speckle kering jarang (struktur 3 lapis)
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
			verts.append(Vector3(x, h, z))
			var hl: float = heights[iz][maxi(ix - 1, 0)]
			var hr: float = heights[iz][mini(ix + 1, n)]
			var hd: float = heights[maxi(iz - 1, 0)][ix]
			var hu: float = heights[mini(iz + 1, n)][ix]
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

	# PADANG BASIC: kolisi Box sederhana = kelas bug "nyangkut/tenggelam"
	# musnah; primitif > heightmap/trimesh untuk fase basic (riset bug dasar).
	# v7 ANTI-TUNNELING: box TEBAL 40 m (puncak tetap y=0). Frame pertama di
	# device punya delta raksasa (jank startup) => vy besar => box tipis 2 m
	# dulu ketembus (tunneling, UAT "char di bawah floor"). 40 m = mustahil
	# ketembus bahkan di vy clamp -12 & delta 0.1 s (langkah maks 1.2 m).
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 40.0, size)
	col.shape = box
	col.position = Vector3(0.0, -20.0, 0.0)
	body.add_child(col)
	add_child(body)
