# RFC — Movement, Kamera, Dodge, dan Medan Mobile

**Status:** DESIGNED, belum IMPLEMENTED  
**Branch:** `arena/01a03ddc-zdev-rpg`  
**Target:** Godot 4.7.2 Compatibility, Infinix Smart 9 HD 720×1600, armv7/Android 14 Go

## Masalah yang dibuktikan

Jalur movement, orbit kamera, dan dodge sudah ada serta pernah DEVICE VERIFIED pada M0, tetapi desain saat ini masih memiliki keterbatasan: kamera child langsung belum memiliki collision arm; terrain shipped masih flat (`amplitude = 0`); shader medan realistic belum ada; dan verify-local menggunakan mode `--check-only` yang terbukti timeout bahkan pada project minimal dengan binary custom.

## Target perubahan

Perubahan akan dikerjakan sebagai irisan kecil dan reversibel. Movement mempertahankan kontrak camera-relative dan anti-feedback yaw. Dodge mempertahankan durasi/timing i-frame yang sudah ada, tetapi guard state, input direction, dan presentasi visual akan dibuat lebih eksplisit sebelum polish. Kamera akan mendapat collision-aware arm hanya jika scene tree dan exclusion player aman. Medan akan memperoleh variasi visual murah berbasis vertex color/spatial shader, dengan pusat combat tetap datar dan fallback density/shadow.

## Acceptance criteria

| Area | Kriteria lokal | Kriteria device |
|---|---|---|
| Movement | arah joystick tidak membentuk feedback spin; idle velocity nol; slope snap tetap aktif | 60 detik jalan bebas tanpa spin/nyangkut; FPS ≥ 30 |
| Kamera | yaw/pitch clamp; tidak menembus collider pada harness/scene test; touch button tidak mengorbit | drag kanan, pinch, follow, dan obstacle camera diuji di APK |
| Dodge | cooldown mencegah retrigger; arah input stabil; i-frame hanya aktif pada dash window; tidak mengubah state touch | dodge 20 kali dari idle/4 arah tanpa stuck; visual dan respons terasa konsisten |
| Terrain/shader | shader parse dan scene boot; center flat; no transparent overdraw untuk ground; fallback shadow/grass tetap tersedia | bukit/warna/landmark terbaca; default FPS tidak turun di bawah 30 menit-1/5 |
| Tooling | gate baru tidak menggantung pada `--check-only` custom binary; error timeout dilaporkan | CI official Godot 4.7.2 tetap menjadi hakim parse/export |

## Non-goals sesi

Sesi ini tidak menjanjikan keseluruhan kualitas Wuthering Waves, open world, combat boss penuh, audio, asset AAA, atau DEVICE VERIFIED tanpa APK dan laporan user. Shader “realistic” berarti peningkatan material/lighting yang masih kompatibel dengan GLES dan budget Mali, bukan ray tracing atau post-processing berat.

## Risiko dan rollback

Risiko terbesar adalah regresi HUD/input dan penurunan FPS akibat terrain/trees/shadow. Setiap slice menyimpan commit hijau terakhir sebagai rollback. HUD tidak disentuh bersamaan dengan movement/camera. Default tetap low-end: shadow OFF dan grass OFF/Jarang sampai pengukuran device membuktikan aman.

## Dasar keputusan

SpringArm3D direkomendasikan dokumentasi Godot 4.7 untuk collision-aware third-person camera dan memiliki collision mask, margin, shape, serta excluded objects. Spatial shader Godot 4.7 mendukung mode opaque dan fitur shader configurable, tetapi alpha-blended transparency lebih mahal; alpha scissor cocok untuk foliage. Sumber: [Godot SpringArm3D](https://docs.godotengine.org/en/4.7/classes/class_springarm3d.html), [Third-person camera](https://docs.godotengine.org/en/4.7/tutorials/3d/spring_arm.html), [Spatial shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html), [StandardMaterial3D](https://docs.godotengine.org/en/4.7/tutorials/3d/standard_material_3d.html), dan [spesifikasi resmi Smart 9 HD](https://wap.ci.infinixmobility.com/specs/smart-9-hd).
