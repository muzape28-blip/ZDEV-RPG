extends Node3D

# Cap frame rate global. Target M0: 45 FPS (lantai 30, keputusan final di UAT #1).
func _ready() -> void:
	Engine.max_fps = 45
