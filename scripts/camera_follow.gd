extends Node3D

# KAMERA v4 — yaw bebas drag, pitch clamp, tracking yaw lateral, dolly dodge.
# SpringArm3D mengatur collision camera; fallback manual tetap tersedia.
const DIST_DEFAULT := 4.4
const DIST_MIN := 4.0
const DIST_MAX := 9.0
const DIST_EXTRA_MAX := 2.2
const RECENTER_DELAY := 0.8
const RECENTER_SPEED := 4.0

var dist := DIST_DEFAULT
var dragging := false
var idle_t := 0.0
var target: Node3D = null
var cam: Camera3D = null
var arm: SpringArm3D = null
var extra := 0.0
var lat_hold := 0.0


func _ready() -> void:
	target = get_parent() as Node3D
	arm = get_node_or_null("CameraArm") as SpringArm3D
	cam = get_node_or_null("CameraArm/Camera3D") as Camera3D
	if cam == null:
		cam = get_node_or_null("Camera3D") as Camera3D
	if arm != null:
		arm.spring_length = dist
		arm.collision_mask = 1
		arm.margin = 0.2
		var body := target as CollisionObject3D
		if body != null:
			arm.add_excluded_object(body.get_rid())
	if cam != null:
		cam.fov = 65.0


func get_yaw() -> float:
	# Local yaw voorkomt feedback loop tussen camera orbit en player rotation.
	return rotation.y


func adjust_dist(delta_dist: float) -> void:
	dist = clampf(dist + delta_dist, DIST_MIN, DIST_MAX)


func _physics_process(dt: float) -> void:
	if target == null:
		return

	# SpringArm bezit child camera position; fallback bezit position direct.
	var fwd := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	var rgt := Vector3(-fwd.z, 0.0, fwd.x)
	var hvel := Vector3(target.velocity.x, 0.0, target.velocity.z)
	var approach := -hvel.dot(fwd)
	var lateral := hvel.dot(rgt)
	var dash_value = target.get("dash_timer")
	var dashing := dash_value != null and float(dash_value) > 0.0
	var urgency := 8.0 if dashing else approach * 0.5
	var target_extra := clampf(maxf(urgency, 0.0), 0.0, DIST_EXTRA_MAX)
	var rate := 6.0 if target_extra > extra else 2.0
	extra = lerpf(extra, target_extra, clampf(rate * dt, 0.0, 1.0))
	var dist_eff := clampf(DIST_DEFAULT + extra, DIST_MIN, DIST_MAX)

	# Tracking yaw hanya saat strafe berkelanjutan, bukan saat drag/dodge.
	if absf(lateral) > 1.5 and not dashing and not dragging:
		lat_hold += dt
	else:
		lat_hold = 0.0
	if lat_hold > 0.4:
		rotation.y -= (lateral / dist_eff) * dt * 0.9

	if arm != null:
		arm.spring_length = dist_eff
	elif cam != null:
		cam.position = Vector3(0.0, dist_eff * 0.63, -dist_eff)

	var speed := Vector2(target.velocity.x, target.velocity.z).length()
	if not dragging and speed < 0.15:
		idle_t += dt
	else:
		idle_t = 0.0
	var block_value = target.get("dodge_block_t")
	var blocked := block_value != null and float(block_value) > 0.0
	if idle_t > RECENTER_DELAY and not blocked:
		rotation.y = lerp_angle(rotation.y, 0.0, RECENTER_SPEED * dt)
		rotation.x = lerp(rotation.x, 0.0, RECENTER_SPEED * dt)

	if cam != null and arm == null:
		var look_target := target.global_position + Vector3(0.0, 1.55 + maxf(0.0, rotation.x - 0.25) * 3.0, 0.0)
		var view_dir := look_target - cam.global_position
		if view_dir.length_squared() > 0.0001:
			var look_up := Vector3.UP
			if absf(view_dir.normalized().dot(look_up)) > 0.98:
				look_up = Vector3.FORWARD
			cam.look_at(look_target, look_up)
