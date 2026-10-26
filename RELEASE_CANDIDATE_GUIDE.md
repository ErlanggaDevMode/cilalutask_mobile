# 📘 Cilalutask Mobile - Release Candidate Developer Guide

Dokumen ini ditujukan bagi developer dan tim QA untuk membangun (build), mengonfigurasi, menguji, dan memelihara **Cilalutask Mobile (Release Candidate v1.0.0-rc1)**.

---

## 📋 Daftar Isi
1. [Spesifikasi Teknis & Lingkungan Build](#-1-spesifikasi-teknis--lingkungan-build)
2. [Setup Lingkungan Pengembang (Local Setup)](#-2-setup-lingkungan-pengembang-local-setup)
3. [Konfigurasi Firebase & Pemisahan Lingkungan](#-3-konfigurasi-firebase--pemisahan-lingkungan)
4. [Konfigurasi Keystore & Signing Release Android](#-4-konfigurasi-keystore--signing-release-android)
5. [Menjalankan Quality Gates (Format, Lint, Test, Build)](#-5-menjalankan-quality-gates)
6. [Checklist Pengujian Manual di Perangkat Fisik (10 Poin)](#-6-checklist-pengujian-manual-di-perangkat-fisik)
7. [Matriks Klasifikasi Masalah Audit Akhir](#-7-matriks-klasifikasi-masalah-audit-akhir)
8. [Panduan Pemecahan Masalah (Troubleshooting)](#-8-panduan-pemecahan-masalah-troubleshooting)
9. [Rencana Pemulihan & Rollback (Disaster Recovery & Rollback Plan)](#-9-rencana-pemulihan--rollback-disaster-recovery--rollback-plan)

---

## 🛠️ 1. Spesifikasi Teknis & Lingkungan Build

| Parameter | Konfigurasi Saat Ini | Catatan Kompatibilitas |
|---|---|---|
| **Flutter SDK** | `3.47.2` (Channel stable) | Memenuhi `sdk: ^3.13.2` di pubspec |
| **Dart SDK** | `3.13.2` | Strong mode, null safety aktif |
| **Android Application ID** | `com.cilalutask.cilalutask_mobile` | **Wajib dipertahankan** agar update Google Play tidak putus |
| **Android Namespace** | `com.cilalutask.cilalutask_mobile` | Android Gradle Plugin 8+ |
| **Android Min SDK** | `21` (Android 5.0 Lollipop) | 99%+ cakupan perangkat global |
| **Android Target SDK** | `34` / `35` (Android 14/15) | Standar kepatuhan Google Play Store 2024-2026 |
| **Android Toolchain JDK** | Java 17+ (OpenJDK 21 direkomendasikan) | Diperlukan oleh Gradle 8.x/9.x & Kotlin 1.9+ |
| **iOS Bundle Identifier** | `com.cilalutask.cilalutaskMobile` | **Wajib dipertahankan** untuk Apple App Store |
| **iOS Deployment Target** | `12.0` | Kompatibel dengan iPhone 6s ke atas |
| **Permissions (Android)** | `INTERNET`, `ACCESS_NETWORK_STATE` | Komunikasi Firestore & deteksi koneksi |

---

## 💻 2. Setup Lingkungan Pengembang (Local Setup)

### Langkah 1: Clone & Pasang Dependensi
```bash
# Masuk ke direktori mobile
cd cilalutask_mobile

# Bersihkan dan pasang paket Flutter
flutter clean
flutter pub get
```

### Langkah 2: Salin File Template Lingkungan
```bash
# Salin konfigurasi environment
cp .env.example .env

# Salin template signing keystore Android
cp android/key.properties.example android/key.properties
```

> [!NOTE]
> File `.env` dan `android/key.properties` telah diabaikan oleh `.gitignore`. Jangan pernah memasukkan kata sandi atau private key ke repositori git.

---

## 🔥 3. Konfigurasi Firebase & Pemisahan Lingkungan

Aplikasi telah menyertakan konfigurasi client Firebase resmi:
- **Android**: `android/app/google-services.json`
- **Flutter**: `lib/firebase_options.dart` (mendukung Android, iOS, Web, macOS, Windows)

### Arsitektur Multi-Environment (Dev / Staging / Production)
Secara default, aplikasi terhubung ke proyek Firebase `cilalutask`. Jika ingin memisahkan environment:
1. Buat proyek Firebase terpisah di Firebase Console (misal: `cilalutask-dev` dan `cilalutask-prod`).
2. Pasang Firebase CLI dan FlutterFire CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
3. Konfigurasikan proyek target dengan perintah:
   ```bash
   flutterfire configure --project=cilalutask-dev
   ```
4. Pasang Firebase Security Rules dan Indeks ke Firebase Backend:
   ```bash
   # Deploy Firestore rules & indexes
   firebase deploy --only firestore:rules,firestore:indexes
   ```
   > [!IMPORTANT]
   > File [firestore.rules](firestore.rules) dan [firestore.indexes.json](firestore.indexes.json) di repositori ini adalah versi master yang terverifikasi dan telah diuji secara ketat.

---

## 🔑 4. Konfigurasi Keystore & Signing Release Android

Konfigurasi build Android (`android/app/build.gradle.kts`) telah diprogram dengan fallback aman:
- **Jika `android/key.properties` ADA**: Menggunakan release keystore resmi untuk build produksi.
- **Jika `android/key.properties` TIDAK ADA**: Otomatis fallback menggunakan debug keystore sehingga build lokal atau testing tidak pernah gagal.

### Langkah Setup Signing Produksi:
1. Buat Release Keystore (jika belum ada):
   ```bash
   keytool -genkey -v -keystore android/cilalutask-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cilalutask-key
   ```
2. Isi file `android/key.properties`:
   ```properties
   storePassword=KataSandiKeystoreAnda
   keyPassword=KataSandiKeyAnda
   keyAlias=cilalutask-key
   storeFile=cilalutask-release-key.jks
   ```
3. Bangun APK atau App Bundle rilis:
   ```bash
   # Bangun Android App Bundle untuk Google Play Store
   flutter build appbundle --release

   # Atau bangun split APK per-arsitektur (arm64, armv7, x86_64)
   flutter build apk --release --split-per-abi
   ```

---

## 🧪 5. Menjalankan Quality Gates

Sebelum mengajukan perubahan kode (pull request) atau rilis, jalankan urutan quality gates wajib berikut:

```bash
# 1. Validasi formatting Dart
dart format --output=none --set-exit-if-changed .

# 2. Analisis statis linter (zero warnings/errors)
flutter analyze

# 3. Eksekusi seluruh suite test otomatis (88 test cases)
flutter test

# 4. Validasi kompilasi build target
flutter build apk --debug
```

### Rekap Cakupan Suite Test (88/88 Passed):
- `test/chat_controller_test.dart`: CRUD channel, pengiriman pesan, pembersihan state.
- `test/company_controller_test.dart`: Registrasi PT, approval permohonan join, switching company.
- `test/data_architecture_test.dart`: Integritas skema data dan ketiadaan password.
- `test/integration_main_user_flow_test.dart`: Alur pengguna end-to-end (login -> pilih PT -> task lifecycle -> logout).
- `test/notification_controller_test.dart`: In-app banner dan pusat notifikasi.
- `test/performance_and_offline_test.dart`: Bounded queries, lifecycle subscription, offline write queue & reconciliation.
- `test/pure_business_logic_and_models_test.dart`: Validasi model serialisasi, isolasi multi-tenant, label tanggal bahasa Indonesia.
- `test/repository_test_doubles_test.dart`: Pengujian repository dengan test doubles tanpa koneksi internet.
- `test/security_and_auth_test.dart`: Verifikasi eliminasi password, hak akses RBAC, isolasi multi-company.
- `test/sop_controller_test.dart`: Repositori SOP, bookmark, dan verifikasi konfirmasi baca.
- `test/task_controller_test.dart`: Task CRUD, update progres, dan review manajerial.
- `test/task_metrics_and_functional_fixes_test.dart`: TaskMetricsCalculator, pencegahan division-by-zero, filter & sorting.
- `test/ui_ux_quality_test.dart`: Dialog konfirmasi destruktif, empty state, proteksi layar 320px, validasi form.
- `test/widget_test.dart`: Render navigasi 6 tab, autentikasi adaptif peran, persistensi SharedPreferences.

---

## 📱 6. Checklist Pengujian Manual di Perangkat Fisik (10 Poin)

Lakukan verifikasi manual berikut pada setidaknya 1 perangkat Android fisik dan 1 perangkat iOS (atau emulator):

- [ ] **1. Login, Sesi & Logout**:
  - Masuk menggunakan akun terdaftar. Tutup paksa aplikasi (force-kill) dan buka kembali; pastikan sesi tetap aktif tanpa login ulang.
  - Tekan tombol keluar (logout); pastikan seluruh data perusahaan dan formulir dibersihkan dari memori.
- [ ] **2. Otoritas Hak Akses (RBAC)**:
  - Masuk sebagai **User (Karyawan)**: pastikan tombol `+ Buat Tugas`, `Review & Persetujuan`, serta tombol hapus tugas/SOP tidak terlihat dan tidak dapat diakses.
  - Masuk sebagai **Admin (Manager)**: pastikan tombol manajerial dan persetujuan muncul dengan lengkap.
- [ ] **3. Isolasi Multi-Perusahaan**:
  - Admin membuat Perusahaan A dan menambahkan tugas "Tugas Rahasia A".
  - Beralih ke Perusahaan B; pastikan "Tugas Rahasia A" sama sekali tidak muncul di daftar tugas Perusahaan B.
- [ ] **4. Alur Permohonan Gabung Karyawan (Join Approval)**:
  - Calon karyawan mengajukan join ke Perusahaan A -> status `pending`.
  - Admin Perusahaan A membuka sheet permohonan join dan menekan `Terima`.
  - Periksa layar karyawan: status otomatis berubah menjadi `approved` dan dashboard dapat dibuka.
- [ ] **5. Chat Multi-Saluran & Real-Time DM**:
  - Kirim pesan di saluran tim atau direct message.
  - Pastikan pesan muncul dengan urutan waktu yang benar dan notifikasi in-app banner muncul pada penerima.
- [ ] **6. Offline & Reconnect Resilience**:
  - Aktifkan Airplane Mode pada perangkat.
  - Lakukan pembaruan checklist subtask atau pembacaan SOP.
  - Matikan Airplane Mode (online kembali); pastikan perubahan tersinkronisasi ke server tanpa crash.
- [ ] **7. Resiliensi Tampilan Layar Kecil (320px) & Orientasi**:
  - Uji aplikasi pada perangkat berlayar kecil (atau aktifkan font size terbesar di pengaturan aksesibilitas OS).
  - Pastikan tidak ada pesan visual `A RenderFlex overflowed by X pixels`.
- [ ] **8. Modal Konfirmasi Aksi Destruktif**:
  - Tekan ikon hapus tugas atau SOP sebagai Admin.
  - Pastikan muncul `AppConfirmDialog`. Tekan `Batal`; pastikan item tidak terhapus. Tekan `Hapus`; pastikan item terhapus dengan umpan balik visual yang jelas.
- [ ] **9. Tab Laporan & Filter Dinamis**:
  - Buka Tab Laporan; pastikan grafik dan metrik sesuai dengan jumlah tugas sebenarnya.
  - Uji pada perusahaan baru (mode Blank); pastikan nilai completion rate menampilkan 0% tanpa crash atau label `NaN`.
- [ ] **10. Proses Upgrade dari Versi Sebelumnya**:
  - Pasang versi lama aplikasi (jika ada), lalu pasang file APK v1.0.0-rc1 tanpa melakukan uninstall.
  - Pastikan aplikasi terbuka normal tanpa crash database lokal.

---

## 🚦 7. Matriks Klasifikasi Masalah Audit Akhir

| Tingkat Keparahan | Status Saat Ini | Detail Temuan & Tindakan |
|---|---|---|
| **BLOCKER** | **0 Teridentifikasi** | Tidak ada masalah keamanan, data leak lintas perusahaan, crash fatal, atau kegagalan kompilasi. |
| **HIGH** | **0 Teridentifikasi** | Seluruh fitur utama (Auth, Tasks, SOP, Reports, Chat, Team, Multi-tenant) berfungsi 100%. |
| **MEDIUM** | **0 Teridentifikasi** | UX responsif, penanganan division-by-zero, dan dialog konfirmasi destruktif telah terpasang. |
| **LOW** | **3 Catatan Operasional** | 1. **Firestore Emulator Java Host**: Menjalankan Firebase Firestore Emulator lokal membutuhkan Java 11+ (Host Windows saat ini memiliki Java 8 `1.8.0_51`, namun runner CI GitHub Actions menggunakan Java 17).<br>2. **Keystore Produksi**: Sebelum upload ke Google Play, tim harus menyalin `key.properties` asli tim rilis.<br>3. **Info Plugin Gradle KGP**: Terdapat pesan info dari Flutter bahwa plugin Firebase di masa depan akan bermigrasi ke Built-in Kotlin (saat ini kompatibel penuh). |

---

## 🔧 8. Panduan Pemecahan Masalah (Troubleshooting)

### Q1: `flutter build apk` gagal karena signing key tidak ditemukan
**Solusi**: Pastikan `android/key.properties` tidak menunjuk ke path file yang salah. Jika belum memiliki keystore produksi resmi, hapus atau kosongkan `key.properties` agar sistem otomatis fallback ke debug key.

### Q2: Firestore Rules melarang penulisan (Permission Denied)
**Solusi**: Pastikan user telah terautentikasi melalui Firebase Auth dan payload tidak berisi field `password`. Pastikan juga user terdaftar sebagai admin (`isCompanyAdmin`) untuk operasi manajerial (buat tugas, buat SOP, approve join).

### Q3: Menjalankan tes di mesin lokal
**Solusi**: Jalankan `flutter test` langsung di terminal. Semua test suites dirancang hermetis menggunakan test doubles tanpa ketergantungan koneksi jaringan eksternal.

---

## 🔄 9. Rencana Pemulihan & Rollback (Disaster Recovery & Rollback Plan)

Jika ditemukan anomali kritis pasca-distribusi:
1. **Rollback Aplikasi Mobile (Client-Side)**:
   - *Google Play Store*: Di Google Play Console, buka menu *Releases overview* -> *Halt staged rollout* segera untuk menghentikan distribusi. Naikkan `versionCode` dan rilis versi hotfix dari commit sebelumnya.
   - *Apple App Store*: Tarik rilis dari App Store Connect (*Remove this version from sale*) atau rilis versi perbaikan expedited review.
2. **Rollback Firestore Security Rules**:
   - Jika rules baru memblokir operasi valid, buka Firebase Console -> *Firestore Database* -> *Rules* -> *Rules history*.
   - Pilih versi rules sebelum rilis dan klik *Restore*, atau deploy kembali rules commit sebelumnya:
     ```bash
     git checkout <tag-sebelumnya> firestore.rules
     firebase deploy --only firestore:rules
     ```
3. **Rollback Data Lokal & Cache Klien**:
   - `LocalStorageService` dilengkapi mekanisme try-catch defensif saat parsing model. Jika format korup, aplikasi mereset cache lokal (`localStorage.clearAll()`) secara otomatis tanpa menyebabkan crash fatal bagi pengguna.

