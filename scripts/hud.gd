extends Control

# HUD kontrak M0 + PEMEGANG semua input layar (kanal _input = terbukti jalan
# di device; joystick jadi buktinya). Drag kanan = orbit kamera, diputar
# lewat pivot, BUKAN lewat _unhandled_input (kanal yang terbukti tidak
# konsisten di export Android — r/godot gabdb9).
const BAR_HEIGHT := 6.0
const CAM_SENS := 0.006
const CAM_PITCH_SENS := 0.004
const PITCH_MIN := -0.5
const PITCH_MAX := 0.3

var player: Node = null
var pivot: Node = null
var fps_label: Label
var boss_fg: ColorRect
var player_fg: ColorRect
var button_rects: Array[Rect2] = []

var cam_drag_id := -1
var cam_last_x := 0.0
var cam_last_y := 0.0
var cam_pitch := 0.0
var _fps_acc := 0.0

# Chip toggle DEBUG (sementara, kiri-atas = zona mati jempol).
# Menu gear beneran = fase polish (non-goal sekarang).
var shadow_on := true
var grass_density := 1
var chip_shadow_lbl: Label = null
var chip_grass_lbl: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = get_node_or_null("/root/Main/Player")
	pivot = get_node_or_null("/root/Main/Player/CameraPivot")

	var vp := get_viewport().get_visible_rect().size
	var bar_w := minf(vp.x * 0.62, 760.0)
	var x0 := (vp.x - bar_w) / 2.0

	_rect(Color(0.0, 0.0, 0.0, 0.55), Rect2(x0, 16, bar_w, BAR_HEIGHT))
	boss_fg = _rect(Color(0.78, 0.12, 0.12, 0.95), Rect2(x0, 16, bar_w, BAR_HEIGHT))
	_rect(Color(0.0, 0.0, 0.0, 0.55), Rect2(x0, 26, bar_w, BAR_HEIGHT))
	player_fg = _rect(Color(0.78, 0.92, 0.78, 0.95), Rect2(x0, 26, bar_w, BAR_HEIGHT))

	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.position = Vector2(vp.x - 130.0, 40.0)
	fps_label.size = Vector2(120.0, 20.0)
	fps_label.text = "FPS --"
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fps_label)

	_build_chips()

	var joystick := Control.new()
	joystick.set_script(load("res://scripts/floating_joystick.gd"))
	joystick.anchor_right = 0.5
	joystick.anchor_bottom = 1.0
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(joystick)
	joystick.moved.connect(_on_move)

	var atk := _make_button(0)
	atk.action_pressed.connect(_on_attack)
	var dodge := _make_button(1)
	dodge.action_pressed.connect(_on_dodge)


func _rect(col: Color, r: Rect2) -> ColorRect:
	var cr := ColorRect.new()
	cr.color = col
	cr.position = r.position
	cr.size = r.size
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cr)
	return cr


func _make_button(slot: int) -> Control:
	var b := Control.new()
	b.set_script(load("res://scripts/ui_button.gd"))
	var r := 46.0 if slot == 0 else 38.0
	b.glyph = 0 if slot == 0 else 1
	b.radius = r
	var vp := get_viewport().get_visible_rect().size
	var x := vp.x - (r * 2.0 + 24.0) if slot == 0 else vp.x - (r * 2.0 + 24.0 + 100.0)
	var y := vp.y - (r * 2.0 + 34.0) if slot == 0 else vp.y - (r * 2.0 + 48.0)
	b.position = Vector2(x, y)
	b.size = Vector2(r * 2.0, r * 2.0)
	button_rects.append(Rect2(x - 12.0, y - 12.0, r * 2.0 + 24.0, r * 2.0 + 24.0))
	add_child(b)
	return b


func _build_chips() -> void:
	chip_shadow_lbl = _chip("BAY:ON", Vector2(40.0, 126.0))
	chip_shadow_lbl.gui_input.connect(_on_chip_shadow)
	chip_grass_lbl = _chip("RPT:JRG", Vector2(40.0, 174.0))
	chip_grass_lbl.gui_input.connect(_on_chip_grass)


func _chip(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5, 0.9))
	l.position = pos
	l.size = Vector2(120.0, 44.0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l


func _chip_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false


func _on_chip_shadow(event: InputEvent) -> void:
	if not _chip_pressed(event):
		return
	shadow_on = not shadow_on
	var sun := get_node_or_null("/root/Main/Sun")
	if sun != null:
		sun.shadow_enabled = shadow_on
	chip_shadow_lbl.text = "BAY:ON" if shadow_on else "BAY:OFF"


func _on_chip_grass(event: InputEvent) -> void:
	if not _chip_pressed(event):
		return
	grass_density = (grass_density + 1) % 3
	var g := get_node_or_null("/root/Main/Grass")
	if g != null and g.has_method("rebuild"):
		g.rebuild(grass_density)
	var nama := ["RPT:OFF", "RPT:JRG", "RPT:SDG"]
	chip_grass_lbl.text = nama[grass_density]


# ---- INPUT LAYAR: satu pintu, kanal terbukti ----
func _input(event: InputEvent) -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	if event is InputEventScreenTouch:
		if event.pressed:
			if _over_button(event.position):
				return  # biar tombol yang urus
			if cam_drag_id == -1 and event.position.x > vp_w * 0.5:
				cam_drag_id = event.index
				cam_last_x = event.position.x
				cam_last_y = event.position.y
		elif event.index == cam_drag_id:
			cam_drag_id = -1
	elif event is InputEventScreenDrag and event.index == cam_drag_id:
		var drag := event as InputEventScreenDrag
		var dx := drag.position.x - cam_last_x
		var dy := drag.position.y - cam_last_y
		cam_last_x = drag.position.x
		cam_last_y = drag.position.y
		if pivot != null:
			pivot.rotation.y -= dx * CAM_SENS
			# pitch: drag vertikal, clamp aman (tidak tembus tanah / tidak
			# top-down ekstrem). UAT #4: kamera baru 70% (yaw saja).
			cam_pitch = clampf(cam_pitch + dy * CAM_PITCH_SENS, PITCH_MIN, PITCH_MAX)
			pivot.rotation.x = cam_pitch


func _over_button(p: Vector2) -> bool:
	for r in button_rects:
		if r.has_point(p):
			return true
	return false


func _on_move(v: Vector2) -> void:
	if player:
		player.set_move_input(v)


func _on_attack() -> void:
	if player:
		player.request_attack()


func _on_dodge() -> void:
	if player:
		player.request_dodge()


func _process(delta: float) -> void:
	_fps_acc += delta
	if _fps_acc >= 0.25:
		_fps_acc = 0.0
		fps_label.text = "FPS %d" % Engine.get_frames_per_second()
