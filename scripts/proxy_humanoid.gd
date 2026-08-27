extends Node3D

# PROXY HUMANOID v2 — perempuan 1.82 m, "hidup" lewat:
#  - lutut/siku two-bone: fleksi puncak saat swing (fase gerak), lurik saat contact
#  - pelvis: bob 2x frekuensi + yaw + roll (weight shift)
#  - torso counter-rotation + lean terlambat ("hips lead, chest follows")
#  - STABILISASI KEPALA: pitch/yaw melawan torso + glance acak (awareness)
#  - siku base-flex 0.35 (jalan) -> 0.9 (lari), ayun kontralateral
#  - idle: napas, weight shift, glance — anti-robotik
#  - ponytail spring 3 segmen + sway lateral (secondary motion)
# Referensi: Johansen thesis (semi-procedural locomotion), tigerabrodi
# (IK/FK layering), ianimate (root/hip overlap), QDStaff (micro-variation),
# Animation Mentor (secondary motion settle).
const HIP_Y := 0.95

var pelvis: Node3D
var torso: Node3D
var head: Node3D
var pony: Array = []
var arm_l: Node3D
var arm_r: Node3D
var fore_l: Node3D
var fore_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var shin_l: Node3D
var shin_r: Node3D

var phase := 0.0
var amp_cur := 0.0
var lean_cur := 0.0
var time_acc := 0.0
var glance_t := 4.0
var glance_target := 0.0
var glance_cur := 0.0

var mat_cloth: StandardMaterial3D
var mat_cloth_dark: StandardMaterial3D
var mat_skin: StandardMaterial3D
var mat_hair: StandardMaterial3D


func _ready() -> void:
	mat_cloth = _mat(Color(0.48, 0.53, 0.64))  # lebih terang: readability senja
	mat_cloth_dark = _mat(Color(0.3, 0.33, 0.4))
	mat_skin = _mat(Color(0.72, 0.55, 0.42))
	mat_hair = _mat(Color(0.12, 0.1, 0.09))
	_build()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	return m


func _capsule(r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.material = m
	mi.mesh = c
	return mi


func _sphere(r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.material = m
	mi.mesh = s
	return mi


# pivot di ATAS mesh (anggota badan menggantung & berayun)
func _limb(parent: Node3D, r: float, h: float, m: Material, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	var mi := _capsule(r, h, m)
	mi.position = Vector3(0.0, -h * 0.5, 0.0)
	n.add_child(mi)
	n.position = pos
	parent.add_child(n)
	return n


func _build() -> void:
	pelvis = Node3D.new()
	pelvis.position = Vector3(0.0, HIP_Y, 0.0)
	add_child(pelvis)
	var pm := _capsule(0.13, 0.2, mat_cloth_dark)
	pelvis.add_child(pm)

	torso = Node3D.new()
	torso.position = Vector3(0.0, 0.12, 0.0)
	pelvis.add_child(torso)
	var tm := _capsule(0.14, 0.44, mat_cloth)
	tm.position = Vector3(0.0, 0.22, 0.0)
	torso.add_child(tm)
	var neck := _capsule(0.05, 0.1, mat_skin)
	neck.position = Vector3(0.0, 0.48, 0.0)
	torso.add_child(neck)

	head = Node3D.new()
	head.position = Vector3(0.0, 0.56, 0.0)
	torso.add_child(head)
	var hm := _sphere(0.115, mat_skin)
	hm.position = Vector3(0.0, 0.1, 0.0)
	head.add_child(hm)
	var cap := _sphere(0.125, mat_hair)
	cap.scale = Vector3(1.0, 0.92, 1.05)
	cap.position = Vector3(0.0, 0.13, 0.02)
	head.add_child(cap)

	var p1 := _limb(head, 0.05, 0.3, mat_hair, Vector3(0.0, 0.08, 0.11))
	var p2 := _limb(p1, 0.042, 0.28, mat_hair, Vector3(0.0, -0.28, 0.0))
	var p3 := _limb(p2, 0.034, 0.26, mat_hair, Vector3(0.0, -0.26, 0.0))
	pony = [p1, p2, p3]

	# bahu bulat + lengan dua-ruas
	var shl := _sphere(0.055, mat_cloth)
	shl.position = Vector3(0.17, 0.44, 0.0)
	torso.add_child(shl)
	var shr := _sphere(0.055, mat_cloth)
	shr.position = Vector3(-0.17, 0.44, 0.0)
	torso.add_child(shr)
	arm_l = _limb(torso, 0.045, 0.28, mat_cloth, Vector3(0.17, 0.44, 0.0))
	arm_r = _limb(torso, 0.045, 0.28, mat_cloth, Vector3(-0.17, 0.44, 0.0))
	var elb_l := _sphere(0.04, mat_skin)
	elb_l.position = Vector3(0.0, -0.28, 0.0)
	arm_l.add_child(elb_l)
	var elb_r := _sphere(0.04, mat_skin)
	elb_r.position = Vector3(0.0, -0.28, 0.0)
	arm_r.add_child(elb_r)
	fore_l = _limb(arm_l, 0.04, 0.26, mat_skin, Vector3(0.0, -0.28, 0.0))
	fore_r = _limb(arm_r, 0.04, 0.26, mat_skin, Vector3(0.0, -0.28, 0.0))
	var hand_l := _sphere(0.045, mat_skin)
	hand_l.position = Vector3(0.0, -0.28, 0.0)
	fore_l.add_child(hand_l)
	var hand_r := _sphere(0.045, mat_skin)
	hand_r.position = Vector3(0.0, -0.28, 0.0)
	fore_r.add_child(hand_r)

	# pinggul + kaki dua-ruas + lutut bulat + telapak
	leg_l = _limb(pelvis, 0.06, 0.44, mat_cloth_dark, Vector3(0.09, -0.02, 0.0))
	leg_r = _limb(pelvis, 0.06, 0.44, mat_cloth_dark, Vector3(-0.09, -0.02, 0.0))
	var knee_l := _sphere(0.05, mat_cloth_dark)
	knee_l.position = Vector3(0.0, -0.44, 0.0)
	leg_l.add_child(knee_l)
	var knee_r := _sphere(0.05, mat_cloth_dark)
	knee_r.position = Vector3(0.0, -0.44, 0.0)
	leg_r.add_child(knee_r)
	shin_l = _limb(leg_l, 0.045, 0.42, mat_cloth_dark, Vector3(0.0, -0.44, 0.0))
	shin_r = _limb(leg_r, 0.045, 0.42, mat_cloth_dark, Vector3(0.0, -0.44, 0.0))
	var foot_l := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.08, 0.07, 0.21)
	fb.material = mat_cloth_dark
	foot_l.mesh = fb
	foot_l.position = Vector3(0.0, -0.46, -0.05)
	shin_l.add_child(foot_l)
	var foot_r := foot_l.duplicate()
	shin_r.add_child(foot_r)


func _physics_process(dt: float) -> void:
	time_acc += dt
	var p: Node = get_parent()
	if p == null:
		return
	var vel: Vector3 = p.velocity
	var speed: float = Vector2(vel.x, vel.z).length()
	var ratio: float = clampf(speed / 5.5, 0.0, 1.0)
	var moving: bool = speed > 0.15
	var dash_raw: Variant = p.get("dash_timer")
	var dashing: bool = false
	if dash_raw != null:
		dashing = float(dash_raw) > 0.0

	if moving:
		var stride: float = lerp(0.7, 1.2, ratio)
		phase += (speed / stride) * dt * TAU
	var amp_t: float = (0.55 + 0.4 * ratio) if moving else 0.0
	amp_cur = lerp(amp_cur, amp_t, 10.0 * dt)
	var idle_f: float = clampf(1.0 - speed / 1.0, 0.0, 1.0)

	# ---- KAKI: hip sinus + knee fleksi puncak saat swing ----
	var ph_l: float = phase
	var ph_r: float = phase + PI
	var hip_l: float = sin(ph_l) * amp_cur
	var hip_r: float = sin(ph_r) * amp_cur
	var knee_l: float = pow(maxf(0.0, cos(ph_l)), 1.3) * (0.25 + 0.85 * amp_cur) + 0.06
	var knee_r: float = pow(maxf(0.0, cos(ph_r)), 1.3) * (0.25 + 0.85 * amp_cur) + 0.06

	# ---- PELVIS: bob 2x + yaw + roll + weight shift idle ----
	var bob: float = sin(2.0 * phase + PI * 0.5) * 0.025 * amp_cur
	var pel_yaw: float = sin(ph_l) * 0.06 * amp_cur
	var pel_roll: float = sin(ph_l) * 0.04 * amp_cur
	pelvis.rotation.y = pel_yaw
	pelvis.rotation.z = pel_roll
	pelvis.position.y = HIP_Y - 0.02 * ratio + bob
	pelvis.position.x = sin(time_acc * 0.7) * 0.015 * idle_f

	# ---- TORSO: lean terlambat + counter-rotation ----
	lean_cur = lerp(lean_cur, lerp(0.0, 0.22, ratio), 8.0 * dt)
	torso.rotation.x = lean_cur + sin(time_acc * 2.0) * 0.012 * idle_f
	torso.rotation.y = -pel_yaw * 0.7
	torso.rotation.z = -pel_roll * 0.4

	# ---- KEPALA: stabilisasi + glance acak ----
	glance_t -= dt
	if glance_t <= 0.0:
		glance_t = randf_range(3.0, 7.0)
		glance_target = randf_range(-0.5, 0.5)
	var glance_w: float = 0.3 if moving else 1.0
	glance_cur = lerp(glance_cur, glance_target * glance_w, 3.0 * dt)
	head.rotation.x = -torso.rotation.x * 0.6
	head.rotation.y = -torso.rotation.y * 0.5 + glance_cur
	head.rotation.z = -torso.rotation.z * 0.5

	# ---- LENGAN: ayun kontralateral + siku base-flex ----
	var sh_l: float = sin(ph_r) * amp_cur * 0.5
	var sh_r: float = sin(ph_l) * amp_cur * 0.5
	var elbow_base: float = 0.35 + 0.55 * ratio
	arm_l.rotation.x = lerp(sh_l, -0.25, idle_f)
	arm_r.rotation.x = lerp(sh_r, -0.5, idle_f)
	fore_l.rotation.x = -elbow_base - 0.1 * sin(ph_r + PI * 0.5) * amp_cur - 0.3 * idle_f
	fore_r.rotation.x = -elbow_base - 0.1 * sin(ph_l + PI * 0.5) * amp_cur - 0.45 * idle_f

	# ---- PONYTAIL: spring + sway lateral ----
	var pt_t: float = -(0.25 + 0.75 * ratio)
	for i in 3:
		var seg: Node3D = pony[i]
		var fi: float = float(i)
		var target: float = pt_t * (0.5 + 0.3 * fi) + sin(phase * 0.5 + fi) * 0.08 * ratio
		seg.rotation.x = lerp(seg.rotation.x, target, 6.0 * dt)
		seg.rotation.z = sin(phase * 0.5 + fi * 0.7) * 0.1 * ratio

	# ---- POSE DODGE SLIDE ----
	if dashing:
		torso.rotation.x = lerp(torso.rotation.x, 0.5, 15.0 * dt)
		pelvis.position.y = lerp(pelvis.position.y, 0.8, 15.0 * dt)
		leg_l.rotation.x = lerp(leg_l.rotation.x, 1.1, 15.0 * dt)
		leg_r.rotation.x = lerp(leg_r.rotation.x, -0.7, 15.0 * dt)
		shin_l.rotation.x = lerp(shin_l.rotation.x, 0.4, 15.0 * dt)
		shin_r.rotation.x = lerp(shin_r.rotation.x, 0.9, 15.0 * dt)
		arm_l.rotation.x = lerp(arm_l.rotation.x, -0.9, 15.0 * dt)
		arm_r.rotation.x = lerp(arm_r.rotation.x, -0.9, 15.0 * dt)
		for i in 3:
			var sg: Node3D = pony[i]
			sg.rotation.x = lerp(sg.rotation.x, -1.2 - 0.2 * float(i), 12.0 * dt)
	else:
		leg_l.rotation.x = hip_l
		leg_r.rotation.x = hip_r
		shin_l.rotation.x = knee_l
		shin_r.rotation.x = knee_r

	# ---- KONFORM TANAH ----
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
