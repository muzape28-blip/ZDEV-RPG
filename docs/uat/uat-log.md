# UAT LOG — ZDEV-RPG

Catatan bukti per build. Format entri:
`tanggal · commit · device · lapisan verifikasi · hasil · keputusan`.

---

## Entri #0 — 2026-08-26 · baseline M0

- **Build:** menunggu CI run pertama (push M0).
- **Device target:** Infinix Smart 9 HD — userspace armv7/32-bit (`armv8l`), Android 14 Go, 720×1600 @90Hz.
- **Lapisan verifikasi sejauh ini:**
  - source inspection + static guard (struktur tscn, referensi resource, path script) — HIJAU;
  - sandbox agen **tidak bisa menjalankan engine headless** (network memblokir unduhan binary Godot) ⇒ tidak ada klaim "LOCAL VERIFIED" untuk runtime; klaim runtime pertama datang dari **CI** (parse + export), lalu dari **device**.
- **Status M0:** IMPLEMENTED → menunggu CI VERIFIED → menunggu DEVICE VERIFIED.
- **Keputusan tertunda:** kunci 45 atau 30 FPS setelah angka FPS arena kosong terukur di device.

## Entri #0.5 — 2026-08-26 · push M0 & kendala permission CI

- **Commit:** `50b4535` (push pertama branch `arena/01a03ddc-zdev-rpg`).
- **Kendala:** credential platform (GitHub App) ditolak GitHub saat push file
  `.github/workflows/*` — *"refusing to allow a GitHub App to create or update
  workflow without `workflows` permission"*.
- **Workaround:** konten workflow dipindah ke `docs/ci/android-build.yml`
  (net diff branch tidak menyentuh `.github/workflows`). Instalasi workflow
  ke `.github/workflows/` dilakukan SEKALI oleh USER lewat web UI GitHub.
  (Opsi "grant permission workflows ke app" DIHAPUS 2026-08-26 — bukti user:
  pengaturan itu tidak ada di sisi Arena maupun GitHub; konsisten 4 bulan
  di 6 repo: ZABACODE, ZABAWHEELS, ZMUX, ZCLAW, ZCODE, ZDEV-RPG.)
- **Prosedur pasang:** copy raw `docs/ci/android-build.yml` (link raw di chat)
  → web UI: Add file → Create new file → nama `.github/workflows/android-build.yml`
  → paste → commit ke branch `arena/01a03ddc-zdev-rpg`.
- **Kondisi pelepasan workaround:** setelah workflow terpasang, file di
  `docs/ci/` boleh dipindah balik dan saya yang kelola CI (update workflow
  selanjutnya tetap butuh paste manual user selama permission belum ada).
- **Verifikasi lokal yang ADA:** static guard tscn (load_steps, referensi
  resource, path script) HIJAU + review manual API GDScript.
- **Verifikasi lokal yang TIDAK ADA:** runtime headless (sandbox memblokir
  unduhan binary Godot) — JANGAN diklaim sebagai teruji.

## Entri #0.6 — 2026-08-26 · CI run pertama & bug nama templates

- **Run:** #32974860643 — FAILURE di step "Install export templates".
- **Root cause (bug agen):** URL templates menulis
  `Godot_v${GODOT_VERSION}_stable_export_templates.tpz` ⇒ ter-render
  `...stable_stable...` ⇒ 404. Nama resmi (diverifikasi via API release):
  `Godot_v4.7.2-stable_export_templates.tpz`.
- **Perbaikan:** copy docs di-commit (`3c189b8`); file workflow aktif di
  `.github/workflows/` menunggu edit satu baris oleh user (agen tidak punya
  permission push workflows).
- **Pelajaran dicatat:** cek nama aset rilis via API sebelum menulis URL di CI.

## Entri #0.7 — 2026-08-26 · run kedua: folder templates salah nama

- **Gejala (log user):** "No export template found at .../export_templates/
  4.7.2.stable/android_debug.apk".
- **Root cause (bug agen):** folder dibuat `4.7.2-stable` (hyphen); Godot
  menuntut `4.7.2.stable` (titik).
- **Perbaikan:** hardcode folder `4.7.2.stable` di workflow + satu baris
  preventif sdkmanager (build-tools & platform 34) biar zipalign/apksigner
  pasti ada saat export.
- **Pelajaran dicatat:** path konvensi Godot (format versi bertitik) harus
  diverifikasi dari pesan error/daftar path yang diharapkan, bukan diasumsikan
  sama dengan tag rilis.

## Entri #1 — 2026-08-26 · DEVICE VERIFIED (launch) — laporan pertama dari Infinix

- **Build:** journey.apk (debug, arm32) — APK pertama yang ter-install & jalan.
- **Temuan user:**
  1. "Sosis nembus ke bawah" → root cause: ground hanya MeshInstance3D,
     TIDAK ADA physics body (klasik, dikonfirmasi komunitas r/godot & forum).
  2. Kamera tidak bisa digerakkan → M0 memang belum ada input orbit (gap desain).
  3. "Sosis coklat" → material putih × matahari senja warm = coklat (kosmetik).
- **Perbaikan (commit menyusul entri ini):**
  - Ground = StaticBody3D + BoxShape3D tebal 400×2×400 (solid, bukan plane
    satu sisi — rekomendasi komunitas anti-tunneling).
  - Kamera: orbit yaw via drag setengah kanan layar (`_unhandled_input`,
    tidak mencuri sentuhan tombol/joystick).
  - Gerakan player kini RELATIF yaw kamera (joystick atas = menjauhi kamera).
  - Guard respawn jika y < -30 (anti-void permanen).
- **Status:** menunggu rebuild CI → UAT #2 (test: jalan, dodge, drag kamera,
  angka FPS menit-1 & menit-5).
