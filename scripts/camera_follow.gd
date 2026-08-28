extends Node3D

# KAMERA v2 — yaw bebas drag, pitch clamp, PINCH dolly (4-9 m),
# RECENTER otomatis 0.8 s saat idle+lepas, look-at dada karakter.
# Movement karakter relatif kamera dihitung di player_controller via get_yaw().
const DIST_DEFAULT := 5.2
const DIST_MIN := 4.0
const DIST_MAX := 9.0
const RECENTER_DELAY := 0.8
const RECENTER_SPEED := 4.0

var dist := DIST_DEFAULT
var dragging := false
var idle_t := 0.0
var target: Node3D = null
var cam: Camera3D = null


func _ready() -> void:
	target = get_parent() as Node3D
	cam = get_node_or_null("Camera3D")


func get_yaw() -> float:
	# ORBIT-LOCAL yaw saja (bukan global!) — global menyuntikkan rotasi
	# player ke referensi movement => feedback loop "muter-muter"
	# (pelajaran UAT video + thread Cinemachine/TDM).
	return rotation.y


func adjust_dist(d: float) -> void:
	dist = clampf(dist + d, DIST_MIN, DIST_MAX)


func _physics_process(dt: float) -> void:
	if target == null:
		return
	if cam != null:
		# dist = jarak horizontal; tinggi proporsional (rasio 0.63)
		cam.position = Vector3(0.0, dist * 0.63, dist)

	var vel: Vector3 = target.velocity
	var speed := Vector2(vel.x, vel.z).length()
	if not dragging and speed < 0.15:
		idle_t += dt
	else:
		idle_t = 0.0
	if idle_t > RECENTER_DELAY:
		rotation.y = lerp_angle(rotation.y, 0.0, RECENTER_SPEED * dt)
		rotation.x = lerp(rotation.x, 0.0, RECENTER_SPEED * dt)
		dist = lerp(dist, DIST_DEFAULT, RECENTER_SPEED * dt)

	if cam != null:
		# pitch tinggi => target look-at naik, biar bisa mendongak ke langit
		var look_h := 1.55 + maxf(0.0, rotation.x - 0.25) * 3.0
		cam.look_at(target.global_position + Vector3(0.0, look_h, 0.0), Vector3.UP)
