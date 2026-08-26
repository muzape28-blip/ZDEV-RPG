extends CharacterBody3D

# M0: gerak + dodge. Attack masih stub (masuk M1).
@export var walk_speed := 6.0
@export var dash_speed := 13.0
@export var dash_duration := 0.22
@export var accel := 40.0
@export var gravity_strength := 20.0

var move_input := Vector2.ZERO
var dash_timer := 0.0
var dash_dir := Vector3(0.0, 0.0, -1.0)


func set_move_input(v: Vector2) -> void:
	move_input = v.limit_length(1.0)


func request_dodge() -> void:
	if dash_timer > 0.0:
		return
	var dir := _move_direction()
	if dir.length_squared() < 0.01:
		dir = -global_transform.basis.z
	dash_dir = dir.normalized()
	dash_timer = dash_duration


func request_attack() -> void:
	# Stub M0. Combo + hitbox masuk di M1.
	pass


func _move_direction() -> Vector3:
	if move_input.length_squared() < 0.001:
		return Vector3.ZERO
	# Kamera duduk di +Z menghadap -Z: layar-atas = -Z, layar-kanan = +X.
	return Vector3(move_input.x, 0.0, move_input.y).normalized()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity_strength * delta

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = dash_dir.x * dash_speed
		velocity.z = dash_dir.z * dash_speed
	else:
		var dir := _move_direction()
		var target := dir * walk_speed
		velocity.x = move_toward(velocity.x, target.x, accel * delta)
		velocity.z = move_toward(velocity.z, target.z, accel * delta)
		if dir.length_squared() > 0.001:
			var target_yaw := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, 14.0 * delta)

	move_and_slide()
