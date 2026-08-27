# REFERENSI GLTF GRATIS/OPEN-SOURCE (perburuan 2026-08-27)

Metode: SKILLS.md ZCODE §5 — klaim "blokir" dibuktikan; host hard-block:
release-assets & raw.githubusercontent. Kanal kerja: api.github.com (base64
≤1MB) + codeload tarball.

## Sudah diunduh (komparasi pipeline)
| File | Isi | Lisensi | Sumber |
|---|---|---|---|
| ASSETS/referensi/CesiumMan.glb | manusia rigged + animasi jalan baked (ground truth gait) | CC-BY (Khronos sample) | KhronosGroup/glTF-Sample-Assets |
| ASSETS/referensi/Fox.glb | quadruped rigged + animasi (studi lokomosi → hydra) | CC0 | KhronosGroup/glTF-Sample-Assets |

## Antrian ambil via HP user (host non-GitHub)
- OpenGameArt "Base Rigged Stylized Humanoid (YW)" — CC0, rigged, anime-slim
  https://opengameart.org/content/base-rigged-stylized-humanoid-character-yw
- awesome-cc0 (indeks 900+ model CC0, 300 avatar VRM, Kenney, Quaternius,
  PolyHaven, Sketchfab-CC0) https://github.com/madjin/awesome-cc0
- Registry CC0 991+ GLB https://github.com/ToxSam/open-source-3D-assets

## Kegunaan komparasi
- CesiumMan = kalibrasi stride/frekuensi langkah vs speed_scale kita.
- Fox = referensi ritme quadruped untuk hydra M2.
- Jules-synth vs Khronos = uji loader yang sama, dua sumber beda.

## LEDGER LISENSI ARRISA (audit 2026-08-28, sumber dikonfirmasi user)

| Aset | Sumber | Lisensi | Aturan pakai |
|---|---|---|---|
| Arissa.fbx + animasi (Catwalk/Fast Run/Idle/Idle→Action) | Mixamo | Mixamo terms | ✅ gratis utk game, tanpa kredit |
| KURENAI / SHOGUN / SAMIDALE | TORTOR collective, itch.io/cybersamurai | **CC BY-ND 4.0** | ⚠️ pakai APA ADANYA + kredit "Pierre Fontaine from TORTOR"; DILARANG modif mesh/tex |
| Retro Tree Pack v1.0 | Pizza Doggy, itch.io/retro-tree-pack | Royalty Free | ✅ (kredit disarankan); nearest filtering, two-sided shader |
| BlenderGoodies | RancidMilk, itch.io/free-character-animations | free | ✅ tool retarget + 2000+ anim; pakai saat ada PC/Blender |
| New free backgrounds part1 | HALAMAN BELUM DIKETAHUI | ❓ | ❌ JANGAN pakai sampai sumber & lisensi ketemu |
| CesiumMan / Fox | Khronos glTF-Sample-Assets | CC-BY | ✅ kredit Khronos Group |

Konsekuensi desain: SHOGUN = kandidat boss (dipakai apa adanya).
Karakter yang akan kita MODIF = harus dari sumber CC0/CC-BY (bukan pack TORTOR).
