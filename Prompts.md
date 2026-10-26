# Cilalutask Mobile — Prompt Perbaikan dan Peningkatan Bertahap

Dokumen ini berisi prompt yang bisa diberikan **satu per satu** kepada AI coding agent (Codex, Cursor, Claude Code, Antigravity, atau sejenisnya) untuk memperbaiki `cilalutask_mobile` sampai siap dirilis. Urutan ini disusun berdasarkan hasil *static review* sebelumnya. Kondisi repository bisa berubah, jadi agen wajib memeriksa kode aktual sebelum mengedit.

## Cara menggunakan

1. Buka workspace repository `ErlanggaDevMode/Cilalutask`.
2. Pastikan working directory/referensi utama adalah `cilalutask_mobile/`.
3. Tempel **Prompt 0** dahulu. Sesudah hasil audit disetujui dan baseline dicatat, lanjutkan fase berikutnya secara berurutan.
4. Jalankan satu fase dalam satu waktu. Periksa diff, jalankan tes, lalu buat commit/checkpoint sebelum melanjutkan.
5. Jangan menjalankan seluruh prompt sekaligus. Perubahan autentikasi dan aturan Firestore bisa berdampak pada akses data, jadi wajib diuji sebelum fitur lain diteruskan.

> **Catatan penting:** Ini dirancang untuk memperbaiki aplikasi yang sudah ada, bukan membuat ulang project. Temuan pada review sebelumnya meliputi controller yang sangat besar, data laporan yang masih statis, jalur pemuatan Firestore yang belum jelas, penyimpanan kredensial di model/data lokal, dan aturan Firestore yang tampak terlalu permisif. Agen harus memverifikasi ulang semua temuan tersebut di repository aktual. Peninjauan sebelumnya bersifat statis; aplikasi belum dinyatakan lulus pengujian runtime atau audit penetrasi.

---

# Instruksi umum — tempel di awal setiap fase

Sertakan blok ini di atas prompt fase yang sedang dijalankan, atau jadikan instruksi permanen pada coding agent.

```text
Kamu bertindak sebagai senior Flutter/Dart engineer, Firebase engineer, dan reviewer keamanan untuk repository Cilalutask.

SCOPE:
- Prioritas utama hanya aplikasi Flutter di `cilalutask_mobile/`.
- File konfigurasi Firebase Security Rules di root repository boleh diubah hanya bila diperlukan untuk keamanan dan kompatibilitas aplikasi mobile.
- Jangan mengubah web app atau bagian project lain yang tidak relevan.
- Pertahankan bahasa, alur kerja, nama fitur, dan desain yang sudah ada sejauh memungkinkan.
- Jangan rewrite seluruh aplikasi hanya karena ingin merapikan arsitektur.

ATURAN WAJIB:
1. Baca kode aktual sebelum membuat perubahan. Jangan mengarang nama file, field, koleksi Firestore, atau behavior yang belum ditemukan.
2. Buat ringkasan keadaan saat ini dan rencana perubahan untuk fase ini. Setelah itu kerjakan fase yang diminta; jangan berhenti hanya pada saran.
3. Perubahan harus kecil, berurutan, dan kompatibel dengan fase sebelumnya. Jangan melakukan perubahan massal yang tidak berkaitan.
4. Jangan menambahkan dependensi tanpa alasan teknis yang jelas. Periksa versi Flutter/Dart dan kompatibilitas package terlebih dahulu.
5. Jangan menaruh API key rahasia, service-account key, password, token, atau kredensial di source code, log, asset, atau repository.
6. Jangan pernah menyimpan password pengguna dalam plaintext di Firestore, SharedPreferences, model, log, atau file lokal. Jangan menganggap SharedPreferences sebagai penyimpanan kredensial yang aman.
7. Jangan menonaktifkan security rules, test, lint, validasi input, atau pemeriksaan error untuk membuat build terlihat berhasil.
8. Semua operasi async penting harus punya state loading/success/error yang dapat ditangani UI. Jangan menampilkan sukses jika operasi backend gagal.
9. Jangan menghapus data atau mengganti schema secara destruktif tanpa strategi migrasi, backup, dan kompatibilitas yang jelas.
10. Ikuti pola kode yang sudah digunakan jika masih layak. Bila perlu memperkenalkan pola baru, lakukan bertahap dan jelaskan manfaatnya.
11. Sesudah mengedit, jalankan pemeriksaan yang tersedia: `dart format`, `flutter analyze`, `flutter test`, dan pemeriksaan tambahan yang relevan. Jika command tidak dapat dijalankan, sebutkan secara eksplisit dan jangan mengklaim lulus.
12. Jangan mengklaim sudah menjalankan aplikasi di emulator/perangkat, menguji Firebase Console, atau melakukan penetration test jika hal itu tidak benar-benar dilakukan.

UNTUK SETIAP FASE, LAPORKAN:
- Temuan kode yang diverifikasi.
- File yang diubah dan alasan setiap perubahan penting.
- Tes/check yang benar-benar dijalankan beserta hasilnya.
- Risiko, pekerjaan manual yang diperlukan (misalnya konfigurasi Firebase Console), dan hal yang belum selesai.
- Kriteria penerimaan fase: PASS atau BLOCKED, dengan alasan yang jelas.

Jangan memulai fase berikutnya sebelum fase saat ini selesai atau blocker-nya ditulis dengan jelas.
```

---

# Phase 0 — Audit aktual, baseline, dan rencana kerja

**Prioritas:** P0 — wajib sebelum perubahan kode.

### Prompt 0

```text
Lakukan audit teknis awal untuk `cilalutask_mobile/` sebelum mengubah kode apa pun.

Tujuan:
1. Petakan struktur project: entry point, screens, models, state/controllers, services, routing/navigation, theme, assets, Firebase initialization, local persistence, dan tests.
2. Baca `pubspec.yaml`, file utama, konfigurasi Android/iOS yang relevan, serta Firebase Security Rules yang digunakan project bila tersedia.
3. Verifikasi kembali isu-isu berikut. Jangan anggap semuanya masih benar sebelum melihat kode:
   - AppStateController terlalu besar dan memegang banyak domain.
   - Ada model atau serialisasi yang mungkin menyimpan password.
   - Status login mungkin hanya disimpan lokal, bukan sesi autentikasi backend.
   - Firestore read/load/sync mungkin belum dipanggil pada jalur inisialisasi aplikasi.
   - Aturan Firestore mungkin mengizinkan akses terlalu luas.
   - Task screen mungkin memiliki filter status awal yang membatasi daftar.
   - Ada tombol filter/tune yang belum punya aksi.
   - Halaman laporan mungkin menggunakan angka atau label bulan statis.
   - Penyimpanan daftar besar mungkin memakai SharedPreferences.
4. Periksa apakah repository memiliki test yang sudah berjalan, lint errors, analyzer warnings, dependency issues, atau build blockers.
5. Buat diagram alur singkat: startup → bootstrap → autentikasi → pemilihan perusahaan → load data → state → UI → write/sync.
6. Susun backlog terurut berdasarkan risiko: keamanan, autentikasi, integritas/sinkronisasi data, bug bisnis, arsitektur, UX, testing, performa, dan release.

Batasan:
- Fase ini bersifat read-only kecuali pembuatan dokumen audit yang tidak mengubah behavior aplikasi.
- Jangan melakukan refactor atau upgrade dependency.
- Jangan mencantumkan asumsi sebagai fakta. Pisahkan temuan terverifikasi, dugaan, dan hal yang membutuhkan konfigurasi Firebase Console.

Kriteria selesai:
- Ada baseline hasil `flutter --version`, `dart --version`, `flutter pub get` (jika dapat dijalankan), `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, serta `flutter test`.
- Jika command gagal, catat pesan error penting dan penyebab yang mungkin; jangan menyembunyikannya.
- Hasil akhirnya berisi audit singkat, peta file, daftar blocker, urutan implementasi, dan rencana migrasi yang tidak merusak data.
```

**Output yang diharapkan:** audit aktual dan backlog yang disesuaikan dengan keadaan kode sekarang. Jangan lompat ke fase berikutnya jika struktur autentikasi dan schema data belum dipahami.

---

# Phase 1 — Keamanan kritis dan autentikasi yang benar

**Prioritas:** P0 — kerjakan paling awal. Security Rules dan autentikasi harus dirancang sebagai satu perubahan yang saling kompatibel.

### Prompt 1

```text
Implementasikan perbaikan keamanan kritis dan autentikasi untuk `cilalutask_mobile/`, berdasarkan temuan aktual dari audit.

Target:
1. Hilangkan password plaintext dari model bisnis, serialisasi `toMap/fromMap`, SharedPreferences, Cloud Firestore, log, dan data join request. Password hanya boleh diberikan ke provider autentikasi tepercaya dan tidak boleh disimpan sendiri oleh aplikasi.
2. Audit seluruh jalur login, logout, persistensi sesi, pembuatan akun, join request, dan pemilihan company. Jangan menganggap flag lokal seperti `isAuthenticated` sebagai bukti autentikasi server.
3. Jika Firebase Authentication belum digunakan, integrasikan dengan provider yang sesuai dengan alur aplikasi (misalnya Email/Password jika didukung kebutuhan produk). Periksa dahulu identifier login yang dipakai saat ini. Jangan mengubah username menjadi email palsu tanpa rencana eksplisit. Jika diperlukan migrasi akun lama, buat strategi migrasi yang aman dan dokumentasikan tindakan yang membutuhkan admin.
4. Jadikan Firebase Auth UID identitas pengguna yang stabil. Pisahkan identitas login dari profil, company membership, dan role/permissions.
5. Pastikan setiap operasi data perusahaan membuktikan bahwa pengguna terautentikasi, merupakan anggota perusahaan yang benar, dan mempunyai role yang diperlukan.
6. Periksa aturan Firestore yang aktual. Hapus aturan terbuka seperti `allow read, write: if true` jika masih ada, lalu susun rules least-privilege untuk company, member, tasks, SOP, chat, notifications, join requests, dan koleksi aktual yang benar-benar digunakan. Jangan membuat nama koleksi/field baru tanpa memeriksa schema aktual.
7. Rules wajib membatasi akses per dokumen/company; validasi tipe data dan field yang diizinkan saat relevan; cegah pengguna mengubah role, UID, company ownership, atau field admin miliknya sendiri tanpa otorisasi.
8. Jangan menaruh password pengguna di dokumen company atau join request. Join request hanya menyimpan data yang diperlukan, seperti UID, metadata profil minimum, company target, status, dan timestamp.
9. Implementasikan logout yang membersihkan session/state sensitif. Cegah UI menampilkan data private yang masih tertinggal setelah logout atau pergantian akun/company.
10. Tambahkan penanganan error autentikasi yang aman dan bisa dipahami pengguna tanpa membocorkan detail sensitif.

Persyaratan penting:
- Jangan mengunci pengguna aktif di luar aplikasi tanpa menjelaskan migrasi. Pertimbangkan kompatibilitas data lama dan sediakan prosedur migrasi yang terdokumentasi.
- Jangan memasang rules production yang permisif sebagai workaround. Bila konfigurasi Firebase belum tersedia, buat perubahan kode yang aman dan dokumentasikan langkah manual yang dibutuhkan.
- Jangan menganggap App Check sebagai pengganti Authentication atau Security Rules.
- Jangan mencetak token, password, email sensitif, atau data pribadi ke log.

Tes wajib:
- Unauthenticated user ditolak membaca/menulis data private.
- User A dari Company A tidak dapat membaca/menulis data Company B.
- Member biasa tidak dapat mengubah role menjadi admin atau mengubah ownership.
- Login gagal, logout, session restoration, dan akun yang dinonaktifkan ditangani.
- Password tidak muncul di serialization, Firestore payload, local persistence, atau log.
- Rules diuji dengan Firebase Emulator Rules Unit Testing jika lingkungan proyek memungkinkan; jika tidak, buat test plan yang tepat dan tandai sebagai belum teruji.

Selesaikan implementasi kode yang bisa dilakukan di repository. Pisahkan daftar langkah Firebase Console/manual (aktifkan provider, konfigurasi domain, migration akun, deploy rules) dari perubahan kode. Jangan mengklaim rules aman sebelum menguji rules yang benar-benar digunakan.
```

**Kriteria selesai fase 1:** tidak ada password plaintext di data aplikasi; sesi menggunakan provider autentikasi yang benar; akses lintas perusahaan tertutup; rules tidak terbuka; serta migrasi akun lama dan langkah Firebase Console didokumentasikan. Jika rules belum dapat diuji, tandai fase sebagai **BLOCKED untuk production**.

---

# Phase 2 — Repository data, sinkronisasi Firestore, dan integritas data

**Prioritas:** P0/P1 — setelah pola autentikasi dan akses ditetapkan.

### Prompt 2

```text
Perbaiki arsitektur pemuatan dan penyimpanan data Cilalutask agar alur lokal dan Cloud Firestore jelas, konsisten, serta dapat menangani kegagalan.

Mulai dengan menelusuri semua domain data aktual: company, users/members, tasks, SOP, chat/messages, notifications, join requests, reports, dan domain lain yang memang ada. Temukan seluruh pemanggilan read/write serta jalur yang dipakai saat startup, login, logout, dan company switching.

Implementasi:
1. Definisikan sumber data yang berwenang untuk setiap domain. Pisahkan data autentikasi, metadata profil, cloud data, dan cache lokal. Jangan memiliki dua sumber kebenaran yang saling menimpa tanpa aturan.
2. Pastikan alur login/company selection memuat data company yang benar setelah hak akses diverifikasi. Loading harus berlangsung berurutan, tidak balapan dengan inisialisasi state.
3. Buat atau rapikan repository/data layer tipis sesuai struktur existing agar screens/controller tidak memanggil Firestore langsung secara tersebar.
4. Pastikan create, read, update, delete, query, pagination, dan real-time stream diterapkan hanya untuk fitur yang memang memerlukannya. Verifikasi apakah stream Firestore benar-benar dikonsumsi dan subscription dibatalkan saat tidak diperlukan.
5. Perbaiki sinkronisasi agar penghapusan data tercermin secara benar. Jangan memakai strategi yang hanya menulis dokumen yang masih ada tetapi tidak pernah menangani dokumen yang dihapus. Hindari menghapus seluruh koleksi lalu menulis ulang daftar.
6. Untuk data terkait, gunakan batch/transaction bila memang diperlukan untuk menjaga integritas. Tetapkan ID dokumen yang stabil dan timestamp yang konsisten.
7. Tangani error jaringan, permission-denied, dokumen tidak ditemukan, data lama/field nullable, dan parsing gagal secara eksplisit. Kembalikan hasil atau error yang dapat ditangani UI, bukan hanya `debugPrint`.
8. Tentukan perilaku offline dan konflik edit. Jangan menyatakan data tersinkron hanya karena penulisan lokal berhasil. UI harus membedakan status lokal, sedang sinkron, tersinkron, dan gagal bila konsep ini relevan.
9. Pastikan semua query dibatasi oleh company membership dan kompatibel dengan Security Rules. Tambahkan kebutuhan indeks Firestore ke dokumentasi jika ada.
10. Jika SharedPreferences masih digunakan sebagai cache sederhana, batasi hanya untuk preferensi atau data kecil yang sesuai; jangan menggunakannya sebagai database relasional untuk seluruh data operasional tanpa alasan kuat.

Migrasi:
- Jaga kompatibilitas model lama dengan parsing defensif jika data lama masih digunakan.
- Jangan menghapus data lama otomatis.
- Dokumentasikan field/schema yang berubah dan prosedur migrasi atau fallback.

Tes wajib:
- Load company A hanya menampilkan data company A.
- CRUD setiap domain utama berhasil dan error backend terlihat sebagai error.
- Deleted item tidak muncul kembali setelah reload/sync.
- Login/logout dan pergantian company tidak memperlihatkan cache milik akun sebelumnya.
- Perilaku saat offline dan saat write ditolak rules terdokumentasi serta diuji sejauh mungkin.

Selesaikan perubahan ini tanpa merombak tampilan layar secara besar-besaran.
```

**Kriteria selesai fase 2:** jelas dari mana data dibaca, ditulis, dan di-cache; operasi cloud tidak gagal diam-diam; serta tidak ada data dari company/akun lain yang tercampur.

---

# Phase 3 — Refactor state/controller dan pemisahan tanggung jawab

**Prioritas:** P1 — mengurangi kompleksitas setelah alur data stabil.

### Prompt 3

```text
Refactor state management Cilalutask secara inkremental. Fokuskan pada controller/state file yang terlalu besar, terutama `AppStateController` jika hasil audit mengonfirmasi bahwa ia mengurus banyak domain sekaligus.

Tujuan:
1. Petakan tanggung jawab controller sekarang, termasuk auth/session, company membership, tasks, SOP, chat, notifications, dan storage.
2. Pisahkan domain secara bertahap menjadi state/controller atau service/repository yang sesuai dengan pola project. Contoh pembagian potensial: Auth, Company/Membership, Tasks, SOP, Chat, Notifications, Reports. Terapkan hanya untuk domain yang benar-benar ada.
3. Controller/UI berfungsi sebagai pengatur state dan interaksi, bukan tempat menyimpan seluruh detail query Firestore, aturan serialisasi, dan business logic.
4. Pertahankan nama API publik yang masih dipakai screens selama tahap migrasi; gunakan adapter/facade sementara bila membantu mencegah banyak file rusak sekaligus.
5. Definisikan state loading, data, empty, dan error secara konsisten. Cegah race condition pada pemuatan awal, perubahan filter, dan company switching.
6. Pastikan listener/subscription, controller, stream, dan lifecycle resource dibersihkan dengan benar.
7. Hilangkan duplikasi logic yang nyata, tetapi jangan membuat abstraksi generik berlebihan. Hindari menambah lapisan hanya demi pola arsitektur.
8. Pertahankan UI serta behavior bisnis yang sudah ada. Jangan mengganti package/state-management framework kecuali ada bukti kuat bahwa hal itu diperlukan.
9. Tambahkan unit test pada business logic yang dipindahkan agar refactor tidak sekadar memindahkan masalah.
10. Lakukan perubahan per domain: mulai dari satu domain yang paling terisolasi, jalankan tes, baru lanjut ke domain berikutnya.

Batasan:
- Jangan mengubah schema backend tanpa kebutuhan dan migrasi yang terdokumentasi.
- Jangan menghapus method yang masih digunakan sebelum semua pemanggil dimigrasikan.
- Jangan melakukan formatting atau rename massal yang mengaburkan inti diff.

Kriteria selesai:
- Setiap kelas memiliki tanggung jawab yang terdefinisi.
- Tidak ada regresi pada autentikasi, company isolation, CRUD, sinkronisasi, dan alur layar utama.
- `flutter analyze` dan test terkait lulus, atau blocker yang tersisa dituliskan secara akurat.
- Dokumentasikan struktur hasil refactor dan alur data baru secara singkat.
```

**Kriteria selesai fase 3:** controller tidak lagi menjadi pusat semua tanggung jawab; domain utama terpisah tanpa mengubah behavior yang sudah benar.

---

# Phase 4 — Perbaikan business logic dan laporan dinamis

**Prioritas:** P1 — memperbaiki perilaku fitur yang salah atau masih statis.

### Prompt 4

```text
Audit dan perbaiki bug fungsional pada `cilalutask_mobile/`, terutama daftar tugas, filter, status, laporan, dan tombol yang terlihat aktif tetapi belum punya aksi.

Mulai dengan menemukan implementasi aktual untuk setiap fitur. Verifikasi, minimal:
- Filter status di task screen dan status default saat halaman dibuka.
- Search, filter, sorting, reset filter, dan kombinasi antarfilter.
- Tombol tune/filter atau control lain yang belum memiliki aksi.
- Perhitungan task selesai, sedang berjalan, tertunda, overdue, dan total.
- Laporan yang masih memakai angka completion rate hardcoded atau label bulan/tahun statis.
- Batas rentang tanggal, timezone, dan kasus data kosong.
- Kesamaan perhitungan antara dashboard, daftar tugas, dan laporan.

Implementasi:
1. Tentukan behavior yang paling masuk akal dari desain dan alur existing. Jangan menebak jika definisi bisnisnya tidak jelas; dokumentasikan asumsi yang dibuat.
2. Status awal daftar tugas jangan menyembunyikan tugas relevan tanpa indikasi yang jelas. Jika filter default tetap dipakai, tampilkan chip/label filter aktif dan sediakan cara mudah untuk melihat semua tugas.
3. Aktifkan tombol filter dengan bottom sheet/dialog yang benar-benar menerapkan filter, atau sembunyikan/disable control jika belum didukung. Jangan mempertahankan affordance palsu.
4. Hitung laporan dari data aktual dan definisi metrik yang konsisten. Buang angka dan label kalender hardcoded. Bentuk periode laporan dari tanggal lokal yang benar dan dukung pergantian bulan/tahun.
5. Tangani pembagian nol, dataset kosong, status unknown/null, duplikasi, dan perubahan tanggal.
6. Jika data laporan belum cukup tersedia, tampilkan empty/incomplete state yang jujur; jangan membuat angka dummy seolah-olah nyata.
7. Pisahkan rumus bisnis ke fungsi murni yang bisa diuji, bukan menghitung semuanya dalam widget build.
8. Pastikan semua data tetap berada dalam batas company dan permission user.

Tes wajib:
- Filter tiap status, pencarian, reset filter, dan kombinasi filter.
- Perhitungan completion rate serta total status dengan dataset valid, kosong, dan edge case.
- Periode laporan pada pergantian bulan dan tahun.
- Tombol filter punya hasil yang terlihat atau sengaja ditandai nonaktif.
- Angka dashboard dan reports konsisten menggunakan definisi yang sama.

Jangan mengubah identitas visual secara besar-besaran pada fase ini. Fokus pada kebenaran perilaku dan data.
```

**Kriteria selesai fase 4:** filter bekerja, angka laporan bersumber dari data aktual, label periode dinamis, dan tidak ada tombol interaktif yang hanya menjadi dekorasi.

---

# Phase 5 — Peningkatan UI/UX, aksesibilitas, dan penanganan state

**Prioritas:** P1/P2 — setelah behavior dan sumber data dapat dipercaya.

### Prompt 5

```text
Tingkatkan kualitas UI/UX Cilalutask tanpa menghilangkan identitas visual yang sudah ada. Gunakan UI existing sebagai baseline; jangan mendesain ulang seluruh aplikasi tanpa kebutuhan.

Audit semua screen utama dan state yang mungkin muncul: initial/loading, loaded, empty, error, offline, permission denied, form validation, save in progress, save success, serta delete confirmation.

Implementasikan secara konsisten:
1. Hirarki tipografi, spacing, padding, alignment, warna semantic, bentuk komponen, dan elevation sesuai theme yang ada. Hindari nilai warna/spacing yang diduplikasi bila token theme sudah tersedia.
2. Loading indicator/skeleton pada operasi yang benar-benar asynchronous; empty state dengan instruksi berikutnya; error state dengan retry ketika retry aman; dan pesan sukses hanya setelah operasi berhasil.
3. Validasi form di sisi client untuk UX, tetapi ingat validasi dan authorization backend tetap wajib.
4. Status tombol yang konsisten: disabled saat input tidak valid atau request berjalan, debounce untuk pencarian bila dibutuhkan, dan cegah double submission.
5. Dialog konfirmasi untuk operasi destruktif; tampilkan pesan yang aman saat gagal; jangan menelan exception lalu menampilkan sukses.
6. Perbaiki overflow pada ukuran layar kecil, teks panjang, keyboard terbuka, dan skala font yang lebih besar.
7. Tambahkan semantics/label yang relevan untuk screen reader, touch target yang memadai, kontras teks yang layak, serta dukungan navigasi dan fokus yang masuk akal.
8. Buat komponen reusable hanya untuk pola yang benar-benar digunakan berulang, bukan untuk setiap widget kecil.
9. Pertahankan format tanggal/angka yang sesuai konteks Indonesia jika aplikasi menargetkan pengguna Indonesia; pastikan zona waktu dan format internal tidak tercampur.
10. Jangan menampilkan data atau aksi yang tidak diizinkan role user.

Tes/validasi:
- Jalankan widget tests pada screen dan state utama.
- Periksa overflow, empty/error state, dan validasi form.
- Gunakan screenshot/golden tests bila project telah memiliki setup yang sesuai; jangan menambah golden suite besar tanpa alasan.
- Jika tidak dapat menjalankan emulator atau melihat rendering, nyatakan keterbatasannya dan jangan mengklaim hasil visual telah diverifikasi.

Jangan mengubah logic bisnis dan schema backend kecuali diperlukan untuk menyelesaikan UX bug yang sudah diidentifikasi. Setiap perubahan behavior harus disertai alasan dan test.
```

**Kriteria selesai fase 5:** layar memiliki loading/empty/error states yang konsisten, formulir jelas, tombol memberi feedback benar, dan layout lebih tahan terhadap ukuran layar serta aksesibilitas.

---

# Phase 6 — Testing, lint, dan regresi end-to-end

**Prioritas:** P1 — quality gate untuk semua fase berikutnya.

### Prompt 6

```text
Perkuat automated testing dan quality gates untuk Cilalutask mobile. Jangan hanya menambahkan test yang mengulang implementasi; test behavior yang penting bagi pengguna dan keamanan.

1. Audit test yang ada dan jalankan seluruh suite. Pertahankan test lama yang relevan; perbaiki test yang rapuh dengan alasan yang jelas.
2. Buat unit tests untuk business logic murni: task status/filter, completion rate, date range, validasi model/serialization, dan permission logic client-side yang relevan.
3. Buat widget tests untuk login/logout states, daftar tugas dan filter, form utama, empty/loading/error state, laporan dinamis, serta pergantian company.
4. Gunakan dependency injection atau test doubles untuk menguji repository tanpa selalu membutuhkan jaringan. Jangan memakai kredensial production di tests.
5. Tambahkan integration tests untuk alur utama: sign in → pilih/join company → load data → create/update/delete task → logout. Bila backend Firebase real tidak tersedia, gunakan Firebase Emulator atau stub dengan jelas.
6. Tambahkan Firestore Rules tests untuk unauthenticated access, akses lintas-company, role escalation, field sensitif, dan allowed CRUD. Tes harus menjalankan rules yang benar-benar akan dideploy.
7. Pastikan test tidak bergantung pada data personal/production, urutan eksekusi, atau waktu berjalan yang tidak stabil. Bersihkan fixture setelah tes.
8. Tambahkan konfigurasi CI yang masuk akal jika repository sudah memakai GitHub Actions atau workflow lain. Jangan membuat CI bergantung pada secret yang belum disiapkan tanpa dokumentasi.
9. Tetapkan gate minimal: formatter, analyzer, unit/widget tests; integration dan rules tests wajib sebelum production release. Jangan menurunkan lint rules untuk membuat pipeline hijau.
10. Catat command yang harus dijalankan developer dan cara menjalankan Firebase Emulator/test lokal.

Validasi final fase:
- Jalankan `dart format --output=none --set-exit-if-changed .`.
- Jalankan `flutter analyze`.
- Jalankan `flutter test`.
- Jalankan integration/security tests yang dapat dijalankan di lingkungan ini.
- Laporkan jumlah test, kegagalan, serta apa yang tidak dapat dieksekusi. Jangan menulis “semua lulus” jika hanya sebagian dijalankan.

Perbaiki penyebab test gagal, bukan menghapus assertion atau melewati test. Jika menemukan defect produk saat menambah test, perbaiki hanya jika sesuai scope fase dan sertakan test regresinya.
```

**Kriteria selesai fase 6:** bug kritis punya test regresi; lint dan test dasar bersih; keamanan Firestore mempunyai test yang dapat direproduksi atau blocker yang eksplisit.

---

# Phase 7 — Performa, lifecycle, dan pengalaman offline

**Prioritas:** P2 — kerjakan setelah kebenaran data dan test dasar terjaga.

### Prompt 7

```text
Audit dan optimalkan performa serta penggunaan resource Cilalutask mobile dengan bukti dari kode dan pengukuran yang tersedia. Hindari optimasi prematur.

Audit:
- Query Firestore yang mengambil data terlalu banyak atau tidak memakai pagination.
- Listener realtime yang duplikat/tidak pernah dihentikan.
- Rebuild UI yang terlalu luas, parsing/transformasi data berulang dalam build(), dan list yang tidak lazy.
- Pemanggilan jaringan berulang, pencarian tanpa debounce, operasi berat di main isolate, serta pemuatan image/asset.
- Penggunaan SharedPreferences untuk collection besar atau data operasional kompleks.
- Perilaku saat offline, reconnect, duplicate write, dan konflik perubahan.

Implementasi sesuai bukti:
1. Batasi query, pilih field/query yang dibutuhkan, gunakan pagination jika dataset dapat tumbuh besar, dan dokumentasikan indeks Firestore yang diperlukan.
2. Pastikan stream/subscription dibuat sekali pada lifecycle yang tepat dan di-cancel dengan benar. Hindari listener baru setiap build.
3. Gunakan lazy list dan pecah widget hanya saat ada manfaat renderability atau maintainability yang jelas.
4. Debounce search/input jika diperlukan dan cegah request lama menimpa hasil yang lebih baru.
5. Evaluasi penyimpanan: SharedPreferences untuk preferensi sederhana; bila data operasional lokal perlu query/relasi/volume besar, usulkan serta implementasikan database lokal seperti SQLite/Drift hanya setelah memeriksa kebutuhan, kompatibilitas dependency, dan rencana migrasi.
6. Tetapkan strategi offline yang realistis: jelaskan data mana yang tersedia offline, bagaimana write tertunda direkonsiliasi, dan bagaimana konflik ditampilkan. Jangan membangun sync engine kompleks jika cache Firestore yang ada sudah memenuhi kebutuhan.
7. Hindari menyalin data sensitif ke cache lokal tanpa kebutuhan. Bersihkan cache yang berkaitan dengan pengguna saat logout/pergantian akun sesuai rancangan keamanan.
8. Ukur atau bandingkan sebelum dan sesudah jika tooling memungkinkan. Jika tidak ada benchmark, tandai perubahan sebagai optimasi berbasis inspeksi, bukan hasil pengukuran.

Validasi:
- Test untuk pagination, listener lifecycle, pencarian cepat, reconnect/offline, dan pergantian akun/company.
- Pastikan keamanan akses lintas-company tetap lulus setelah optimasi.
- Jalankan formatter, analyzer, unit/widget tests, serta integration tests yang relevan.
- Jangan menambahkan state-management/database package baru hanya demi tren atau karena asumsi.
```

**Kriteria selesai fase 7:** tidak ada query/listener boros yang jelas, lifecycle tertib, keputusan storage didasarkan pada kebutuhan, dan perilaku offline tidak menyesatkan pengguna.

---

# Phase 8 — Dokumentasi, konfigurasi, dan release candidate

**Prioritas:** P1 — sebelum build dibagikan ke pengguna produksi.

### Prompt 8

```text
Siapkan Cilalutask mobile menjadi release candidate yang dapat dibangun, dikonfigurasi, diuji, dan dipelihara oleh developer lain.

1. Audit konfigurasi build Android/iOS yang ada: application ID/bundle ID, minimum SDK, target SDK, versi Flutter/Dart, permission, signing, Firebase config, dan environment separation. Jangan mengganti ID aplikasi atau signing yang sudah dipakai tanpa alasan kuat karena dapat memutus update untuk pengguna lama.
2. Pastikan tidak ada file kredensial rahasia, password, token, service-account JSON, atau environment file berisi rahasia yang ikut ter-commit. Jangan menghapus Firebase client config yang memang diperlukan oleh platform tanpa memahami sifatnya; fokuskan pada pembatasan akses lewat rules, auth, dan konfigurasi yang tepat.
3. Pisahkan konfigurasi development/staging/production bila infrastruktur yang tersedia mendukung. Jangan menyimpan secret di source code. Dokumentasikan setup yang membutuhkan tindakan manual.
4. Periksa error handling, logging, data sensitif di log, crash behavior, empty state, permission denied, dan session restoration.
5. Pastikan Firebase Auth provider, Firestore rules, indexes, dan setiap langkah migration yang diperlukan tercatat secara akurat. Jangan menyatakan deployment sudah dilakukan jika hanya mengedit file lokal.
6. Lengkapi README/guide untuk setup Flutter, konfigurasi Firebase, menjalankan app, test, emulator, build Android, environment variables (bila ada), serta troubleshooting umum.
7. Siapkan release notes ringkas: fitur/bug yang diperbaiki, perubahan perilaku yang berdampak pada pengguna, dan langkah migrasi akun/data.
8. Jalankan quality gates terakhir dan build target yang tersedia. Jika build release memerlukan signing key atau konfigurasi rahasia yang tidak tersedia, jangan membuat key production palsu; catat blocker dan cara konfigurasi aman.
9. Periksa status package/dependency dan warning yang relevan. Hindari upgrade besar tak terkait pada saat release candidate.
10. Buat checklist manual untuk pengujian di perangkat fisik: login/logout, role/permission, data per company, push/notification jika dipakai, offline/reconnect, ukuran layar, dan proses upgrade dari versi sebelumnya.

Lakukan audit akhir dengan kategori:
- BLOCKER: masalah keamanan, kehilangan/korupsi data, akses lintas-company, crash utama, atau build gagal.
- HIGH: fitur utama tidak berfungsi atau laporan salah.
- MEDIUM: UX/performa yang mengganggu tetapi tidak merusak keamanan/data.
- LOW: polish dan improvement non-kritis.

Jangan menyebut aplikasi production-ready bila blocker keamanan belum diuji, Security Rules belum diverifikasi, atau migrasi akun/data belum disiapkan.
```

**Kriteria selesai fase 8:** dokumentasi dan konfigurasi build lengkap; pemeriksaan otomatis dijalankan; blocker release tercatat; proses instalasi, upgrade, dan migrasi dapat diikuti developer lain.

---

# Phase 9 — Final audit dan keputusan rilis

**Prioritas:** P0 release gate — jangan dilewati.

### Prompt 9

```text
Lakukan final audit Cilalutask mobile terhadap semua perubahan fase 0–8. Tujuan fase ini adalah membuktikan kesiapan atau menyatakan secara jujur alasan aplikasi belum siap rilis, bukan menambah fitur baru.

Periksa kembali diff dan implementasi aktual:
1. Security: tidak ada password plaintext; Auth benar-benar menjadi sumber sesi; Firestore Rules least-privilege; company isolation dan role enforcement diuji; tidak ada data rahasia di log/repository.
2. Data integrity: startup/load, CRUD, delete, offline/reconnect, error handling, company switching, logout, dan cache cleanup tidak menyebabkan data hilang atau bocor.
3. Business logic: filter task, status, deadline, laporan, angka statistik, dan periode dinamis konsisten.
4. Architecture: controller/services memiliki tanggung jawab wajar; tidak ada duplikasi sync, listener leak, atau error yang diam-diam diabaikan.
5. Quality: format, analyze, unit/widget/integration tests, Firestore Rules tests, dan build dijalankan sesuai kemampuan lingkungan.
6. Release: dokumentasi, konfigurasi Firebase, indexes, migrasi akun/data, build/signing, dan rollback/recovery plan tersedia.

Lakukan pemeriksaan terakhir untuk TODO/FIXME, penggunaan `allow read, write: if true`, hardcoded report values, password fields, `debugPrint` berisi data sensitif, error yang diabaikan, tombol tanpa aksi, test yang di-skip, dan penggunaan mock data di production path. Untuk setiap hit, verifikasi konteks sebelum mengubahnya.

Jangan membuat perubahan besar dalam final audit. Perbaiki hanya defect kecil yang jelas dan aman; masalah lebih besar harus dicatat sebagai blocker dan ditugaskan ke fase sebelumnya.

Hasil akhir wajib berupa:
- Ringkasan perubahan yang benar-benar ada.
- Daftar command beserta hasil aktual.
- Matriks PASS / FAIL / NOT TESTED untuk keamanan, autentikasi, data/sync, fitur inti, UI states, tests, dan build.
- Daftar BLOCKER/HIGH/MEDIUM/LOW.
- Langkah manual tersisa dengan pemilik aksi yang jelas (developer, Firebase Console/admin, atau QA).
- Keputusan akhir: `READY FOR INTERNAL TESTING`, `READY FOR STAGING`, `READY FOR PRODUCTION`, atau `NOT READY`, disertai alasan.

Aturan penentuan keputusan:
- Jika keamanan atau isolasi company belum diverifikasi, jangan pilih READY FOR PRODUCTION.
- Jika rules production belum diuji terhadap rules yang benar-benar dideploy, status maksimal READY FOR STAGING hanya jika staging environment dan rules staging sudah aman; jika tidak, NOT READY.
- Jika build atau test penting tidak dapat dijalankan, tandai NOT TESTED dan jelaskan risiko. Jangan mengarang hasil.
```

---

# Urutan eksekusi yang direkomendasikan

| Urutan | Fase | Prioritas | Alasan |
|---:|---|---|---|
| 1 | Phase 0 — Audit & baseline | P0 | Menghindari perubahan berdasarkan asumsi lama |
| 2 | Phase 1 — Security & Auth | P0 | Mencegah kebocoran data dan login yang tidak tepercaya |
| 3 | Phase 2 — Data & sync | P0/P1 | Menjaga konsistensi dan isolasi data |
| 4 | Phase 3 — State/controller | P1 | Memudahkan pemeliharaan setelah data stabil |
| 5 | Phase 4 — Business logic | P1 | Memastikan filter dan laporan benar |
| 6 | Phase 5 — UI/UX | P1/P2 | Menyempurnakan pengalaman pengguna |
| 7 | Phase 6 — Automated tests | P1 | Mengunci behavior dan mencegah regresi |
| 8 | Phase 7 — Performance/offline | P2 | Mengoptimalkan setelah behavior benar |
| 9 | Phase 8 — Release candidate | P1 | Menyiapkan build dan dokumentasi |
| 10 | Phase 9 — Final audit | P0 release gate | Memutuskan readiness berdasarkan bukti |

## Aturan praktis selama pengerjaan

- Buat commit/checkpoint sebelum memulai setiap fase.
- Review `git diff` sebelum menerima perubahan dari agent.
- Setelah setiap fase, jalankan setidaknya `flutter analyze` dan `flutter test`.
- Jangan deploy rules baru langsung ke production sebelum diuji di Firebase Emulator atau environment staging yang aman.
- Simpan backup dan siapkan prosedur migrasi sebelum mengubah model data pengguna.
- Jangan biarkan agent menganggap compile sukses sebagai bukti bahwa autentikasi, aturan akses, atau sinkronisasi aman.
- UI boleh dipoles belakangan; **keamanan, autentikasi, dan integritas data harus selesai lebih dulu**.

## Definisi “selesai akhir”

Cilalutask mobile baru layak disebut siap produksi jika seluruh syarat berikut telah diverifikasi, bukan sekadar diimplementasikan:

- Autentikasi server berjalan dan logout benar-benar mengakhiri sesi.
- Tidak ada password plaintext tersimpan atau terekspos.
- Firestore Rules yang dideploy sudah diuji dan akses lintas-company ditolak.
- CRUD dan sinkronisasi tidak diam-diam gagal atau menghidupkan kembali data yang telah dihapus.
- Laporan memakai data aktual serta perhitungan yang konsisten.
- Tes dan analyzer lulus pada lingkungan yang sesuai.
- Build release berhasil dengan konfigurasi yang benar.
- Setup Firebase, indeks, migrasi, dan prosedur pemulihan didokumentasikan.
- Hasil pengujian manual pada perangkat nyata dicatat oleh QA/developer.
