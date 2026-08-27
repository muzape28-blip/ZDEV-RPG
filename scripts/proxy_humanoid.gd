extends Node3D

# S2/S3 — proxy humanoid perempuan 1.82 m, bersegmen, locomotion prosedural
# (fase terkunci kecepatan — anti "seluncur"), ponytail spring 3 segmen,
# pose dodge slide, konform tanah. Skin akhir (MakeHuman+mocap) mengganti
# segmen; controller ini tetap dipakai.
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
var mat_cloth: StandardMaterial3D
var mat_cloth_dark: StandardMaterial3D
var mat_skin: StandardMaterial3D
var mat_hair: StandardMaterial3D
var time_acc := 0.0


func _ready() -> void:
	mat_cloth = _mat(Color(0.35, 0.38, 0.45))
	mat_cloth_dark = _mat(Color(0.22, 0.24, 0.3))
	mat_skin = _mat(Color(0.72, 0.55, 0.42))
	mat_hair = _mat(Color(0.12, 0.1, 0.09))
	_build()
	# sosis pensiun:
	var body := get_node_or_null("../Body")
	if body != null:
		body.visible = false


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	return m


func _seg(parent: Node3D, size: Vector3, m: Material, pos: Vector3, pivot_top: bool) -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = m
	mi.mesh = b
	mi.position = Vector3(0.0, -size.y * 0.5 if pivot_top else size.y * 0.5, 0.0)
	n.add_child(mi)
	n.position = pos
	parent.add_child(n)
	return n


func _build() -> void:
	pelvis = Node3D.new()
	pelvis.position = Vector3(0.0, HIP_Y, 0.0)
	add_child(pelvis)
	var hipm := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.26, 0.18, 0.16)
	hb.material = mat_cloth_dark
	hipm.mesh = hb
	pelvis.add_child(hipm)

	torso = _seg(pelvis, Vector3(0.3, 0.5, 0.18), mat_cloth, Vector3(0.0, 0.1, 0.0), false)
	head = Node3D.new()
	head.position = Vector3(0.0, 0.62, 0.0)
	torso.add_child(head)
	var hm := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.115
	hs.material = mat_skin
	hm.mesh = hs
	hm.position = Vector3(0.0, 0.115, 0.0)
	head.add_child(hm)

	var p1 := _seg(head, Vector3(0.06, 0.28, 0.06), mat_hair, Vector3(0.0, 0.1, 0.1), true)
	var p2 := _seg(p1, Vector3(0.05, 0.26, 0.05), mat_hair, Vector3(0.0, -0.26, 0.0), true)
	var p3 := _seg(p2, Vector3(0.04, 0.24, 0.04), mat_hair, Vector3(0.0, -0.24, 0.0), true)
	pony = [p1, p2, p3]

	arm_l = _seg(torso, Vector3(0.08, 0.3, 0.08), mat_cloth, Vector3(0.19, 0.47, 0.0), true)
	arm_r = _seg(torso, Vector3(0.08, 0.3, 0.08), mat_cloth, Vector3(-0.19, 0.47, 0.0), true)
	fore_l = _seg(arm_l, Vector3(0.07, 0.28, 0.07), mat_skin, Vector3(0.0, -0.3, 0.0), true)
	fore_r = _seg(arm_r, Vector3(0.07, 0.28, 0.07), mat_skin, Vector3(0.0, -0.3, 0.0), true)

	leg_l = _seg(pelvis, Vector3(0.12, 0.47, 0.12), mat_cloth_dark, Vector3(0.1, 0.0, 0.0), true)
	leg_r = _seg(pelvis, Vector3(0.12, 0.47, 0.12), mat_cloth_dark, Vector3(-0.1, 0.0, 0.0), true)
	shin_l = _seg(leg_l, Vector3(0.1, 0.45, 0.1), mat_cloth_dark, Vector3(0.0, -0.47, 0.0), true)
	shin_r = _seg(leg_r, Vector3(0.1, 0.45, 0.1), mat_cloth_dark, Vector3(0.0, -0.47, 0.0), true)
	var foot_l := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.09, 0.08, 0.22)
	fb.material = mat_cloth_dark
	foot_l.mesh = fb
	foot_l.position = Vector3(0.0, -0.49, -0.05)
	shin_l.add_child(foot_l)
	var foot_r := foot_l.duplicate()
	shin_r.add_child(foot_r)


func _physics_process(dt: float) -> void:
	time_acc += dt
	var p := get_parent()
	if p == null:
		return
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	var ratio := clampf(speed / 5.5, 0.0, 1.0)
	var moving := speed > 0.15
	var dashing := p.get("dash_timer") != null and p.dash_timer > 0.0

	# fase terkunci kecepatan (stride lerp jalan->lari)
	if moving:
		var stride := lerp(0.7, 1.2, ratio)
		phase += (speed / stride) * dt * TAU
	var amp_t := (0.5 + 0.45 * ratio) if moving else 0.0
	amp_cur = lerp(amp_cur, amp_t, 10.0 * dt)

	var idle_f := clampf(1.0 - speed / 1.0, 0.0, 1.0)
	var sw_l := sin(phase) * amp_cur
	var sw_r := sin(phase + PI) * amp_cur

	# kaki
	leg_l.rotation.x = sw_l
	leg_r.rotation.x = sw_r
	shin_l.rotation.x = clampf((1.0 - sin(phase)) * 0.5, 0.0, 1.0) * amp_cur * 0.8 + 0.05
	shin_r.rotation.x = clampf((1.0 - sin(phase + PI)) * 0.5, 0.0, 1.0) * amp_cur * 0.8 + 0.05

	# lengan: ayun berlawanan kaki, blend ke stance saat idle
	var swing_l := sw_r * 0.6
	var swing_r := sw_l * 0.6
	arm_l.rotation.x = lerp(swing_l, -0.25, idle_f)
	arm_r.rotation.x = lerp(swing_r, -0.5, idle_f)
	fore_l.rotation.x = -0.35 - 0.3 * idle_f
	fore_r.rotation.x = -0.35 - 0.45 * idle_f

	# torso: lean lari + napas idle
	torso.rotation.x = lerp(0.0, 0.2, ratio) + sin(time_acc * 2.0) * 0.015 * idle_f
	pelvis.position.y = HIP_Y - 0.03 * ratio + abs(cos(phase)) * 0.03 * ratio

	# ponytail: spring sederhana, makin horizontal saat lari
	var pt_t := -(0.25 + 0.75 * ratio)
	for i in 3:
		var seg: Node3D = pony[i]
		var target := pt_t * (0.5 + 0.3 * float(i)) + sin(phase * 0.5 + float(i)) * 0.08 * ratio
		seg.rotation.x = lerp(seg.rotation.x, target, 6.0 * dt)

	# pose dodge slide (S3)
	if dashing:
		torso.rotation.x = lerp(torso.rotation.x, 0.5, 15.0 * dt)
		pelvis.position.y = lerp(pelvis.position.y, 0.8, 15.0 * dt)
		leg_l.rotation.x = lerp(leg_l.rotation.x, 1.1, 15.0 * dt)
		leg_r.rotation.x = lerp(leg_r.rotation.x, -0.7, 15.0 * dt)
		arm_l.rotation.x = lerp(arm_l.rotation.x, -0.9, 15.0 * dt)
		arm_r.rotation.x = lerp(arm_r.rotation.x, -0.9, 15.0 * dt)
		for i in 3:
			var seg: Node3D = pony[i]
			seg.rotation.x = lerp(seg.rotation.x, -1.2 - 0.2 * float(i), 12.0 * dt)

	# konform tanah (S3): pitch/roll halus + shift tinggi lokal
	var ter := get_node_or_null("/root/Main/Terrain")
	if ter != null and ter.has_method("get_height_at"):
		var g := p.global_position
		var fwd := -p.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() > 0.01:
			fwd = fwd.normalized()
		else:
			fwd = Vector3(0.0, 0.0, -1.0)
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var h_c: float = ter.get_height_at(g.x, g.z)
		var h_f: float = ter.get_height_at(g.x + fwd.x * 0.6, g.z + fwd.z * 0.6)
		var h_r: float = ter.get_height_at(g.x + right.x * 0.6, g.z + right.z * 0.6)
		position.y = lerp(position.y, h_c, 12.0 * dt)
		rotation.x = lerp(rotation.x, clampf((h_c - h_f) * 0.35, -0.18, 0.18), 8.0 * dt)
		rotation.z = lerp(rotation.z, clampf((h_r - h_c) * 0.35, -0.18, 0.18), 8.0 * dt)
