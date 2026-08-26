extends Node3D

# Sabana graybox: pohon mati + batu, posisi deterministik (seed tetap)
# supaya hasil konsisten antar build & antar sesi UAT.
@export var tree_count := 10
@export var rock_count := 8
@export var seed_value := 7


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.13, 0.10, 0.08)
	bark.roughness = 1.0

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.06
	trunk.bottom_radius = 0.14
	trunk.height = 2.4
	trunk.material = bark

	var branch := CylinderMesh.new()
	branch.top_radius = 0.02
	branch.bottom_radius = 0.05
	branch.height = 1.1
	branch.material = bark

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.22, 0.20, 0.18)
	rock_mat.roughness = 1.0

	for i in tree_count:
		var pos := _ring_position(rng, 14.0, 70.0)
		var t := MeshInstance3D.new()
		t.mesh = trunk
		t.position = pos + Vector3(0.0, 1.2, 0.0)
		t.rotation.y = rng.randf_range(0.0, TAU)
		add_child(t)
		var b := MeshInstance3D.new()
		b.mesh = branch
		b.position = pos + Vector3(0.0, 1.9, 0.0)
		b.rotation = Vector3(rng.randf_range(-0.9, 0.9), 0.0, rng.randf_range(-0.9, 0.9))
		add_child(b)

	for i in rock_count:
		var pos := _ring_position(rng, 10.0, 60.0)
		var r := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(rng.randf_range(0.5, 1.4), rng.randf_range(0.3, 0.8), rng.randf_range(0.5, 1.4))
		m.material = rock_mat
		r.mesh = m
		r.position = pos + Vector3(0.0, m.size.y / 2.0, 0.0)
		r.rotation.y = rng.randf_range(0.0, TAU)
		add_child(r)


func _ring_position(rng: RandomNumberGenerator, r_min: float, r_max: float) -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var radius := rng.randf_range(r_min, r_max)
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
