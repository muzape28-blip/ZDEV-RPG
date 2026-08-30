extends Control

# Floating joystick: muncul di titik sentuh (kiri layar), pudar saat idle.
# Hint ring tipis (~12% alpha) tetap ada demi discoverability (AGENTS.md §12).
signal moved(vector: Vector2)

# v9: travel DIPERLUAS (78→105) biar gradasi walk↔run punya ruang;
# dead-zone 0.08 anti-jitter; skin AAA prosedural (cincin tipis translucent,
# knob gradient, arc arah aktif) — nol tekstur, nol lisensi, ringan di GPU.
const RADIUS := 105.0
const DEAD := 0.08
const HINT_X := 160.0
const HINT_BOTTOM_MARGIN := 200.0

var active_id := -1
var origin := Vector2.ZERO
var vec := Vector2.ZERO
var pressed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _hint_origin() -> Vector2:
	return Vector2(HINT_X, size.y - HINT_BOTTOM_MARGIN)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_id == -1 and _in_zone(event.position):
			active_id = event.index
			pressed = true
			origin = event.position
			vec = Vector2.ZERO
			moved.emit(vec)
			queue_redraw()
		elif not event.pressed and event.index == active_id:
			_release()
	elif event is InputEventScreenDrag and event.index == active_id:
		vec = (event.position - origin) / RADIUS
		vec = vec.limit_length(1.0)
		# v9 dead-zone radial: noise jempol nggak kebaca gerak
		var out := vec if vec.length() > DEAD else Vector2.ZERO
		moved.emit(out)
		queue_redraw()


func _in_zone(p: Vector2) -> bool:
	return p.x < size.x and p.y > 0.0


func _release() -> void:
	active_id = -1
	pressed = false
	vec = Vector2.ZERO
	moved.emit(vec)
	queue_redraw()


# Dipanggil HUD saat app kehilangan fokus: touch-release bisa hilang
# saat pause => stick nyangkut (bug ghost-input Android). [moonlight #1536]
func release_all() -> void:
	if pressed:
		_release()


func _draw() -> void:
	if not pressed:
		origin = _hint_origin()
	# v9 skin AAA: cincin tipis translucent + isi sangat pudar + knob dua lapis
	var ring_a := 0.32 if pressed else 0.14
	var fill_a := 0.10 if pressed else 0.04
	var knob_a := 0.75 if pressed else 0.22
	draw_circle(origin, RADIUS, Color(1.0, 1.0, 1.0, fill_a))
	draw_arc(origin, RADIUS, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, ring_a), 2.0)
	# arc highlight arah aktif (feedback gradasi walk↔run kebaca mata)
	if pressed and vec.length() > DEAD:
		var ang := atan2(vec.y, vec.x)
		draw_arc(origin, RADIUS - 5.0, ang - 0.45, ang + 0.45, 12,
			Color(1.0, 1.0, 1.0, clampf(vec.length(), 0.0, 1.0) * 0.55), 4.0)
	# knob: halo lembut + inti
	var kp := origin + vec * RADIUS
	draw_circle(kp, 34.0, Color(1.0, 1.0, 1.0, knob_a * 0.35))
	draw_circle(kp, 26.0, Color(1.0, 1.0, 1.0, knob_a))
