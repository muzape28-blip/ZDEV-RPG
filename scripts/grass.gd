extends Node3D

# S1 — rumput sabana: kartu cutout patchy, sway+gust, fade jarak, density
# toggle, MultiMesh = 1 draw call, re-center mengikuti player (pelajaran
# OpenMW: cull fitur kecil by jarak).
@export var density := 1  # 0 off, 1 jarang, 2 sedang

const BASE_COUNT := 500
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
	mm.use_colors = true
	mm.instance_count = count
	mm.mesh = _card_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var ter := get_node_or_null("/root/Main/Terrain")
	var placed := 0
	var guard := 0
	while placed < count and guard < count * 14:
		guard += 1
		var ang := rng.randf_range(0.0, TAU)
		var rad := sqrt(rng.randf()) * SPAWN_RADIUS
		var wx := center.x + cos(ang) * rad
		var wz := center.z + sin(ang) * rad
		if noise.get_noise_2d(wx, wz) < 0.02:
			continue  # patchy: hanya zona "subur"
		if sqrt(wx * wx + wz * wz) < 5.0 and rng.randf() < 0.6:
			continue  # arena tengah lebih bersih
		var h := 0.0
		if ter != null and ter.has_method("get_height_at"):
			h = ter.get_height_at(wx, wz)
		var t := Transform3D()
		t.basis = t.basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		var s := rng.randf_range(0.5, 0.9)
		var sy := rng.randf_range(0.2, 0.5)  # tinggi nyata 0.2-0.5 m (setinggi lutut)
		t.basis = t.basis.scaled(Vector3(s, sy, s))
		t.origin = Vector3(wx, h - 0.02, wz)
		mm.set_instance_transform(placed, t)
		var tint := Color(0.55, 0.45, 0.25).lerp(Color(0.75, 0.65, 0.4), rng.randf())
		if rng.randf() < 0.06:
			tint = Color(0.6, 0.4, 0.75)  # aksen bunga liar (vibe referensi)
		mm.set_instance_color(placed, tint)
		placed += 1
	mm.instance_count = maxi(placed, 1)
	mm_instance = MultiMeshInstance3D.new()
	mm_instance.multimesh = mm
	mm_instance.material_override = mat
	add_child(mm_instance)


func _card_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var nrms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var w := 0.28
	var quats: Array = [0.0, PI * 0.5]
	for q in quats:
		var ca: float = cos(q)
		var sa: float = sin(q)
		var base := verts.size()
		var corners: Array = [-w, w, w, -w]
		var ys: Array = [0.0, 0.0, 1.0, 1.0]
		var uv: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for i in 4:
			var lx: float = corners[i]
			verts.append(Vector3(lx * ca, ys[i], -lx * sa))
			nrms.append(Vector3(sa, 0.0, ca))
			uvs.append(uv[i])
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
