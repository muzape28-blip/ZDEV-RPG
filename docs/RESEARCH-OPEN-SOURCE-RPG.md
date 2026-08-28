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
| [godot-arpg-kit](https://github.com/ClarkWain/godot-arpg-kit) | Godot 4, GDScript | sistem combat/stats/skill **data-driven + 189 test** — pola struktur GDScript & cara ngetes yang harus kita tiru. **Lisensi: MIT (terverifikasi)** ⇒ kode boleh dipakai ulang dengan atribusi |

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

---

## HASIL GALIAN 2026-08-26 (Tambang A & B)

### 🗡️ Tambang A — godot-arpg-kit (MIT ✅)
Sumber: [repo](https://github.com/ClarkWain/godot-arpg-kit),
[postmortem v0.1.0](https://github.com/ClarkWain/godot-arpg-kit/blob/master/docs/tech-notes/godot-arpg-kit-postmortem.md)

1. **CI Godot 4 (konteks SAMA dengan kita):**
   - fresh checkout tak punya cache `.godot/` ⇒ `load().new()` rusak di CI;
     wajib **`godot --import`预热 (warmup)** sebelum test; fallback
     `--editor --quit` + timeout;
   - **exit code headless TIDAK bisa dipercaya** (ERROR resource leak bikin
     non-nol walau test lolos) ⇒ parse baris mesin `[RESULT] suite=...`;
   - flake deterministik: `seed(0)` di awal runner.
2. **Postmortem double-settlement combat:** dua sistem reduksi damage
   overlapped terantai ⇒ defense/dodge/shield kena dua kali; test hijau karena
   setup **menolkan default** (test smell). Fix = blast-radius minimum +
   **6 regression test**. Pelajaran M1: pipeline damage TUNGGAL; setup test
   jangan nolkan semua nilai realistis.
3. **CombatEventBus** (signal terpusat) → pola untuk Feel Stack kita
   (hitstop/slowmo mencolok ke bus, bukan saling pangggil langsung).
4. Aksi: adopsi pola CI (1) saat memperbaiki workflow kita (butuh 1x paste
   user); (2)-(3) jadi bahan desain M1; reuse MIT legal — **atribusi wajib
   dicatat** bila kode dipakai.

### 🌍 Tambang B — OpenMW / openmw-android (GPL ⇒ pelajaran saja)
Sumber: thread komunitas (r/OpenMW, forum.openmw.org)

1. object paging + active-grid + culling objek kecil-by-pixel ⇒ padanan
   Godot: visibility range, jarak rumput kita divalidasi.
2. anisotropy 0 + filter nearest di low-end ⇒ kebijakan tekstur kita.
3. "water shader memakan setengah FPS" ⇒ shader luas = mahal; api hydra =
   quad shader (keputusan kita divalidasi).
4. physics rate 30 di device kentang ⇒ kerangka 30/60 kita sehat.
5. fillrate-bound ⇒ turunkan resolusi render (+sharpen) ⇒ tangga resolusi.
6. vsync driver tak bisa dipercaya ⇒ ukur di device, jangan asumsi.

### 📚 Q&A lisensi (bahasa manusia)
- "Pakai semua lisensi bisa?" → copy semua: tidak. Menambang semua: **iya**,
  dengan strategi kombinasi: MIT = reuse+atribusi; GPL = pelajari logika,
  tulis ulang sendiri; aset CC = cek per-aset.
- Analogi: MIT = resep boleh difotokopi asal cantumkan nama; GPL = restoran
  boleh dicicipi & dimasak ulang di rumah, tapi pancinya nggak boleh dibawa.

---

## 🧍 PIPELINE KARAKTER RESMI — FASE 2 (dikunci 2026-08-26)

Kombinasi juara: full-gratis, full-legal, minim akun, anti-ketergantungan
pada satu vendor (Mixamo = legacy tak terurus).

| Tahap | Tool | Lisensi | Akses |
|---|---|---|---|
| Badan manusia realistis | **MakeHuman** (parametrik) | CC0 utk export resmi | ⚠️ desktop — nunggu PC user |
| Rig otomatis | **Cinevva Auto Rigger** (browser) | gratis | ✅ HP bisa |
| Animasi (idle/jalan/lari/serang/dodge) | **Quaternius UAL 1+2** | **CC0**, retarget-able ke Godot | ✅ tanpa akun |
| Animasi spesial custom | Cinevva Prompt Animations | gratis | ✅ browser |
| Cadangan animasi spesifik | Mixamo | royalty-free komersial | ⚠️ Adobe ID, legacy |

Budget device tetap: ±10-15k tris, tekstur 1-2K (kontrak M0).
**Merah / jangan dulu:** CMU mocap (flag lisensi komersial), Cascadeur
free-tier (non-komersial).
Urutan eksekusi: setelah 6 poin M0 hijau + proxy humanoid (fase 1).

## Sensus ARPG Open-Source (verifikasi langsung 2026-08-28, API GitHub + web)

Daftar kandidat "harta karun" (masuk via ChatGPT) diverifikasi ulang satu
per satu. Hasil: semua repo NYATA, tapi beberapa klaim ChatGPT salah —
jangan telan mentah.

| Project | Stack | Lisensi | Status | Nilai utk kita |
|---|---|---|---|---|
| **Reia** (Quaint-Studios) | Godot 4.6, GDScript + Rust GDExt, client/server | **AGPL-3.0** ⚠️ | AKTIF (push 2026-08) | 🔥 Arsitektur Godot-4 paling relevan: combat components (c_health, c_damage_event, s_damage_calculation), movement sync, ECS-lite. **JANGAN copy code** (AGPL menular) — belajar pola |
| **Broken Seals** (Relintai) | GDScript di atas **Pandemonium** (fork Godot, bukan Godot 4) | MIT | Game tidur (2023), engine hidup | 🔥 Referensi spell/entity system; code Godot-3-era, port mahal |
| **entity_spell_system** | C++ module Godot | MIT | 2023 | Pola Entity/Item/Loot/Aura/targeting utk M1+ |
| **Veloren** | Rust, voxel | GPL-3.0 | Sangat aktif | Referensi arsitektur open-world+multiplayer; 1.2GB repo, jangan clone di sandbox |
| **OpenMW** | C++ engine reimplement Morrowind | GPL-3.0 | Aktif | Bukti open-world RPG besar bisa Android; ref teknik large-world |
| **openmw-android** | — | GPL-3.0 | URL asli = `xyzz/openmw-android` (bukan EvilRussia), tidur 2021 | Ref port Android engine besar |
| **JDungeon3D** | Godot, GDScript | MIT | Kecil, 2024-08 | Contoh MMORPG Godot skala kecil |
| **Source of Mana** | Godot 4, **2D** | MIT | Aktif (GitLab sourceofmana) | Ref netcode+Android, tapi 2D |
| **FLARE** | C++/SDL2, 2D | GPL-3.0 | Aktif | Ref arsitektur ARPG engine, 2D |
| **Solarus** | C++/Lua, 2D | GPLv3 | Pindah GitLab 2018 | 2D Zelda-like; skip |
| **Ascension Adventure 2** | engine retro (Dubnium) | GPLv3+CC-BY-SA | 2017, selesai | **First-person** dungeon crawl — ChatGPT salah label; tidak relevan |
| **GTA-VI-caliber** | Godot 4.6 | MIT (code), CC-BY-4.0 (aset) | Dibuat 2026-06, M0, 0 star | "AAA caliber" = aspirasi sendiri; isinya baru sandbox M0. Menarik cuma: mereka juga pakai pola AGENTS.md + tools/check.sh gate seperti kita |
| Pandemonium/Voxelman | C++ Godot module | MIT | aktif/tidur | Ekosistem Relintai; tidak langsung dipakai |

### Kesimpulan operasional
1. **Tidak ada satu pun yang bisa dicomot langsung** ke stack kita
   (Godot 4.7 + GDScript + armv7 + aset orisinal/CC). Bahasa/engine/lisensi
   beda semua. Yang diambil = POLA & ARSITEKTUR.
2. Ambil dari **Reia**: dekomposisi combat jadi komponen kecil
   (sehat utk M1: health/damage/skill-exec terpisah, gampang dites).
   Ambil dari **Broken Seals/entity_spell_system**: model
   Spell/Aura/targeting/cooldown sbg data, bukan kode keras.
   Ambil dari **OpenMW/Veloren** (nanti, fase open-world): streaming
   sel dunia & LOD — BUKAN sekarang (dunia kita 300 m, aman tanpa streaming).
3. Lisensi: AGPL/GPL = **baca saja, jangan salin**. Aset mereka jangan
   masuk repo kita (ledger REFERENSI-GLTF tetap acuan).
4. Celah yang ChatGPT sebut memang nyata: kombinasi OSS + 3D + ARPG +
   Android + open-world + aset orisinal hampir tidak ada → posisi kita
   (build sendiri di atas pola-pola di atas) justru masuk akal.
