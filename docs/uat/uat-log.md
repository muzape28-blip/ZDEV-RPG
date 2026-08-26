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
  ke `.github/workflows/` dilakukan sekali oleh USER lewat web UI GitHub,
  atau user memberi permission `workflows` ke app.
- **Kondisi pelepasan workaround:** setelah workflow terpasang/permission
  diberikan, file di `docs/ci/` boleh dipindah balik dan saya yang kelola CI.
- **Verifikasi lokal yang ADA:** static guard tscn (load_steps, referensi
  resource, path script) HIJAU + review manual API GDScript.
- **Verifikasi lokal yang TIDAK ADA:** runtime headless (sandbox memblokir
  unduhan binary Godot) — JANGAN diklaim sebagai teruji.
