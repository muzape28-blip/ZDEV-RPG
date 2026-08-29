extends Node3D

# KAMERA v4 (PAKET v7) — tinggi DIKUNCI (nggak ada "naik" = zoom terselubung);
# mundur/dodge = jarak horizontal; menyamping = TRACKING YAW (dunia geser).
# yaw bebas drag, pitch clamp, RECENTER hanya idle & bukan pasca-dodge.
const DIST_DEFAULT := 4.4
const DIST_EXTRA_MAX := 2.2
const CAM_H := 2.772  # 4.4 * 0.63 — tinggi kunci, TIDAK berubah lagi
const RECENTER_DELAY := 0.8
const RECENTER_SPEED := 4.0

var dragging := false
var idle_t := 0.0
var target: Node3D = null
var cam: Camera3D = null

# dolly-out state
var extra := 0.0
var lat_hold := 0.0


func _ready() -> void:
	target = get_parent() as Node3D
	cam = get_node_or_null("Camera3D")
	if cam != null:
		cam.fov = 65.0  # framing referensi: char ~33-35% tinggi layar


func get_yaw() -> float:
	# ORBIT-LOCAL yaw saja (bukan global!) — global menyuntikkan rotasi
	# player ke referensi movement => feedback loop "muter-muter"
	# (pelajaran UAT video + thread Cinemachine/TDM).
	return rotation.y


func _physics_process(dt: float) -> void:
	if target == null:
		return

	# ---- DOLLY MUNDUR: hanya pendekatan (mundur) & dodge; TINGGI TETAP ----
	var fwd := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	var rgt := Vector3(-fwd.z, 0.0, fwd.x)
	var hvel := Vector3(target.velocity.x, 0.0, target.velocity.z)
	var approach := -hvel.dot(fwd)          # mundur = positif
	var lateral := hvel.dot(rgt)            # menyamping, bertanda
	var dv = target.get("dash_timer")       # dodge aktif?
	var dashing := dv != null and float(dv) > 0.0
	var urg := 0.0
	if dashing:
		urg = 8.0                            # dodge arah mana pun: napas langsung
	urg = maxf(urg, approach * 0.5)          # jalan mundur
	var target_extra := clampf(urg, 0.0, DIST_EXTRA_MAX)
	var rate := 6.0 if target_extra > extra else 2.0  # naik cepet, turun pelan
	extra = lerpf(extra, target_extra, clampf(rate * dt, 0.0, 1.0))
	var dist_eff := DIST_DEFAULT + extra

	# v7 TRACKING YAW: menyamping bertahan 0.4 dtk => kamera ngorbit ngikut
	# (omega = -v_lat / d, x0.9 biar halus) => char tetap tengah, dunia geser.
	# BUKAN nambah jarak (itu = zoom-out auto yang dipensiunkan). Pause saat drag.
	if absf(lateral) > 1.5 and not dashing and not dragging:
		lat_hold += dt
	else:
		lat_hold = 0.0
	if lat_hold > 0.4:
		rotation.y -= (lateral / dist_eff) * dt * 0.9

	if cam != null:
		# kamera di BELAKANG, TINGGI KUNCI CAM_H (konvensi hadap +Z)
		cam.position = Vector3(0.0, CAM_H, -dist_eff)

	var speed := Vector2(target.velocity.x, target.velocity.z).length()
	if not dragging and speed < 0.15:
		idle_t += dt
	else:
		idle_t = 0.0
	# RECENTER: hanya idle, dan DIBLOK 2 dtk pasca-dodge (PAKET v5:
	# posisi kamera abis dodge = posisi baru, jangan "balik tengah")
	var bv = target.get("dodge_block_t")
	var blocked := bv != null and float(bv) > 0.0
	if idle_t > RECENTER_DELAY and not blocked:
		rotation.y = lerp_angle(rotation.y, 0.0, RECENTER_SPEED * dt)
		rotation.x = lerp(rotation.x, 0.0, RECENTER_SPEED * dt)

	if cam != null:
		# pitch tinggi => target look-at naik, biar bisa mendongak ke langit
		var look_h := 1.55 + maxf(0.0, rotation.x - 0.25) * 3.0
		cam.look_at(target.global_position + Vector3(0.0, look_h, 0.0), Vector3.UP)
