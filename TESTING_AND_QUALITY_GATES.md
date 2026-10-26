# 🛡️ Panduan Pengujian & Quality Gates — CILALUTASK Mobile

Dokumen ini mendefinisikan standar pengujian otomatis (*automated testing*), *quality gates*, serta panduan langkah demi langkah bagi pengembang untuk menjalankan pengujian lokal dan emulator.

---

## 🚦 Quality Gates Wajib (Pre-Merge & Pre-Release)

Setiap kontribusi kode wajib melewati 4 gerbang kualitas (*quality gates*) berikut tanpa pengecualian:

| Gate | Deskripsi | Perintah | Toleransi |
| :--- | :--- | :--- | :--- |
| **Gate 1: Format** | Standar format kode Dart resmi | `dart format --output=none --set-exit-if-changed .` | 0 file berbeda |
| **Gate 2: Static Analysis** | Linter & analyzer integritas tipe | `flutter analyze` | 0 error, 0 warning |
| **Gate 3: Unit & Widget Tests**| Seluruh suite pengujian aplikasi | `flutter test` | 100% lulus (0 gagal) |
| **Gate 4: Security Rules Tests** | Pengujian aturan keamanan Firestore | `firebase emulators:exec --only firestore "npm --prefix test_rules test"` | 100% lulus (0 gagal) |

---

## 📋 Inventaris Suite Pengujian

Saat ini terdapat **13 file pengujian** otomatis yang mencakup seluruh lapisan aplikasi:

### A. Business Logic & Models
1. **`test/pure_business_logic_and_models_test.dart`**:
   - Serialisasi model (`Company`, `Assignee`, `Task`, `SOPDocument`, `JoinRequest`).
   - Validasi keamanan zero-password (tidak ada kata sandi yang diserialisasi ke `toMap()`).
   - Perhitungan metrik tugas agregat (`TaskMetricsCalculator.computeMetrics`).
   - Kombinasi filter tugas (divisi, status, prioritas, pencarian).
   - Matriks perizinan peran klien (*Admin vs Regular User*).
2. **`test/task_metrics_and_functional_fixes_test.dart`**:
   - Pembagian nol pada dataset kosong.
   - Peringkat karyawan dan produktivitas divisi.
   - Format tanggal dan bulan bahasa Indonesia.
   - Kontrol filter pada widget bottom sheet (`TaskFilterBottomSheet`, `SopFilterBottomSheet`).

### B. Controller & State Management (Domain Isolated)
3. **`test/company_controller_test.dart`**: Multi-tenant isolation, registrasi perusahaan, join requests.
4. **`test/task_controller_test.dart`**: CRUD tugas, kalkulasi progres subtasks, persetujuan admin.
5. **`test/sop_controller_test.dart`**: SOP checklist, konfirmasi baca, penanda bookmark.
6. **`test/chat_controller_test.dart`**: Manajemen saluran (channels), pengiriman pesan, realtime chat.
7. **`test/notification_controller_test.dart`**: Stream notifikasi, dismissal, banner heads-up.

### C. Data Architecture, Security & Test Doubles
8. **`test/repository_test_doubles_test.dart`**:
   - Pengujian `CilaluRepository` menggunakan `FakeFirestoreService` tanpa koneksi internet.
   - Fallback offline saat cloud tidak tersedia (`SyncStatus.offline`).
   - Penanganan error izin (*permission-denied*) dari security rules.
   - Propagasi penghapusan data antara cache disk lokal dan remote.
   - Isolasi data antar-perusahaan (*multi-tenant partitioning*).
9. **`test/data_architecture_test.dart`**: Verifikasi sumber data otoritatif (*Source of Truth*).
10. **`test/security_and_auth_test.dart`**: Pencegahan kebocoran kata sandi, otentikasi sesi backend.

### D. UI/UX, Form Validation & Responsive Layout
11. **`test/ui_ux_quality_test.dart`**:
    - Komponen reusable `AppEmptyState` dan semantik pembaca layar.
    - Dialog konfirmasi aksi destruktif `AppConfirmDialog`.
    - Validasi format email regex dan panjang password.
    - Fallback aman pada modal buat tugas saat daftar karyawan kosong.
    - Verifikasi bebas overflow pada layar kecil (`320x480 dp`).
12. **`test/widget_test.dart`**:
    - Navigasi tab 6 ikon untuk Admin vs antarmuka Karyawan.
    - Notifikasi banner in-app heads-up.
    - Restorasi data persisten lokal lintas restart aplikasi.

### E. End-to-End Integration Flow
13. **`test/integration_main_user_flow_test.dart`**:
    - Alur lengkap: *Launch → Sign In Admin → Load Data Perusahaan → Buat Tugas → Perbarui Progres 100% → Hapus Tugas → Registrasi Perusahaan Baru (Blank Mode) → Logout*.

---

## 💻 Panduan Menjalankan Pengujian Lokal

### 1. Menjalankan Format dan Linter
```bash
# Cek format (tanpa mengubah file)
dart format --output=none --set-exit-if-changed .

# Auto-format semua file yang belum sesuai standar
dart format .

# Analisis kode statis
flutter analyze
```

### 2. Menjalankan Seluruh Pengujian Flutter
```bash
# Jalankan seluruh suite test Flutter
flutter test

# Jalankan dengan laporan coverage
flutter test --coverage
```

### 3. Menjalankan Suite Pengujian Tertentu
```bash
# Menjalankan pengujian logika bisnis dan model
flutter test test/pure_business_logic_and_models_test.dart

# Menjalankan pengujian repository test doubles (offline simulation)
flutter test test/repository_test_doubles_test.dart

# Menjalankan pengujian alur integrasi end-to-end
flutter test test/integration_main_user_flow_test.dart

# Menjalankan pengujian kualitas UI/UX & responsivitas
flutter test test/ui_ux_quality_test.dart
```

---

## 🔥 Panduan Menjalankan Firebase Emulator & Security Rules Tests

Pengujian unit aturan keamanan Firestore (`firestore.rules`) dijalankan secara terisolasi menggunakan **Firebase Emulator Suite** tanpa menyentuh data produksi.

### Prasyarat:
1. **Node.js** (v18 atau v20 LTS).
2. **Java Runtime Environment (JRE)** v11 atau v17 (diperlukan untuk menjalankan Firestore Emulator JAR).
3. **Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

### Langkah Eksekusi:
```bash
# 1. Masuk ke direktori test_rules dan pasang dependensi
cd test_rules
npm install

# 2. Jalankan pengujian security rules menggunakan emulator
# Dari root direktori proyek:
firebase emulators:exec --only firestore "npm --prefix test_rules test"

# Atau jika emulator sudah berjalan di latar belakang:
npm --prefix test_rules test
```

> [!NOTE]
> Jika Firebase Emulator belum terpasang atau versi Java lokal di bawah Java 11, pengujian `flutter test` tetap dapat dijalankan 100% karena menggunakan repository test doubles (`FakeFirestoreService`) dan mock local storage. Pengujian rules otomatis dijalankan pada pipeline GitHub Actions yang telah dikonfigurasi dengan Java 17 dan Node 20.
