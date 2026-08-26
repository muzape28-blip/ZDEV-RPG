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

## Entri #2 — 2026-08-26 · UAT #2: kamera mati total; redesign struktural

- **Laporan user:** ground & tombol & joystick HIDUP; kamera diam total
  (tidak follow, tidak merespons drag).
- **Analisis kanal:** joystick (_input) & tombol (_gui_input) terbukti jalan;
  satu-satunya kanal tak terbukti = `_unhandled_input` (drag kamera) dan
  script kamera itu sendiri. Komunitas mengonfirmasi `_unhandled_input`
  bisa tidak menerima touch di export bila ada UI fullscreen
  (r/godot gabdb9).
- **Redesign (referensi: bugnet.io "Fix Camera3D Not Following Player"):**
  1. Follow jadi STRUKTURAL: CameraPivot child of Player → kamera nempel
     lewat scene tree; bahkan jika script mati, follow tetap jalan
     (rotasi statis di tscn sebagai fallback framing).
  2. Orbit drag dipindah ke `hud.gd::_input` (kanal terbukti), dengan
     pengecualian rect tombol.
  3. Player baca yaw dari pivot; fallback yaw=0 bila script pivot mati.
  4. Debug label dihapus (kebijakan user: tanpa scaffolding support).
- **Pelajaran dicatat:** di platform yang tidak bisa di-debug langsung,
  gunakan kanal/pola yang SUDAH terbukti hidup di device; jadikan follow
  struktural, bukan ketergantungan script.
- **Status:** menunggu CI → UAT #3.

## Entri #3 — 2026-08-26 · regresi, insiden GitHub, lapisan verifikasi lokal

- **Regresi e0f93a1 diakui:** HUD mati di device (joystick/tombol hilang).
  Target kini BUG-FIXING M0 (6 poin, WORKING-AGREEMENT §2). Belum ada
  perubahan game-code sejak regresi (disengaja, menunggu lapisan verifikasi).
- **Insiden GitHub Actions** (15:09–15:23+ UTC, database primary failover)
  ⇒ CI tidak boleh jadi satu-satunya gerbang. Bukti tambahan untuk lapisan
  verifikasi lokal.
- **Lapisan verifikasi lokal (Langkah 0, disetujui user dgn syarat keamanan):**
  - source tarball 4.7.2-stable (codeload.github.com, HTTPS) sha256
    `e954996374cbd1cb5d72e0e3781cc537408e6ce73b010b12c6c2f308a820690a`;
  - compile di `.cache/` (di luar git & snapshot), venv terpisah (scons +
    pykg-config sebagai shim pkg-config), tanpa kredensial apa pun;
  - flags minimal headless: x11=no wayland=no alsa=no pulseaudio=no udev=no;
  - tujuan: parse script + boot headless SEMUA perubahan sebelum push.
- **Riset sela (kebiasaan user):** docs resmi InputEvent (urutan pipeline
  dikonfirmasi) + referensi locomotion blend (magnitude joystick → blend
  walk/run; pola threshold komunitas & blend space industri). Desain
  analog-movement dicatat di WORKING-AGREEMENT §4.

## Entri #4 — 2026-08-26 · MISTERI TERPECAHKAN + lapisan verifikasi lahir

- **Root cause regresi e0f93a1:** `hud.gd:99` — `var dx := event.position.x`
  dengan `event: InputEvent` (kelas dasar tanpa `.position`) ⇒ **Parse Error
  di runtime device** ⇒ seluruh HUD (dibangun via kode) mati ⇒ joystick,
  tombol, dan drag kamera lenyap. Follow struktural kamera TIDAK rusak —
  sosis hanya tak bisa bergerak tanpa joystick.
- **Kenapa CI/export lolos:** export Godot **tidak meng-compile GDScript**;
  kompilasi terjadi saat runtime di device. Blind spot ini kini ditutup.
- **Lapisan verifikasi lokal LAHIR:** Godot 4.7.2-stable di-compile headless
  di sandbox (sha source tercatat di entri #3) → `tools/verify-local.sh`:
  parse semua script + boot 40 frame. Hasil pasca-fix: **7/7 parse OK,
  boot OK**.
- **Fix minimal (1 baris):** cast eksplisit `event as InputEventScreenDrag`.
  Rollback tidak diperlukan — desain drag-di-hud terbukti valid.
- **Aturan permanen:** verify-local WAJIB hijau sebelum push; step serupa
  akan ditambahkan ke CI pada paste workflow berikutnya.
- **Status:** menunggu Actions pulih (insiden GH) → APK → UAT #4 device.

## Entri #5 — 2026-08-26 · M0 LULUS 6/6 + pitch kamera

- **UAT #4 (user):** enam poin M0 HIJAU; kamera dinilai 70% (yaw saja).
- **Perbaikan:** pitch kamera via drag vertikal, clamp [-0.5, 0.3] rad
  (tidak tembus tanah / tidak top-down ekstrem), sensitivitas 0.004.
- **Gerbang:** verify-local HIJAU (7 parse + boot 40 frame).
- **Infra:** binary engine tidak bertahan di snapshot ⇒ arsip
  `tools/godot-headless.xz` (18M) + auto-dekompres di verify-local.sh.
- **Status:** menunggu CI → UAT #5 (kamera 100%: yaw + pitch).

## Entri #6 — 2026-08-26 · regresi berulang di device + blackbox DIAG

- **Laporan user:** gejala identik UAT#3 (HUD mati total) muncul lagi pada
  build pitch (run 33007148743), padahal parse+boot lokal HIJAU.
- **Hipotesis terbuka:** ada kegagalan runtime/parse khusus device yang tak
  tertangkap desktop — KITA BUTUH BUKTI, bukan tebakan.
- **Blackbox DIAG (main.gd):** label on-screen `DIAG hud=? anak=? pivot=?`
  (script hud load?, jumlah child HUD terbangun, pivot ada?) — terpisah dari
  hud.gd sehingga hidup walau hud mati. UAT #6 = baca baris ini.
- **Infra persisten:** snapshot membuang file >~10MB ⇒ engine diarsip
  terpecah `tools/parts/gh.*` (7M+7M+3.8M); verify-local merakit ulang
  otomatis. Terbukti: gate bangkit dari parts, HIJAU.
- **Gerbang CI permanen (menunggu paste user sekali):** step PARSE-CHECK +
  BOOT-CHECK headless di docs/ci/android-build.yml — CI tidak bergantung
  pada persistensi sandbox.
