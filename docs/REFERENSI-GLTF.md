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
