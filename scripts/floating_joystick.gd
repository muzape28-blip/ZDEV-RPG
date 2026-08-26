extends Control

# Floating joystick: muncul di titik sentuh (kiri layar), pudar saat idle.
# Hint ring tipis (~12% alpha) tetap ada demi discoverability (AGENTS.md §12).
signal moved(vector: Vector2)

const RADIUS := 78.0
const HINT_X := 150.0
const HINT_BOTTOM_MARGIN := 190.0

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
		moved.emit(vec)
		queue_redraw()


func _in_zone(p: Vector2) -> bool:
	return p.x < size.x and p.y > 0.0


func _release() -> void:
	active_id = -1
	pressed = false
	vec = Vector2.ZERO
	moved.emit(vec)
	queue_redraw()


func _draw() -> void:
	if not pressed:
		origin = _hint_origin()
	var base_alpha := 0.30 if pressed else 0.12
	var knob_alpha := 0.85 if pressed else 0.25
	draw_circle(origin, RADIUS, Color(1.0, 1.0, 1.0, base_alpha * 0.35))
	draw_arc(origin, RADIUS, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, base_alpha), 3.0)
	draw_circle(origin + vec * RADIUS, 26.0, Color(1.0, 1.0, 1.0, knob_alpha))
