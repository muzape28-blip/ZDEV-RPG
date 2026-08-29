extends Node3D

# HUMAN_FEMALE_WARRIOR v3 — Integrasi 3D Skeletal Mesh & Animasi (In-Place 30 FPS)
# Memuat aset GLTF character (Idle, Walking, Running, Sprint)
# Menghubungkan kecepatan joystick ke AnimationTree (BlendSpace1D) / AnimationPlayer

var anim_player: AnimationPlayer
var model_node: Node3D
var current_anim := "Idle"
var one_shot_active := false
var one_shot_t := 0.0  # v7 watchdog anti-stuck-ngangkang


# dipanggil player_controller saat dodge berarah
func play_one_shot(anim: String) -> void:
	if anim_player != null and anim != "" and anim_player.has_animation(anim):
		anim_player.play(anim, 0.08)
		one_shot_active = true
		one_shot_t = 0.0


func _ready() -> void:
	_load_and_setup_character()


# Prioritas karakter: Arissa (Mixamo, HP user) > sintetis Jules (glTF).
# Animasi tambahan dijahit dari FBX Mixamo rig sama (path tulang identik).
const CHAR_PATHS: Array = [
	"res://ASSETS/ARRISA/Standing Idle 02.fbx",
	"res://ASSETS/mixamo/sample_female_warrior.gltf",
	"res://ASSETS/mixamo/Idle.gltf",
]
const ANIM_SOURCES: Array = [
	["res://ASSETS/ARRISA/Catwalk Walking.fbx", "Walking", true],
	["res://ASSETS/ARRISA/Fast Run.fbx", "Running", true],
	["res://ASSETS/ARRISA/Standing Dodge Left.fbx", "DodgeLeft", false],
	["res://ASSETS/ARRISA/Standing Dodge Right.fbx", "DodgeRight", false],
	["res://ASSETS/ARRISA/Standing Dodge Backward.fbx", "DodgeBack", false],
	["res://ASSETS/ARRISA/Standing Dodge Forward.fbx", "DodgeForward", false],
	# v5 STRAFE HYBRID: jalan menyamping/mundur (nama file persis, "right" kecil)
	["res://ASSETS/ARRISA/Standing Walk Left.fbx", "WalkLeft", true],
	["res://ASSETS/ARRISA/Standing Walk right.fbx", "WalkRight", true],
	["res://ASSETS/ARRISA/Standing Walk Back.fbx", "WalkBack", true],
]


func _load_and_setup_character() -> void:
	var char_scene: PackedScene = null
	var char_path_used := ""
	for p in CHAR_PATHS:
		if ResourceLoader.exists(p):
			char_scene = load(p) as PackedScene
			if char_scene != null:
				char_path_used = p
				break
	if char_scene == null:
		return
	var inst := char_scene.instantiate()
	inst.scale = inst.scale * 1.1  # Arissa menjulang (permintaan UAT)
	add_child(inst)
	model_node = inst
	_hide_cloak(inst)  # v5: jubah "tempurung" OFF (Cloak_Geo node terpisah)
	if char_path_used.findn("arissa") != -1:
		_attach_hair()  # v7: rambut Sketchfab (CC-BY Marc Sawyer)
	anim_player = _find_animation_player(inst)
	if anim_player == null:
		return
	var lib := anim_player.get_animation_library("")
	if lib == null:
		return

	# normalisasi animasi bawaan jadi "Idle"
	# (Godot 4: remove/add hidup di AnimationLibrary, bukan AnimationPlayer —
	#  pelajaran CI merah dua run beruntun)
	var names: Array = anim_player.get_animation_list()
	var first := true
	for n in names:
		if first:
			if String(n) != "Idle":
				var a := anim_player.get_animation(n)
				lib.remove_animation(n)
				lib.add_animation("Idle", a)
			first = false
		else:
			lib.remove_animation(n)

	# jahit Walking/Running dari FBX lain dengan rig Mixamo yang sama
	for src in ANIM_SOURCES:
		var path: String = src[0]
		var alias: String = src[1]
		var loop_it: bool = src[2]
		if not ResourceLoader.exists(path):
			continue
		var sc := load(path) as PackedScene
		if sc == null:
			continue
		var tmp := sc.instantiate()
		var tp := _find_animation_player(tmp)
		if tp != null:
			var tl: Array = tp.get_animation_list()
			if tl.size() > 0 and not lib.has_animation(alias):
				var an := tp.get_animation(tl[0])
				an.loop_mode = Animation.LOOP_LINEAR if loop_it else Animation.LOOP_NONE
				lib.add_animation(alias, an)
		tmp.free()

	# pastikan locomotion loop (pelajaran UAT: anim beku setelah 3-4 langkah)
	for nm in ["Idle", "Walking", "Running"]:
		if lib.has_animation(nm):
			lib.get_animation(nm).loop_mode = Animation.LOOP_LINEAR

	# v5: strip translasi horizontal Hips di SEMUA anim jahitan = fix bug
	# "char geser balik seakan recenter" pasca-dodge (klip dodge Mixamo bawa
	# root-motion samping; badan udah meluncur lewat kode => gerak dobel,
	# lalu tulang balik nol => snap). Kalau klip emang in-place, strip no-op.
	for nm2 in anim_player.get_animation_list():
		_strip_hips_xz(anim_player.get_animation(nm2))

	if anim_player.has_animation("Idle"):
		anim_player.play("Idle")


# v7: pasang rambut ponytail Sketchfab (CC-BY Marc Sawyer) ke kepala.
# Dihitung dari AABB OBJ (terverifikasi lokal — importer OBJ tersedia):
# satuan OBJ = 10x meter => skala 0.1; crown lokal y~+0.08 => origin y 1.78
# (puncak kepala Arissa 1.1x ~1.87). Ponytail menjuntai -Y = punggung bila
# konvensi hadap +Z (back OBJ = -Z, sama dgn konvensi kita) => z 0.
# Hair.mtl BELUM di-push user => material deterministik dari kode (v1).
# Parent = proxy (tak berskala, ikut konform tanah), bukan bone Head:
# v1 — rotasi bone kepala di set locomotion kecil; upgrade bila perlu.
const HAIR_PATH := "res://ASSETS/ARRISA/Hair.obj"
const HAIR_SCALE := 0.1
const HAIR_Y := 1.78
const HAIR_Z := 0.0  # tuning depan/belakang setelah screenshot UAT pertama


func _attach_hair() -> void:
	if not ResourceLoader.exists(HAIR_PATH):
		return
	var hs := load(HAIR_PATH) as PackedScene
	if hs == null:
		return
	var hi := hs.instantiate()
	var mi: MeshInstance3D = null
	if hi is MeshInstance3D:
		mi = hi as MeshInstance3D
	else:
		mi = _find_mesh(hi)
	if mi == null or mi.mesh == null:
		hi.free()
		return
	# material deterministik: Hair = coklat gelap, Dummy (scalp) = kulit
	for i in range(mi.mesh.get_surface_count()):
		var sm := StandardMaterial3D.new()
		sm.roughness = 0.9
		if String(mi.mesh.surface_get_name(i)).findn("dummy") != -1:
			sm.albedo_color = Color(0.55, 0.40, 0.30)
		else:
			sm.albedo_color = Color(0.09, 0.06, 0.04)
		mi.set_surface_override_material(i, sm)
	hi.scale = Vector3(HAIR_SCALE, HAIR_SCALE, HAIR_SCALE)
	hi.position = Vector3(0.0, HAIR_Y, HAIR_Z)
	add_child(hi)


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var f := _find_mesh(child)
		if f != null:
			return f
	return null


# v5: sembunyikan mesh jubah (node terpisah "Cloak_Geo" di FBX Arissa).
# visible=false (bukan free) biar skin/bone refs aman.
func _hide_cloak(root: Node) -> void:
	for n in root.get_children():
		_hide_cloak(n)
	if root.name.findn("cloak") != -1 and root is MeshInstance3D:
		(root as MeshInstance3D).visible = false


# v5: nolkan translasi X/Z track Hips (biar Y: bob/ngangkang tetap hidup).
func _strip_hips_xz(an: Animation) -> void:
	if an == null:
		return
	for ti in range(an.get_track_count()):
		# API resmi 4.7: TYPE_POSITION_3D (TRACK_POSITION = alias deprecated
		# yang cuma ada di build lokal — pelajaran CI #6)
		if an.track_get_type(ti) != Animation.TYPE_POSITION_3D:
			continue
		if str(an.track_get_path(ti)).find("Hips") == -1:
			continue
		for ki in range(an.track_get_key_count(ti)):
			var kv = an.track_get_key_value(ti, ki)
			if kv is Vector3:
				an.track_set_key_value(ti, ki, Vector3(0.0, kv.y, 0.0))


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _physics_process(dt: float) -> void:
	var p: Node = get_parent()
	if p == null:
		return
	var vel: Vector3 = p.velocity
	var speed: float = Vector2(vel.x, vel.z).length()
	var ratio: float = clampf(speed / 6.0, 0.0, 1.0)

	# Pilih animasi berdasar kecepatan gerak
	var target_anim := "Idle"
	if speed > 4.5:
		target_anim = "Sprint"
	elif speed > 2.5:
		target_anim = "Running"
	elif speed > 0.15:
		target_anim = "Walking"
	if anim_player != null and target_anim == "Sprint" and not anim_player.has_animation("Sprint"):
		target_anim = "Running"  # fallback: sprint = run + speed_scale tinggi

	# v5 STRAFE HYBRID: band jalan + arah samping/belakang (dihitung di
	# player_controller) => Standing Walk Left/right/Back.
	var sa = p.get("strafe_anim")
	if target_anim == "Walking" and sa != null and String(sa) != "":
		if anim_player != null and anim_player.has_animation(String(sa)):
			target_anim = String(sa)

	# one-shot (dodge): jangan ditimpa switching sampai selesai.
	# v7 ANTI-STUCK-NGANGKANG berlapis: (1) clear saat anim berakhir,
	# (2) watchdog 2.5 dtk paksa clear bila state nyangkut di device jank.
	var skip_switch := false
	if one_shot_active:
		one_shot_t += dt
		if anim_player != null and anim_player.is_playing() and one_shot_t < 2.5:
			skip_switch = true
		else:
			one_shot_active = false

	if anim_player != null and not skip_switch:
		# stride match: playback ikut kecepatan biar kaki nggak seluncur
		anim_player.speed_scale = clampf(lerp(0.9, 1.35, ratio), 0.5, 1.6)
		if anim_player.has_animation(target_anim):
			if current_anim != target_anim:
				current_anim = target_anim
				anim_player.play(target_anim, 0.2) # Blend 0.2s
		elif anim_player.has_animation("Idle") and current_anim != "Idle":
			current_anim = "Idle"
			anim_player.play("Idle", 0.2)

	# ---- KONFORM TANAH SABANA ----
	var ter := get_node_or_null("/root/Main/Terrain")
	if ter != null and ter.has_method("get_height_at"):
		var g: Vector3 = p.global_position
		var fwd: Vector3 = -p.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() > 0.01:
			fwd = fwd.normalized()
		else:
			fwd = Vector3(0.0, 0.0, -1.0)
		var right: Vector3 = Vector3(-fwd.z, 0.0, fwd.x)
		var h_c: float = ter.get_height_at(g.x, g.z)
		var h_f: float = ter.get_height_at(g.x + fwd.x * 0.6, g.z + fwd.z * 0.6)
		var h_r: float = ter.get_height_at(g.x + right.x * 0.6, g.z + right.z * 0.6)
		position.y = lerp(position.y, h_c, 12.0 * dt)
		rotation.x = lerp(rotation.x, clampf((h_c - h_f) * 0.15, -0.12, 0.12), 8.0 * dt)
		rotation.z = lerp(rotation.z, clampf((h_r - h_c) * 0.15, -0.12, 0.12), 8.0 * dt)
