import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'
    show ImagePicker, ImageSource, XFile;

import '../../models/company.dart';
import '../../models/employee.dart';
import '../../models/sop.dart';
import '../../models/task.dart';
import 'task_metrics_calculator.dart';

/// Represents a picked or generated SOP attachment file after security validation.
class PickedSopAttachment {
  final String fileName;
  final int fileSize;
  final String mimeType;
  final Uint8List bytes;
  final String? extractedText;

  const PickedSopAttachment({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.bytes,
    this.extractedText,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Encodes bytes as base64 if within safe storage threshold (<= 750 KB).
  String? get safeBase64ForStorage {
    if (bytes.length > 750 * 1024) return null;
    return base64Encode(bytes);
  }
}

/// Options for customizing which sections to include in an exported report.
class ReportExportOptions {
  final String format; // 'pdf' | 'xlsx' | 'csv'
  final String period;
  final String divisionFilter; // 'Semua Divisi' or specific division
  final bool includeExecutiveSummary;
  final bool includeDivisionProductivity;
  final bool includeEmployeeLeaderboard;
  final bool includeTaskDetails;
  final bool includeSopCompliance;

  const ReportExportOptions({
    required this.format,
    required this.period,
    this.divisionFilter = 'Semua Divisi',
    this.includeExecutiveSummary = true,
    this.includeDivisionProductivity = true,
    this.includeEmployeeLeaderboard = true,
    this.includeTaskDetails = true,
    this.includeSopCompliance = true,
  });
}

/// Result of generating and exporting a report or SOP document.
class ExportResult {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final String textPreview;
  final bool savedToDevice;
  final String savedLocationHint;

  const ExportResult({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.textPreview,
    required this.savedToDevice,
    required this.savedLocationHint,
  });

  String get formattedSize {
    final len = bytes.length;
    if (len < 1024) return '$len B';
    if (len < 1024 * 1024) return '${(len / 1024).toStringAsFixed(1)} KB';
    return '${(len / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Utility for secure SOP file upload handling, PDF-1.4 binary generation,
/// Excel SpreadsheetML (.xls/.xlsx) generation, and UTF-8 CSV generation.
class ReportAndSopExporter {
  /// Maximum allowed upload file size: 10 MB.
  static const int maxUploadBytes = 10 * 1024 * 1024;

  /// Strict allow-list of permitted SOP attachment file extensions.
  static const List<String> allowedSopExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.md',
    '.png',
    '.jpg',
    '.jpeg',
  ];

  // Security Note: Server-side malware scanning (ClamAV/Cloud API) and Content Disarm &
  // Reconstruction (CDR) should be enforced by the backend storage service in production.

  /// Sanitizes a filename by stripping path traversal sequences and unsafe characters.
  static String sanitizeFileName(
    String rawName, {
    String fallback = 'dokumen_sop.pdf',
  }) {
    if (rawName.trim().isEmpty) return fallback;
    // Strip directory paths (both POSIX '/' and Windows '\')
    final parts = rawName.split(RegExp(r'[/\\]'));
    String base = parts.isNotEmpty ? parts.last.trim() : '';
    // Remove any '..' traversal sequences
    base = base.replaceAll('..', '');
    // Replace any characters outside safe allow-list
    base = base.replaceAll(RegExp(r'[^a-zA-Z0-9._\- ]'), '_').trim();
    base = base.replaceAll(RegExp(r'\s+'), '_');
    if (base.isEmpty || base.startsWith('.')) {
      return fallback;
    }
    return base;
  }

  /// Validates whether a filename has an allowed extension for SOP upload.
  static bool isAllowedSopExtension(String fileName) {
    final lower = fileName.toLowerCase().trim();
    return allowedSopExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Infers MIME type from filename extension.
  static String inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'text/plain';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return 'application/vnd.ms-excel';
    }
    return 'application/octet-stream';
  }

  /// Opens native/browser file picker to select an SOP document (PDF, DOC, DOCX, TXT, Image).
  static Future<PickedSopAttachment?> pickSopDocumentFile() async {
    XFile? pickedFile;
    final picker = ImagePicker();

    try {
      pickedFile = await picker.pickMedia();
    } catch (_) {
      try {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } catch (e) {
        debugPrint('File picker fallback error: $e');
      }
    }

    if (pickedFile == null) return null;

    final rawName = pickedFile.name.isNotEmpty
        ? pickedFile.name
        : pickedFile.path;
    final cleanName = sanitizeFileName(rawName, fallback: 'lampiran_sop.pdf');

    if (!isAllowedSopExtension(cleanName)) {
      throw FormatException(
        'Format berkas "$cleanName" tidak didukung. Gunakan PDF, DOC, DOCX, TXT, atau Gambar (PNG/JPG).',
      );
    }

    final bytes = await pickedFile.readAsBytes();
    if (bytes.length > maxUploadBytes) {
      throw FormatException(
        'Ukuran berkas terlalu besar (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB). Maksimal 10 MB.',
      );
    }

    String? extractedText;
    if (cleanName.toLowerCase().endsWith('.txt') ||
        cleanName.toLowerCase().endsWith('.md')) {
      try {
        extractedText = utf8.decode(bytes, allowMalformed: true).trim();
      } catch (_) {}
    }

    return PickedSopAttachment(
      fileName: cleanName,
      fileSize: bytes.length,
      mimeType: pickedFile.mimeType ?? inferMimeType(cleanName),
      bytes: bytes,
      extractedText: extractedText,
    );
  }

  /// Generates a ready-to-attach official PDF SOP document from form fields.
  static PickedSopAttachment generateSopAttachmentFromForm({
    required String code,
    required String title,
    required String category,
    required String version,
    required String description,
    required List<ContentSection> sections,
    String companyName = 'PT Cilalu Sentosa',
  }) {
    final safeCode = sanitizeFileName(code, fallback: 'SOP-DOC');
    final fileName = '${safeCode}_${version.replaceAll('.', '_')}.pdf';
    final sopDoc = SOPDocument(
      id: 'sop-preview',
      code: code,
      title: title,
      category: category,
      version: version,
      lastUpdatedText: 'Baru saja diterbitkan',
      description: description,
      contentSections: sections,
    );
    final bytes = generateSopPdfBytes(sopDoc, companyName: companyName);
    return PickedSopAttachment(
      fileName: fileName,
      fileSize: bytes.length,
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  /// Exports or downloads an SOP Document (either its uploaded file or a generated official PDF).
  static Future<ExportResult> exportSopDocument(
    SOPDocument sop, {
    String companyName = 'PT Cilalu Sentosa',
    bool saveFile = true,
  }) async {
    Uint8List bytes;
    String fileName;
    String mimeType;

    if (sop.attachmentBase64 != null && sop.attachmentBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(sop.attachmentBase64!);
        fileName = sanitizeFileName(
          sop.attachmentFileName ?? '${sop.code}_${sop.version}.pdf',
          fallback: '${sop.code}.pdf',
        );
        mimeType = sop.attachmentMimeType ?? inferMimeType(fileName);
      } catch (_) {
        bytes = generateSopPdfBytes(sop, companyName: companyName);
        fileName = sanitizeFileName(
          '${sop.code}_${sop.version}.pdf',
          fallback: 'SOP_Document.pdf',
        );
        mimeType = 'application/pdf';
      }
    } else {
      bytes = generateSopPdfBytes(sop, companyName: companyName);
      fileName = sanitizeFileName(
        sop.attachmentFileName ?? '${sop.code}_${sop.version}.pdf',
        fallback: 'SOP_Document.pdf',
      );
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }
      mimeType = 'application/pdf';
    }

    final preview = buildSopTextSummary(sop, companyName: companyName);
    bool saved = false;
    if (saveFile) {
      saved = await _triggerSaveFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    return ExportResult(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      textPreview: preview,
      savedToDevice: saved,
      savedLocationHint: kIsWeb
          ? 'Folder Unduhan Browser ($fileName)'
          : fileName,
    );
  }

  /// Generates and exports the Performance Report in the requested format (PDF, XLSX/XLS, CSV).
  static Future<ExportResult> exportPerformanceReport({
    required Company company,
    required List<Task> tasks,
    required List<Assignee> employees,
    required List<SOPDocument> sops,
    required ReportExportOptions options,
    bool saveFile = true,
  }) async {
    // Filter tasks by division if specified
    final filteredTasks = options.divisionFilter == 'Semua Divisi'
        ? tasks
        : TaskMetricsCalculator.filterTasks(
            tasks,
            division: options.divisionFilter,
          );

    final filteredEmployees = options.divisionFilter == 'Semua Divisi'
        ? employees
        : employees
              .where(
                (e) => e.division.toLowerCase().contains(
                  options.divisionFilter
                      .replaceAll(' & Tech', '')
                      .toLowerCase(),
                ),
              )
              .toList();

    final metrics = TaskMetricsCalculator.computeMetrics(filteredTasks);
    final divisions = TaskMetricsCalculator.computeDivisionProductivity(
      filteredTasks,
    );
    final rankings = TaskMetricsCalculator.computeEmployeePerformance(
      filteredTasks,
      filteredEmployees.isNotEmpty ? filteredEmployees : employees,
    );

    final cleanCompanyCode = sanitizeFileName(
      company.code,
      fallback: 'COMPANY',
    );
    final cleanPeriod = sanitizeFileName(options.period, fallback: 'Periode');

    final textPreview = buildReportTextSummary(
      company: company,
      metrics: metrics,
      divisions: divisions,
      rankings: rankings,
      tasks: filteredTasks,
      sops: sops,
      options: options,
    );

    late Uint8List bytes;
    late String fileName;
    late String mimeType;

    final fmt = options.format.toLowerCase();
    if (fmt == 'csv') {
      final csvContent = generateReportCsv(
        company: company,
        metrics: metrics,
        divisions: divisions,
        rankings: rankings,
        tasks: filteredTasks,
        sops: sops,
        options: options,
      );
      // Prepend UTF-8 BOM so Microsoft Excel opens UTF-8 CSV properly
      bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(csvContent),
      ]);
      fileName = 'Laporan_Kinerja_${cleanCompanyCode}_$cleanPeriod.csv';
      mimeType = 'text/csv;charset=utf-8';
    } else if (fmt == 'xlsx' || fmt == 'xls') {
      final xmlContent = generateReportExcelXml(
        company: company,
        metrics: metrics,
        divisions: divisions,
        rankings: rankings,
        tasks: filteredTasks,
        sops: sops,
        options: options,
      );
      bytes = Uint8List.fromList(utf8.encode(xmlContent));
      fileName = 'Laporan_Kinerja_${cleanCompanyCode}_$cleanPeriod.xls';
      mimeType = 'application/vnd.ms-excel';
    } else {
      bytes = generateReportPdfBytes(
        company: company,
        metrics: metrics,
        divisions: divisions,
        rankings: rankings,
        tasks: filteredTasks,
        sops: sops,
        options: options,
      );
      fileName = 'Laporan_Kinerja_${cleanCompanyCode}_$cleanPeriod.pdf';
      mimeType = 'application/pdf';
    }

    bool saved = false;
    if (saveFile) {
      saved = await _triggerSaveFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    return ExportResult(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      textPreview: textPreview,
      savedToDevice: saved,
      savedLocationHint: kIsWeb
          ? 'Folder Unduhan Browser ($fileName)'
          : fileName,
    );
  }

  static Future<bool> _triggerSaveFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final safeName = sanitizeFileName(fileName);
      final xfile = XFile.fromData(
        bytes,
        mimeType: mimeType,
        name: safeName,
        path: safeName,
      );
      await xfile.saveTo(safeName);
      return true;
    } catch (e) {
      debugPrint('Save file notice (fallback to in-app preview): $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  TEXT SUMMARY BUILDERS (FOR IN-APP PREVIEW & CLIPBOARD)
  // ─────────────────────────────────────────────────────────────

  static String buildSopTextSummary(
    SOPDocument sop, {
    String companyName = 'PT Cilalu Sentosa',
  }) {
    final sb = StringBuffer();
    sb.writeln('====================================================');
    sb.writeln('DOKUMEN STANDAR OPERASIONAL PROSEDUR (SOP)');
    sb.writeln(companyName.toUpperCase());
    sb.writeln('====================================================');
    sb.writeln('Kode Dokumen : ${sop.code}');
    sb.writeln('Judul SOP    : ${sop.title}');
    sb.writeln('Kategori     : ${sop.category}');
    sb.writeln('Versi        : ${sop.version}');
    sb.writeln(
      'Status Wajib : ${sop.isUrgentMandatory ? "WAJIB PRIORITAS (MANDATORY K3)" : "Standar Operasional"}',
    );
    sb.writeln('Pembaruan    : ${sop.lastUpdatedText}');
    if (sop.duration != null) {
      sb.writeln('Estimasi Baca: ${sop.duration}');
    }
    if (sop.attachmentFileName != null) {
      sb.writeln('Lampiran     : ${sop.attachmentFileName}');
    }
    sb.writeln('----------------------------------------------------');
    if (sop.description != null && sop.description!.isNotEmpty) {
      sb.writeln('RINGKASAN & LINGKUP:');
      sb.writeln(sop.description);
      sb.writeln('----------------------------------------------------');
    }
    sb.writeln('PROSEDUR & INSTRUKSI KERJA:');
    if (sop.contentSections.isEmpty) {
      sb.writeln(
        '1. Lakukan pemeriksaan menyeluruh sebelum menjalankan operasional.',
      );
      sb.writeln(
        '2. Laporkan kendala langsung kepada supervisor penanggung jawab.',
      );
      sb.writeln('3. Ikuti regulasi K3 dan standar ISO yang berlaku.');
    } else {
      for (int i = 0; i < sop.contentSections.length; i++) {
        final sec = sop.contentSections[i];
        sb.writeln('\nBagian ${i + 1}: ${sec.heading}');
        for (final item in sec.items) {
          sb.writeln('  - $item');
        }
      }
    }
    sb.writeln('====================================================');
    return sb.toString();
  }

  static String buildReportTextSummary({
    required Company company,
    required TaskMetrics metrics,
    required List<DivisionMetric> divisions,
    required List<EmployeeRankItem> rankings,
    required List<Task> tasks,
    required List<SOPDocument> sops,
    required ReportExportOptions options,
  }) {
    final sb = StringBuffer();
    sb.writeln('====================================================');
    sb.writeln('LAPORAN EKSEKUTIF KINERJA & OPERASIONAL');
    sb.writeln('${company.name.toUpperCase()} (${company.code})');
    sb.writeln('Periode : ${options.period}');
    sb.writeln('Filter  : ${options.divisionFilter}');
    sb.writeln('====================================================');

    if (options.includeExecutiveSummary) {
      sb.writeln('\n[1] RINGKASAN EKSEKUTIF');
      sb.writeln('- Total Tugas Operasional : ${metrics.total} Tugas');
      sb.writeln(
        '- Tingkat Penyelesaian    : ${metrics.completionRate}% (${metrics.completed} Selesai)',
      );
      sb.writeln('- Sedang Dalam Proses     : ${metrics.inProgress} Tugas');
      sb.writeln('- Belum Dimulai           : ${metrics.notStarted} Tugas');
      sb.writeln('- Menunggu Review Manajer : ${metrics.needsReview} Tugas');
      sb.writeln('- Ketepatan Waktu (SLA)   : ${metrics.onTimeRate}% On-Time');
      sb.writeln('- Rata-rata Progres Tim   : ${metrics.averageProgress}%');
    }

    if (options.includeDivisionProductivity) {
      sb.writeln('\n[2] PRODUKTIVITAS PER DIVISI');
      if (divisions.isEmpty) {
        sb.writeln('- Belum ada data divisi pada filter ini.');
      } else {
        for (final div in divisions) {
          sb.writeln(
            '- ${div.name}: ${div.completionRate}% Selesai (${div.completed}/${div.total} Tugas)',
          );
        }
      }
    }

    if (options.includeEmployeeLeaderboard) {
      sb.writeln('\n[3] REKAP KINERJA & PERINGKAT KARYAWAN');
      if (rankings.isEmpty) {
        sb.writeln('- Belum ada anggota tim terdaftar.');
      } else {
        for (final emp in rankings) {
          sb.writeln(
            '#${emp.rank} ${emp.employee.name} (${emp.employee.division}) — Skor: ${emp.score}/100 | ${emp.completedCount}/${emp.assignedCount} Selesai (${emp.statusBadge})',
          );
        }
      }
    }

    if (options.includeTaskDetails) {
      sb.writeln('\n[4] RINCIAN DAFTAR TUGAS (${tasks.length} Item)');
      for (final t in tasks) {
        sb.writeln(
          '- [${t.status.label.toUpperCase()}] ${t.title} | Divisi: ${t.division} | PIC: ${t.assignee.name} | Progres: ${t.progressPercent}% | Batas: ${t.deadlineLabel}',
        );
      }
    }

    if (options.includeSopCompliance) {
      final verifiedCount = sops.where((s) => s.isReadByMe).length;
      sb.writeln(
        '\n[5] KEPATUHAN STANDAR OPERASIONAL (SOP: $verifiedCount/${sops.length} Terverifikasi)',
      );
      for (final s in sops) {
        sb.writeln(
          '- ${s.code} (${s.version}): ${s.title} [${s.category}] — ${s.readTeamCount ?? "Aktif"}',
        );
      }
    }

    sb.writeln('\n====================================================');
    sb.writeln('Dicetak otomatis oleh Sistem Cilulatask');
    return sb.toString();
  }

  // ─────────────────────────────────────────────────────────────
  //  CSV GENERATOR (WITH FORMULA INJECTION PROTECTION)
  // ─────────────────────────────────────────────────────────────

  /// Prevents CSV Formula Injection (CSV-Inj) by neutralizing leading triggers.
  static String sanitizeCsvCell(String value) {
    String cleaned = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').trim();
    if (cleaned.isNotEmpty &&
        ('=+-@\t\r'.contains(cleaned[0]) || cleaned.startsWith('0x'))) {
      cleaned = "'$cleaned";
    }
    cleaned = cleaned.replaceAll('"', '""');
    return '"$cleaned"';
  }

  static String generateReportCsv({
    required Company company,
    required TaskMetrics metrics,
    required List<DivisionMetric> divisions,
    required List<EmployeeRankItem> rankings,
    required List<Task> tasks,
    required List<SOPDocument> sops,
    required ReportExportOptions options,
  }) {
    final rows = <List<String>>[];

    rows.add(['LAPORAN KINERJA & OPERASIONAL Cilulatask']);
    rows.add(['Perusahaan', company.name, 'Kode ID', company.code]);
    rows.add([
      'Periode Laporan',
      options.period,
      'Filter Divisi',
      options.divisionFilter,
    ]);
    rows.add([]);

    if (options.includeExecutiveSummary) {
      rows.add(['RINGKASAN EKSEKUTIF METRIK']);
      rows.add(['Indikator Kinerja (KPI)', 'Nilai', 'Keterangan']);
      rows.add(['Total Tugas', '${metrics.total}', 'Seluruh tugas terdaftar']);
      rows.add([
        'Tugas Selesai',
        '${metrics.completed}',
        '${metrics.completionRate}% tingkat penyelesaian',
      ]);
      rows.add([
        'Dalam Proses',
        '${metrics.inProgress}',
        'Sedang dikerjakan tim',
      ]);
      rows.add(['Belum Dimulai', '${metrics.notStarted}', 'Menunggu eksekusi']);
      rows.add([
        'Menunggu Review',
        '${metrics.needsReview}',
        'Butuh persetujuan manajer',
      ]);
      rows.add([
        'Ketepatan Waktu (SLA)',
        '${metrics.onTimeRate}%',
        '${metrics.lateRate}% melewati target',
      ]);
      rows.add([
        'Rata-rata Progres',
        '${metrics.averageProgress}%',
        'Akumulasi progres seluruh tugas',
      ]);
      rows.add([]);
    }

    if (options.includeDivisionProductivity) {
      rows.add(['PRODUKTIVITAS PER DIVISI']);
      rows.add([
        'Nama Divisi',
        'Tugas Selesai',
        'Total Tugas',
        'Rasio Penyelesaian (%)',
      ]);
      for (final d in divisions) {
        rows.add([
          d.name,
          '${d.completed}',
          '${d.total}',
          '${d.completionRate}%',
        ]);
      }
      rows.add([]);
    }

    if (options.includeEmployeeLeaderboard) {
      rows.add(['REKAP KINERJA & PERINGKAT KARYAWAN']);
      rows.add([
        'Peringkat',
        'Nama Karyawan',
        'Divisi',
        'Jabatan',
        'Tugas Selesai',
        'Total Penugasan',
        'Skor Kinerja',
        'Predikat',
      ]);
      for (final emp in rankings) {
        rows.add([
          '#${emp.rank}',
          emp.employee.name,
          emp.employee.division,
          emp.employee.role,
          '${emp.completedCount}',
          '${emp.assignedCount}',
          '${emp.score}/100',
          emp.statusBadge,
        ]);
      }
      rows.add([]);
    }

    if (options.includeTaskDetails) {
      rows.add(['DAFTAR RINCIAN TUGAS OPERASIONAL']);
      rows.add([
        'ID Tugas',
        'Judul Tugas',
        'Divisi',
        'Penanggung Jawab',
        'Prioritas',
        'Status',
        'Progres (%)',
        'Batas Waktu',
      ]);
      for (final t in tasks) {
        rows.add([
          t.id,
          t.title,
          t.division,
          t.assignee.name,
          t.priority.label,
          t.status.label,
          '${t.progressPercent}%',
          t.deadlineLabel,
        ]);
      }
      rows.add([]);
    }

    if (options.includeSopCompliance) {
      rows.add(['DAFTAR KEPATUHAN DOKUMEN SOP']);
      rows.add([
        'Kode SOP',
        'Judul Dokumen',
        'Kategori',
        'Versi',
        'Status Wajib',
        'Progres Baca Tim',
        'Status Baca Saya',
      ]);
      for (final s in sops) {
        rows.add([
          s.code,
          s.title,
          s.category,
          s.version,
          s.isUrgentMandatory ? 'Wajib Prioritas' : 'Standar',
          s.readTeamCount ?? '-',
          s.isReadByMe ? 'Sudah Diverifikasi' : 'Belum Dibaca',
        ]);
      }
    }

    return rows.map((r) => r.map(sanitizeCsvCell).join(',')).join('\r\n');
  }

  // ─────────────────────────────────────────────────────────────
  //  EXCEL SPREADSHEETML (.XLS / .XLSX WORKBOOK) GENERATOR
  // ─────────────────────────────────────────────────────────────

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String generateReportExcelXml({
    required Company company,
    required TaskMetrics metrics,
    required List<DivisionMetric> divisions,
    required List<EmployeeRankItem> rankings,
    required List<Task> tasks,
    required List<SOPDocument> sops,
    required ReportExportOptions options,
  }) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<?mso-application progid="Excel.Sheet"?>');
    sb.writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    );
    sb.writeln('<Styles>');
    sb.writeln(
      '<Style ss:ID="Title"><Font ss:Bold="1" ss:Size="14" ss:Color="#00236F"/></Style>',
    );
    sb.writeln(
      '<Style ss:ID="Header"><Font ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#0051D5" ss:Pattern="Solid"/></Style>',
    );
    sb.writeln('<Style ss:ID="Bold"><Font ss:Bold="1"/></Style>');
    sb.writeln('</Styles>');

    void writeRow(List<String> cells, {String? styleId}) {
      sb.write('<Row>');
      for (final c in cells) {
        final safe = _escapeXml(c);
        if (styleId != null) {
          sb.write(
            '<Cell ss:StyleID="$styleId"><Data ss:Type="String">$safe</Data></Cell>',
          );
        } else {
          sb.write('<Cell><Data ss:Type="String">$safe</Data></Cell>');
        }
      }
      sb.writeln('</Row>');
    }

    // Sheet 1: Ringkasan & Divisi
    sb.writeln('<Worksheet ss:Name="Ringkasan Kinerja"><Table>');
    writeRow([
      'LAPORAN EKSEKUTIF KINERJA - ${company.name} (${company.code})',
    ], styleId: 'Title');
    writeRow([
      'Periode: ${options.period}',
      'Filter: ${options.divisionFilter}',
    ], styleId: 'Bold');
    writeRow([]);

    if (options.includeExecutiveSummary) {
      writeRow([
        'Indikator Kinerja Utama (KPI)',
        'Nilai',
        'Keterangan',
      ], styleId: 'Header');
      writeRow(['Total Tugas Operasional', '${metrics.total}', 'Tugas']);
      writeRow([
        'Tugas Selesai',
        '${metrics.completed}',
        '${metrics.completionRate}% dari total tugas',
      ]);
      writeRow([
        'Tugas Dalam Proses',
        '${metrics.inProgress}',
        'Sedang berjalan',
      ]);
      writeRow(['Tugas Belum Dimulai', '${metrics.notStarted}', 'Menunggu']);
      writeRow(['Menunggu Review Manajer', '${metrics.needsReview}', 'Review']);
      writeRow([
        'Ketepatan Waktu (SLA)',
        '${metrics.onTimeRate}%',
        '${metrics.lateRate}% Terlambat',
      ]);
      writeRow([
        'Rata-rata Progres',
        '${metrics.averageProgress}%',
        'Progres rata-rata',
      ]);
      writeRow([]);
    }

    if (options.includeDivisionProductivity) {
      writeRow([
        'Divisi',
        'Tugas Selesai',
        'Total Tugas',
        'Tingkat Penyelesaian (%)',
      ], styleId: 'Header');
      for (final d in divisions) {
        writeRow([
          d.name,
          '${d.completed}',
          '${d.total}',
          '${d.completionRate}%',
        ]);
      }
    }
    sb.writeln('</Table></Worksheet>');

    // Sheet 2: Kinerja Karyawan
    if (options.includeEmployeeLeaderboard) {
      sb.writeln('<Worksheet ss:Name="Kinerja Karyawan"><Table>');
      writeRow([
        'Peringkat',
        'Nama Karyawan',
        'Divisi',
        'Jabatan',
        'Selesai',
        'Total Tugas',
        'Skor (/100)',
        'Status Kinerja',
      ], styleId: 'Header');
      for (final emp in rankings) {
        writeRow([
          '#${emp.rank}',
          emp.employee.name,
          emp.employee.division,
          emp.employee.role,
          '${emp.completedCount}',
          '${emp.assignedCount}',
          '${emp.score}',
          emp.statusBadge,
        ]);
      }
      sb.writeln('</Table></Worksheet>');
    }

    // Sheet 3: Rincian Tugas & SOP
    if (options.includeTaskDetails || options.includeSopCompliance) {
      sb.writeln('<Worksheet ss:Name="Rincian Tugas dan SOP"><Table>');
      if (options.includeTaskDetails) {
        writeRow([
          'ID Tugas',
          'Judul Tugas',
          'Divisi',
          'Penanggung Jawab',
          'Prioritas',
          'Status',
          'Progres',
          'Batas Waktu',
        ], styleId: 'Header');
        for (final t in tasks) {
          writeRow([
            t.id,
            t.title,
            t.division,
            t.assignee.name,
            t.priority.label,
            t.status.label,
            '${t.progressPercent}%',
            t.deadlineLabel,
          ]);
        }
        writeRow([]);
      }
      if (options.includeSopCompliance) {
        writeRow([
          'Kode SOP',
          'Judul Dokumen SOP',
          'Kategori',
          'Versi',
          'Kepatuhan Tim',
          'Status Verifikasi',
        ], styleId: 'Header');
        for (final s in sops) {
          writeRow([
            s.code,
            s.title,
            s.category,
            s.version,
            s.readTeamCount ?? '-',
            s.isReadByMe ? 'Terverifikasi' : 'Belum Dibaca',
          ]);
        }
      }
      sb.writeln('</Table></Worksheet>');
    }

    sb.writeln('</Workbook>');
    return sb.toString();
  }

  // ─────────────────────────────────────────────────────────────
  //  NATIVE PDF-1.4 BINARY GENERATOR (ZERO EXTERNAL DEPENDENCIES)
  // ─────────────────────────────────────────────────────────────

  static String _escapePdfText(String text) {
    // Convert non-ASCII characters to safe ASCII equivalents for Type1 Helvetica
    final clean = text
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    return clean;
  }

  static List<String> _wrapText(String text, int maxChars) {
    if (text.length <= maxChars) return [text];
    final words = text.split(' ');
    final lines = <String>[];
    var current = StringBuffer();
    for (final word in words) {
      if (current.isEmpty) {
        current.write(word);
      } else if (current.length + 1 + word.length <= maxChars) {
        current.write(' $word');
      } else {
        lines.add(current.toString());
        current = StringBuffer(word);
      }
    }
    if (current.isNotEmpty) lines.add(current.toString());
    return lines;
  }

  /// Generates a standards-compliant multi-page PDF-1.4 document from structured lines.
  static Uint8List _buildPdfFromLines({
    required String title,
    required String subtitle,
    required List<String> bodyLines,
  }) {
    const int linesPerPage = 42;
    final wrappedLines = <String>[];
    for (final rawLine in bodyLines) {
      if (rawLine.trim().isEmpty) {
        wrappedLines.add('');
      } else {
        wrappedLines.addAll(_wrapText(rawLine, 82));
      }
    }

    final pages = <List<String>>[];
    if (wrappedLines.isEmpty) {
      pages.add(['Tidak ada data.']);
    } else {
      for (int i = 0; i < wrappedLines.length; i += linesPerPage) {
        final end = (i + linesPerPage < wrappedLines.length)
            ? i + linesPerPage
            : wrappedLines.length;
        pages.add(wrappedLines.sublist(i, end));
      }
    }

    final objects = <String>[];
    // Object 1: Catalog
    objects.add('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj');

    // Object 2: Pages (placeholder, filled after page objects created)
    objects.add('');

    // Object 3: Font Helvetica Regular
    objects.add(
      '3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj',
    );
    // Object 4: Font Helvetica Bold
    objects.add(
      '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj',
    );

    final pageObjIds = <int>[];
    int nextObjId = 5;

    for (int p = 0; p < pages.length; p++) {
      final pageLines = pages[p];
      final contentSb = StringBuffer();

      // Header Banner Rectangle (Navy Blue #00236F -> 0.0, 0.14, 0.44)
      contentSb.writeln('0.0 0.14 0.44 rg');
      contentSb.writeln('40 765 515 48 re f');

      // Header Text (White)
      contentSb.writeln('BT');
      contentSb.writeln('1 1 1 rg');
      contentSb.writeln('/F2 13 Tf');
      contentSb.writeln('52 792 Td');
      contentSb.writeln('(${_escapePdfText(title)}) Tj');
      contentSb.writeln('/F1 9 Tf');
      contentSb.writeln('0 -16 Td');
      contentSb.writeln(
        '(${_escapePdfText(subtitle)}  |  Halaman ${p + 1} dari ${pages.length}) Tj',
      );
      contentSb.writeln('ET');

      // Body Text (Dark Slate)
      contentSb.writeln('BT');
      contentSb.writeln('0.05 0.11 0.19 rg');
      contentSb.writeln('44 740 Td');

      for (final line in pageLines) {
        final isSectionHeader =
            line.startsWith('[') ||
            line.startsWith('Bagian ') ||
            line.startsWith('===');
        if (isSectionHeader) {
          contentSb.writeln('/F2 10 Tf');
        } else {
          contentSb.writeln('/F1 9.5 Tf');
        }
        contentSb.writeln('(${_escapePdfText(line)}) Tj');
        contentSb.writeln('0 -15.5 Td');
      }
      contentSb.writeln('ET');

      // Footer line
      contentSb.writeln('0.85 0.88 0.92 RG');
      contentSb.writeln('40 42 m 555 42 l S');
      contentSb.writeln('BT');
      contentSb.writeln('0.45 0.5 0.58 rg');
      contentSb.writeln('/F1 8 Tf');
      contentSb.writeln('44 28 Td');
      contentSb.writeln(
        '(Dokumen Resmi Cilulatask - Sistem Manajemen Tugas & Standar Operasional) Tj',
      );
      contentSb.writeln('ET');

      final streamData = contentSb.toString();
      final contentObjId = nextObjId++;
      final pageObjId = nextObjId++;
      pageObjIds.add(pageObjId);

      objects.add(
        '$contentObjId 0 obj\n<< /Length ${streamData.length} >>\nstream\n$streamData\nendstream\nendobj',
      );
      objects.add(
        '$pageObjId 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
        '/Contents $contentObjId 0 R >>\nendobj',
      );
    }

    final kidsStr = pageObjIds.map((id) => '$id 0 R').join(' ');
    objects[1] =
        '2 0 obj\n<< /Type /Pages /Kids [$kidsStr] /Count ${pageObjIds.length} >>\nendobj';

    final pdfSb = StringBuffer();
    pdfSb.writeln('%PDF-1.4');
    final offsets = <int>[];

    for (final obj in objects) {
      offsets.add(pdfSb.length);
      pdfSb.writeln(obj);
    }

    final xrefOffset = pdfSb.length;
    pdfSb.writeln('xref');
    pdfSb.writeln('0 ${objects.length + 1}');
    pdfSb.writeln('0000000000 65535 f ');
    for (final off in offsets) {
      pdfSb.writeln('${off.toString().padLeft(10, '0')} 00000 n ');
    }
    pdfSb.writeln('trailer');
    pdfSb.writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>');
    pdfSb.writeln('startxref');
    pdfSb.writeln('$xrefOffset');
    pdfSb.write('%%EOF');

    return Uint8List.fromList(latin1.encode(pdfSb.toString()));
  }

  static Uint8List generateSopPdfBytes(
    SOPDocument sop, {
    String companyName = 'PT Cilalu Sentosa',
  }) {
    final summary = buildSopTextSummary(sop, companyName: companyName);
    return _buildPdfFromLines(
      title: 'DOKUMEN SOP: ${sop.code} (${sop.version})',
      subtitle: '$companyName - ${sop.category}',
      bodyLines: summary.split('\n'),
    );
  }

  static Uint8List generateReportPdfBytes({
    required Company company,
    required TaskMetrics metrics,
    required List<DivisionMetric> divisions,
    required List<EmployeeRankItem> rankings,
    required List<Task> tasks,
    required List<SOPDocument> sops,
    required ReportExportOptions options,
  }) {
    final summary = buildReportTextSummary(
      company: company,
      metrics: metrics,
      divisions: divisions,
      rankings: rankings,
      tasks: tasks,
      sops: sops,
      options: options,
    );
    return _buildPdfFromLines(
      title: 'LAPORAN KINERJA EKSEKUTIF - ${company.name}',
      subtitle:
          'Periode: ${options.period} | Divisi: ${options.divisionFilter}',
      bodyLines: summary.split('\n'),
    );
  }
}
