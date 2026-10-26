# 🚀 Cilalutask Mobile - Release Notes (v1.0.0-rc1)

**Tanggal Rilis**: 26 Oktober 2026  
**Target Platform**: Android (minSdk 21 / targetSdk 34+), iOS (12.0+), Web, Windows Desktop  
**Status**: Release Candidate 1 (RC1) — Siap Uji Lapangan & Audit Keamanan

---

## 📌 Ringkasan Rilis (Executive Summary)
Cilalutask Mobile v1.0.0-rc1 merupakan tonggak penting transformasi aplikasi dari prototipe berbasis in-memory/dummy menjadi platform operasional korporat berskala production. Rilis ini mencakup arsitektur Multi-Tenant yang terisolasi ketat, autentikasi terstandarisasi Firebase Auth tanpa password plaintext, audit dan refactoring kontroler domain, peningkatan kualitas UI/UX responsif terhadap layar kecil (320px), strategi caching offline-first dengan rekonsiliasi otomatis, serta 100% lolos automated quality gates (88 automated tests).

---

## 🔒 1. Peningkatan Keamanan & Autentikasi (Security Hardening)
- **Eliminasi Total Password Plaintext**:
  - Menghapus seluruh field `password`, `adminPassword`, dan `userPassword` dari model data (`Company`, `Assignee`, `JoinRequest`, `Employee`), mock data, dan `LocalStorageService`.
  - Migrasi sistem autentikasi ke [AuthService](file:///c:/T/Cilalutask/cilalutask_mobile/lib/services/auth_service.dart) berbasis **Firebase Authentication** terverifikasi.
- **Pembersihan Log & Kredensial**:
  - Seluruh statement `print` dihapus dari kode sumber. `debugPrint` hanya mencatat trace error operasional tanpa data sensitif atau PII.
  - File rahasia (`.env`, `key.properties`, keystore, service-account JSON) diproteksi di `.gitignore` dengan template `.example` yang aman.
- **Firestore Security Rules (Least-Privilege & RBAC)**:
  - Implementasi [firestore.rules](file:///c:/T/Cilalutask/cilalutask_mobile/firestore.rules) (179 baris) dengan aturan isolasi per `companyCode`.
  - Memvalidasi kepemilikan admin (`isCompanyAdmin`), keanggotaan aktif (`isCompanyMember`), serta penolakan otomatis dokumen yang mengandung atribut password (`hasNoPasswords()`).

---

## 🏢 2. Arsitektur Multi-Perusahaan & Alur Persetujuan (Multi-Tenant & Approval)
- **Pemisahan Data Antar-Perusahaan**:
  - Seluruh sub-koleksi (`tasks`, `sops`, `messages`, `channels`, `join_requests`, `members`, `notifications`) dipartisi di bawah `companies/{companyCode}`.
  - Pengujian isolasi multi-tenant menjamin karyawan Perusahaan A tidak dapat membaca atau memanipulasi data Perusahaan B.
- **Alur Persetujuan Karyawan (Join Approval Workflow)**:
  - Calon karyawan mengajukan permohonan dengan status `pending`.
  - Admin perusahaan menerima notifikasi real-time dan meninjau di bottom sheet join requests.
  - Dashboard baru dapat diakses setelah disetujui (status `approved`).
- **Mode Blank Slate (Data Bersih)**:
  - Perusahaan baru dimulai 100% kosong tanpa data demo tiruan, dengan empty state intuitif dan tombol aksi cepat untuk input pertama.

---

## 🧩 3. Refactoring Arsitektur State Management (Domain Separation)
`AppStateController` yang sebelumnya monolithic (1.500+ baris) telah dipecah menjadi kontroler domain modular:
- [CompanyController](file:///c:/T/Cilalutask/cilalutask_mobile/lib/state/company_controller.dart): Mengelola registrasi perusahaan, join requests, anggota, dan switching company.
- [TaskController](file:///c:/T/Cilalutask/cilalutask_mobile/lib/state/task_controller.dart): Mengelola CRUD tugas, checklist subtask, delegasi, dan review manajerial.
- [SopController](file:///c:/T/Cilalutask/cilalutask_mobile/lib/state/sop_controller.dart): Mengelola repositori SOP, bookmark, dan verifikasi kepatuhan baca karyawan.
- [ChatController](file:///c:/T/Cilalutask/cilalutask_mobile/lib/state/chat_controller.dart): Mengelola saluran divisi, percakapan tim, dan direct messaging (DM).
- [NotificationController](file:///c:/T/Cilalutask/cilalutask_mobile/lib/state/notification_controller.dart): Mengelola notifikasi in-app banner dan pusat notifikasi.
- [AppStateController](file:///c:/T/Cilalutask/cilalutask_mobile/lib/state/app_state_controller.dart): Berfungsi sebagai koordinator dan facade kompatibilitas mundur untuk screen existing.

---

## ⚡ 4. Perbaikan Fungsional & Metrik Kinerja (Bug Fixes & Metrics)
- **Kalkulator Metrik Terpusat**:
  - Dibuat [TaskMetricsCalculator](file:///c:/T/Cilalutask/cilalutask_mobile/lib/core/utils/task_metrics_calculator.dart) untuk menjamin kesamaan kalkulasi completion rate, tugas selesai, sedang berjalan, dan overdue antara Dashboard Beranda, Daftar Tugas, dan Tab Laporan.
  - Memperbaiki pembagian nol (division by zero) pada perusahaan yang belum memiliki tugas (menghasilkan angka 0% aman, bukan `NaN`).
  - Label bulan/tahun kini dinamis mengikuti kalender lokal Indonesia (contoh: "Oktober 2026").
- **Filter & Search Reaktif**:
  - Memperbaiki tab awal TasksScreen agar selalu menampilkan "Semua" secara default tanpa menyembunyikan tugas aktif.
  - Menambahkan debouncing pencarian 300ms untuk mencegah query Firestore berlebihan.
  - Mengaktifkan bottom sheet filter untuk filter kombinasi status, divisi, dan urutan prioritas.

---

## 🎨 5. Peningkatan Kualitas UI/UX (Accessibility & Resilience)
- **Komponen Standar Baru**:
  - [AppEmptyState](file:///c:/T/Cilalutask/cilalutask_mobile/lib/core/widgets/app_empty_state.dart): Empty state konsisten dengan ilustrasi ikon lembut, judul, deskripsi, dan tombol aksi berikutnya.
  - [AppConfirmDialog](file:///c:/T/Cilalutask/cilalutask_mobile/lib/core/widgets/app_confirm_dialog.dart): Dialog konfirmasi modal sebelum aksi destruktif (menghapus tugas atau SOP) untuk mencegah salah tekan.
- **Resiliensi Layar Kecil (320px x 480px)**:
  - Membungkus dialog, modal sheets, dan kartu metrik dalam `SingleChildScrollView` dan layout fleksibel untuk mengeliminasi overflow pixel pada perangkat kecil.
- **Pemberian Umpan Balik Asinkron**:
  - Tombol aksi mematikan (disable) interaksi ganda selama proses penyimpanan (`isLoading`) dan menampilkan indikator loading.

---

## 📶 6. Performa & Pengalaman Offline (Offline-First Resilience)
- **Batas Query (Bounded Queries)**:
  - Query Firestore dibatasi (`limit(50)` untuk tasks/SOPs, `limit(100)` untuk pesan) guna menghemat kuota pembacaan Cloud Firestore.
- **Siklus Hidup Subscription Bersih**:
  - Seluruh StreamSubscription Firestore (`tasks`, `sops`, `messages`, `join_requests`, `notifications`) dihentikan (`cancel()`) saat berganti perusahaan atau logout, mencegah kebocoran memori (memory leak).
- **Antrean Tulis Tertunda & Rekonsiliasi**:
  - Operasi saat koneksi offline disimpan ke antrean `_prefixPendingTasks` di memori dan SharedPreferences.
  - Metode `reconcilePendingWrites()` otomatis mengeksekusi sinkronisasi saat perangkat terhubung kembali ke jaringan.

---

## 🔄 7. Panduan Migrasi Data & Akun (Migration Guide)
Bagi pengguna atau pengembang dari versi prototipe lama:
1. **Pembaruan Akun Pengguna**:
   - Versi sebelumnya menyimpan akun dan kata sandi di `SharedPreferences` lokal.
   - Pada v1.0.0-rc1, pengguna cukup mendaftar/masuk menggunakan email dan password melalui Firebase Auth.
   - Sesi token pengguna dikelola aman oleh SDK Firebase Auth.
2. **Struktur Data Firestore**:
   - Jika memiliki basis data Firestore prototipe lama yang menyimpan field `password` pada dokumen perusahaan atau user, jalankan skrip migrasi atau hapus field tersebut, karena [firestore.rules](file:///c:/T/Cilalutask/cilalutask_mobile/firestore.rules) v1.0.0 akan menolak operasi tulis (`create`/`update`) pada dokumen yang memiliki atribut password.
3. **Penyebaran Aturan & Indeks**:
   - Jalankan `firebase deploy --only firestore:rules,firestore:indexes` dari mesin administrator sebelum merilis ke pengguna umum.
