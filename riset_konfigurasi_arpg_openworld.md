# Riset Konfigurasi Teknis: Kamera, Dodge, Floor, First Spawn & Basic Action Config di Game ARPG Open-World Third-Person AAA

## Catatan Pembuka & Metodologi (Baca Dulu)

Sebelum masuk ke data, penting untuk jujur soal apa yang bisa dan tidak bisa didapat dari riset publik:

- Studio-studio besar (FromSoftware, Sony Santa Monica, Guerrilla, Ubisoft, Team Ninja, Game Science, Sucker Punch) memakai **engine internal/proprietary**. Mereka **tidak pernah mempublikasikan source code atau nama variabel internal**. Jadi angka seperti i-frame Elden Ring itu bukan dari dokumen resmi FromSoftware — itu hasil **frame-counting komunitas** (dari review footage, disilangkan lintas banyak tester selama bertahun-tahun). Angka ini terbukti sangat konsisten lintas sumber, jadi reliabilitasnya tinggi, tapi tetap bukan dokumentasi resmi developer.
- Data **Unreal Engine** dan **Unity** di bawah ini ADALAH dokumentasi/API resmi — nama variabel dan default value ini memang benar-benar ada di engine tersebut. Tapi **tidak semua game di bawah pakai Unreal/Unity** (Genshin Impact confirmed pakai Unity; Elden Ring, God of War, Horizon, Ghost of Tsushima pakai engine internal masing-masing). Jadi bagian Unreal/Unity saya posisikan sebagai **"blueprint arsitektur rujukan industri"** — cara paling umum & terdokumentasi untuk membangun sistem yang konsepnya sama dengan game-game AAA tersebut, bukan klaim "Elden Ring pakai variabel bernama TargetArmLength".
- Setiap klaim ditandai levelnya:
  - **[RESMI]** = dokumentasi/API resmi developer atau engine, atau wawancara langsung developer di media resmi.
  - **[KOMUNITAS]** = hasil riset/frame-count/wiki komunitas yang biasanya reliable dan cross-referenced bertahun-tahun.
  - **[FORUM/OPINI]** = laporan/opini pemain di forum — dipakai untuk menunjukkan pola desain atau keluhan nyata, bukan fakta keras.

**Game yang dijamah untuk riset ini:** Elden Ring & lineage Dark Souls (FromSoftware), God of War 2018 & Ragnarök (Sony Santa Monica), Nioh 1/2/3 (Team Ninja), Horizon Zero Dawn & Forbidden West (Guerrilla), Assassin's Creed Valhalla & Shadows (Ubisoft), Ghost of Tsushima (Sucker Punch), Black Myth Wukong (Game Science), Genshin Impact (miHoYo/HoYoverse) — plus dokumentasi resmi **Unreal Engine** dan **Unity** sebagai referensi arsitektur teknis paling umum dipakai industri.

---

## BAGIAN 1 — LOGIKA KAMERA DI SEMUA MOVEMENT

### 1.1 Fondasi: Camera Boom / Spring Arm `[RESMI — Unreal Engine docs]`

Hampir semua kamera third-person modern dibangun di atas konsep "spring arm" / "camera boom": kamera tidak nempel langsung ke karakter, tapi digantung di ujung sebuah lengan virtual yang:

- Punya panjang natural (**Target Arm Length** — contoh resmi di dokumentasi: 400 unit)
- Otomatis **memendek** kalau ada tembok/objek menghalangi antara pivot dan kamera (collision test), lalu **kembali memanjang** begitu halangan hilang
- Collision-nya dites pakai sebuah **probe sphere** (parameter **Probe Size** = radius bola tes) di **collision channel** tertentu (default `ECC_Camera`)
- Punya **Socket Offset** (geser posisi akhir kamera dari ujung lengan) dan **Target Offset** (geser titik yang dilihat)

Contoh setup resmi dari dokumentasi C++ Unreal Engine:

```
SpringArm->TargetArmLength = 400.0f;
SpringArm->bEnableCameraLag = true;
SpringArm->CameraLagSpeed = 3.0f;
```

`bEnableCameraLag` + `CameraLagSpeed` inilah yang bikin kamera "telat sedikit" mengikuti karakter, bukan snap instan. Ada juga `bEnableCameraRotationLag` untuk delay rotasi kamera secara terpisah dari delay posisi.

**Masalah klasik spring arm default:** saat retract akibat collision, kamera bisa **teleport** balik-maju dan kelihatan patah-patah. Solusi tingkat-AAA yang lebih halus (pola yang beredar di komunitas, terinspirasi struktur internal Lyra milik Epic) memakai teknik **"penetration avoidance feelers"**: bukan satu probe lurus dari pivot ke kamera, tapi **banyak sphere-sweep** dengan sudut rotasi berbeda di sekitar arah utama, supaya sistem bisa **memprediksi** collision sebelum kamera benar-benar menembus dinding, lalu bergeser mulus — bukan teleport. `[KOMUNITAS]`

### 1.2 Camera-Relative Movement `[Prinsip umum industri]`

Hampir semua ARPG third-person modern pakai kontrol **camera-relative**, bukan character-relative: saat pemain menekan "kiri", karakter bergerak ke **kiri layar** (relatif arah pandang kamera), bukan ke kiri tubuh karakter itu sendiri. Implementasi umumnya:

1. Ambil vektor input dari stick/WASD
2. Rotasi vektor itu berdasarkan **yaw kamera saat ini**
3. Karakter berputar menghadap arah hasil rotasi tadi, baru bergerak maju ke sana

Developer menyebut ini jauh lebih intuitif buat pemain dibanding character-relative, walau perlu sinkronisasi rotasi kamera dan rotasi badan karakter setiap frame.

### 1.3 Smoothing Kamera: Kenapa Lerp Naif Itu Salah `[Prinsip umum — matematika kontrol, dari beberapa artikel teknis]`

Ini bagian yang sering diskip developer pemula, padahal krusial buat "rasa" kamera AAA.

- **Cara naif (bermasalah):** `camera.position = lerp(camera.position, target, 0.1)` tiap frame. Ini **tidak framerate-independent** — di 60fps kamera "mengejar" 10% jarak sisa per frame; di 30fps update lebih jarang jadi kelihatan lambat/nyendat; di 144fps kamera jadi terlalu gesit/kedutan (twitchy).
- **Cara benar: exponential damping.** Formulanya berbentuk `factor = 1 - exp(-λ * Δt)`, di mana λ = damping constant (makin besar λ, makin gesit respons) — dan hasilnya **konsisten di framerate berapa pun**.
- **Level lebih tinggi: critically damped spring** (spring-mass-damper system). Sistem pegas ini punya 4 kategori: undamped (berosilasi terus), underdamped (mantul-mantul dulu baru diam), **critically damped** (langsung menuju target secepat mungkin TANPA mantul), overdamped (terlalu lambat). Kamera AAA nyaris selalu pakai critically damped — ini juga dasar fungsi `SmoothDamp` di Unity, yang mengimplementasikan artikel klasik "Critically Damped Ease-In/Ease-Out Smoothing" (Game Programming Gems 4).
- **Look-ahead:** kamera sering menggeser titik fokus beberapa meter **di depan** arah gerak karakter (bukan pas di tengah karakter) supaya pemain lebih bisa lihat ke depan. Offset ini tetap di-smooth, bukan snap.
- **Parameter kontekstual dinamis:** kamera AAA jarang statis satu setting — umumnya blending antar beberapa "profile" tergantung state: mode combat kamera lebih dekat & rendah, mode eksplorasi lebih jauh & tinggi, saat aiming geser ke over-the-shoulder. Transisi antar-profile tetap pakai damping yang sama, dilakukan dalam pecahan detik.

### 1.4 Studi Kasus: Sistem Lock-On Elden Ring `[KOMUNITAS — analisis desain independen, bukan dokumentasi FromSoftware]`

Berdasarkan analisis reverse-engineering independen oleh seorang game designer (dipublikasikan di blog pribadinya, bukan dari FromSoftware), sistem lock-on Elden Ring menentukan target berdasarkan kombinasi 3 faktor utama:

1. **Frontal cone** — apakah musuh ada di kerucut arah hadap model karakter
2. **Camera view** — apakah musuh kelihatan di frame kamera saat ini
3. **Jarak** musuh ke pemain

Musuh yang lebih dekat ke **pusat** frontal cone/kamera makin diprioritaskan. Saat lock-on berhasil, kamera melakukan **re-centering** — otomatis memutar supaya searah hadap karakter, lalu berputar mengunci ke target baru.

Pola masalah yang sering dikeluhkan pemain (dan dikonfirmasi analisis tersebut):

- Musuh **pasif** yang jauh tapi persis di depan mata kadang malah ke-lock ketimbang musuh agresif yang lebih dekat tapi di luar frontal cone (contoh klasik: tanpa sengaja lock ke domba di kejauhan saat sedang dikejar boss)
- Musuh yang **terhalang objek** kadang tetap bisa ke-lock
- Re-centering kamera bisa "menarik paksa" ke target yang tidak dimaksud pemain

`[FORUM]` Jangkauan lock-on Elden Ring jauh lebih besar dibanding game Souls sebelumnya (kompensasi untuk open world). Terhadap musuh yang sangat cepat/besar, banyak pemain justru mematikan lock-on dan main free-cam manual, karena rotasi kamera yang whip-cepat saat lock malah bikin disorientasi.

### 1.5 Studi Kasus: Kamera "One-Shot" God of War (2018 & Ragnarök) `[RESMI — wawancara developer via Polygon/GameDeveloper/Variety]`

Sony Santa Monica membangun seluruh game (2018 dan Ragnarök) sebagai satu shot kamera tanpa potongan — tidak ada cut, tidak ada loading screen terlihat. Menurut sutradara Cory Barlog, ini **bukan continuous shot murni secara teknis** — timnya memakai "enam sampai delapan trik" tersembunyi (transisi disamarkan lewat pan kamera, lewat pintu, dsb) sepanjang permainan untuk menyembunyikan cut/load sebenarnya. Camera director game ini, Dori Arazi, menyebut kameranya diperlakukan sebagai **"karakter tambahan"** dalam setiap scene — bukan sekadar alat lihat, tapi bagian dari storytelling.

Konsekuensi desain:

- Framing **over-the-shoulder yang sangat dekat** (untuk kedekatan/intimasi sinematik)
- Tradeoff: kamera dekat ini bagus untuk 1-lawan-1/beberapa musuh, tapi jadi kelemahan saat harus membaca arena besar/grup musuh banyak — sebagian diskusi komunitas desain (ResetEra) berpendapat ini yang bikin GoW modern terasa "sempit" dibanding game action lain yang kameranya lebih jauh. `[FORUM/OPINI]`

### 1.6 Perbandingan Pola Kamera Lintas Game

| Game | Sistem Kunci Target | Karakteristik Kamera | Level Sumber |
|---|---|---|---|
| Elden Ring | Hard lock-on (frontal cone + camera view + jarak) | Jangkauan besar, kadang salah target di grup musuh | KOMUNITAS |
| God of War 2018/Ragnarök | Soft-aim, tidak ada lock-on klasik | Sangat dekat, over-the-shoulder, "one shot" tanpa cut | RESMI |
| Horizon Forbidden West | Tidak ada lock-on di kombat sama sekali | Kamera bebas, mengandalkan awareness arah manual pemain | FORUM (keluhan eksplisit) |
| Assassin's Creed Shadows/Valhalla | Soft-target otomatis ke musuh yang sedang menyerang | Dekat, dinamis pindah fokus antar musuh | RESMI (blog Ubisoft) + FORUM |
| Genshin Impact | Tidak ada hard lock-on tradisional | Third-person bebas orbit, jarak zoom manual | KOMUNITAS |

### 1.7 Dead Zone & Sensitivitas Kamera `[RESMI — spesifikasi input umum]`

Stick analog kanan (gerak kamera) hampir selalu punya **dead zone** — radius kecil di sekitar titik netral yang diabaikan sistem supaya noise/drift stick tidak terbaca sebagai gerakan kamera. Nilai umum di industri **~20–30% dari total travel stick** (contoh konkret yang sering disebut: sekitar 8000 dari skala mentah 0–32767 untuk XInput, kira-kira 25%). Ada dua lapis: **inner dead zone** (dekat pusat, buang noise diam) dan **outer dead zone** (dekat batas maksimal, menjamin nilai penuh tetap tercapai walau stick fisik tidak mentok sempurna). Bentuknya biasanya **radial (lingkaran)**, bukan per-axis, supaya gerakan diagonal tidak terasa "nyangkut".

---

## BAGIAN 2 — LOGIKA DODGE

### 2.1 Konsep Dasar: I-Frame (Invincibility Frame)

Di hampir semua ARPG bergaya Souls, dodge/roll punya jendela beberapa frame di awal animasi di mana karakter **kebal total** terhadap damage — walau secara visual hitbox-nya kelihatan overlap dengan serangan musuh. Setelah jendela itu habis, masuk **recovery frame**: karakter masih dalam animasi (tidak bisa input lain) tapi sudah bisa kena hit lagi.

### 2.2 Data Rinci: Elden Ring `[KOMUNITAS — frame-count wiki, cross-referenced bertahun-tahun; semua angka di 30fps]`

Roll/backstep ditentukan oleh rasio **Equip Load** (berat bawaan / max load):

| Equip Load | I-Frame Roll | Recovery Frame Roll | Backstep Recovery |
|---|---|---|---|
| ≤ 29.9% (Light) | 13 | 8 | Fast |
| 30.0–69.9% (Medium) | 13 | 8 | Medium |
| 70.0–99.9% (Heavy) | 12 | 16 | Slow |
| ≥ 100% (Overloaded) | Tidak bisa roll/backstep | — | — |

Jarak tempuh roll (meter, selama fase invulnerable): Light 4.09m, Medium 3.21m, Heavy 2.66m, Overencumbered 0.51m.

**Jump juga punya i-frame** — tapi cuma **parsial** (kebal dari pinggang ke bawah saja; kepala/dada/tangan tetap bisa kena), selama 25 frame + 5 frame recovery (di 30fps). Makanya jump efektif untuk serangan horizontal/dari-tanah, tidak efektif untuk serangan overhead.

**Sumber i-frame lain** yang jarang disadari pemain baru: membuka pintu/peti, mengaktifkan tuas, mount/dismount Torrent (kuda), parry sukses, dan saat melakukan critical hit.

**Item yang extend i-frame** (contoh): Crucible Feather Talisman (+3 i-frame, -3 recovery frame, dengan trade-off -damage negation), Windy Crystal Tear (efek serupa, sementara 3 menit).

**Skill dodge (Ashes of War)** — contoh representatif:

| Skill | FP | Delay | I-Frame | Recovery |
|---|---|---|---|---|
| Quickstep | 3 | 0 | ~15 | 10 |
| Bloodhound's Step | 5 | 0 | ~16 | 10–12 |
| Vow of the Indomitable | 20 | 4 | 30 | 11 |
| Miriam's Vanishing (spell) | 9 | 16 | 27 | 0 |

Catatan: i-frame Quickstep & Bloodhound's Step **berkurang 2** kalau dipakai berulang beruntun (kecuali versi light-load Quickstep, hanya berkurang 1), dan cuma 5 i-frame kalau FP habis.

### 2.3 Nioh — Dodge Terikat Sistem "Ki" `[KOMUNITAS/FORUM]`

Nioh (Team Ninja) mengganti stamina biasa dengan sistem **Ki**: dodge (dan serangan) menguras Ki, dan pemain bisa menekan tombol **Ki Pulse** setelah aksi untuk memulihkan Ki lebih cepat. Ada skill khusus yang membuat **dodge otomatis melakukan Ki Pulse** tanpa input terpisah — jadi dodge dan manajemen stamina jadi satu aksi menyatu. Timing Ki Pulse perlu jeda kecil (~0.5–1.0 detik) setelah aksi sebelumnya. Berat senjata/armor memengaruhi seberapa besar Ki terpakai tiap dodge — build armor ringan = dodge lebih murah.

### 2.4 God of War Ragnarök — Dodge + Parry + Sistem Cincin Warna `[KOMUNITAS — pola desain terverifikasi konsisten lintas banyak guide]`

GoW Ragnarök punya sistem telegraf warna yang jelas untuk mengajari pemain aksi defensif mana yang benar:

- **Cincin kuning** = serangan bisa **di-parry** (timing block/L1 tepat sebelum kena)
- **Cincin merah** = serangan **unblockable**, wajib **dodge** (atau interupsi via Spartan Rage)
- **Cincin biru ganda** = harus **diinterupsi** dengan double-tap shield-bash (tidak bisa full di-dodge karena area serangannya luas/AoE)

Dodge sendiri: tekan tombol dodge + arah stick kiri ke arah yang diinginkan.

### 2.5 Horizon Zero Dawn vs Forbidden West — Evolusi Sistem Dodge `[FORUM — konsisten lintas banyak diskusi pemain]`

- **Zero Dawn:** dodge-roll bisa dispam tanpa batas stamina yang keras.
- **Forbidden West:** dodge **dibatasi maksimal 3x beruntun** sebelum Aloy staggered/lelah (bisa ditambah via perk armor +1/+2). Ada **slide** sebagai alternatif dodge (jarak lebih jauh, juga punya i-frame), keduanya bisa **dirantai** (roll lalu slide) untuk memperpanjang durasi kebal + jarak tempuh. Ada opsi (default ON) dodge otomatis lewat double-tap tombol arah gerak.
- Salah satu keluhan komunitas paling konsisten: HFW **tidak punya sistem lock-on** sama sekali di kombat — beda dari kebanyakan game di riset ini — jadi pertahanan sepenuhnya mengandalkan awareness arah manual pemain.

### 2.6 Assassin's Creed Shadows/Valhalla — Dodge Berbeda per Karakter `[RESMI — blog resmi Ubisoft + guide]`

AC Shadows punya dua protagonis dengan implementasi dodge **berbeda secara mekanis**, bukan cuma beda animasi:

- **Naoe (shinobi):** dodge berupa **roll** terarah; endurance-nya lebih rendah sehingga dodge jadi alat pertahanan utamanya.
- **Yasuke (samurai):** dodge berupa **directional step** yang mempertahankan postur tegak; dodge kedua berturut-turut punya sedikit recovery period yang tidak dimiliki Naoe.
- Serangan **unblockable** ditandai cahaya **merah** (pola mirip God of War) — wajib dodge, parry tidak akan berhasil.
- **Dodge punish:** dodge dengan timing tepat membuka state vulnerable di musuh, memberi peluang counter.

### 2.7 Black Myth Wukong — Perfect Dodge & Cloud Step `[KOMUNITAS/wiki + FORUM]`

Wukong punya konsep **"Perfect Dodge"** — dodge dengan timing presisi tinggi yang otomatis memicu state **Cloud Step** (karakter jadi semi-transparan, meninggalkan decoy/bayangan untuk mengecoh musuh, pemain dapat serangan balik gratis lewat "Unveiling Strike"). Versi manual Cloud Step (dicasting via spell terpisah) juga bisa dipicu lewat "Tactical Retreat".

`[FORUM/OPINI]` Contoh tegangan desain nyata: sebagian pemain di forum Steam mengeluh dodge normal terasa kurang responsif dibanding Cloud Step, dan mengusulkan agar dodge dasar dibuat sama instannya (tanpa animation-lock). Ini contoh bagus soal tradeoff **commitment vs responsiveness** dalam desain dodge — makin "murah"/instan sebuah dodge, makin gampang di-spam dan makin kurang terasa berisiko.

### 2.8 Genshin Impact — Dash I-Frame, Bukan Dodge-Roll Klasik `[KOMUNITAS/wiki]`

Genshin tidak punya tombol "dodge" terpisah seperti game lain di riset ini. Sebagai gantinya, animasi **dash** (mulai lari cepat/menghindar) punya jendela i-frame kecil di awal — pemain harus membaca timing serangan musuh dan mengaktifkan dash tepat sebelum kena. Ada juga i-frame kecil terpisah saat **swap karakter** di tim. Genshin Impact confirmed dibangun di atas **Unity**.

### 2.9 Pola Umum Lintas Game

- **Trade-off resource** hampir universal: dodge selalu menguras sesuatu (stamina/Ki/jumlah-dodge-beruntun) supaya tidak bisa dispam tanpa batas.
- **Telegraf warna** (kuning=parry, merah=dodge/unblockable) muncul independen di God of War **dan** Assassin's Creed — konvergensi ini menunjukkan pola tersebut adalah "best practice" genre untuk readability, bukan kebetulan.
- **Dodge terarah** (directional, mengikuti input stick gerak) jadi standar, bukan tombol terpisah per arah.
- **"Perfect"/timed dodge** yang dikasih reward ekstra (Perfect Dodge Wukong, perfect parry GoW, dsb) adalah pola umum untuk memberi skill ceiling ke pemain hardcore tanpa mempersulit pemain casual — dodge biasa tetap berfungsi, hanya tidak dapat bonus.

---

## BAGIAN 3 — LOGIKA FLOOR / GROUND DETECTION

### 3.1 Unreal Engine: Character Movement Component `[RESMI]`

- **Walkable Floor Angle** — sudut maksimum (derajat) permukaan yang masih dianggap "bisa dipijak". Default sekitar **45°**. Lebih curam dari itu, karakter tidak bisa naik / malah melorot turun.
- **Walkable Floor Z** — representasi setara dalam komponen-Z dari normal permukaan (dipakai internal untuk perbandingan cepat dibanding menghitung sudut tiap frame).
- Deteksi lantai (`FindFloor` / `ComputeFloorDist`) dilakukan lewat **capsule sweep ke bawah** dari kapsul collision karakter, dengan fallback **line trace sederhana** kalau sweep gagal menemukan lantai walkable.
- Tiap objek/physics body individual bisa **override** aturan walkable-slope-nya sendiri (independen dari setting default karakter) lewat **Walkable Slope Behavior** (bisa menurunkan atau menaikkan batas sudut walkable khusus permukaan itu).
- `[KOMUNITAS]` Rule of thumb yang sering direkomendasikan: batasi Walkable Floor Angle di kisaran **50–55°** — lebih dari itu sudah terasa "manjat tembok", bukan jalan di tanjakan.

### 3.2 Unity: CharacterController & Ground Detection `[RESMI + KOMUNITAS]`

- `CharacterController.isGrounded` — flag boolean, tapi `[KOMUNITAS — keluhan developer berulang]` nilainya baru valid **setelah** pemanggilan `Move()`/`SimpleMove()` terakhir, jadi ada jeda semacam "1 frame" dan bisa false-negative kalau karakter diam persis di atas tanah tanpa gerakan vertikal kecil. Banyak developer profesional akhirnya membuat **ground check custom**: raycast atau spherecast pendek ke bawah dari dasar kapsul karakter, dievaluasi eksplisit tiap frame, lebih reliable untuk hal presisi seperti jump-buffering.
- **Slope Limit** dan **Step Offset** adalah dua parameter bawaan `CharacterController` yang otomatis menangani tanjakan dan anak tangga tanpa kode tambahan.
- Package Unity yang lebih baru (`com.unity.charactercontroller`) memformalkan konsep ini lewat callback `IsGroundedOnHit` (evaluasi sudut slope custom), fitur **snap-to-ground** (`SnapToGround`, karakter "nempel" ke permukaan menurun alih-alih terlempar ke udara tiap kali lewat turunan kecil), dan **reorientasi velocity** otomatis mengikuti kemiringan lantai (supaya kecepatan tidak hilang saat transisi datar-ke-miring).

### 3.3 Foot IK — Menempelkan Kaki ke Permukaan Tidak Rata `[RESMI/praktik industri universal]`

Hampir semua AAA third-person modern memakai **2-bone IK** per kaki untuk koreksi pose:

1. Line trace ke bawah dari posisi tiap kaki (sesuai animasi asli) untuk mencari ketinggian & normal lantai sebenarnya di titik itu
2. Blend pose animasi asli dengan target IK yang sudah dikoreksi, supaya kaki tidak "melayang" atau "menembus" tanah di permukaan miring/tangga
3. Sering dipasangkan dengan **"speed warping"** (menyesuaikan panjang langkah animasi agar match kecepatan gerak aktual, mencegah foot-sliding) dan koreksi offset pinggul/pelvis supaya badan tidak menembus tanah kalau dua kaki beda ketinggian

Tanpa foot IK, karakter yang berjalan di tangga/tanjakan/medan tidak rata akan terlihat "meluncur" atau kaki menembus lantai — salah satu tanda paling jelas pembeda AAA vs game murahan secara visual, karena kamera third-person "membaca" animasi kaki jauh lebih kritis dibanding first-person.

---

## BAGIAN 4 — LOGIKA FIRST SPAWN

### 4.1 Unreal Engine: PlayerStart & GameMode `[RESMI]`

- **PlayerStart Actor** — actor penanda lokasi spawn, ditaruh manual di level; punya representasi visual panah yang menunjukkan **arah hadap** karakter saat spawn di titik itu.
- **Kalau level tidak punya PlayerStart sama sekali**, engine akan spawn pemain di koordinat **(0,0,0)** secara default — detail kecil yang sering jadi sumber bug "kenapa karakter spawn di tengah lantai/menembus dunia" bagi developer pemula.
- Kalau ada **lebih dari satu PlayerStart**, engine memilih salah satu secara acak, dengan prioritas ke yang **tidak terhalang** (unobstructed) objek lain.
- Alur teknis di `GameMode`: fungsi `ChoosePlayerStart()` menentukan titik spawn yang dipakai, lalu `RestartPlayer()` benar-benar melakukan proses spawn/respawn — fungsi yang sama dipanggil lagi tiap kali karakter perlu **respawn**, biasanya dengan titik PlayerStart yang sudah di-update ke checkpoint terakhir.

### 4.2 Studi Kasus: Sistem Checkpoint Dua-Lapis Elden Ring `[KOMUNITAS/wiki]`

Elden Ring (dan seri Souls secara umum) memakai pola checkpoint yang jadi rujukan genre:

- **Site of Grace** (setara "bonfire" di Dark Souls) — checkpoint "full-service": heal HP/FP penuh, isi ulang flask/konsumabel, **respawn ulang musuh biasa** di sekitar area (bukan boss), membuka fast-travel, dan tempat leveling. Kalau karakter mati, dia **resurrect** di Site of Grace terakhir yang disinggahi.
- **Stake of Marika** — checkpoint ringan lapis-kedua: hanya menentukan **titik resurrect** kalau mati (supaya tidak perlu jalan jauh dari Site of Grace terakhir), tapi TIDAK memberi akses leveling/isi ulang flask seperti Site of Grace penuh.

Pola dua-lapis ini (checkpoint "murah tapi sering" ditumpuk di atas checkpoint "lengkap tapi jarang") cukup umum dipakai untuk menyeimbangkan antara "hukuman kematian yang berarti" dan "tidak bikin pemain frustrasi jalan ulang kejauhan".

Titik **spawn pertama** (awal game) biasanya adalah lokasi naratif tetap yang terhubung ke cutscene intro — bukan checkpoint dinamis — baru berubah jadi checkpoint-driven begitu pemain mulai explore dan menyalakan Grace pertama mereka.

### 4.3 Pola Umum Spawn/Checkpoint di Open World `[Prinsip umum, disarikan dari sumber di atas + praktik industri]`

- Checkpoint biasanya menyimpan **transform lengkap** (posisi + rotasi), bukan cuma posisi — supaya arah hadap karakter juga konsisten saat spawn ulang.
- Game open-world modern yang menonjolkan "no loading screen" (seperti pendekatan GoW dan game seamless-world lain) berusaha supaya proses respawn **tidak** memicu loading screen terpisah — dunia sudah di-stream terus-menerus di background sebelum dan sesudah titik spawn.

---

## BAGIAN 5 — KONFIGURASI ACTION PALING BASIC

### 5.1 Set Input Standar Genre `[Prinsip umum, konsisten di semua game yang diriset]`

Hampir semua ARPG third-person modern konvergen ke set input dasar yang sama:

| Aksi | Kontrol Umum | Tipe Input |
|---|---|---|
| Move | Stick kiri / WASD | Vector2, camera-relative |
| Look/Kamera | Stick kanan / mouse delta | Vector2 |
| Jump | Tombol dedicated | Button |
| Sprint | Hold atau toggle | Button/Bool |
| Dodge/Roll | Tombol dedicated (kadang double-tap arah) | Button |
| Light Attack | Tombol dedicated | Button |
| Heavy/Strong Attack | Tombol dedicated (kadang hold light) | Button |
| Block/Guard | Hold tombol | Button (hold) |
| Parry | Timed-press dari Block, atau tombol terpisah | Button (timed) |
| Interact | Tombol dedicated | Button |
| Lock-on/Target | Toggle tombol / klik stick | Button |

Implementasi teknis di Unity modern (New Input System) biasanya berupa **Input Actions asset** dengan action seperti `Move` (Vector2), `Look` (Vector2), `Jump` (Button) — masing-masing punya binding untuk keyboard/mouse **dan** gamepad secara paralel, sehingga pemain bisa berpindah device tanpa setup ulang.

### 5.2 Input Buffering — "Memaafkan" Timing Pemain `[Prinsip umum industri, konsisten lintas banyak sumber teknis]`

Input buffering adalah teknik menyimpan input pemain selama beberapa frame **sebelum** karakter benar-benar bisa menjalankannya, supaya kalau pemain menekan tombol sedikit lebih awal dari "jendela sah", inputnya tetap dieksekusi begitu jendela itu terbuka — bukan diabaikan/hangus.

- **Ukuran jendela buffer** yang umum disebut developer: **5–15 frame** (~80–250ms di 60fps).
- **Prinsip penting soal kapan buffer dieksekusi:** input yang di-buffer sebaiknya dieksekusi di **kesempatan sah paling awal**, bukan ditahan sampai frame terakhir jendela buffer — kalau ditahan sampai akhir, chaining input malah terasa lambat/nyendat walau ukuran jendelanya sama.
- **Beda jenis aksi, beda lebar jendela:** dari praktik developer, input **serangan** (attack-chain) biasanya lebih toleran (~6–8 frame) dibanding input **dodge** (~3–4 frame) — karena dodge yang telat terasa "game-nya tidak mendengar aku", sementara attack yang sedikit lebih awal terasa normal/agresif.
- **Implementasi konkret Unreal:** jendela buffer sering diauthor **per-animasi**, ditandai lewat `AnimNotifyState` yang ditaruh langsung di timeline animation montage — window buffer bisa beda-beda persis di titik mana dalam tiap animasi serangan, bukan satu angka global untuk seluruh game.
- Sistem prioritas juga umum: kalau ada beberapa input ke-buffer bersamaan (misal attack DAN dodge), sistem perlu aturan jelas siapa yang menang.

### 5.3 State Machine Aksi Dasar `[Prinsip umum, disarikan dari sumber animasi/movement di atas]`

Pola umum state machine tingkat-tinggi untuk karakter action:

```
Idle/Locomotion
  -> (input Jump + IsGrounded true) -> Falling/Jumping
  -> (mendarat, IsGrounded true lagi) -> kembali ke Locomotion
  -> (input Attack) -> Attack state
       -> hanya interruptible di "cancel window" tertentu (telat di animasi)
          via dodge-cancel / attack-cancel
  -> (input Dodge, atau kena hit tertentu) -> Dodge state (i-frame di window tertentu)
  -> (kena hit di luar i-frame) -> Hitstun state
```

Umumnya, state **Attack** mengunci sebagian besar input Move (karakter tidak bisa belok bebas di tengah ayunan senjata, walau beberapa game memberi sedikit "steering" minor), dan hanya bisa "dibatalkan" (canceled) ke state lain di jendela-jendela spesifik yang sudah di-tag di animasinya — mekanisme yang sama persis dengan sistem input-buffer/`AnimNotifyState` di 5.2.

### 5.4 Dead Zone Analog Stick (Detail Konfigurasi) `[RESMI/spesifikasi umum]`

Sudah disinggung di bagian kamera (1.7), tapi ini berlaku sama pentingnya untuk stick **movement**: tanpa dead zone, drift kecil di stick (yang hampir selalu ada walau stick masih baru — biasanya membaca ~0.01–0.03 dari skala -1 sampai 1) akan terbaca sebagai input gerak/kamera terus-menerus. Value dead zone biasa dikonfigurasi terpisah untuk stick kiri (movement) dan stick kanan (kamera) — kadang malah beda lagi tergantung konteks (misal dead zone gerak biasa vs dead zone aiming presisi bisa beda nilai dalam game yang sama).

---

## Ringkasan Cepat (TL;DR per Bagian)

1. **Kamera** = spring arm/boom (target length + probe collision) + damping eksponensial/critically-damped (bukan lerp naif) + (opsional) hard lock-on dengan prioritas frontal-cone/camera-view/jarak.
2. **Dodge** = i-frame di awal animasi + recovery frame setelahnya, ada biaya resource (stamina/Ki/charge count) supaya tidak bisa spam, sering dibantu telegraf warna musuh (kuning=parry, merah=dodge).
3. **Floor** = capsule/spherecast ke bawah untuk deteksi ground + walkable-angle threshold (~45°, praktik aman 50–55°) + foot IK 2-bone per kaki untuk presisi visual di permukaan tidak rata.
4. **First Spawn** = marker eksplisit (PlayerStart) dengan posisi+rotasi tersimpan, checkpoint bisa berlapis (ringan vs lengkap), spawn awal biasanya lokasi naratif tetap sebelum checkpoint dinamis mengambil alih.
5. **Action Dasar** = set input universal (move/look/jump/sprint/dodge/attack/block/interact/lock-on), input buffer 5–15 frame dieksekusi di kesempatan tercepat, dead zone stick ~20–30%, state machine yang mengunci/membuka input berdasarkan cancel-window per animasi.

---

## Sumber & Referensi

**[RESMI — dokumentasi/pernyataan developer]**
- Unreal Engine — dokumentasi Spring Arm Component (dev.epicgames.com)
- Unreal Engine — dokumentasi Character Movement Component / Walkable Slope (docs.unrealengine.com, dev.epicgames.com)
- Unreal Engine — dokumentasi PlayerStart & GameMode (dev.epicgames.com)
- Unity — Scripting API CharacterController & manual Character Controller package (docs.unity3d.com)
- Wawancara Cory Barlog soal one-shot camera — GameDeveloper.com, Variety.com (dikutip ulang dari Polygon)
- Assassin's Creed Shadows combat overview — ubisoft.com (blog resmi)

**[KOMUNITAS — wiki/riset frame-count/analisis desain independen]**
- Data frame dodge Elden Ring — eldenring.wiki.fextralife.com
- Sites of Grace Elden Ring — eldenring.wiki.fextralife.com, progameguides.com, wccftech.com
- "Improving Elden Ring's Lock-On Experience" — analisis desain independen oleh Nik Jeleniauskas (jeleniauskas.com)
- Cloud Step Black Myth Wukong — blackmythwukong.wiki.fextralife.com
- Artikel teknis camera damping/spring math — moonjump.com, ryanjuckett.com, blog.littlepolygon.com, sulley.cc, alexisbacot.com
- Artikel input buffering — wayline.io, salivity.github.io, moonjump.com, yuewu.dev

**[FORUM/OPINI — laporan pemain, dipakai untuk pola desain & keluhan nyata]**
- Diskusi Steam Community: Elden Ring, Horizon Forbidden West, Black Myth Wukong, God of War Ragnarök
- Thread ResetEra soal kamera God of War

---

*Riset ini disusun sebagai rujukan desain. Kalau ada bagian yang mau digali lebih dalam — misal breakdown lebih detail animation-cancel window, fokus ke satu game doang, atau nambah game lain — tinggal bilang bagian mana yang mau diperdalam.*
