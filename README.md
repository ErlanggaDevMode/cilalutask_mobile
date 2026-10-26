# CILALUTASK Mobile (Dart & Flutter)

[![Release Candidate](https://img.shields.io/badge/Release%20Candidate-v1.0.0--rc1-brightgreen.svg)](RELEASE_NOTES.md)
[![Quality Gates](https://img.shields.io/badge/Quality%20Gates-100%25%20Passed%20(88%2F88)-blue.svg)](TESTING_AND_QUALITY_GATES.md)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.2%20%7C%20Dart%203.13.2-02569B.svg)](https://flutter.dev)

Aplikasi mobile korporat **CILALUTASK** untuk manajemen tugas operasional, verifikasi kepatuhan Standard Operating Procedure (SOP), pelaporan efisiensi tim, komunikasi chat multi-saluran, serta **arsitektur Multi-Perusahaan dengan Mode Data Bersih (Blank Slate) & Alur Persetujuan Karyawan (Admin Approval Workflow)**.

### 📚 Dokumentasi Release Candidate & Pengembang:
- 🚀 [**RELEASE_NOTES.md**](RELEASE_NOTES.md) — Rangkuman fitur, bug fixes, dan langkah migrasi akun/data.
- 📘 [**RELEASE_CANDIDATE_GUIDE.md**](RELEASE_CANDIDATE_GUIDE.md) — Panduan build, signing Android keystore, checklist pengujian manual 10 poin, dan klasifikasi audit.
- 🧪 [**TESTING_AND_QUALITY_GATES.md**](TESTING_AND_QUALITY_GATES.md) — Inventaris pengujian (Unit, Widget, Integration), Firebase Emulator setup, dan CI/CD.
- ⚡ [**PERFORMANCE_AND_OFFLINE_STRATEGY.md**](PERFORMANCE_AND_OFFLINE_STRATEGY.md) — Strategi bounded queries, lifecycle listener, antrean offline, dan rekonsiliasi data.

---

## 🌟 Fitur Baru: Multi-Company & Blank State Ready

### 🏢 1. Arsitektur Multi-Perusahaan (Multi-Tenant by Company ID)
- **ID / Kode Perusahaan Unik**: Setiap perusahaan memiliki kode unik (contoh: `CILALU-88`, `SINERGI-01`, `CORP-4821`).
- **Kartu Identitas Perusahaan**: Tersedia kartu identitas perusahaan dengan tombol **Salin Kode (Copy)** di Tab Tim dan Profil.
- **Peralihan Perusahaan (Company Switcher)**: Admin dapat membuat dan beralih antar perusahaan secara instan.

### 🧹 2. Mode Data Bersih (Blank Slate) untuk Input Manual Admin
- **Mulai dari Nol (100% Blank)**: Saat Admin membuat perusahaan baru melalui tab **Daftar PT**, sistem otomatis dimulai dalam status bersih tanpa data tiruan (dummy).
- **Input Manual Penuh oleh Admin**:
  - Admin dapat membuat tugas baru (`+ Buat Tugas Baru`)
  - Admin dapat mengunggah SOP operasional (`+ Unggah SOP`)
  - Admin dapat membuat saluran chat divisi (`+ Saluran`)
  - Admin dapat menyetujui dan menugaskan karyawan yang bergabung
- **Empty State Premium**: Jika belum ada data yang diinput, setiap tab (Beranda, Tugas, SOP, Laporan, Chat, Tim) menampilkan kartu antarmuka yang bersih, elegan, dan tombol aksi cepat untuk input pertama.
- **Pengalih Mode di Profil**: Melalui menu profil, Admin dapat beralih kapan saja antara **Reset ke Blank (Data Bersih)** dan **Muat Data Demo (Contoh)**.

### 👥 3. Alur Gabung Karyawan & Persetujuan Admin (Join Approval Workflow)
1. **Calon Karyawan Mengajukan Permohonan**:
   - Di halaman login, pilih tab **Gabung Tim**.
   - Masukkan **ID / Kode Perusahaan** (misal: `CILALU-88` atau kode perusahaan yang baru dibuat).
   - Isi Nama Lengkap, Divisi Kerja, Posisi/Jabatan, Email, dan Kata Sandi.
   - Tekan **Kirim Permohonan Bergabung**.
2. **Status Menunggu Persetujuan (Pending)**:
   - Karyawan langsung melihat kartu status: **⏳ Menunggu Persetujuan Admin**.
   - Karyawan belum dapat mengakses dashboard sampai disetujui Admin.
3. **Notifikasi & Review Admin Real-time**:
   - Admin pengelola perusahaan menerima notifikasi real-time seketika: *"Permintaan Bergabung Baru dari [Nama] ([Divisi])"*.
   - Di Tab Tim muncul banner perhatian: *"[X] Permohonan Karyawan Baru Menunggu Persetujuan"*.
4. **Keputusan Admin (Accept / Reject)**:
   - Admin membuka sheet **Permintaan Bergabung Tim**.
   - Admin meninjau data pelamar (Nama, Divisi, Role, Email, Foto).
   - Klik **Terima (Accept)** untuk mengesahkan karyawan masuk ke daftar pekerja aktif, atau **Tolak (Reject)**.
5. **Karyawan Resmi Bergabung**:
   - Status permohonan karyawan otomatis berubah menjadi **Diterima (Approved)**.
   - Karyawan dapat langsung masuk ke dashboard dan mulai memperbarui progres tugas divisi.

---

## 📱 Fitur Utama & Otoritas Akses (RBAC)

### 🔐 1. Halaman Masuk 3 Tab (Login, Daftar PT, Gabung Tim)
- **Tab 1: Masuk**:
  - Pilihan peran masuk sebagai **Admin (Manager)** atau **User (Karyawan)**.
  - Pilihan perusahaan aktif.
  - Pintasan Demo Cepat: `Demo Admin`, `Admin Blank (Bersih 100%)`, `Demo Karyawan`.
- **Tab 2: Daftar PT (Admin Baru)**:
  - Pendaftaran perusahaan baru dengan saran Kode ID otomatis.
  - Memulai dashboard dalam mode **Blank** untuk input manual.
- **Tab 3: Gabung Tim (Karyawan)**:
  - Input Kode ID Perusahaan tujuan & pengajuan akun karyawan.
  - Kartu pemantau status persetujuan langsung (Pending / Approved / Rejected).

### 🛡️ 2. Aturan Hak Akses (Role-Based Access Control)
- **User (Karyawan)**:
  - **Hanya User** yang dapat memperbarui checklist subtask & progres tugas (`Update Progres`).
  - Membaca dan mengonfirmasi kepatuhan SOP digital.
  - Berkomunikasi via Saluran Chat Tim dan Pesan Langsung (DM).
  - *Dibatasi*: Tidak dapat menerbitkan tugas baru dan tidak dapat mereview/menyetujui tugas.
- **Admin (Manager)**:
  - **Hanya Admin** yang dapat mereview dan memberikan persetujuan tugas (`Review & Persetujuan`).
  - **Hanya Admin** yang dapat membuat tugas baru (`Buat Tugas Baru` / `+ Tugas`) dan mendelegasikannya kepada karyawan.
  - Mengelola dan menyetujui permohonan gabung karyawan (`Join Requests`).
  - Menerbitkan dokumen SOP baru & membuat saluran chat baru.
  - Mengirimkan siaran pengumuman (Broadcast) ke seluruh divisi.

### 📑 3. Navigasi 6 Tab Terpadu
1. **Beranda (Home)**: Metrik tugas aktif, kartu sambutan perusahaan, aksi cepat adaptif peran, dan daftar tugas mendesak.
2. **Tugas (Tasks)**: Manajemen tugas dengan filter divisi, status, dan aksi terpisah sesuai peran (User: Update Progres, Admin: Review & + Tugas).
3. **Pusat SOP (Knowledge Base)**: Direktori dokumen SOP, filter kepatuhan, dan pembaca dokumen interaktif.
4. **Kinerja & Analisis (Reports)**: Laporan analitik dinamis (otomatis beradaptasi dengan mode blank), leaderboard tim, dan ekspor data.
5. **💬 Tab Chat (Kolaborasi Tim)**:
   - **Saluran Tim (Channels)**: Saluran divisi terpisah + tombol Admin untuk membuat saluran baru (`+ Saluran`).
   - **Pesan Langsung (Direct Messages)**: Chat 1-on-1 dengan seluruh karyawan perusahaan.
6. **Tim & Notifikasi (Team)**:
   - Kartu Identitas Perusahaan & Kode ID dengan tombol salin.
   - Banner notifikasi permohonan join karyawan (Admin).
   - Daftar anggota tim aktif dan riwayat notifikasi real-time.

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Masuk ke direktori mobile
```bash
cd cilalutask_mobile
```

### 2. Unduh dependensi
```bash
flutter pub get
```

### 3. Analisis kode & jalankan unit/widget test
```bash
flutter analyze
flutter test
```
*Hasil pengujian: `No issues found!` & `All tests passed!` (100% Lulus).*

### 4. Jalankan aplikasi
```bash
flutter run
```
Untuk memilih device tertentu:
```bash
flutter devices
flutter run -d <device-id>
```
Atau di web browser untuk preview instan:
```bash
flutter run -d chrome
```

---

## 🏛️ Struktur Arsitektur Codebase

```
cilalutask_mobile/
├── lib/
│   ├── main.dart                          # Entry point aplikasi
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart            # Token warna korporat & semantik
│   │   │   └── app_theme.dart             # ThemeData & komponen style
│   │   └── widgets/
│   │       ├── custom_avatar.dart         # Avatar dengan network fallback
│   │       └── custom_badge.dart          # Badge prioritas & divisi
│   ├── models/
│   │   ├── company.dart                   # Model Company, JoinRequest & Status
│   │   ├── task.dart                      # Model Tugas & Subtask
│   │   ├── sop.dart                       # Model Dokumen SOP
│   │   ├── employee.dart                  # Model Assignee & Performa
│   │   ├── activity.dart                  # Model Aktivitas Tim
│   │   ├── chat_model.dart                # Model ChatChannel & ChatMessage
│   │   ├── notification_item.dart         # Model Notifikasi
│   │   └── user_role.dart                 # Enum UserRole (Admin / User)
│   ├── data/
│   │   └── mock_data.dart                 # Data demo awal
│   ├── services/
│   │   └── local_storage_service.dart     # Engine penyimpanan lokal permanen (SharedPreferences)
│   ├── state/
│   │   ├── app_state_controller.dart      # Reactive business logic & multi-tenant state
│   │   └── app_state_scope.dart           # InheritedNotifier provider
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart          # 3 Tab: Masuk, Daftar PT, Gabung Tim
│   │   ├── main_navigation_screen.dart    # App Bar + BottomNav 6 Tab
│   │   ├── home/home_screen.dart          # Tab Beranda + Blank State handling
│   │   ├── tasks/tasks_screen.dart        # Tab Tugas + Blank State handling
│   │   ├── sop/sop_screen.dart            # Tab SOP + Blank State handling
│   │   ├── reports/reports_screen.dart    # Tab Laporan + Blank State handling
│   │   ├── chat/
│   │   │   ├── chat_screen.dart           # Tab Chat + Tambah Saluran dialog
│   │   │   └── chat_room_screen.dart      # Ruang Obrolan Saluran / DM
│   │   └── team/team_screen.dart          # Tab Tim + ID Perusahaan & Join Banner
│   └── widgets/modals/
│       ├── join_requests_bottom_sheet.dart# Modal persetujuan permohonan join (Admin)
│       ├── create_task_bottom_sheet.dart  # Form pembuatan tugas baru
│       ├── update_progress_bottom_sheet.dart # Checklist progres subtask
│       ├── review_task_bottom_sheet.dart  # Review manajerial
│       ├── sop_detail_bottom_sheet.dart   # Reader SOP
│       ├── upload_sop_bottom_sheet.dart   # Upload SOP
│       ├── export_report_bottom_sheet.dart# Ekspor PDF/Excel
│       ├── broadcast_bottom_sheet.dart    # Broadcast pengumuman
│       ├── notification_center_bottom_sheet.dart # Pusat notifikasi
│       └── profile_bottom_sheet.dart      # Info perusahaan, inisial avatar & pengalih Blank/Demo
└── test/
    └── widget_test.dart                   # Automated tests: Auth, Multi-Company, Join Flow, Realtime, Persistence
```

## 🧪 Automated Testing & Quality Gates

Cilalutask Mobile dilengkapi dengan rangkaian pengujian otomatis dan quality gates komprehensif (Unit, Widget, Integration, Security Rules, Linter, dan Formatter).

Panduan lengkap mengenai inventaris pengujian, perintah eksekusi lokal, dan cara menjalankan Firebase Emulator dapat dilihat pada:
👉 [**TESTING_AND_QUALITY_GATES.md**](TESTING_AND_QUALITY_GATES.md)

### Perintah Cepat Pengujian:
```bash
# 1. Validasi format kode
dart format --output=none --set-exit-if-changed .

# 2. Analisis kode statis
flutter analyze

# 3. Jalankan seluruh suite test Flutter
flutter test
```

---

## 💾 Arsitektur Penyimpanan & Backend (100% Free & Tahan Lama)

### 1. Lapisan Penyimpanan Lokal (Aktif Saat Ini - Zero Setup, Zero Cost)
- **Engine**: Menggunakan `LocalStorageService` berbasis `shared_preferences`.
- **Fitur Tersimpan Otomatis**:
  - Semua Perusahaan yang terdaftar (`Company`)
  - Sesi login akun aktif & kode perusahaan aktif
  - Riwayat obrolan lengkap (`ChatMessage`) per saluran dan direct message
  - Tugas operasional (`Task`) dan subtask checklist
  - Standar Operasional Prosedur (`SOPDocument`) & status pembaca
  - Permohonan bergabung karyawan (`JoinRequest`) & status persetujuan
  - Anggota tim (`Assignee`) & performa divisi
  - Riwayat notifikasi
- **Kelebihan**:
  - Berfungsi langsung 100% offline di Android, iOS, Web, dan Desktop.
  - Data **tidak akan hilang** meskipun aplikasi ditutup, di-restart, atau browser di-refresh.
  - Bebas biaya selamanya ($0), tanpa batas kuota server.

### 2. Panduan Integrasi Google Firebase (Cloud Sync Antar-Perangkat - 100% Free Spark Plan)
Untuk menghubungkan data secara online lintas HP karyawan dan Admin secara realtime tanpa biaya:
1. **Pilih Google Firebase (Spark Plan - Gratis Selamanya)**:
   - Tidak pernah *auto-pause* atau *sleep* (berbeda dengan Supabase free-tier yang tidur jika 7 hari tanpa akses).
   - Kuota gratis: 50.000 baca/hari, 20.000 tulis/hari, 1 GB penyimpanan database Cloud Firestore.
2. **Langkah Instalasi FlutterFire**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. **Struktur Koleksi Firestore (Multi-Tenant by Company Code)**:
   - `companies/{companyCode}`
   - `companies/{companyCode}/tasks/{taskId}`
   - `companies/{companyCode}/sops/{sopId}`
   - `companies/{companyCode}/channels/{channelId}/messages/{messageId}`
   - `companies/{companyCode}/join_requests/{requestId}`
   - `companies/{companyCode}/members/{memberId}`
4. Model serialization di aplikasi sudah 100% siap (`toMap()` dan `fromMap()`) sehingga dapat langsung dipetakan ke dokumen Firestore.

