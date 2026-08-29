# ZDEV-RPG — Final Hardening Report

**Author:** Manus AI  
**Branch audited:** `arena/01a03ddc-zdev-rpg`  
**Initial commit:** `599144755c8067b6f0b2f968908ea93b0cb1048a`

## Ringkasan

Sesi ini menyelesaikan hardening vertical slice pada movement, kamera third-person, dodge, terrain, shader Compatibility, fallback karakter, dan verifikasi lokal. Hasil tidak boleh disebut setara Wuthering Waves secara keseluruhan: repository masih belum memiliki combat lengkap, parry/boss production-ready, aset final yang konsisten, polish UI, CI run terbaru, atau pengujian perangkat Infinix Smart 9 HD secara langsung.

> Klaim aman: source berubah nyata, gate lokal hijau, official headless parse hijau, dan official Compatibility capture berjalan pada Xvfb. Klaim yang tidak aman: DEVICE VERIFIED baru atau parity keseluruhan dengan Wuthering Waves.

## Perubahan implementasi

| Area | Perubahan | Bukti |
|---|---|---|
| Movement | Camera-relative movement dipertahankan; acceleration, smoothing, floor snap, slope guard, anti-drift tetap aktif. | Contract guard + runtime smoke hijau. |
| Dodge | Neutral dodge menjauh dari posisi kamera secara horizontal; input directional tetap camera-relative; dash window dan i-frame dipertahankan. | Mutation test mendeteksi arah terbalik; runtime smoke memverifikasi dash velocity setelah physics polling. |
| Kamera | Camera3D menjadi child langsung SpringArm3D; sphere cast, margin, collision mask, player RID exclusion, yaw lokal, dolly 4–9 m, fallback camera lama. Arm yaw-only; child pitch eksplisit; pivot dinaikkan ke 2.0 m. | Official capture: `current=true`, posisi `(0,2.0,-4.4)`, rotasi `(-0.45,-π,0)`, FPS 45. |
| Terrain | Flat terrain diganti relief heightmap deterministik dengan pusat arena datar; HeightMapShape3D memakai scaling konsisten dengan mesh. | Runtime smoke menemukan HeightMapShape3D; AABB valid. |
| Terrain shader | Shader Compatibility opaque murah dengan variasi warna procedural; `cull_disabled` dipilih setelah probe membuktikan `cull_back` menghilangkan hampir seluruh mesh pada orientasi saat ini. | Official capture menampilkan medan penuh. |
| Arena | `spawn_trees=false` default untuk melindungi low-end; aset dan jalur rollback tidak dihapus. | Contract guard hijau. |
| Dummy | Dummy combat dibuat non-physical (`collision_layer=0`, `collision_mask=0`) agar tidak mendorong Player; hit detection range/arc tetap tersedia. | Clean-cache experiment membuktikan displacement ilegal hilang; runtime smoke hijau. |
| Karakter | Fallback humanoid low-poly unshaded dibuat bila FBX/GLTF atau AnimationPlayer gagal: body, head, arms, legs, blade. | Visual-tree probe menemukan 7 MeshInstance3D terlihat. |
| Android | `architectures/arm64-v8a=true` diaktifkan, armeabi-v7a tetap aktif. | Export preset parse/inspection hijau. |
| Verification | `verify-local.sh` memakai parse harness bounded + boot harness; runtime smoke autoload; `verify-contracts.sh` menjaga invariant kamera, movement, dodge, terrain, shader, Dummy. | Final local gate hijau. |

## Hasil verifikasi

| Gate | Hasil | Batasan |
|---|---|---|
| `git diff --check` | **PASS** | Tidak memvalidasi gameplay. |
| Contract guard | **PASS** | Structural/runtime contracts yang ditulis, bukan full QA. |
| Local script-load | **PASS — 11/11** | Custom binary masih mencetak global script cache warning/error internal yang direproduksi pada project minimal; gate tidak memakai `--check-only`. |
| Local boot | **PASS — 40 frame** | Tidak ada `SCRIPT ERROR` atau `Parse Error`. |
| Runtime smoke | **PASS** | Memverifikasi camera tree, FOV, collision mask, visible mesh, Dummy non-physical, dodge velocity, terrain collider, shader material. |
| Official Godot headless parse | **PASS** | Warning root/sandbox bukan bug gameplay. |
| Official Compatibility visual | **PASS untuk vertical-slice readability** | Xvfb, bukan device Infinix; frame menunjukkan terrain/fallback character/FPS 45. |
| GitHub Actions CI | **NOT RUN** | Perubahan belum dipush. |
| Infinix Smart 9 HD | **NOT DEVICE VERIFIED** | `adb` tidak tersedia; tidak ada device terhubung. |

## Error penting dan koreksi

Baseline `verify-local.sh` sempat timeout setelah enam script. Isolasi pada project minimal membuktikan mode `--check-only` custom binary sendiri bermasalah pada global script cache. Gate lalu dipindahkan ke runtime bounded harness dan boot scene.

Visual harness custom renderer crash dengan `Parameter "t" is null` dan exit 139. Validator diganti ke Godot official 4.7.2 Compatibility yang dipin sesuai CI. Hasil awal masih frame gelap; cache harness kemudian dibersihkan setiap eksperimen agar script lama tidak terbaca.

Dummy CharacterBody3D terbukti mendorong Player dengan velocity horizontal sekitar 473 walau input dan timer nol. Layer/mask Dummy dinolkan di source produksi. Runtime smoke sempat false-red karena membaca velocity pada frame yang sama dengan request dodge; polling lima process frame memperbaiki test timing, bukan menyembunyikan bug controller.

Eksperimen visual membuktikan `cull_back` hanya menyisakan strip terrain, sedangkan `cull_disabled` menampilkan medan penuh pada FPS 45. Ambient dan OmniLight tidak mengangkat asset karakter yang gagal di-load; fallback humanoid dibuat agar Player tidak invisible pada renderer/device yang tidak mengimpor FBX/GLTF.

## Status dan langkah berikutnya

Repository berada pada status **IMPLEMENTED + LOCALLY VERIFIED + OFFICIAL VISUAL VALIDATED untuk vertical slice**. Belum ada commit, push, CI run, APK install, atau device UAT baru dalam sesi ini.

Sebelum menyebut release siap device, lakukan export APK armv7 dan arm64, install ke Infinix Smart 9 HD, lalu uji touch joystick, kamera drag/pinch, movement slope, dodge neutral/directional, collision camera, FPS sustained, thermal behavior, dan lifecycle pause/resume. Hasil device harus ditambahkan ke `docs/uat/uat-log.md` dengan video atau logcat sebagai bukti.

## Referensi

[1]: https://docs.godotengine.org/en/latest/tutorials/3d/spring_arm.html "Godot SpringArm3D tutorial"  
[2]: https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html "Godot 4.7 CharacterBody3D reference"  
[3]: https://docs.godotengine.org/en/4.7/classes/class_heightmapshape3d.html "Godot 4.7 HeightMapShape3D reference"  
[4]: https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html "Godot 4.7 spatial shader reference"  
[5]: https://github.com/muzape28-blip/ZDEV-RPG/issues "ZDEV-RPG issue tracker audited during session"
