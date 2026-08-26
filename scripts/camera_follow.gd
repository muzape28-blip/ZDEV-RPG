extends Camera3D

# Kamera aksi third-person: offset tetap di belakang player, lerp halus.
@export var offset := Vector3(0.0, 4.6, 6.8)
@export var look_height := 1.5
@export var follow_speed := 10.0

var target: Node3D = null


func _ready() -> void:
	target = get_node("/root/Main/Player")


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0.0, look_height, 0.0), Vector3.UP)
