extends Node

var failures := 0

func _ready() -> void:
	if OS.get_environment("ZDEV_RUNTIME_SMOKE") != "1":
		queue_free()
		return
	_run.call_deferred()


func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var scene: Node = get_tree().current_scene
	var wait_frames := 0
	while scene == null and wait_frames < 30:
		await get_tree().process_frame
		wait_frames += 1
		scene = get_tree().current_scene
	_assert(scene != null, "Main scene tersedia")
	if scene == null:
		get_tree().quit(1)
		return

	var player := scene.get_node_or_null("Player") as CharacterBody3D
	_assert(player != null, "Player CharacterBody3D ada")
	if player != null:
		var pivot := player.get_node_or_null("CameraPivot") as Node3D
		var arm := player.get_node_or_null("CameraPivot/CameraArm") as SpringArm3D
		var camera := player.get_node_or_null("CameraPivot/CameraArm/Camera3D") as Camera3D
		_assert(pivot != null, "CameraPivot ada")
		_assert(arm != null, "CameraArm SpringArm3D terpasang")
		_assert(camera != null, "Camera3D menjadi child CameraArm")
		if arm != null:
			_assert(arm.spring_length >= 2.0 and arm.spring_length <= 6.0, "SpringArm length dalam budget")
			_assert(arm.collision_mask == 1, "SpringArm collision mask terrain/obstacle")
		if camera != null:
			_assert(is_equal_approx(camera.fov, 65.0), "FOV third-person tetap 65")
		var proxy := player.get_node_or_null("Proxy") as Node3D
		_assert(proxy != null, "Proxy karakter ada")
		if proxy != null:
			_assert(_find_visible_mesh(proxy) != null, "Proxy memiliki MeshInstance3D terlihat")

		var dummy := scene.get_node_or_null("Dummy") as CollisionObject3D
		_assert(dummy != null, "Dummy combat ada")
		if dummy != null:
			_assert(dummy.collision_layer == 0 and dummy.collision_mask == 0, "Dummy tidak mendorong Player")

		player.request_dodge()
		_assert(player.dash_timer > 0.0, "request_dodge mengaktifkan dash window")
		var velocity_after_dodge := player.velocity
		for _i in range(5):
			await get_tree().process_frame
			velocity_after_dodge = player.velocity
			if Vector2(velocity_after_dodge.x, velocity_after_dodge.z).length() > 0.1:
				break
		_assert(Vector2(velocity_after_dodge.x, velocity_after_dodge.z).length() > 0.1, "dodge memberi velocity horizontal")

	var terrain := scene.get_node_or_null("Terrain") as Node3D
	_assert(terrain != null, "Terrain node ada")
	if terrain != null:
		var found_heightmap := false
		var found_shader := false
		for child in terrain.get_children():
			if child is StaticBody3D:
				for shape_node in child.get_children():
					if shape_node is CollisionShape3D and shape_node.shape is HeightMapShape3D:
						found_heightmap = true
			var mesh_node := child as MeshInstance3D
			if mesh_node != null and mesh_node.material_override is ShaderMaterial:
				var shader_mat := mesh_node.material_override as ShaderMaterial
				if shader_mat.shader != null:
					found_shader = true
		_assert(found_heightmap, "terrain memiliki HeightMapShape3D")
		_assert(found_shader, "terrain memakai ShaderMaterial")

	if failures == 0:
		print("RUNTIME SMOKE: HIJAU")
	else:
		print("RUNTIME SMOKE: MERAH (%d failure)" % failures)
	get_tree().quit(failures)


func _find_visible_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_visible_mesh(child)
		if found != null:
			return found
	return null


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("smoke OK: %s" % label)
	else:
		print("smoke FAIL: %s" % label)
		failures += 1
