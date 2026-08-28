extends Node3D

# RUMPUT v3 — hijau, padat, realistis lewat aturan komunitas:
#  - CLUMPS (gerombolan), bukan scatter seragam [polycount]
#  - variasi ukuran ±20%+ & skala per-clump [polycount Bajwa]
#  - variasi warna frekuensi kecil + sedikit helai kering di sela hijau
#  - crossed planes, alpha cutout, fade jarak, sway angin
@export var density := 0  # PADANG BASIC default tidur; 1 jarang, 2 sedang

const BASE_COUNT := 700
const REBUILD_DIST := 8.0
const SPAWN_RADIUS := 18.0

var mm_instance: MultiMeshInstance3D = null
var mat: ShaderMaterial = null
var noise: FastNoiseLite = null
var center := Vector3.ZERO
var cam_node: Node3D = null
var player_node: Node3D = null


func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 23
	noise.frequency = 0.06
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/grass.gdshader")
	player_node = get_node_or_null("/root/Main/Player")
	cam_node = get_node_or_null("/root/Main/Player/CameraPivot/Camera3D")
	rebuild(density)


func rebuild(d: int) -> void:
	density = d
	if mm_instance != null:
		mm_instance.queue_free()
		mm_instance = null
	if d <= 0:
		return
	var count := BASE_COUNT * (1 if d == 1 else 2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true  # 4.7: tidak ada enum COLOR_8BIT (pelajaran CI #3)
	mm.instance_count = count
	mm.mesh = _card_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var ter := get_node_or_null("/root/Main/Terrain")

	# clump centers: patch noise menentukan zona subur
	var clusters: Array = []
	var guard_c := 0
	while clusters.size() < count / 9 and guard_c < 400:
		guard_c += 1
		var a := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf()) * SPAWN_RADIUS
		var wx := center.x + cos(a) * r
		var wz := center.z + sin(a) * r
		if noise.get_noise_2d(wx, wz) < 0.0:
			continue
		if sqrt(wx * wx + wz * wz) < 5.0:
			continue  # arena tengah tetap relatif bersih
		clusters.append(Vector2(wx, wz))

	var placed := 0
	var guard := 0
	while placed < count and guard < count * 20:
		guard += 1
		if clusters.is_empty():
			break
		var c: Vector2 = clusters[rng.randi() % clusters.size()]
		var ox := rng.randf_range(-1.3, 1.3)
		var oz := rng.randf_range(-1.3, 1.3)
		var wx := c.x + ox
		var wz := c.y + oz
		var h := 0.0
		if ter != null and ter.has_method("get_height_at"):
			h = ter.get_height_at(wx, wz)
		var t := Transform3D()
		t.basis = t.basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t.basis = t.basis.rotated(Vector3.RIGHT, rng.randf_range(-0.08, 0.08))
		var cs := rng.randf_range(0.8, 1.3)  # skala clump
		var s := rng.randf_range(0.5, 0.9) * cs
		var sy := rng.randf_range(0.25, 0.5) * cs
		t.basis = t.basis.scaled(Vector3(s, sy, s))
		t.origin = Vector3(wx, h - 0.02, wz)
		mm.set_instance_transform(placed, t)
		# hijau dominan; variasi kecil; ~8% helai kering di sela
		var tint := Color(0.3, 0.5, 0.22).lerp(Color(0.55, 0.65, 0.3), rng.randf())
		if rng.randf() < 0.08:
			tint = Color(0.65, 0.55, 0.3)
		mm.set_instance_color(placed, tint)
		placed += 1
	mm.instance_count = maxi(placed, 1)
	mm_instance = MultiMeshInstance3D.new()
	mm_instance.multimesh = mm
	mm_instance.material_override = mat
	add_child(mm_instance)


# 5 helai tipis per quad, dua quad silang => volume tanpa overdraw gila
func _card_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var nrms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var xs: Array = [0.1, 0.3, 0.5, 0.7, 0.9]
	var ws: Array = [0.05, 0.07, 0.06, 0.08, 0.05]
	for q in [0.0, PI * 0.5]:
		var ca := cos(q)
		var sa := sin(q)
		for i in 5:
			var cx: float = xs[i]
			var w: float = ws[i]
			var base := verts.size()
			var corners := [cx - w, cx + w, cx + w, cx - w]
			var ys := [0.0, 0.0, 1.0, 1.0]
			var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			for k in 4:
				var lx: float = (corners[k] - 0.5) * 0.6
				verts.append(Vector3(lx * ca, ys[k], -lx * sa))
				nrms.append(Vector3(sa, 0.0, ca))
				uvs.append(uv[k])
			idx.append(base)
			idx.append(base + 1)
			idx.append(base + 2)
			idx.append(base)
			idx.append(base + 2)
			idx.append(base + 3)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = nrms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


func _process(_delta: float) -> void:
	if cam_node != null and mat != null:
		mat.set_shader_parameter("cam_pos", cam_node.global_position)
	if player_node != null and density > 0:
		var p := player_node.global_position
		var d2 := (Vector2(p.x, p.z) - Vector2(center.x, center.z)).length()
		if d2 > REBUILD_DIST:
			center = Vector3(p.x, 0.0, p.z)
			rebuild(density)
