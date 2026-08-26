# KESEPAKATAN KERJA — ZDEV-RPG

Disepakati 2026-08-26 antara user dan agen. Dokumen ini mengikat
cara kerja; perubahan lewat diskusi.

## 1. Prinsip kerja agen (dari user)

1. **Teliti berlapis:** sebelum menyentuh kode apa pun, check ulang
   berkali-kali. Tidak ada push kode yang belum terverifikasi.
2. **Riset dalam-dalam di sela kerja:** gali semua sumber (komunitas,
   docs resmi, Context7 bila relevan). Bandingkan ide/logika internal
   dengan data luar; putuskan mana yang layak, mana yang bisa dikombinasi.
3. **Ritme fleksibel:** laporan besar atau check-in kecil — pilihan agen —
   tetapi kualitas tidak dinegosiasikan.
4. **Keamanan sandbox utama:** segala kerja lokal (compile engine dsb.)
   wajib memprioritaskan keamanan: tanpa kredensial, artefak besar di
   direktori yang tidak ikut snapshot/git (.cache/), sumber hanya dari
   host resmi via HTTPS.

## 2. Target saat ini: BUG-FIXING M0 (bukan fitur)

Enam poin "M0 sehat" — semuanya harus terbukti di device sebelum M1:
1. Sosis berdiri di tanah ✅ (terbukti UAT #1)
2. Joystick kiri terlihat & berfungsi
3. Tombol dodge + serang terlihat & berfungsi
4. Kamera ikut saat berjalan
5. Kamera berputar saat drag kanan
6. Angka FPS terbaca

## 3. Aturan eksekusi

- Maksimal **satu perubahan perilaku per push**.
- Setiap push wajib lolos **verifikasi lokal headless** (engine compile
  lokal) setelah lapisan itu siap.
- Entri UAT ditulis sebelum & sesudah perubahan.
- Rollback ke "known good" lebih dihormati daripada perbaikan spekulatif.

## 4. Catatan desain dari user (untuk M1/M2, bukan sekarang)

- **Analog movement:** joystick sedikit = jalan, banyak = berlari —
  belum bisa dinilai selama karakter masih kapsul; logika kecepatan
  analog tetap bisa divalidasi lebih dulu lewat rasa kecepatan.
- **Motion style** (gaya tubuh berjalan/berlari/dodge) tertunda sampai
  karakter manusiawi ada (fase aset/animasi).
- UI/UX sebelum regresi terakhir dinilai **normal** oleh user selain kamera.
