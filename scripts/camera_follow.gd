extends Node3D

# PIVOT kamera (child of Player). Follow GRATIS lewat parenting —
# walaupun script ini mati, kamera tetap nempel player (UAT #2 lesson).
# Script ini hanya: look_at halus + getter yaw. Drag di-set hud.gd via _input.
var target: Node3D = null


func _ready() -> void:
	target = get_parent() as Node3D


func get_yaw() -> float:
	return rotation.y


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	var cam := get_node_or_null("Camera3D")
	if cam is Camera3D:
		cam.look_at(target.global_position + Vector3(0.0, 1.55, 0.0), Vector3.UP)
