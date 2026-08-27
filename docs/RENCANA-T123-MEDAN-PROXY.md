# RENCANA KERJA GABUNGAN T1+T2+T3 — MEDAN & PROXY HUMANOID

Status: 🟡 MENUNGGU APPROVE (note arah kerja; bukan eksekusi)
Diusulkan: 2026-08-27 · Branch `arena/01a03ddc-zdev-rpg`
Prinsip: **dev dalam irisan kecil ter-gerbang, delivery SATU APK = SATU UAT.**

---

## 1. BAGAIMANA ALURNYA

```
[Slice S1 Medan]  edit → verify-local → commit
[Slice S2 Proxy]  edit → verify-local → commit
[Slice S3 Motion] edit → verify-local → commit
        ↓ semua slice HIJAU lokal
SATU push → CI (PARSE-CHECK + BOOT-CHECK + export)
        ↓
SATU APK journey.apk → SATU UAT (checklist gabungan, di bawah)
        ↓ (bila ada temuan)
fix lokal ter-gerbang → push → UAT ronde 2 (hanya bila perlu)
```

- Tiap slice = 1-3 commit kecil; **rollback point** = commit terakhir yang
  gerbangnya hijau.
- UAT checklist gabungan:
  1. Bukit terlihat, arena tengah tetap datar; sosis→manekin berdiri di tanah
     miring tanpa tenggelam/melayang.
  2. Rumput sway + gust; density toggle bekerja; fade jarak halus.
  3. Batu: klaster sedang + batu besar + monolit jauh terlihat sebagai landmark.
  4. Bayangan matahari ON (karakter+batu), toggle OFF berfungsi.
  5. Manekin 1.82 m: idle napas, jalan→lari analog mulus (fase terkunci
     kecepatan, tidak "seluncur"), ponytail mengibas.
  6. Dodge slide: pose condong + i-frame tetap.
  7. FPS ≥ 35 di default (baseline 40); bila jatuh → default rumput Jarang +
     bayangan OFF, catat di uat-log.
  8. DIAG tetap tampil sampai fase ini dinyatakan stabil.

## 2. APA RENCANANYA (isi per slice)

**S1 — Medan**
- Heightmap grid ±64², amplitudo 2-3 m, **pusat (r<12 m) datar**; StaticBody
  trimesh dari mesh yang sama.
- Rumput: kartu cutout opaque, patchy + variasi regional (noise), tinggi
  0.2-0.5 (dasar 0.3), sway+gust vertex-shader, fade ≤15 m, tanpa shadow,
  **toggle Off/Jarang(default)/Sedang**.
- Batu: 3 klaster sedang (15-25 m), 3 batu besar (35-60 m), ±15 kerikil
  (dilarang r<10 m), **1 monolit reruntuhan ±80 m**; MultiMesh per kelas
  (3 draw call); collision hanya besar+sedang (convex); cast shadow ✅.
- Pohon: **dihapus**. Matahari: shadow ON, map 1024, 16-bit, jarak terbatas,
  caster terbatas; **toggle OFF**.

**S2 — Proxy humanoid**
- Manekin bersegmen perempuan **1.82 m** (±7.6 kepala; bahu 0.36; kaki ±0.95;
  ponytail 3 segmen). Collision capsule radius **0.28**.
- Locomotion prosedural: fase dari jarak (`fase += v/stride × Δ`), stride
  jalan 0.7 / lari 1.2; idle napas; lean lari ≤12°; ayun lengan berlawanan
  kaki; bob 2×frekuensi. Referensi: sinkron stride-kecepatan (gamedev.net),
  spring-chain rambut (mocap guide), "stability > detail" (Nimian).
- Kamera: offset disesuaikan tinggi baru (penyesuaian angka, bukan rombak).

**S3 — Motion akhir**
- Dodge slide: pose condong + tangan rendah, 0.28 s, i-frame tak berubah.
- Kaki: raycast per kaki → telapak menapak tinggi tanah + pitch torso halus.
- Polish lean & ponytail saat dodge/lari.

**NON-GOALS fase ini:** interaksi rumput-karakter, wind trails, foot-IK
berjalan di lereng curam, rambut mesh, opsi joystick fixed (antri nanti),
semua hal combat M1, **menu settings gear+panel** (ganti chip debug di
fase polish).

**UI TOGGLE (sementara, debug):** dua chip kiri-atas di bawah DIAG —
`[BAY:ON/OFF]` & `[RPT:OFF/JRG/SDG]`, tap = siklus, target sentuh ≥44 px,
glyph/teks polos. Zona kiri-atas = zona mati jempol: tak kepencet saat
main, mudah ditunjuk saat UAT. Bukan bagian dari kontrak HUD pemain.

## 3. FILE PASTI & KEMUNGKINAN DISENTUH + PENANGANAN

| File | Status | Penanganan |
|---|---|---|
| `scenes/main.tscn` | PASTI | ground→heightmesh+collision, sun shadow, kapsul 0.28; edit ter-gerbang |
| `scripts/arena_spawner.gd` | PASTI (rewrite) | jadi spawner batu+kerikil+monolit (pohon hapus) |
| `scripts/terrain_generator.gd` | PASTI (baru) | heightmap + trimesh; pusat datar |
| `scripts/grass.gd` + `shaders/grass.gdshader` | PASTI (baru) | kartu cutout, sway, fade, density parameter |
| `scripts/proxy_humanoid.gd` | PASTI (baru) | segmen + locomotion + ponytail spring |
| `scripts/player_controller.gd` | PASTI | integrasi pose dodge + referensi kaki; logika gerak/inti TIDAK berubah |
| `scripts/hud.gd` | KEMUNGKINAN | toggle bayangan/rumput = 2 glyph kecil; **slice terpisah sendiri** (HUD = zona rapuh kita) |
| `scripts/camera_follow.gd` | KEMUNGKINAN | angka offset tinggi; clamp pitch tak berubah |
| `scripts/main.gd` | KEMUNGKINAN | teks DIAG diperbarui bila perlu |
| `shaders/*.gdshader` lain | KEMUNGKINAN kecil | rock tint bila perlu |

Aturan penanganan: HUD disentuh PALING AKHIR & sendiri; setiap file baru
langsung masuk daftar gerbang verify-local (daftar script di-update);
setiap commit = ≤1 file-cluster logis.

## 4. SEARCHING DI SELA KERJA — SETUJU, WAJIB

Ya. Di sela edit & test: gali referensi (dalam/luar target). Bukti nilai:
Wilderless/Nimian (filosofi toggle & landmark), OpenMW (culling), MLBB-guide
(ladder low-end), gamedev.net (stride), mocap guide (spring chain).
Temuan ditulis ke `docs/RESEARCH-OPEN-SOURCE-RPG.md` (atau doc baru) dengan
label "layak adopsi / menarik-nanti / tolak".

## 5. APAKAH AKAN MENGULANG KESALAHAN SAMA? — TIDAK, INI PAGARNYA

| Kesalahan lama | Pagarnya sekarang |
|---|---|
| Push kode tak terverifikasi (regresi HUD #1) | verify-local per commit + CI parse/boot |
| File chimera (deklarasi hilang) | verifikasi ISI remote pasca-push + CI parse |
| Perubahan raksasa per push | slice mikro; delivery satu APK ≠ satu commit |
| Kebutaan device (tanpa logcat) | DIAG on-screen dipertahankan + toggle katup |
| Binary engine lenyap snapshot | parts <8M ter-git + auto-rakit |
| Ref git kacau pasca-snapshot | prosedur fetch→reset→recommit→push→verif |
| "Indah tapi kosong" (jebakan Wilderless) | komposisi landmark batu+monolit |
| Overdraw transparansi (jebakan Mali) | rumput cutout opaque, caster terbatas |
| Kamera liar (keluhan Nimian) | clamp pitch/yaw dipertahankan |

Bila UAT gabungan menemukan masalah: kita bisect lewat **toggle + parameter**
dulu (murah), baru kode; dan satu temuan = satu entri uat-log + satu pelajaran.

---

*Note ini arah kerja. Setelah approve: S1 → S2 → S3 → satu push → satu UAT.*
