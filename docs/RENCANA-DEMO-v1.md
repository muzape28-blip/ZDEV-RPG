# RENCANA DETAIL — DEMO "HYDRA DI SABANA SENJA"

**Proyek:** ZDEV-RPG · Vertical Slice Combat (1 player vs 1 boss)
**Versi dokumen:** v1 · 2026-08-26
**Branch:** `arena/01a03ddc-zdev-rpg`
**Status:** 🟢 **IN PROGRESS — M0 dimulai 2026-08-26 setelah approve user**

---

## 0. Kontrak keputusan (hasil diskusi, terkunci)

| Slot | Keputusan | Bukti / konsep |
|---|---|---|
| Engine | Godot 4.7.2-stable, bahasa utama GDScript | rilis 18 Agu 2026 (github.com/godotengine/godot/releases) |
| Renderer | Compatibility (`gl_compatibility`, OpenGL ES 3.0) | GPU Mali kelas bawah + driver Vulkan terbatas |
| Device target | Infinix Smart 9 HD — userspace **32-bit** (`armv8l` ⇒ armeabi-v7a), SoC Helio G81-class, Mali 1–2 core, RAM 3/4 GB, Android 14 Go, 720×1600 @90Hz | cek `uname -m` oleh user |
| Player | Manusia realistis dewasa, **tanpa helm**, rambut hitam panjang, armor+kain berlapis | `docs/concepts/player-character-v1.jpg` |
| Boss | **Hydra naga api 3 kepala** | `docs/concepts/boss-hydra-v1.jpg` |
| Arena | **Sabana luas**, tone senja/dusk (dark fantasy tetap dapet) | `docs/concepts/demo-arena-target-v2.jpg` (tone) |
| HUD | Dua bar **tipis** tengah-atas (boss atas, player bawah, kode warna merah vs hijau-pucat); tombol combat **glyph putih** kanan-bawah; **floating joystick** kiri-bawah dengan hint ring tipis ±15% + toggle fixed di settings | bedah screenshot PGR |
| Kamera | Third-person jauh-tinggi gaya PGR | screenshot user |
| Audio | **TIDAK ADA** dulu (non-goal) | keputusan user |
| Frame rate | **Target 45 FPS, lantai 30 FPS** — diputuskan final pakai data ukur di M0 | kesepakatan "coba dulu" |

---

## 1. APA RENCANA GW

Tiga milestone. **Setiap milestone berakhir dengan APK ter-install di Infinix**, bukan "jalan di editor".

### M0 — "Pijakan" (fondasi + bukti device)
- Setup proyek Godot: renderer Compatibility, override mobile, cap FPS, struktur folder.
- Export Android **arm32 only** (armeabi-v7a) — bukti jalur 32-bit hidup.
- Arena sabana graybox: ground bertekstur, horizon, fog tipis tepi, beberapa pohon mati low-poly.
- Input: floating joystick + tombol serang + tombol dodge (glyph putih).
- Kamera third-person mengikuti kapsul player.
- **FPS meter on-screen** + log.
- **Gerbang lolos:** APK ter-install & jalan; 60 detik gerak bebas tanpa freeze; angka FPS baseline terekam di UAT log → **di titik ini kita kunci 45 atau 30** berdasar data (arena kosong = langit-langit kemampuan device).

### M1 — "Rasa Combat"
- Serangan combo 2 tahap, **dodge dengan i-frame**, **parry dengan window timing**.
- Hitbox/hurtbox sederhana, hitstop kecil, flash feedback (pengganti audio).
- Hydra graybox (badan + 3 leher kapsul) dengan 1 pola serangan dummy.
- **Gerbang lolos:** loop serang→dodge→parry terasa enak saat user main; FPS ≥ gerbang; tidak crash.

### M2 — "Hydra"
- Aset hydra stylized-realistic sesuai budget (§3 poin 4).
- 3 pola serangan: **bite sweep**, **tail swipe**, **semburan api (shader, bukan banjir partikel)** — semua ber-telegraph warna.
- Aturan desain+performa: **hanya 1 kepala aktif menyerang pada satu waktu** (2 lainnya idle) — baca: telegraph jelas + biaya animasi rendah.
- Bar boss tipis, win/lose state, restart, pause sederhana.
- **Gerbang lolos:** 3 kemenangan beruntun di Infinix; sesi 5 menit tanpa crash; FPS menit-5 ≥ gerbang (cek thermal); parry terasa adil.

### Non-goals (sengaja TIDAK dikerjakan)
Audio, open world/peta, save system, inventory, skill tree, multi-senjata, party/switch karakter, teks cerita, menu lengkap, export arm64, rilis Play Store.

---

## 2. BAGAIMANA ALURNYA

Loop per milestone (adaptasi loop engineering AGENTS.md §5):

```
spec kecil → implementasi kecil → tes editor → export APK arm32
→ install di Infinix (ADB; fallback transfer manual) → ukur & main
→ catat di docs/uat/uat-log.md (device, hash commit, FPS menit-1 & menit-5, RAM, catatan rasa)
→ perbaiki → ulang sampai gerbang lolos → commit unit kecil → ringkasan sesi di docs
```

- **Git:** commit kecil, reversibel, pesan jujur, hanya di branch `arena/01a03ddc-zdev-rpg`.
- **Riset sela** di antara pekerjaan: lihat §4.
- **Label status** dipakai apa adanya: IMPLEMENTED ≠ DEVICE VERIFIED.

### CI di GitHub Actions (masuk begitu skeleton M0 ada)
- Repo **publik** ⇒ menit Actions gratis unlimited.
- Workflow: push → Godot headless **4.7.2-stable (pin, jangan "latest")** → unit test headless → export APK arm32 → upload artifact.
- Export templates di-download + di-cache di runner, **tidak boleh masuk repo**.
- Keystore debug digenerate di CI; keystore release (nanti, kalau rilis) via GitHub Secrets sesuai §9 keamanan.
- **Bonus alur kerja:** artifact APK bisa lu install di Infinix langsung dari halaman GitHub — tanpa perlu PC build.
- Referensi pola teruji: game-ci *Build Godot Action* (Android SDK/NDK/JDK + cache templates) dan *godot-ci-android-export* (APK/AAB + debug keystore).
- Yang CI **tidak** bisa: menyentuh Infinix lu. Pembagian jujur — CI = compile/build/unit test (level CI VERIFIED), lu = rasa + FPS di device (level DEVICE VERIFIED).

---

## 3. KENDALA: YANG PASTI, YANG MUNGKIN, & PENANGANANNYA

### Pasti ditemui
| # | Kendala | Penanganan |
|---|---|---|
| 1 | **Fillrate/overdraw GPU Mali** (musuh utama) | tanpa MSAA, hindari alpha bertumpuk, lighting vertex/baked, tangga resolusi 100→85→70% sebelum memotong desain |
| 2 | **Userspace 32-bit** | export arm32 only; uji install sejak M0; budget memori ketat |
| 3 | **Compat renderer: tanpa compute shader; GPUParticles3D gagal diam-diam** | semburan api = shader animasi di quad/billboard; partikel = CPUParticles jumlah kecil bila perlu |
| 4 | **Rig 3 kepala hydra mahal (bone/skinning)** | aturan "1 kepala aktif"; animasi share/offset; badan ±20–30k tris, tekstur 1–2K |
| 5 | **Sabana = rumput = overdraw** | ground = tekstur+vertex color; rumput = kartu jarang hanya ≤±10 m dari kamera, tanpa alpha jarak jauh |
| 6 | **45 FPS mungkin tak tercapai** | lantai 30 sudah disepakati; M0 = titik keputusan berdasar data |
| 7 | **Agen tidak bisa membuat model 3D** | aset dari sumber CC (Sketchfab/Mixamo/Quaternius) dengan **cek lisensi tercatat di docs**; fallback: primitif stylized |
| 8 | **Tanpa audio ⇒ semua "feel" harus visual** | hitstop, flash, screen-shake kecil wajib dipoles di M1 |

### Mungkin ditemui
| # | Kendala | Penanganan |
|---|---|---|
| 9 | Quirk driver GLES di XOS/Infinix | ketahuan dini lewat device-test M0 |
| 10 | ADB/driver PC user bermasalah | fallback transfer APK manual (kabel/cloud) — tidak memblokir |
| 11 | XOS battery-optimization membunuh proses | skenario uji: layar tetap on; catat di UAT |
| 12 | Thermal throttling | bandingkan FPS menit-1 vs menit-5; drop >20% ⇒ turunkan setelan default |
| 13 | Bug Godot 4.7.2 | pin versi; cek issue tracker; workaround wajib ditulis + kondisi pelepasannya |
| 14 | Scope creep | non-goals di atas; tambahan apa pun = diskusi dulu (AGENTS.md §4) |

---

## 4. RISET DI SELA PEKERJAAN — SETUJU, WAJIB

Setuju — ini juga mandat AGENTS.md §17. Aturan gw:
- **Kapan search:** API/versi Godot yang ragu, teknik performa khusus Mali/GLES, resep shader, pencarian aset CC + lisensi.
- **Sitasi:** setiap keputusan penting mencantumkan URL sumber di docs.
- **Hierarki bukti:** hasil search = penunjuk, bukan kebenaran final. Kebenaran final = **jalan di device lu**.
- **Pin versi:** dokumentasi yang dibaca harus sesuai versi pin (4.7), bukan "latest".

---

## 5. TARGET GW (kriteria terima)

1. **Fungsional:** loop lengkap — gerak, serang, dodge, parry, 3 pola boss, menang/kalah, restart — jalan di Infinix.
2. **Performa:** 45 FPS target / 30 lantai, stabil 5 menit, tanpa crash; RAM terukur & tercatat.
3. **UX:** HUD sesuai kontrak §0; kontrol discoverable; parry adil.
4. **Bukti:** `docs/uat/uat-log.md` berisi nama device, angka, hash commit; status tiap milestone dilabeli jujur.
5. **Handoff:** docs selalu memungkinkan sesi lanjutan tanpa mengulang percakapan.

---

## 6. KEPATUHAN AGENTS.md

| Bagian | Penerapan |
|---|---|
| §1.1 Jujur | label status dipakai; non-goals ditulis; klaim tak teruji disebut "target" |
| §1.2 Teliti | commit kecil; baca dulu baru ubah; tidak ada write paralel ke file sama |
| §2 Kemitraan | dokumen ini = diskusi sebelum eksekusi; perubahan desain user diadopsi DENGAN catatan teknis |
| §3 Level status | dipakai per milestone (IMPLEMENTED → LOCALLY VERIFIED → DEVICE VERIFIED) |
| §4 Otonomi | **eksekusi hanya setelah approve user** (status dokumen ini) |
| §5 Loop | loop milestone = adaptasi 14 langkah |
| §6 Guard | FPS meter + UAT log = guard performa; skenario merah→hijau di device |
| §7 Diagnosis | angka UAT, bukan tebakan |
| §8 Lifecycle | satu pemilik game loop; pause/restart diuji di M2 |
| §9 Secrets | keystore debug lokal; tidak ada kredensial di repo |
| §10 Dependensi | tanpa dependensi baru selain aset CC; lisensi dicatat |
| §11 Platform | semua keputusan berbasis bukti armv7/Mali; sukses emulator ≠ sukses device |
| §12 UX | hint joystick, glyph putih, info penting tidak di zona jempol |
| §13 Resource | budget performa §3; artefak besar di luar git bila perlu |
| §16 Commit | unit kecil reversibel, pesan jujur |
| §18 Handoff | ringkasan sesi + langkah berikutnya selalu di docs |
| §20 Overlay | dokumen ini berperan sebagai PRD-lite repo |

**Gap yang gw akui:** saat dokumen ini ditulis CI belum ada ⇒ level "CI VERIFIED" sementara diganti gerbang lokal+device; CI GitHub Actions **direncanakan masuk di M0** (§2) untuk menutup gap ini; verifikasi device **belum terjadi** — dokumen ini rencananya, bukan buktinya.

---

## 7. LANGKAH PERTAMA SETELAH APPROVE (checklist M0)

1. Struktur proyek + `project.godot` (renderer, override mobile, FPS cap).
2. Setup export Android arm32.
3. Sabana graybox + kamera + input + FPS meter.
4. APK pertama → UAT log #1 → **keputusan 45/30 FPS**.

---

*Dokumen ini kontrak kerja. Perubahan apa pun lewat diskusi. Menunggu approve.*
