extends Node3D

# M0: cap FPS + DIAGNOSTIK HUD (UAT #6): blackbox layar untuk device,
# karena kita tidak punya logcat. Node ini terpisah dari hud.gd sehingga
# tetap hidup walau hud mati.
func _ready() -> void:
	Engine.max_fps = 45
	_diag_hud()
	_setup_sun_sky()


# Matahari sky-shader terkunci ke arah DirectionalLight:
# langit + cahaya = satu sumber kebenaran. [sky shader sun disc]
func _setup_sun_sky() -> void:
	var we := get_node_or_null("WorldEnvironment")
	var sun := get_node_or_null("Sun")
	if we == null or sun == null:
		return
	var env := we.environment
	if env == null or env.sky == null:
		return
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/sky_sun.gdshader")
	env.sky.material = sm
	sm.set_shader_parameter("sun_dir", sun.global_transform.basis.z)


# ---- kontrol waktu: hitstop & slow-mo (real-time, tak terpengaruh scale) ----
var hitstop_until := 0
var slowmo_until := 0
var _tel_acc := 0.0


func hitstop(ms: int) -> void:
	hitstop_until = Time.get_ticks_msec() + ms


func slowmo(ms: int) -> void:
	slowmo_until = Time.get_ticks_msec() + ms


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now < hitstop_until:
		Engine.time_scale = 0.0
	elif now < slowmo_until:
		Engine.time_scale = 0.3
	else:
		Engine.time_scale = 1.0

	# TELEMETRI: print state tiap 0.5 s => logcat CI = ground truth
	_tel_acc += delta
	if _tel_acc >= 0.5:
		_tel_acc = 0.0
		var p := get_node_or_null("Player")
		var pv := get_node_or_null("Player/CameraPivot")
		if p != null and pv != null:
			var v: Vector3 = p.velocity
			print("TEL stick=(%.2f,%.2f) vel=(%.2f,%.2f) face=%.2f camY=%.2f camP=%.2f dist=%.2f" % [
				p.move_input.x, p.move_input.y, v.x, v.z,
				p.rotation.y, pv.rotation.y, pv.rotation.x, pv.dist])


func _diag_hud() -> void:
	var scr = load("res://scripts/hud.gd")
	var hud_root := get_node_or_null("HUD/HudRoot")
	var n_child := hud_root.get_child_count() if hud_root != null else -1
	var pivot := get_node_or_null("Player/CameraPivot")
	var lay := CanvasLayer.new()
	var lbl := Label.new()
	lbl.text = "DIAG hud=%s anak=%d pivot=%s" % [
		str(scr != null), n_child, str(pivot != null)]
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	lbl.position = Vector2(40.0, 90.0)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(lbl)
	add_child(lay)
# trigger eye
