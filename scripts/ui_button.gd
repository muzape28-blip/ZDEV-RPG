extends Control

# Tombol combat: lingkaran semi-transparan + glyph putih vektor (stabil,
# tidak bergantung emoji/font OEM — AGENTS.md §12).
signal action_pressed

enum Glyph { SWORD, DASH }

@export var glyph: Glyph = Glyph.SWORD
@export var radius := 44.0

var pressed := false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not pressed:
			pressed = true
			action_pressed.emit()
			queue_redraw()
		elif not event.pressed:
			pressed = false
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed and not pressed:
			pressed = true
			action_pressed.emit()
			queue_redraw()
		elif not event.pressed:
			pressed = false
			queue_redraw()


func _draw() -> void:
	var c := get_rect().size / 2.0
	var bg_alpha := 0.35 if pressed else 0.20
	draw_circle(c, radius, Color(0.05, 0.05, 0.08, bg_alpha + 0.15))
	draw_arc(c, radius, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.55 if pressed else 0.30), 3.0)
	var g := Color(1.0, 1.0, 1.0, 0.9)
	match glyph:
		Glyph.SWORD:
			# bilah + crossguard sederhana
			draw_line(c + Vector2(-14, 14), c + Vector2(10, -10), g, 4.0)
			draw_line(c + Vector2(-2, -8), c + Vector2(8, 2), g, 4.0)
		Glyph.DASH:
			# chevron ganda = dash
			draw_line(c + Vector2(-14, -10), c + Vector2(0, 0), g, 4.0)
			draw_line(c + Vector2(0, 0), c + Vector2(-14, 10), g, 4.0)
			draw_line(c + Vector2(0, -10), c + Vector2(14, 0), g, 4.0)
			draw_line(c + Vector2(14, 0), c + Vector2(0, 10), g, 4.0)
