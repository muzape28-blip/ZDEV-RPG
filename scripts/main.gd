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
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if we == null or sun == null:
		return
	var env: Environment = we.environment
	if env == null or env.sky == null:
		return
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/sky_sun.gdshader")
	env.sky.sky_material = sm  # API resmi: Sky.sky_material (bukan .material, pelajaran CI #4)
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
			print("TEL stick=(%.2f,%.2f) vel=(%.2f,%.2f) face=%.2f camY=%.2f camP=%.2f extra=%.2f" % [
				p.move_input.x, p.move_input.y, v.x, v.z,
				p.rotation.y, pv.rotation.y, pv.rotation.x, pv.extra])

	# DIAG LIVE v2 on-screen (mata device, pengganti logcat):
	# st = stick (ghost-input?), anim+o = state animasi (stuck-ngangkang?),
	# y/fl = tunneling?, fps = perf. Satu screenshot = ground truth.
	if diag_lbl != null:
		diag_acc += delta
		if diag_acc >= 0.25:
			diag_acc = 0.0
			var y := 0.0
			var fl := 0
			var stx := 0.0
			var sty := 0.0
			var an := ""
			var on := 0
			if diag_player != null:
				y = diag_player.global_position.y
				if diag_player.has_method("is_on_floor") and diag_player.is_on_floor():
					fl = 1
				var mi2 = diag_player.get("move_input")
				if mi2 != null:
					stx = mi2.x
					sty = mi2.y
				var pr := diag_player.get_node_or_null("Proxy")
				if pr != null:
					var ca = pr.get("current_anim")
					if ca != null:
						an = String(ca)
					var oo = pr.get("one_shot_active")
					if oo != null and bool(oo):
						on = 1
			diag_lbl.text = "t=%05.1f y=%.2f fl=%d fps=%d st=(%.1f,%.1f) %s o=%d" % [
				Time.get_ticks_msec() / 1000.0, y, fl, Engine.get_frames_per_second(),
				stx, sty, an, on]


var diag_lbl: Label = null
var diag_player: Node = null
var diag_acc := 0.0


# v5: DIAG LIVE on-screen (mata kita di device, pengganti logcat):
# t=detik-sejak-boot, y=tinggi player, fl=on_floor, fps. Kecil, pojok
# kiri-atas (zona mati jempol), update 4x/detik biar nggak noise.
func _diag_hud() -> void:
	diag_player = get_node_or_null("Player")
	var lay := CanvasLayer.new()
	var lbl := Label.new()
	lbl.text = "DIAG ..."
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	lbl.position = Vector2(12.0, 40.0)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(lbl)
	add_child(lay)
	diag_lbl = lbl


# trigger eye
