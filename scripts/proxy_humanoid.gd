extends Node3D

# HUMAN_FEMALE_WARRIOR v3 — Integrasi 3D Skeletal Mesh & Animasi (In-Place 30 FPS)
# Memuat aset GLTF character (Idle, Walking, Running, Sprint)
# Menghubungkan kecepatan joystick ke AnimationTree (BlendSpace1D) / AnimationPlayer

var anim_player: AnimationPlayer
var model_node: Node3D
var current_anim := "Idle"


func _ready() -> void:
	_load_and_setup_character()


func _load_and_setup_character() -> void:
	# Coba muat model GLTF yang telah disiapkan di ASSETS/mixamo/
	var paths := [
		"res://ASSETS/mixamo/sample_female_warrior.gltf",
		"res://ASSETS/mixamo/Idle.gltf"
	]

	var char_scene: PackedScene = null
	for p in paths:
		if ResourceLoader.exists(p):
			char_scene = load(p) as PackedScene
			if char_scene != null:
				break

	if char_scene != null:
		var inst := char_scene.instantiate()
		add_child(inst)
		model_node = inst

		# Cari AnimationPlayer di dalam scene ter-instansiasi
		anim_player = _find_animation_player(inst)
		if anim_player != null:
			if anim_player.has_animation("Idle"):
				anim_player.play("Idle")
			elif anim_player.has_animation("Scene"):
				anim_player.play("Scene")


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _physics_process(dt: float) -> void:
	var p: Node = get_parent()
	if p == null:
		return
	var vel: Vector3 = p.velocity
	var speed: float = Vector2(vel.x, vel.z).length()
	var ratio: float = clampf(speed / 6.0, 0.0, 1.0)

	# Pilih animasi berdasar kecepatan gerak
	var target_anim := "Idle"
	if speed > 4.5:
		target_anim = "Sprint"
	elif speed > 2.5:
		target_anim = "Running"
	elif speed > 0.15:
		target_anim = "Walking"

	if anim_player != null:
		if anim_player.has_animation(target_anim):
			if current_anim != target_anim:
				current_anim = target_anim
				anim_player.play(target_anim, 0.2) # Blend 0.2s
		elif anim_player.has_animation("Idle") and current_anim != "Idle":
			current_anim = "Idle"
			anim_player.play("Idle", 0.2)

	# ---- KONFORM TANAH SABANA ----
	var ter := get_node_or_null("/root/Main/Terrain")
	if ter != null and ter.has_method("get_height_at"):
		var g: Vector3 = p.global_position
		var fwd: Vector3 = -p.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() > 0.01:
			fwd = fwd.normalized()
		else:
			fwd = Vector3(0.0, 0.0, -1.0)
		var right: Vector3 = Vector3(-fwd.z, 0.0, fwd.x)
		var h_c: float = ter.get_height_at(g.x, g.z)
		var h_f: float = ter.get_height_at(g.x + fwd.x * 0.6, g.z + fwd.z * 0.6)
		var h_r: float = ter.get_height_at(g.x + right.x * 0.6, g.z + right.z * 0.6)
		position.y = lerp(position.y, h_c, 12.0 * dt)
		rotation.x = lerp(rotation.x, clampf((h_c - h_f) * 0.35, -0.18, 0.18), 8.0 * dt)
		rotation.z = lerp(rotation.z, clampf((h_r - h_c) * 0.35, -0.18, 0.18), 8.0 * dt)
