extends Node3D

# S1 — komposisi batuan sabana (pohon DIHAPUS): landmark, bukan clutter.
# 3 klaster sedang (15-25 m) + 3 batu besar (35-60 m) + ±15 kerikil
# (dilarang r<10 m) + 1 monolit reruntuhan ±80 m.
# MultiMesh per kelas = 3 draw call; collision hanya besar+sedang.
@export var seed_value := 7

const CLUSTER_ANGLES := [40.0, 160.0, 280.0]
const BIG_ANGLES := [90.0, 210.0, 330.0]

var rock_mat: StandardMaterial3D = null


func _ready() -> void:
	rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.16, 0.15, 0.14)
	rock_mat.roughness = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_spawn_pebbles(rng)
	_spawn_clusters(rng)
	_spawn_big_rocks(rng)
	_spawn_monolith()
	_spawn_trees(rng)


func _rock_mesh() -> SphereMesh:
	var m := SphereMesh.new()
	m.radial_segments = 6
	m.rings = 4
	m.material = rock_mat
	return m


func _h(x: float, z: float) -> float:
	var ter := get_node_or_null("/root/Main/Terrain")
	if ter != null and ter.has_method("get_height_at"):
		return ter.get_height_at(x, z)
	return 0.0


func _pos(angle_deg: float, radius: float, rng: RandomNumberGenerator) -> Vector3:
	var a := deg_to_rad(angle_deg) + rng.randf_range(-0.2, 0.2)
	var r := radius + rng.randf_range(-3.0, 3.0)
	var x := cos(a) * r
	var z := sin(a) * r
	return Vector3(x, _h(x, z), z)


func _spawn_pebbles(rng: RandomNumberGenerator) -> void:
	var count := 15
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = _rock_mesh()
	var placed := 0
	var guard := 0
	while placed < count and guard < 200:
		guard += 1
		var a := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(10.0, 45.0)  # dilarang r<10
		var x := cos(a) * r
		var z := sin(a) * r
		var s := rng.randf_range(0.15, 0.4)
		var t := Transform3D()
		t.basis = t.basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t.basis = t.basis.scaled(Vector3(s, s * rng.randf_range(0.6, 1.0), s))
		t.origin = Vector3(x, _h(x, z) + s * 0.3, z)
		mm.set_instance_transform(placed, t)
		placed += 1
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = 0  # kerikil terlalu kecil untuk layak dapat bayangan
	add_child(mi)


func _spawn_clusters(rng: RandomNumberGenerator) -> void:
	var mesh := _rock_mesh()
	for ang in CLUSTER_ANGLES:
		var c := _pos(ang, rng.randf_range(15.0, 25.0), rng)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = 6
		mm.mesh = mesh
		for i in 6:
			var off := Vector3(rng.randf_range(-1.6, 1.6), 0.0, rng.randf_range(-1.6, 1.6))
			var s := rng.randf_range(0.4, 0.9)
			var t := Transform3D()
			t.basis = t.basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			t.basis = t.basis.scaled(Vector3(s, s * rng.randf_range(0.7, 1.1), s))
			t.origin = c + off + Vector3(0.0, s * 0.35 + _h(c.x + off.x, c.z + off.z) - _h(c.x, c.z), 0.0)
			mm.set_instance_transform(i, t)
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		add_child(mi)
		# collision sederhana: 2 kotak per klaster
		for k in 2:
			var b := StaticBody3D.new()
			var sh := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(2.2, 1.0, 1.6)
			sh.shape = box
			sh.rotation.y = rng.randf_range(0.0, TAU)
			b.add_child(sh)
			b.position = c + Vector3(rng.randf_range(-0.8, 0.8), 0.4, rng.randf_range(-0.8, 0.8))
			add_child(b)


func _spawn_big_rocks(rng: RandomNumberGenerator) -> void:
	var mesh := _rock_mesh()
	for ang in BIG_ANGLES:
		var p := _pos(ang, rng.randf_range(35.0, 60.0), rng)
		var s := rng.randf_range(1.5, 2.5)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.scale = Vector3(s, s * rng.randf_range(0.8, 1.2), s)
		mi.rotation.y = rng.randf_range(0.0, TAU)
		mi.position = p + Vector3(0.0, s * 0.35, 0.0)
		add_child(mi)
		var b := StaticBody3D.new()
		var sh := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = s * 0.8
		sh.shape = sp
		b.add_child(sh)
		b.position = p + Vector3(0.0, s * 0.4, 0.0)
		add_child(b)


func _spawn_trees(rng: RandomNumberGenerator) -> void:
	# pohon low-poly Pizza Doggy (Royalty Free) — nearest filtering sesuai
	# catatan kreator; sebar di luar arena combat
	var paths: Array = [
		"res://ASSETS/trees/dead_tree_rt_1.glb",
		"res://ASSETS/trees/dead_tree_rt_2.glb",
		"res://ASSETS/trees/small_tree_rt_1.glb",
	]
	var scenes: Array = []
	for p in paths:
		if ResourceLoader.exists(p):
			scenes.append(load(p))
	if scenes.is_empty():
		return
	for i in 12:
		var sc: PackedScene = scenes[i % scenes.size()]
		var inst := sc.instantiate()
		var a := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(18.0, 60.0)
		var x := cos(a) * r
		var z := sin(a) * r
		inst.position = Vector3(x, _h(x, z), z)
		inst.rotation.y = rng.randf_range(0.0, TAU)
		var s := rng.randf_range(0.8, 1.4)
		inst.scale = Vector3(s, s, s)
		add_child(inst)


func _spawn_monolith() -> void:
	# landmark senja ±80 m: balok runtuh + puncak miring
	var m := BoxMesh.new()
	m.size = Vector3(1.4, 7.0, 0.9)
	m.material = rock_mat
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var x := 80.0
	var z := 4.0
	mi.position = Vector3(x, _h(x, z) + 3.2, z)
	mi.rotation = Vector3(0.06, 0.4, 0.04)
	add_child(mi)
	var m2 := BoxMesh.new()
	m2.size = Vector3(1.1, 2.2, 0.8)
	m2.material = rock_mat
	var mi2 := MeshInstance3D.new()
	mi2.mesh = m2
	mi2.position = Vector3(x + 0.8, _h(x, z) + 6.6, z + 0.3)
	mi2.rotation = Vector3(0.3, 0.4, 0.5)
	add_child(mi2)
