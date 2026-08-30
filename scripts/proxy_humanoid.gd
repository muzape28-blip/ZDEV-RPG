extends Node3D

# HUMAN_FEMALE_WARRIOR v3 — Integrasi 3D Skeletal Mesh & Animasi (In-Place 30 FPS)
# Memuat aset GLTF character (Idle, Walking, Running, Sprint)
# Menghubungkan kecepatan joystick ke AnimationTree (BlendSpace1D) / AnimationPlayer

const CLOAK_ON := false  # v10 saklar: jubah + kibar (OFF dulu utk UAT rambut+tekstur)
const HAIR_ON := true    # v10 saklar: rambut bertekstur

var anim_player: AnimationPlayer
var model_node: Node3D
var current_anim := "Idle"
var one_shot_active := false
var one_shot_t := 0.0  # v7 watchdog anti-stuck-ngangkang
var fallback_node: Node3D = null
var fallback_dodge_t := 0.0
var fallback_dodge_sign := 1.0


# dipanggil player_controller saat dodge berarah
func play_one_shot(anim: String) -> void:
	# v9: FREEZE locomotion dipisah dari ketersediaan anim — walau klip
	# absen, switching tetap beku selama dodge (anti-"skateboard").
	one_shot_active = true
	one_shot_t = 0.0
	if anim_player != null and anim != "" and anim_player.has_animation(anim):
		anim_player.play(anim, 0.08)
		current_anim = anim  # v9: rantai state eksplisit => blend keluar mulus
	if fallback_node != null:
		fallback_dodge_t = 0.22
		fallback_dodge_sign = -1.0 if anim.contains("Left") else 1.0


func _ready() -> void:
	_load_and_setup_character()


func _build_fallback_humanoid() -> void:
	if fallback_node != null:
		return
	fallback_node = Node3D.new()
	fallback_node.name = "FallbackHumanoid"
	add_child(fallback_node)
	var skin := StandardMaterial3D.new()
	skin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skin.albedo_color = Color(0.74, 0.46, 0.30)
	var cloth := StandardMaterial3D.new()
	cloth.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloth.albedo_color = Color(0.08, 0.16, 0.25)
	var metal := StandardMaterial3D.new()
	metal.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	metal.albedo_color = Color(0.45, 0.56, 0.64)
	_add_fallback_capsule("Body", Vector3(0.34, 0.72, 0.22), Vector3(0.0, 1.05, 0.0), cloth)
	_add_fallback_capsule("Head", Vector3(0.23, 0.28, 0.23), Vector3(0.0, 1.92, 0.0), skin)
	_add_fallback_capsule("LeftArm", Vector3(0.10, 0.52, 0.10), Vector3(-0.42, 1.10, 0.0), cloth)
	_add_fallback_capsule("RightArm", Vector3(0.10, 0.52, 0.10), Vector3(0.42, 1.10, 0.0), cloth)
	_add_fallback_capsule("LeftLeg", Vector3(0.12, 0.58, 0.12), Vector3(-0.16, 0.42, 0.0), metal)
	_add_fallback_capsule("RightLeg", Vector3(0.12, 0.58, 0.12), Vector3(0.16, 0.42, 0.0), metal)
	_add_fallback_capsule("Blade", Vector3(0.035, 0.52, 0.035), Vector3(0.62, 1.25, -0.10), metal)


func _add_fallback_capsule(part_name: String, dimensions: Vector3, at: Vector3, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = part_name
	var capsule := CapsuleMesh.new()
	capsule.radius = dimensions.x
	capsule.height = dimensions.y * 2.0
	capsule.material = material
	mesh_node.mesh = capsule
	mesh_node.position = at
	mesh_node.scale.z = dimensions.z / maxf(dimensions.x, 0.001)
	fallback_node.add_child(mesh_node)


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
	["res://ASSETS/ARRISA/Standing Dodge Forward.fbx", "DodgeForward", false],  # v9: file naik, slot hidup
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
		_build_fallback_humanoid()
		return
	var inst := char_scene.instantiate()
	inst.scale = inst.scale * 1.1  # Arissa menjulang (permintaan UAT)
	add_child(inst)
	model_node = inst
	# v10: saklar kepala — hood jubah vs rambut. Jubah OFF = mesh Cloak
	# disembunyikan (biar rambut kelihatan); ON = kibar spring-bone.
	if CLOAK_ON:
		_setup_cloak(inst)
	else:
		_hide_cloak(inst)
	if HAIR_ON and char_path_used.findn("arissa") != -1:
		_attach_hair()  # v7: rambut Sketchfab (CC-BY Marc Sawyer)
	anim_player = _find_animation_player(inst)
	if anim_player == null:
		_build_fallback_humanoid()
		return
	var lib := anim_player.get_animation_library("")
	if lib == null:
		_build_fallback_humanoid()
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
	# material: Hair = tekstur diffuse asli (CC-BY Marc Sawyer) bila ada,
	# fallback coklat gelap; Dummy (scalp) = warna kulit.
	var hair_tex: Texture2D = null
	var ht := load("res://ASSETS/ARRISA/Hair_Diffuse_Map.png")
	if ht != null:
		hair_tex = ht as Texture2D
	for i in range(mi.mesh.get_surface_count()):
		var sm := StandardMaterial3D.new()
		sm.roughness = 0.9
		if String(mi.mesh.surface_get_name(i)).findn("dummy") != -1:
			sm.albedo_color = Color(0.55, 0.40, 0.30)
		elif hair_tex != null:
			sm.albedo_texture = hair_tex
			sm.uv1_scale = Vector3(1.0, 1.0, 1.0)
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


# Sembunyikan mesh jubah (node "Cloak_Geo" di FBX Arissa) saat CLOAK_ON=false.
# visible=false (bukan free) biar skin/bone refs aman.
func _hide_cloak(root: Node) -> void:
	for n in root.get_children():
		_hide_cloak(n)
	if root.name.findn("cloak") != -1 and root is MeshInstance3D:
		(root as MeshInstance3D).visible = false


# v10 JUBAH KIBAR — spring-bone lite teredam di rantai mixamorig:Cloak1..7
# (riset_fisika_jubah_cape_mobile.md §2.2: pendekatan B = standar mobile;
#  Verlet penuh = upgrade path). Root 100% ikut anim; anak di-simulasi:
#  angin = -velocity (ruang model) + sway idle; pitch/roll di-clamp;
#  gain membesar ke ujung (ujung paling liar). Dodge arah mana pun =>
#  whip-lag simetris (Verlet peduli perubahan posisi, bukan arah).
var skel_cloak: Skeleton3D = null
var cloak_ids: Array = []
var cloak_rest: Array = []
var cloak_pitch: Array = []
var cloak_roll: Array = []
var cloak_t := 0.0

const CAPE_PITCH_K := 0.05
const CAPE_ROLL_K := 0.035
const CAPE_MAX_P := 0.4
const CAPE_MAX_R := 0.3


func _setup_cloak(root: Node) -> void:
	skel_cloak = _find_skeleton(root)
	if skel_cloak == null:
		return
	for i in range(1, 9):
		var idx := skel_cloak.find_bone("mixamorig:Cloak%d" % i)
		if idx == -1:
			continue
		cloak_ids.append(idx)
		cloak_rest.append(skel_cloak.get_bone_pose_rotation(idx))
		cloak_pitch.append(0.0)
		cloak_roll.append(0.0)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var f := _find_skeleton(child)
		if f != null:
			return f
	return null


func _tick_cloak(dt: float) -> void:
	if skel_cloak == null or cloak_ids.is_empty() or model_node == null:
		return
	var p := get_parent()
	if p == null:
		return
	cloak_t += dt
	var vel: Vector3 = p.velocity
	# angin relatif: kebalikan velocity char, di ruang model
	var wind: Vector3 = model_node.global_transform.basis.inverse() * Vector3(vel.x, 0.0, vel.z) * -1.0
	for n in range(cloak_ids.size()):
		var gain := 1.0 + float(n) * 0.4
		var tp := clampf(wind.z * CAPE_PITCH_K * gain + sin(cloak_t * 2.1 + float(n) * 0.7) * 0.03, -CAPE_MAX_P, CAPE_MAX_P)
		var tr := clampf(wind.x * CAPE_ROLL_K * gain + cos(cloak_t * 1.7 + float(n)) * 0.02, -CAPE_MAX_R, CAPE_MAX_R)
		cloak_pitch[n] = lerpf(cloak_pitch[n], tp, clampf(10.0 * dt, 0.0, 1.0))
		cloak_roll[n] = lerpf(cloak_roll[n], tr, clampf(10.0 * dt, 0.0, 1.0))
		var q: Quaternion = cloak_rest[n] * Quaternion(Vector3(1.0, 0.0, 0.0), cloak_pitch[n]) * Quaternion(Vector3(0.0, 0.0, 1.0), cloak_roll[n])
		skel_cloak.set_bone_pose_rotation(cloak_ids[n], q)


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
		# Player sudah ditempatkan physics di permukaan; proxy hanya perlu
		# offset lokal relatif terhadap body, bukan tinggi dunia mentah.
		var local_ground_offset: float = h_c - p.global_position.y
		position.y = lerp(position.y, local_ground_offset, 12.0 * dt)

		rotation.x = lerp(rotation.x, clampf((h_c - h_f) * 0.15, -0.12, 0.12), 8.0 * dt)
		rotation.z = lerp(rotation.z, clampf((h_r - h_c) * 0.15, -0.12, 0.12), 8.0 * dt)

	_tick_cloak(dt)  # v10: jubah kibar tiap frame fisika
