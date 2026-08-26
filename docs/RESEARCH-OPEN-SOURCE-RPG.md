# PETA HARTA KARUN — GAME/ENGINE OPEN SOURCE UNTUK BELAJAR

Riset 2026-08-26 (permintaan user). Tujuan: meniru/mengkombinasi LOGIKA,
mengurangi iterasi UAT buta, dan belajar dari issue tracker mereka.
**Bukan untuk copy-paste kode berlisensi copyleft ke proyek kita.**

## Aturan lisensi (AGENTS.md §10)

- **GPL-3.0** (OpenMW, Solarus, Flare, Veloren, Barony): PELAJARI logika,
  tulis ulang dengan bahasa/konsep kita sendiri. Jangan salin kode.
- **MIT / Apache-2.0** (godot-open-rpg, template O3DE): boleh dipakai ulang
  dengan atribusi. **Verifikasi lisensi aktual di repo sebelum reuse.**

## Tambang pilihan (prioritas)

### 🗡️ Tambang A — logika combat & boss
| Proyek | Engine/Bahasa | Yang ditambang |
|---|---|---|
| [Solarus](https://www.solarus-games.org/) (repo github solarus) | C++/Lua | state machine boss, telegraph, sword/dodge/parry 2D yang teruji bertahun-tahun; issue tracker = sejarah bug combat ARPG |
| [godot-arpg-kit](https://github.com/ClarkWain/godot-arpg-kit) | Godot 4, GDScript | sistem combat/stats/skill **data-driven + 189 test** — pola struktur GDScript & cara ngetes yang harus kita tiru |

### 🌍 Tambang B — open world & performa low-end
| Proyek | Engine/Bahasa | Yang ditambang |
|---|---|---|
| [OpenMW](https://gitlab.com/OpenMW/openmw) | C++ | streaming dunia terbuka (cell loading), save system, AI aktor; issue tracker legendaris |
| **openmw-android** | — | **emas untuk kita**: thread performa device low-end / GPU Mali / workaround driver Android — kelas device yang sama dengan Infinix |
| [Veloren](https://github.com/veloren/veloren) | Rust, ECS | arsitektur open world + ECS (referensi jangka panjang, bukan untuk ditiru langsung) |

### 🏗️ Tambang C — praktik terbaik Godot
| Proyek | Catatan |
|---|---|
| [godot-open-rpg (GDQuest)](https://github.com/gdquest-demos/godot-open-rpg) | struktur proyek Godot 4 yang "benar" (pin 4.6.2); turn-based, tapi arsitektur & dokumentasi = contoh |
| [O3DE minimal action-rpg](https://github.com/matteogrs/templates.o3de.minimal.action-rpg) | Apache-2.0; mekanisme inti melee real-time + enemy reaction sederhana |

## Jujur: yang TIDAK ada

Tidak ada open source "ARPG 3D third-person mobile-quality" ala PGR/Elden.
Yang 3D open-world = OpenMW/Veloren (bukan mobile). Yang combat ARPG murni =
Solarus/Flare/godot-arpg-kit (2D/isometrik). **Kesimpulan: logika kita adopsi,
rasa 3D mobile kita bangun sendiri di atas Godot — peta di atas memangkas
riset, bukan menggantikan UAT device.**

## Lain-lain (indeks & cadangan)
- Indeks besar: [osgameclones.com](https://osgameclones.com/)
- [Flare engine+game](https://github.com/flareteam/flare-engine) (isometrik, aktif Agu 2026) — stats/buff/loot/AI
- [Barony](https://github.com/turnercl/...) (3D ARPG roguelike, GPL3) — rasa melee 3D
- [Reia](https://github.com/Quaint-Studios/Reia) (Godot+Rust, ambisius) — cara mereka menata proyek Godot besar
