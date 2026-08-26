extends Camera3D

# Kamera aksi third-person + ORBIT: drag di setengah kanan layar memutar yaw.
# (Setengah kiri = zona joystick; tombol menyerap sentuhannya sendiri.)
@export var distance := 8.2
@export var height := 4.6
@export var follow_speed := 10.0
@export var yaw_sensitivity := 0.006

var yaw := 0.0
var target: Node3D = null
var drag_id := -1
var last_x := 0.0


func _ready() -> void:
	target = get_node("/root/Main/Player")


func get_yaw() -> float:
	return yaw


func _unhandled_input(event: InputEvent) -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	if event is InputEventScreenTouch:
		if event.pressed and drag_id == -1 and event.position.x > vp_w * 0.5:
			drag_id = event.index
			last_x = event.position.x
		elif not event.pressed and event.index == drag_id:
			drag_id = -1
	elif event is InputEventScreenDrag and event.index == drag_id:
		var dx := event.position.x - last_x
		last_x = event.position.x
		yaw -= dx * yaw_sensitivity


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var offset := Vector3(sin(yaw), 0.0, cos(yaw)) * distance
	offset.y = height
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0.0, 1.5, 0.0), Vector3.UP)
