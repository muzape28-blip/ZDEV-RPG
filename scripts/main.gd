extends Node3D

# M0: cap FPS + DIAGNOSTIK HUD (UAT #6): blackbox layar untuk device,
# karena kita tidak punya logcat. Node ini terpisah dari hud.gd sehingga
# tetap hidup walau hud mati.
func _ready() -> void:
	Engine.max_fps = 45
	_diag_hud()


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
