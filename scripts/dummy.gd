extends CharacterBody3D

# M1 — dummy latihan (placeholder hydra): HP, telegraph windup, swing,
# stagger saat diparry, reset saat mati.
@export var max_hp := 100.0

var hp := 100.0
var state := "idle"
var t := 0.0
var mat: StandardMaterial3D = null
var flash := 0.0

const ARC_RANGE := 2.4
const ARC_COS := 0.36  # ~69 derajat


func _ready() -> void:
	mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.3, 0.25)
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.55
	c.height = 2.6
	c.material = mat
	mi.mesh = c
	mi.position = Vector3(0.0, 1.3, 0.0)
	add_child(mi)
	var col := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.55
	sh.height = 2.6
	col.shape = sh
	col.position = Vector3(0.0, 1.3, 0.0)
	add_child(col)
	position = Vector3(0.0, 0.0, 8.0)


func _physics_process(dt: float) -> void:
	t += dt
	flash = maxf(0.0, flash - dt)
	var windup := state == "windup" or flash > 0.0
	mat.albedo_color = Color(0.9, 0.15, 0.1) if windup else Color(0.45, 0.3, 0.25)

	match state:
		"idle":
			if t > 3.5:
				go("windup")
		"windup":
			if t > 0.7:
				go("swing")
		"swing":
			if t > 0.25:
				go("idle")
		"stagger":
			if t > 1.2:
				go("idle")
		"dead":
			if t > 3.0:
				hp = max_hp
				go("idle")

	var p := get_node_or_null("/root/Main/Player")
	if p != null and state != "dead":
		var dir: Vector3 = p.global_position - global_position
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 3.0 * dt)
	_update_bar()


func go(s: String) -> void:
	state = s
	t = 0.0
	if s == "swing":
		_try_hit_player()


func _try_hit_player() -> void:
	var p := get_node_or_null("/root/Main/Player")
	if p == null or not p.has_method("receive_swing"):
		return
	var rel: Vector3 = p.global_position - global_position
	rel.y = 0.0
	if rel.length() > ARC_RANGE:
		return
	var fwd: Vector3 = -global_transform.basis.z
	if fwd.dot(rel.normalized()) < ARC_COS:
		return
	p.receive_swing()


func stagger() -> void:
	go("stagger")


func alive() -> bool:
	return state != "dead"


func take_damage(amount: float) -> void:
	if state == "dead":
		return
	hp -= amount
	flash = 0.12
	if hp <= 0.0:
		hp = 0.0
		go("dead")


func _update_bar() -> void:
	var hud := get_node_or_null("/root/Main/HUD/HudRoot")
	if hud != null and hud.has_method("set_boss"):
		hud.set_boss(hp / max_hp)
