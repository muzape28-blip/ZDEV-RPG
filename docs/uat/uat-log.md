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
