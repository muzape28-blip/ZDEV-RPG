# Session Log — 2026-08-28

## Tujuan sesi
Audit dan peningkatan nyata ZDEV-RPG dengan fokus movement, kamera, dodge, medan/shader, dan performa Infinix Smart 9 HD. Status harus dibedakan antara DESIGNED, IMPLEMENTED, LOCALLY VERIFIED, CI VERIFIED, dan DEVICE VERIFIED.

## Baseline repository

| Item | Bukti | Status |
|---|---|---|
| Branch | `arena/01a03ddc-zdev-rpg` | Dikonfirmasi |
| Commit awal | `599144755c8067b6f0b2f968908ea93b0cb1048a` | Dikonfirmasi |
| Engine | Godot 4.7.2, Compatibility / GLES | Dikonfirmasi dari `project.godot` dan docs |
| Target device | Infinix Smart 9 HD, Android 14 Go, armv7/32-bit, 720×1600 | Dikonfirmasi dari UAT log |
| Renderer | `gl_compatibility`, MSAA 3D 0 | Dikonfirmasi dari `project.godot` |
| FPS cap | 45 FPS | Dikonfirmasi dari `main.gd` |
| M0 | 6/6 pernah DEVICE VERIFIED pada UAT #7, FPS 40 baseline | Dikonfirmasi dari `docs/uat/uat-log.md` |
| Workspace awal | clean sebelum audit | Dikonfirmasi `git status --short` |

## Dokumentasi yang dibaca

Semua Markdown yang terdeteksi pada branch dibaca: `AGENTS.md`, `README.md`, `docs/REFERENSI-GLTF.md`, `docs/RENCANA-DEMO-v1.md`, `docs/RENCANA-T123-MEDAN-PROXY.md`, `docs/RESEARCH-OPEN-SOURCE-RPG.md`, `docs/WORKING-AGREEMENT.md`, dan `docs/uat/uat-log.md`.

## Temuan teknis utama

1. Jalur movement produksi berada di `scripts/player_controller.gd`: movement relatif yaw kamera, analog curve `pow(magnitude, 1.25)`, smoothing arah, acceleration, anti-drift, camera-relative dodge, dan dash timer sudah IMPLEMENTED.
2. Jalur input sentuh dan kamera berada di `scripts/hud.gd`: `_input` menangani touch drag kanan, pinch zoom, pengecualian tombol, dan reset focus-out. File ini pernah menjadi sumber parse regression dan merupakan area risiko tinggi.
3. `scripts/camera_follow.gd` memakai pivot sebagai child Player, yaw lokal untuk mencegah feedback spin, pitch/recenter, dan dolly 4–9 m.
4. `scripts/terrain_generator.gd` memiliki scaffolding heightmap, tetapi `amplitude := 0.0`; arena shipped masih flat dan collider aktif berupa Box sederhana.
5. `scripts/arena_spawner.gd` memiliki landmark batu/monolit dan collider, tetapi komentar menyebut pohon dihapus sedangkan `_ready()` masih memanggil `_spawn_trees(rng)` dan fungsi itu masih dapat menambah 12 tree GLB. Ini mismatch source-of-truth yang harus diputuskan berdasarkan target performa/visual.
6. `scripts/proxy_humanoid.gd` memuat Arissa lalu fallback GLTF, menyambung animasi Mixamo, memilih Idle/Walking/Running/Sprint, dan memainkan directional dodge one-shot. Integrasi runtime masih harus diuji pada engine resmi/device.
7. `scripts/main.gd` mengatur hitstop/slowmo global via `Engine.time_scale`, telemetry, DIAG HUD, dan sky shader resmi `Sky.sky_material`.

## Verifikasi baseline

Perintah: `tools/verify-local.sh`.

Hasil parsial:

- Engine headless dirakit dari `tools/parts/gh.*`.
- Parse berhasil untuk: `main`, `player_controller`, `camera_follow`, `hud`, `floating_joystick`, `ui_button`.
- Proses berhenti menghasilkan progres sebelum parse `arena_spawner`, `terrain_generator`, `grass`, `proxy_humanoid` dan tahap boot; setelah lebih dari 6 menit proses dihentikan.
- Kesimpulan: **baseline belum LOCALLY VERIFIED** pada run ini. Ini bukan bukti kode rusak dan bukan bukti hijau; kemungkinan perlu diagnosis timeout/engine/process/import/cache.
- Tidak ada perubahan perilaku game yang dilakukan sebelum diagnosis.

## Error/risko tercatat

- **Timeout/hang verify-local baseline:** proses tidak maju setelah enam parse script. Perlu reproduksi terisolasi dengan timeout per script, pemeriksaan engine process, dan log import.
- **Mismatch arena comment-vs-runtime:** pohon masih dapat dispawn walau komentar menyebut dihapus. Jangan mengubah sebelum menetapkan acceptance criterion performa/komposisi.
- **Gap bukti:** sandbox bukan Infinix; emulator/sandbox tidak menggantikan DEVICE VERIFIED. APK dan UAT user tetap diperlukan.
- **Scope reality:** target “setara Wuthering Waves secara keseluruhan” tidak dapat dibuktikan atau diselesaikan dalam satu iterasi solo developer dengan proyek saat ini. Sesi ini akan mengejar vertical slice yang dapat diuji dan menjaga klaim tetap jujur.

## Status fase

- Phase 1 Audit repository dan dokumentasi: **sedang diselesaikan**.
- Phase 2 Pemetaan arsitektur dan risiko: **belum dimulai penuh**; diagnosis verify-local dan inspeksi workflow masih diperlukan.
- Tidak ada commit/push/release dilakukan.

## Riset eksternal fase desain

- Dokumentasi Godot 4.7 menjelaskan bahwa kamera third-person sebagai child langsung dapat menembus geometri; `SpringArm3D` melakukan motion cast dan memendekkan jarak kamera saat bertabrakan. Sumber: https://docs.godotengine.org/en/latest/tutorials/3d/spring_arm.html. Ini menjadi kandidat perbaikan kamera, tetapi harus diuji terhadap scene tree saat ini dan biaya physics di device.
- Referensi resmi `CharacterBody3D` Godot 4.7 mengonfirmasi `move_and_slide()` bekerja bersama `floor_snap_length` untuk menjaga badan menempel pada slope, dan properti floor/slope/sliding harus diperlakukan sebagai kontrak movement. Sumber: https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html.
- Riset mesin menampilkan fakta penting: pada isolated baseline, setiap invocation headless tertahan di `ERROR: Could not load global script cache` dan timeout, sehingga verifikasi lokal saat ini gagal pada lapisan tooling/cache sebelum kesimpulan kode gameplay dapat dibuat.

## Keputusan sementara

1. Jangan mengubah movement/dodge sebelum gerbang lokal dapat dijalankan secara deterministik atau diganti dengan harness yang sah; perubahan tanpa gerbang akan mengulang regresi HUD sebelumnya.
2. Kamera collision akan dievaluasi melalui `SpringArm3D` hanya bila scene tree dan collision mask dapat dibuat tanpa mengganggu orbit touch yang sudah DEVICE VERIFIED.
3. Medan realistic tidak berarti shader mahal: target Compatibility/GLES dan GPU Mali mengharuskan shader murah, material opaque, jarak fade, dan toggle fallback. Klaim visual tetap menunggu DEVICE VERIFIED.

## Diagnosis timeout tooling

Eksperimen terisolasi:

| Eksperimen | Hasil | Kesimpulan |
|---|---|---|
| `verify-local.sh` penuh | timeout setelah parse script ke-6 | belum dapat dijadikan bukti hijau/merah kode |
| parse terisolasi dengan `--check-only` | semua invocation timeout dan mencetak `ERROR: Could not load global script cache` | mode pemeriksaan script bermasalah pada binary custom |
| warmup editor tanpa `--path` | exit 0, tetap mencetak global script cache error, cache tidak terbentuk | warmup tidak memperbaiki mode check |
| warmup dengan `--path` | langsung gagal karena binary dikompilasi tanpa `disable_path_overrides=no` | binary memiliki keterbatasan path override |
| project minimal + binary sama + `--editor --quit` | exit 0 | binary dapat boot/editor dasar |
| project minimal + binary sama + `--check-only` | timeout 20 detik dengan error global script cache yang sama | isu dapat direproduksi tanpa ZDEV-RPG/aset; akar utama adalah toolchain/custom build + `--check-only`, bukan bukti bug game |

Status verifikasi tetap **BELUM LOCALLY VERIFIED**. Perbaikan berikutnya harus membuat gate tidak bergantung pada mode yang terbukti hang, misalnya menggunakan runtime boot terisolasi dan/atau binary resmi yang sesuai, lalu divalidasi terhadap CI resmi Godot 4.7.2. Tidak ada klaim compile hijau dari eksperimen ini.

## Riset terrain collision

Dokumentasi resmi Godot 4.7 menyatakan `HeightMapShape3D` memakai grid tinggi terpusat pada origin, spacing 1 unit pada X/Z, dan lebih cepat daripada `ConcavePolygonShape3D` namun lebih lambat daripada primitive. Sumber: https://docs.godotengine.org/en/4.7/classes/class_heightmapshape3d.html. Karena terrain proyek memakai resolusi 64 untuk dunia 300 m, collider heightmap memerlukan scale seragam sekitar `size / resolution` dan data tinggi yang konsisten dengan mesh. Implementasi harus menguji batasan scaling physics; bila tidak stabil, rollback ke Box collider untuk basic arena.

## Implementasi slice kamera

- `scenes/main.tscn`: Camera3D dipindahkan menjadi child langsung `CameraPivot/CameraArm/Camera3D`; arm memakai sphere shape 0.18, margin 0.2, mask 1, dan rotasi 180° agar tetap berada di belakang player.
- `scripts/camera_follow.gd`: mendukung SpringArm3D, mengecualikan RID player, mempertahankan fallback camera lama, dan menjaga API `get_yaw()`/`adjust_dist()`.
- `scripts/grass.gd` dan `scripts/player_controller.gd`: path camera diperbarui dengan fallback scene lama.
- Kesalahan selama edit: satu kali salah indentasi pada `camera_follow.gd` dan satu kali salah indentasi pada blok dodge; keduanya diperiksa dan dikoreksi sebelum boot test.
- Kesalahan harness: perintah copy dengan dua direktori tujuan gagal; diperbaiki dengan dua perintah copy terpisah.
- Boot harness setelah koreksi: exit 0; tidak ada `SCRIPT ERROR`/`Parse Error`/`WARNING` baru, tetapi tetap mencetak error tooling global script cache yang sudah direproduksi di project minimal. Ini **belum** LOCALLY VERIFIED penuh.

## Perubahan slice medan, kamera, dan dodge

Perubahan IMPLEMENTED pada working tree, belum commit/push:

| File | Perubahan | Alasan |
|---|---|---|
| `scenes/main.tscn` | CameraArm SpringArm3D + sphere shape; kamera menjadi child arm; cahaya senja diturunkan | collision-aware camera dan palet dusk |
| `scripts/camera_follow.gd` | SpringArm length/margin/mask, exclude player RID, fallback scene lama, look-at guard | mencegah kamera menembus collider dan warning colinear |
| `scripts/player_controller.gd` | no-input dodge menghitung arah player menuju posisi kamera secara horizontal | memperbaiki bug konseptual: dodge back tidak boleh menuju kamera |
| `scripts/grass.gd` | path kamera baru + fallback | menjaga shader grass menerima posisi kamera |
| `scripts/terrain_generator.gd` | amplitude 2.4, shader terrain, HeightMapShape3D collider dengan scaling konsisten | medan berbukit dan collision mengikuti mesh |
| `scripts/proxy_humanoid.gd` | offset konform visual memakai `h_c - player_y` | mencegah proxy melayang karena body sudah mengikuti terrain |
| `scripts/arena_spawner.gd` | `spawn_trees=false` default | menyelaraskan komentar dan target low-end |
| `shaders/terrain.gdshader` | shader opaque berbasis vertex color/world position | variasi material murah untuk terrain |
| `shaders/sky_sun.gdshader` | palet senja warm/dark | konsistensi visual arena |
| `tools/verify-local.sh` | dua harness bounded: script-load ringan + boot scene subset aset | menghindari `--check-only` yang hang pada custom binary |

## Iterasi error yang dikoreksi

1. Edit awal `camera_follow.gd` sempat menempatkan update SpringArm di dalam `if target == null`; diperbaiki melalui review line-level.
2. Edit path dodge sempat menghasilkan indentasi berlebih; diperbaiki setelah inspeksi `sed -n l`.
3. Edit proxy terrain-conform sempat menghasilkan indentasi berlebih; diperbaiki setelah inspeksi literal.
4. Sinkronisasi harness pertama gagal karena `cp` menerima dua direktori tujuan; diperbaiki dengan copy per direktori.
5. `verify-local` versi pertama tetap timeout karena mode runtime dilakukan di salinan yang terlalu berat dan setiap invocation mengulang import; direvisi menjadi parse harness tanpa aset + satu boot harness dengan subset aset.
6. Wrapper command ber-pipeline sempat mengembalikan kode shell tidak konsisten walau log hijau; direct log diverifikasi terpisah, lalu cache dibersihkan. Tidak ada proses engine tertinggal menurut `ps`.

## Gate setelah revisi

Run `tools/verify-local.sh` v2 menghasilkan:

- `script load OK` untuk 9/9 script.
- `boot OK: 40 frame tanpa SCRIPT ERROR`.
- `VERIFIKASI LOKAL: HIJAU` pada log.
- Log tetap menampilkan error global script cache dari binary custom pada output engine, tetapi filter gate sengaja hanya menghukum `SCRIPT ERROR`, `Parse Error`, dan `treated as error`; keterbatasan ini harus disebutkan dan CI official tetap wajib.

Status slice saat ini: **IMPLEMENTED + LOCALLY VERIFIED melalui runtime bounded harness**, dengan catatan bahwa gate lokal bukan pengganti CI official atau device. Belum ada commit/push dan belum ada DEVICE VERIFIED baru.

## Issue tracker

Halaman issue tracker repository pada 2026-08-28 menunjukkan **0 issue open dan 0 issue closed**. Tidak ada issue publik tambahan yang dapat dijadikan sumber requirement atau blocker. Sumber: https://github.com/muzape28-blip/ZDEV-RPG/issues. Konsekuensinya, UAT log, source code, dokumentasi proyek, dan verifikasi CI/device menjadi sumber bukti utama.

## Regression guard dan runtime smoke

Guard `tools/verify-contracts.sh` ditambahkan untuk wiring CameraArm, camera-local yaw, arah camera-relative movement, arah neutral dodge, i-frame timer, HeightMapShape3D, terrain shader, pohon OFF, dan resource shader. Mutation test membuktikan dua guard berubah merah pada bug yang sengaja dimasukkan: `global_rotation.y` menggantikan local yaw, dan vektor dodge dibalik. Source kemudian dipulihkan dan contract suite kembali hijau.

Runtime smoke pertama berbasis command-line `extends SceneTree` timeout. Diagnosis menemukan custom binary tidak menjalankan `--script` seperti asumsi; probe minimal hanya mencetak global script cache error dan mencoba main_scene. Smoke kedua berbasis SceneTree juga gagal karena statement sempat tergabung satu baris dan lifecycle tidak terpanggil. Smoke direvisi menjadi `extends Node` autoload sementara pada harness runtime; setelah itu smoke menemukan ownership salah (`get_parent()` bukan Main), diperbaiki menjadi `get_tree().current_scene`, dan run berikutnya hijau.

Run final `tools/verify-local.sh` setelah runtime smoke masuk parse loop:

- 11/11 script load OK.
- Boot 40 frame tanpa `SCRIPT ERROR`/`Parse Error`.
- Runtime smoke hijau pada scene produksi: CameraPivot, CameraArm, Camera3D, FOV, collision mask, request_dodge/velocity, Terrain, HeightMapShape3D, dan ShaderMaterial.
- Contract suite final hijau.

CI workflow diperluas ke 11 script dan smoke production menggunakan Godot official 4.7.2, dengan restore `project.godot` via trap. Belum dijalankan di GitHub Actions karena perubahan belum dipush; status CI masih NOT RUN.

## Validasi visual Compatibility

Binary custom `tools/godot-headless` tidak dapat dipakai untuk visual: build dummy renderer crash di Xvfb dengan `Parameter "t" is null` dan exit 139. Saya mengunduh Godot official 4.7.2 sesuai pin CI ke `/tmp` (tidak masuk repository) dan menjalankan scene Compatibility via Xvfb.

Capture official pertama berhasil membuat PNG 1152×648 dengan HUD, tombol dodge, dan langit dusk, tetapi terrain/karakter tidak terlihat; FPS label menunjukkan 1 pada frame capture. Capture kedua setelah elevasi SpringArm diubah dari `0.30` ke `-0.62` juga berhasil tanpa SCRIPT ERROR, tetapi world/karakter tetap tidak terlihat dan FPS label tetap 1. Ini **bukan visual pass**. Kemungkinan aktif yang belum dibuktikan: capture terlalu cepat saat asset import, transform/camera world, atau terrain/material terlalu gelap. Warning V-Sync/ALSA dari Xvfb/host dicatat sebagai noise host, bukan bug device. Tidak ada APK/device Infinix yang diuji di sandbox.

## Diagnosis displacement dan visual follow-up

Trace official Godot dengan cache bersih membuktikan displacement berasal dari Dummy CharacterBody3D: Terrain-only dan Terrain+Arena tanpa Dummy stabil di origin; full scene dengan Dummy aktif memberi velocity horizontal ~473 tanpa input/timer. Menonaktifkan `Dummy.collision_layer` dan `collision_mask` mengembalikan Player ke `(0,0,0)` dengan velocity nol selama 120 frame. Fix produksi diterapkan pada `scripts/dummy.gd`; Dummy tetap memiliki mesh/collider resource untuk visual, tetapi tidak lagi ikut physical pushing karena hit detection combat memakai range/arc.

Capture official setelah fix menghasilkan FPS 45 dan geometri mulai terlihat, sehingga blocker movement teratasi. Namun frame masih belum dianggap visual pass: terrain/garis geometri menumpuk di tepi atas, dunia terlalu gelap, dan karakter belum terbaca jelas. Ini perlu perbaikan framing/material/asset visibility berikutnya. Semua eksperimen Box/Concave/mask-zero harness dipulihkan; tidak ada perubahan eksperimen masuk source produksi.

## Isolasi visual shader

Setelah cache harness dibersihkan, full scene dengan fix Dummy stabil: Player tetap di `(0,0,0)`, velocity `(0,0,0)`, collision normal `(0,1,0)` selama frame 1–120, dan FPS capture 45.

Eksperimen shader harness `unshaded, cull_disabled` mengubah frame dari hampir seluruhnya `(22,12,9)` gelap menjadi terrain tan terang dengan objek arena terlihat. Ini membuktikan mesh/camera/depth bekerja; visual gelap berasal dari lighting/culling/material terrain shader, bukan terrain hilang. Eksperimen unshaded **tidak** masuk source produksi. Langkah berikutnya: kunci material terrain Compatibility yang tetap murah tetapi menerima cahaya dengan normal/culling yang benar, lalu ulangi capture official.

## Isolasi lighting terrain

Control `unshaded, cull_disabled` menampilkan terrain tan dan objek arena jelas pada FPS 45. Control berikutnya `diffuse_burley, cull_disabled` tetap hampir hitam walau back-face culling dimatikan. Maka culling bukan akar visual gelap; terrain geometry/depth/camera sudah ada, sedangkan lighting directional/ambient pada scene tidak memberi energi yang cukup atau arah normal/lampu tidak cocok. Keputusan berikutnya: gunakan material terrain lit yang murah dengan ambient/base readability yang eksplisit dan validasi ulang, tanpa mengubah ke efek post-processing berat.

## Audit lanjutan shader import/material

Capture fake-diffuse produksi dan control constant-albedo harness sama-sama masih menampilkan world gelap, sedangkan control unshaded sebelumnya terang. Tidak ada SCRIPT ERROR atau shader compile error pada log. Karena constant-albedo mengabaikan normal/dot product tetapi tetap gelap, perhitungan `world_normal` bukan satu-satunya kandidat; perlu memeriksa material assignment/import/cache dan memastikan mesh terrain aktif memakai shader resource yang sedang diuji. Status visual masih **GAGAL/INCONCLUSIVE**, walau FPS 45 dan movement idle sudah stabil.

## Kamera native SpringArm dan visual final sementara

Introspeksi membuktikan `cam.look_at()` pada child SpringArm menimpa rotasi native menjadi `(1.570796, π, 0)`, sehingga kamera mengarah vertikal/flip. Guard `if cam != null and arm == null` diuji pada harness; rotasi child menjadi `(-0.62, -π, 0)`, sesuai orientasi SpringArm native. Percobaan tanda `+0.62` melihat langit; tanda `-0.62` adalah orientasi yang benar untuk melihat turun.

Capture final official dengan source scene `-0.62`, camera native, Dummy non-physical, dan terrain shader fake-diffuse: exit 0, PNG berhasil, FPS 45, Player stabil di origin, tetapi frame masih dominan gelap dengan geometry terrain/objek hanya terlihat sebagai garis/objek gelap di bagian atas. Jadi camera physics/movement sudah lebih konsisten, tetapi **visual pass belum tercapai**. Material runtime terpasang sebagai ShaderMaterial dan AABB terrain valid; penyebab visual tersisa kemungkinan kombinasi arah camera/mesh winding dan shader output, bukan crash/lifecycle.

## Camera decoupling probe

Pada harness shader unshaded, eksperimen arm yaw-only (`rotation.x=0`, yaw `π`) + child Camera3D pitch `-0.10` menghasilkan camera position `(0,1.5,-4.4)` dan framing horizon/terrain yang nyata; Player terlihat di tengah bawah dan arena/relief terbaca di garis horizon. Ini membuktikan solusi SpringArm tidak perlu `look_at`, tetapi child camera harus memiliki pitch eksplisit. Karena foreground masih gelap pada shader lit dan kamera terlalu rendah untuk third-person nyaman, nilai final akan dituning dengan camera pivot/child pitch dan material ambient terukur.

External reference yang digunakan tetap: Godot HeightMapShape3D 4.7 (`https://docs.godotengine.org/en/4.7/classes/class_heightmapshape3d.html`), SpringArm tutorial (`https://docs.godotengine.org/en/latest/tutorials/3d/spring_arm.html`), dan spatial shader reference (`https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html`).

## Konfirmasi winding terrain

Probe shader unshaded dengan camera child pitch `-0.65`: saat `cull_back`, hanya strip terrain yang terlihat; saat `cull_disabled`, terrain mengisi foreground secara penuh pada FPS 45. Dengan demikian mesh terrain memiliki winding/normal yang tidak konsisten terhadap sisi yang dilihat kamera (atau kamera melihat sisi belakang pada orientasi saat ini). Solusi produksi yang aman untuk Compatibility low-end adalah `cull_disabled` pada terrain opaque, karena biaya relatif kecil dan mencegah medan hilang; normal/lighting tetap harus dibuat stabil. Probe terakhir tetap harness-only sampai source shader dan scene final ditetapkan.

## Framing camera dan culling final sementara

Source scene dengan `CameraArm` yaw-only (`rotation.x=0`, yaw `π`), child pitch `-0.65`, pivot `y=1.5`, dan terrain `cull_disabled` berhasil menampilkan medan penuh pada capture official dengan FPS 45, Player stabil di origin, serta tanpa SCRIPT ERROR/Parse Error. Tuning berikutnya menaikkan pivot ke `y=2.0` dan mengurangi child pitch ke `-0.45`; hasil visual menunjukkan horizon lebih natural dan Player berada di tengah atas medan.

Frame masih belum polish pass: karakter tampak sangat gelap/siluet, HUD masih diagnostic, dan landmark belum cukup terbaca pada satu capture. Culling fix terbukti wajib untuk mesh saat ini; no-op/layer eksperimen tetap tidak masuk source.

## Ambient lighting validation

Environment produksi diberi ambient light warna senja (`ambient_light_source=2`, energy `0.85`) tanpa tambahan lampu dinamis. Capture official tetap exit 0, FPS 45, Player stabil di origin, camera `(0,2.0,-4.4)` rotation `(-0.45,-π,0)`, dan terrain memenuhi frame. Namun karakter masih hampir seluruhnya siluet; ambient scene saja tidak cukup pada Compatibility/asset material saat ini. Perbaikan berikutnya harus membuat visual karakter low-end memiliki material fallback/readability eksplisit atau fill-light yang hemat, bukan mengandalkan scene lighting.

## Fill-light validation

Satu `OmniLight3D` lokal tanpa bayangan (`energy=1.6`, range 8 m) ditambahkan sementara ke source scene dan diuji dengan official Compatibility. Terrain tetap terbaca, FPS tetap 45, Player/camera stabil, tetapi objek karakter tetap siluet gelap tanpa perubahan berarti. Ambient/fill-light bukan solusi akar; kemungkinan asset GLTF/FBX memiliki material/mesh import yang tidak terbaca pada renderer atau karakter yang terlihat adalah collision proxy, sehingga perlu inspeksi node visual dan fallback material yang benar-benar diterapkan ke MeshInstance3D.

## Fallback karakter, gate final, dan device boundary

Probe visual-tree official menemukan `Proxy` tanpa `MeshInstance3D` karena FBX/GLTF tidak berhasil menjadi scene runtime pada harness. `proxy_humanoid.gd` kini membuat fallback humanoid low-poly unshaded dengan body, head, arms, legs, dan blade ketika asset/AnimationPlayer gagal. Capture official berikutnya membuktikan tujuh MeshInstance3D fallback terlihat, Player stabil di origin, terrain terbaca, dan FPS 45.

Runtime smoke sempat merah pada `dodge memberi velocity horizontal`; diagnosis log membuktikan assertion membaca velocity sebelum custom binary menerapkan physics tick. Smoke diperbaiki dengan polling lima process frame. Run berikutnya hijau: 11/11 script load OK, boot 40 frame tanpa SCRIPT ERROR, runtime smoke hijau, contract guard hijau.

`export_presets.cfg` mengaktifkan `architectures/arm64-v8a=true` sambil mempertahankan armeabi-v7a. `adb` tidak tersedia dan tidak ada Infinix Smart 9 HD terhubung; status DEVICE VERIFIED baru tidak boleh diklaim. Preview/import artifacts hasil validator dibersihkan; file tracked EYE import dipulihkan.

Status final sesi: implementasi dan local verification hijau; official headless parse hijau; official Compatibility visual validated untuk terrain, camera, fallback mesh, dan FPS 45 pada Xvfb; CI NOT RUN karena belum push; device NOT VERIFIED. HUD diagnostic dan fallback humanoid masih merupakan vertical-slice hardening, bukan klaim setara Wuthering Waves.
