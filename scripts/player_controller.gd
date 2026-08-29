extends CharacterBody3D

# M0: gerak + dodge. Attack masih stub (masuk M1).
@export var walk_speed := 6.0
@export var dash_speed := 17.0   # v5: jangkauan dodge 3.9 m -> ~5.1 m
@export var dash_duration := 0.30
@export var accel := 40.0
@export var gravity_strength := 20.0

var move_input := Vector2.ZERO
var dash_timer := 0.0
var dash_dir := Vector3(0.0, 0.0, -1.0)
var cam: Node = null
var move_smooth := Vector3.ZERO
var was_dash := false      # v5: deteksi transisi dodge->biasa utk fallback smooth
var dodge_block_t := 0.0   # v5: blok recenter kamera pasca-dodge (dibaca kamera)
var strafe_anim := ""      # v5: dibaca proxy utk anim Standing Walk L/R/Back


func _ready() -> void:
	cam = get_node_or_null("CameraPivot")
	# Guard preventif CharacterBody3D (riset bug dasar): anti-jitter dinding,
	# anti-meluncur di lereng, snap tanah. [bugnet wall-jitter & slope-slide]
	max_slides = 6
	wall_min_slide_angle = deg_to_rad(15.0)
	slide_on_ceiling = false
	floor_snap_length = 0.6
	floor_stop_on_slope = true


func set_move_input(v: Vector2) -> void:
	move_input = v.limit_length(1.0)


func request_dodge() -> void:
	if dash_timer > 0.0:
		return
	var dir := _move_direction()
	var alias := ""
	if dir.length_squared() < 0.01:
		# tanpa input: backstep dengan animasi DodgeBack
		var cam := get_node_or_null("CameraPivot/Camera3D")
		if cam != null:
			dir = -cam.global_transform.basis.z
		else:
			dir = -global_transform.basis.z
		dir.y = 0.0
		alias = "DodgeBack"
	else:
		# arah stick relatif KAMERA (bukan hadap karakter — karakter selalu
		# menghadap stick, jadi referensi hadap selalu "depan" = bug lama)
		var pivot := get_node_or_null("CameraPivot")
		var cyaw: float = 0.0
		if pivot != null:
			cyaw = pivot.rotation.y
		var fwd := Vector3(sin(cyaw), 0.0, cos(cyaw))
		var rgt := Vector3(-fwd.z, 0.0, fwd.x)
		var lat := dir.dot(rgt)
		var lon := dir.dot(fwd)
		# v5: sektor BELAKANG diperlebar — serong kiri/kanan-belakang tetap
		# pakai anim DodgeBack, tapi VETTOR dash tetap serong ikut stick.
		if lon < 0.0 and abs(lon) > 0.35 * abs(lat):
			alias = "DodgeBack"
		elif abs(lat) > abs(lon):
			alias = "DodgeRight" if lat > 0.0 else "DodgeLeft"
		elif lon > 0.0:
			alias = "DodgeForward"
		else:
			alias = "DodgeBack"
	dash_dir = dir.normalized()
	dash_timer = dash_duration
	dodge_block_t = 2.0  # v5: kamera jangan recenter 2 dtk pasca-dodge
	rot_hold = 0.3  # jangan putar badan selama & sesaat setelah dodge
	var proxy := get_node_or_null("Proxy")
	if proxy != null and proxy.has_method("play_one_shot"):
		proxy.play_one_shot(alias)


var hp := 100.0
var atk_step := 0
var atk_cd := 0.0
var atk_buffer := 0.0
var parry_timer := 0.0
var lunge_timer := 0.0
var lunge_dir := Vector3(0.0, 0.0, -1.0)
var rot_hold := 0.0

const DMGS: Array = [10.0, 10.0, 25.0]
const CDS: Array = [0.35, 0.4, 0.62]


func request_attack() -> void:
	if atk_cd > 0.0:
		atk_buffer = 0.35
		return
	_start_attack()


func request_parry() -> void:
	parry_timer = 0.22


# dipanggil dummy saat swing-nya nyambung ke kita
func receive_swing() -> void:
	if dash_timer > 0.0:  # i-frame => dodge sukses => hadiah slow-mo
		var m := get_node_or_null("/root/Main")
		if m != null:
			m.slowmo(400)
		return
	if parry_timer > 0.0:  # parry sukses => stagger + slow-mo + hitstop
		var d := get_node_or_null("/root/Main/Dummy")
		if d != null and d.has_method("stagger"):
			d.stagger()
		var m2 := get_node_or_null("/root/Main")
		if m2 != null:
			m2.slowmo(450)
			m2.hitstop(80)
		return
	hp -= 20.0
	var hud := get_node_or_null("/root/Main/HUD/HudRoot")
	if hud != null and hud.has_method("hurt_flash"):
		hud.hurt_flash()
	if hp <= 0.0:
		hp = 100.0


func _start_attack() -> void:
	var idx: int = atk_step
	var cd: float = CDS[idx]
	var dmg: float = DMGS[idx]
	atk_cd = cd
	atk_step = (atk_step + 1) % 3
	lunge_dir = -global_transform.basis.z
	lunge_dir.y = 0.0
	if lunge_dir.length_squared() > 0.01:
		lunge_dir = lunge_dir.normalized()
	lunge_timer = 0.12
	var d := get_node_or_null("/root/Main/Dummy")
	if d != null and d.has_method("alive") and d.alive():
		var rel: Vector3 = d.global_position - global_position
		rel.y = 0.0
		if rel.length() < 2.3 and lunge_dir.dot(rel.normalized()) > 0.3:
			d.take_damage(dmg)
			var m := get_node_or_null("/root/Main")
			if m != null:
				m.hitstop(70)


func _move_direction() -> Vector3:
	if move_input.length_squared() < 0.001:
		return Vector3.ZERO
	# Gerakan RELATIF kamera: joystick atas selalu menjauhi kamera,
	# berapa pun yaw orbitnya.
	var pivot := get_node_or_null("CameraPivot")
	var cyaw := 0.0
	if pivot != null and pivot.has_method("get_yaw"):
		cyaw = pivot.get_yaw()
	# hadap kita +Z = arah jalan => fwd = +Z di-yaw orbit
	var fwd := Vector3(sin(cyaw), 0.0, cos(cyaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	return (fwd * -move_input.y + right * move_input.x).normalized()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity_strength * delta

	parry_timer = maxf(0.0, parry_timer - delta)
	rot_hold = maxf(0.0, rot_hold - delta)
	dodge_block_t = maxf(0.0, dodge_block_t - delta)
	atk_cd -= delta
	if atk_cd <= 0.0 and atk_buffer > 0.0:
		atk_buffer = 0.0
		_start_attack()
	else:
		atk_buffer = maxf(0.0, atk_buffer - delta)

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = dash_dir.x * dash_speed
		velocity.z = dash_dir.z * dash_speed
	elif lunge_timer > 0.0:
		lunge_timer -= delta
		velocity.x = lunge_dir.x * 7.0
		velocity.z = lunge_dir.z * 7.0
	else:
		# v5: transisi dodge->biasa = fallback SMOOTH: arah blend mulai dari
		# arah dodge, bukan nilai lama sebelum dodge (anti cross-blend aneh).
		if was_dash:
			move_smooth = dash_dir
		var dir := _move_direction()
		# PAKET ANTI-MOBIL: kurva pow 1.25 = rasa gas-pedal;
		# smoothing arah = anti zig-zag overcorrection; turn-rate 26 =
		# "menghadap" bukan "menyetir".
		var mag := move_input.length()
		var spd := pow(mag, 1.25) * 6.0
		if mag > 0.15 and spd < 2.0:
			spd = 2.0
		if mag < 0.05 and is_on_floor():
			velocity.x = 0.0  # zero saat idle di lantai: anti-drift gravitasi
			velocity.z = 0.0
		# v5 STRAFE HYBRID: band jalan + stick dominan samping/belakang =>
		# anim Standing Walk L/R/Back & badan lerp hadap KAMERA (rasa PGR);
		# lari/depan = putar hadap arah (rasa Genshin).
		strafe_anim = ""
		if mag > 0.15 and spd < 2.6:
			var lat := move_input.x
			var lon := -move_input.y
			if abs(lat) > 0.5 and abs(lat) >= abs(lon):
				strafe_anim = "WalkRight" if lat > 0.0 else "WalkLeft"
			elif lon < -0.5:
				strafe_anim = "WalkBack"
		move_smooth = move_smooth.lerp(dir, clampf(14.0 * delta, 0.0, 1.0))
		var target := move_smooth * spd
		velocity.x = move_toward(velocity.x, target.x, accel * delta)
		velocity.z = move_toward(velocity.z, target.z, accel * delta)
		if move_smooth.length_squared() > 0.001 and dash_timer <= 0.0 and rot_hold <= 0.0:
			if strafe_anim != "" and cam != null and cam.has_method("get_yaw"):
				# hadap kamera pelan-pelan saat strafe
				rotation.y = lerp_angle(rotation.y, cam.get_yaw(), 10.0 * delta)
			else:
				var target_yaw := atan2(move_smooth.x, move_smooth.z)
				rotation.y = lerp_angle(rotation.y, target_yaw, 26.0 * delta)
	was_dash = dash_timer > 0.0

	move_and_slide()

	var hud := get_node_or_null("/root/Main/HUD/HudRoot")
	if hud != null and hud.has_method("set_player_hp"):
		hud.set_player_hp(hp / 100.0)

	# Guard anti-void: kalau kelak ada lubang/bug fisika, respawn,
	# bukan jatuh selamanya (pelajaran UAT #1).
	if global_position.y < -30.0:
		global_position = Vector3(0.0, 2.0, 0.0)
		velocity = Vector3.ZERO
