import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../models/sop.dart';
import '../models/activity.dart';
import '../models/notification_item.dart';
import '../core/theme/app_colors.dart';

final CurrentUser kCurrentUser = CurrentUser(
  name: 'Sarah Pratama',
  role: 'Admin / Manager',
  email: 'sarah.pratama@cilulataks.id',
  avatar: '',
  division: 'Operations & Strategy',
  targetQuarterPercent: 88,
  teamEfficiencyPercent: 94,
);

final List<Assignee> kEmployees = [
  const Assignee(
    id: 'emp-1',
    name: 'Kevin Maulana',
    shortName: 'Kevin M.',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=256',
    division: 'IT & Tech',
    role: 'Lead Cloud Engineer',
    hasTeamBadge: true,
    teamCount: 2,
    email: 'kevin.maulana@cilulataks.id',
  ),
  const Assignee(
    id: 'emp-2',
    name: 'Nadia Salsabila',
    shortName: 'Nadia S.',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=256',
    division: 'Pemasaran',
    role: 'Senior Content Strategist',
    email: 'nadia.salsabila@cilulataks.id',
  ),
  const Assignee(
    id: 'emp-3',
    name: 'Budi Santoso',
    shortName: 'Budi S.',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=256',
    division: 'Operasional',
    role: 'Supervisor Gudang',
    email: 'budi.santoso@cilulataks.id',
  ),
  const Assignee(
    id: 'emp-4',
    name: 'Rian Dermawan',
    shortName: 'Rian D.',
    avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=256',
    division: 'Finance & Akuntansi',
    role: 'Tax & Compliance Officer',
    email: 'rian.dermawan@cilulataks.id',
  ),
  const Assignee(
    id: 'emp-5',
    name: 'Ahmad Fauzi',
    shortName: 'Ahmad F.',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=256',
    division: 'Operasional',
    role: 'Quality & Inbound Lead',
    email: 'ahmad.fauzi@cilulataks.id',
  ),
  const Assignee(
    id: 'emp-6',
    name: 'Dina Putri',
    shortName: 'Dina P.',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=256',
    division: 'Pemasaran',
    role: 'Visual Designer',
    email: 'dina.putri@cilulataks.id',
  ),
];

final List<Task> kInitialTasks = [
  Task(
    id: 'tsk-001',
    title: 'Migrasi Database Transaksi ke AWS Aurora',
    description: 'Sinkronisasi schema replika dan verifikasi failover cluster sebelum proses cut-over production.',
    division: 'IT & Tech',
    priority: PriorityType.high,
    status: TaskStatus.inProgress,
    deadlineLabel: '2 hari lagi',
    isUrgentDeadline: false,
    progressPercent: 67,
    needsReview: true,
    assignee: kEmployees[0],
    subtasks: const [
      Subtask(
        id: 'sub-1',
        title: 'Backup full dump database PostgreSQL',
        completed: true,
      ),
      Subtask(
        id: 'sub-2',
        title: 'Konfigurasi replication slot AWS DMS',
        completed: true,
      ),
      Subtask(
        id: 'sub-3',
        title: 'Uji stress test throughput 10k RPS',
        completed: true,
      ),
      Subtask(
        id: 'sub-4',
        title: 'Validasi integritas checksum transaksi',
        completed: true,
      ),
      Subtask(
        id: 'sub-5',
        title: 'Simulasi auto-failover cluster multi-AZ',
        completed: false,
      ),
      Subtask(
        id: 'sub-6',
        title: 'Dokumentasi SOP pemulihan darurat',
        completed: false,
      ),
    ],
  ),
  Task(
    id: 'tsk-002',
    title: 'Penyusunan Konten Campaign Mid-Year Sale',
    description: 'Finalisasi copy banner, brief influencer reels, dan peluncuran newsletter diskon 50%.',
    division: 'Pemasaran',
    priority: PriorityType.medium,
    status: TaskStatus.inProgress,
    deadlineLabel: '3 hari lagi (17 Mei)',
    isUrgentDeadline: false,
    progressPercent: 40,
    assignee: kEmployees[1],
    subtasks: const [
      Subtask(
        id: 'sub-201',
        title: 'Draft copy headline promo & CTA voucher',
        completed: true,
      ),
      Subtask(
        id: 'sub-202',
        title: 'Desain visual master banner 3 format',
        completed: true,
      ),
      Subtask(
        id: 'sub-203',
        title: 'Kirim brief 5 Key Opinion Leaders (KOL)',
        completed: false,
      ),
      Subtask(
        id: 'sub-204',
        title: 'Review script video edukasi TikTok',
        completed: false,
      ),
      Subtask(
        id: 'sub-205',
        title: 'Pengaturan jadwal email blast Mailchimp',
        completed: false,
      ),
    ],
  ),
  Task(
    id: 'tsk-003',
    title: 'Pemeriksaan Stok Gudang Pusat Cikarang',
    description: 'Stock opname kuartal II unit elektronik dan pencocokan kartu stok fisik dengan ERP WMS.',
    division: 'Operasional',
    priority: PriorityType.high,
    status: TaskStatus.inProgress,
    deadlineLabel: 'Hari ini 18:00',
    isUrgentDeadline: true,
    isToday: true,
    progressPercent: 88,
    assignee: kEmployees[2],
    subtasks: const [
      Subtask(
        id: 'sub-301',
        title: 'Pengecekan rack A1 sampai A12 modul TV',
        completed: true,
      ),
      Subtask(
        id: 'sub-302',
        title: 'Scanning barcode serial number AC & Kulkas',
        completed: true,
      ),
      Subtask(
        id: 'sub-303',
        title: 'Validasi barang retur & karantina',
        completed: true,
      ),
      Subtask(
        id: 'sub-304',
        title: 'Pemeriksaan segel kemasan pallet transit',
        completed: true,
      ),
      Subtask(
        id: 'sub-305',
        title: 'Rekap selisih fisik vs sistem warehouse',
        completed: true,
      ),
      Subtask(
        id: 'sub-306',
        title: 'Foto dokumentasi kondisi fisik gudang',
        completed: true,
      ),
      Subtask(
        id: 'sub-307',
        title: 'Verifikasi tanda tangan kepala logistik',
        completed: true,
      ),
      Subtask(
        id: 'sub-308',
        title: 'Input berita acara serah terima ke portal',
        completed: false,
      ),
    ],
  ),
  Task(
    id: 'tsk-004',
    title: 'Rekonsiliasi Pajak Bulanan Divisi Finance',
    description: 'Penyusunan e-Faktur PPN, bukti potong PPh 21/23, dan konfirmasi setoran SPT Masa.',
    division: 'Finance & Akuntansi',
    priority: PriorityType.high,
    status: TaskStatus.inProgress,
    deadlineLabel: 'Hari Ini, 17:00',
    isUrgentDeadline: true,
    isToday: true,
    progressPercent: 75,
    needsReview: true,
    assignee: kEmployees[3],
    subtasks: const [
      Subtask(
        id: 'sub-401',
        title: 'Sinkronisasi billing faktur pajak masukan',
        completed: true,
      ),
      Subtask(
        id: 'sub-402',
        title: 'Rekapitulasi withholding tax vendor jasa',
        completed: true,
      ),
      Subtask(
        id: 'sub-403',
        title: 'Validasi NTPN bukti transfer bank Mandiri',
        completed: true,
      ),
      Subtask(
        id: 'sub-404',
        title: 'Final upload file CSV ke DJP Online',
        completed: false,
      ),
    ],
  ),
  Task(
    id: 'tsk-005',
    title: 'Audit Keamanan Server Q2 Divisi IT',
    description: 'Pemeriksaan akses SSH bastion host, sertifikat SSL TLS, dan rotasi secret key API.',
    division: 'IT & Tech',
    priority: PriorityType.medium,
    status: TaskStatus.inProgress,
    deadlineLabel: 'Besok, 12:00',
    isUrgentDeadline: true,
    progressPercent: 40,
    assignee: kEmployees[0],
    subtasks: const [
      Subtask(
        id: 'sub-501',
        title: 'Scan vulnerability port open Nessus',
        completed: true,
      ),
      Subtask(
        id: 'sub-502',
        title: 'Audit list user root & privilege sudoers',
        completed: true,
      ),
      Subtask(
        id: 'sub-503',
        title: 'Revoke token API key yang tidak aktif >90 hari',
        completed: false,
      ),
      Subtask(
        id: 'sub-504',
        title: 'Pembaruan sertifikat wildcard LetsEncrypt',
        completed: false,
      ),
      Subtask(
        id: 'sub-505',
        title: 'Laporan rekap insiden triwulan',
        completed: false,
      ),
    ],
  ),
  Task(
    id: 'tsk-006',
    title: 'Penerimaan & Sortir Pallet Bahan Baku Vendor',
    description: 'Inspeksi kedatangan 4 kontainer bahan baku tekstil sesuai standar ISO 9001.',
    division: 'Operasional',
    priority: PriorityType.low,
    status: TaskStatus.completed,
    deadlineLabel: 'Selesai kemarin',
    progressPercent: 100,
    assignee: kEmployees[4],
    subtasks: const [
      Subtask(
        id: 'sub-601',
        title: 'Cek delivery order surat jalan ekspedisi',
        completed: true,
      ),
      Subtask(
        id: 'sub-602',
        title: 'Sampling kelembaban & ketahanan kain',
        completed: true,
      ),
      Subtask(
        id: 'sub-603',
        title: 'Input kode batch barcode ke inventory ERP',
        completed: true,
      ),
    ],
  ),
  Task(
    id: 'tsk-007',
    title: 'Desain Banner Promosi & Mockup Kemasan Baru',
    description: 'Eksplorasi visual packaging premium ramah lingkungan edisi ulang tahun perusahaan.',
    division: 'Pemasaran',
    priority: PriorityType.medium,
    status: TaskStatus.completed,
    deadlineLabel: 'Selesai tadi pagi',
    progressPercent: 100,
    assignee: kEmployees[5],
    subtasks: const [
      Subtask(
        id: 'sub-701',
        title: 'Brainstorming palet warna & gaya ilustrasi',
        completed: true,
      ),
      Subtask(
        id: 'sub-702',
        title: '3D packaging render di Blender',
        completed: true,
      ),
      Subtask(
        id: 'sub-703',
        title: 'Approval final cetak dari Brand Manager',
        completed: true,
      ),
    ],
  ),
  Task(
    id: 'tsk-008',
    title: 'Review Anggaran Belanja Modal Q3 Divisi Gudang',
    description: 'Analisis kelayakan investasi 2 unit forklift elektrik dan racking tier tinggi.',
    division: 'Finance & Akuntansi',
    priority: PriorityType.medium,
    status: TaskStatus.notStarted,
    deadlineLabel: '5 hari lagi',
    progressPercent: 0,
    assignee: kEmployees[3],
    subtasks: const [
      Subtask(
        id: 'sub-801',
        title: 'Komparasi vendor forklift Toyota vs Yale',
        completed: false,
      ),
      Subtask(
        id: 'sub-802',
        title: 'Hitung ROI & perkiraan penghematan energi',
        completed: false,
      ),
      Subtask(
        id: 'sub-803',
        title: 'Penyusunan slide presentasi Direksi',
        completed: false,
      ),
    ],
  ),
];

final List<SOPDocument> kInitialSops = [
  const SOPDocument(
    id: 'sop-001',
    code: 'SOP-2025-OPS-04',
    title: 'Prosedur Keselamatan Kerja Alat Berat Baru',
    category: 'Keamanan Kerja (K3)',
    version: 'v1.0',
    isUrgentMandatory: true,
    deadlineWarning: '2 hari lagi',
    complianceTag: 'Kepatuhan K3 Divisi Alat',
    lastUpdatedText: 'Diterbitkan 10 Mei 2025',
    checkPoints: '8 Titik Inspeksi Wajib',
    duration: '10 Menit Baca',
    description: 'Instruksi wajib keselamatan operator dan kru lapangan saat pengoperasian excavator mini dan forklift heavy-duty generasi terbaru.',
    contentSections: [
      ContentSection(
        heading: 'Pemeriksaan Awal (Pre-Operation Checklist)',
        items: [
          'Memastikan APD lengkap: Helm safety, rompi reflektor grade 3, kacamata pelindung, dan sepatu boots baja.',
          'Pemeriksaan level oli mesin, cairan hidrolik, dan indikator rem angin sebelum kontak dihidupkan.',
          'Uji fungsi alarm mundur (reverse buzzer) dan lampu rotary suar darurat.',
        ],
      ),
      ContentSection(
        heading: 'Zona Steril & Komunikasi Lapangan',
        items: [
          'Membuat batas radius aman minimal 5 meter dari jangkauan lengan alat berat.',
          'Menggunakan sinyal tangan standar K3 internasional jika komunikasi radio terputus.',
        ],
      ),
    ],
    isReadByMe: false,
  ),
  const SOPDocument(
    id: 'sop-002',
    code: 'SOP-CC-012',
    title: 'Penanganan Komplain Pelanggan Prioritas',
    category: 'Customer Service',
    version: 'v2.4',
    readProgressPercent: 94,
    complianceRatioText: '94% Karyawan sudah membaca & menyetujui',
    readTeamCount: '32/34 Tim',
    lastUpdatedText: 'Perbaruan: 3 Mei 2025',
    description: 'Standar penanganan tiket eskalasi pelanggan korporat Platinum dengan jaminan SLA response time di bawah 15 menit.',
    isBookmarked: false,
    contentSections: [
      ContentSection(
        heading: 'Klasifikasi Tingkat Keparahan Tiket',
        items: [
          'Tier 1: Gangguan sistemik berdampak ke seluruh cabang mitra.',
          'Tier 2: Kendala fungsional transaksi satuan.',
          'Penyampaian salam empati dan nomor tiket pelacakan otomatis via WhatsApp verified.',
        ],
      ),
    ],
    isReadByMe: true,
  ),
  const SOPDocument(
    id: 'sop-003',
    code: 'SOP-FIN-008',
    title: 'Pengajuan Reimbursement dan Klaim Medis',
    category: 'Finance & HRD',
    version: 'v3.1',
    readProgressPercent: 100,
    complianceRatioText: 'Status: 100% Karyawan terverifikasi',
    readTeamCount: 'Lengkap',
    lastUpdatedText: 'Diperbarui 1 bln lalu',
    description: 'Pedoman administrasi klaim biaya perjalanan dinas, makan lembur, serta asuransi kesehatan rawat jalan/inap.',
    isBookmarked: true,
    contentSections: [
      ContentSection(
        heading: 'Syarat Kelengkapan Dokumen',
        items: [
          'Struk asli bermaterai atau e-receipt resmi ber-NPWP.',
          'Form klaim ditandatangani atasan langsung maksimal tanggal 20 tiap bulannya.',
        ],
      ),
    ],
    isReadByMe: true,
  ),
  const SOPDocument(
    id: 'sop-004',
    code: 'SOP-IT-005',
    title: 'Penanganan Insiden Keamanan Data',
    category: 'IT Department',
    version: 'v1.8',
    isNewUpdate: true,
    fileInfo: 'Versi 1.8 (PDF 2.4 MB)',
    lastUpdatedText: 'Diperbarui 2 minggu lalu',
    description: 'Pedoman eskalasi dan mitigasi serangan siber, phishing email, dan kebocoran kredensial akses pada infrastruktur cloud.',
    isBookmarked: false,
    contentSections: [
      ContentSection(
        heading: 'Langkah Awal Penahanan (Containment)',
        items: [
          'Segera isolasi instance/IP yang terinfeksi dari subnet produksi.',
          'Aktifkan mode rotasi darurat IAM credentials dan force logout active sessions.',
        ],
      ),
    ],
    isReadByMe: false,
  ),
  const SOPDocument(
    id: 'sop-005',
    code: 'SOP-OPS-022',
    title: 'Maintenance Mesin Produksi Harian',
    category: 'Operasional Gudang',
    version: 'v2.0',
    checkPoints: '12 Poin Pengecekan',
    duration: '15 Menit / Sesi',
    lastUpdatedText: 'Revisi Berkala',
    description: 'Prosedur pembersihan belt conveyor, pelumasan bearing motor, dan kalibrasi sensor timbangan otomatis.',
    isBookmarked: false,
    contentSections: [
      ContentSection(
        heading: 'Protokol Lock-Out Tag-Out (LOTO)',
        items: [
          'Putuskan saklar daya utama sebelum membuka penutup rotor motor.',
          'Pasang gembok fisik keselamatan dengan nama teknisi yang bertugas.',
        ],
      ),
    ],
    isReadByMe: true,
  ),
];

final List<ActivityItem> kInitialActivities = [
  const ActivityItem(
    id: 'act-1',
    userName: 'Ahmad Fauzi',
    userAvatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=256',
    actionPrefix: 'menyelesaikan SOP',
    targetObject: 'Penerimaan Barang Baru.',
    timeAgo: '10 mnt lalu',
    department: 'Bagian Logistik',
    type: 'sop',
  ),
  const ActivityItem(
    id: 'act-2',
    userName: 'Dina Putri',
    userAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=256',
    actionPrefix: 'memperbarui status tugas',
    targetObject: 'Desain Kemasan',
    actionSuffix: 'ke Selesai.',
    timeAgo: '25 mnt lalu',
    department: 'Bagian Kreatif',
    type: 'task',
  ),
  const ActivityItem(
    id: 'act-3',
    userName: 'Rian Dermawan',
    userAvatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=256',
    actionPrefix: 'mengajukan review tugas',
    targetObject: 'Rekonsiliasi Pajak Bulanan.',
    timeAgo: '45 mnt lalu',
    department: 'Divisi Finance',
    type: 'task',
  ),
];

final List<EmployeePerformance> kEmployeePerformance = [
  const EmployeePerformance(
    id: 'perf-1',
    rank: 1,
    name: 'Ahmad Fauzi',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=256',
    division: 'Operasional',
    completedTasks: 28,
    delayedTasks: 0,
    score: 98,
    statusTag: 'SANGAT BAIK',
    isStar: true,
  ),
  const EmployeePerformance(
    id: 'perf-2',
    rank: 2,
    name: 'Rian Dermawan',
    avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=256',
    division: 'Finance & Akuntansi',
    completedTasks: 22,
    delayedTasks: 0,
    score: 96,
    statusTag: 'SANGAT BAIK',
  ),
  const EmployeePerformance(
    id: 'perf-3',
    rank: 3,
    name: 'Nadia Salsabila',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=256',
    division: 'Pemasaran',
    completedTasks: 24,
    delayedTasks: 1,
    score: 94,
    statusTag: 'OPTIMAL',
  ),
  const EmployeePerformance(
    id: 'perf-4',
    rank: 4,
    name: 'Kevin Maulana',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=256',
    division: 'IT & Development',
    completedTasks: 19,
    delayedTasks: 2,
    score: 89,
    statusTag: 'STABIL',
  ),
];

final List<DivisionProductivity> kDivisionProductivity = [
  const DivisionProductivity(
    name: 'Operasional',
    percent: 95,
    color: AppColors.success,
  ),
  const DivisionProductivity(
    name: 'Finance & Akuntansi',
    percent: 94,
    color: Color(0xFFA5B4FC),
  ),
  const DivisionProductivity(
    name: 'IT & Development',
    percent: 91,
    color: AppColors.primary,
  ),
  const DivisionProductivity(
    name: 'Pemasaran',
    percent: 89,
    color: AppColors.primaryDark,
  ),
];

final List<NotificationItem> kNotificationsData = [
  const NotificationItem(
    id: 'notif-1',
    title: 'SOP Baru Wajib Dibaca',
    description: 'Prosedur Keselamatan Kerja Alat Berat Baru (SOP-2025-OPS-04) butuh konfirmasi verifikasi Anda.',
    time: '30 menit lalu',
    unread: true,
    type: 'sop',
  ),
  const NotificationItem(
    id: 'notif-2',
    title: 'Permintaan Review Tugas',
    description: 'Rian D. telah menyelesaikan draft Rekonsiliasi Pajak dan menunggu persetujuan manajerial.',
    time: '1 jam lalu',
    unread: true,
    type: 'task',
  ),
  const NotificationItem(
    id: 'notif-3',
    title: 'Peringatan Batas Waktu',
    description: 'Tugas Pemeriksaan Stok Gudang Cikarang jatuh tempo hari ini pukul 18:00 WIB.',
    time: '2 jam lalu',
    unread: true,
    type: 'deadline',
  ),
];
