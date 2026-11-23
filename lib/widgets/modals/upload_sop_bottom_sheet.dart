import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/report_and_sop_exporter.dart';
import '../../models/sop.dart';
import '../../state/app_state_scope.dart';

class UploadSopBottomSheet extends StatefulWidget {
  final void Function(SOPDocument newSop) onAddSop;
  final SOPDocument? initialSop;

  const UploadSopBottomSheet({
    super.key,
    required this.onAddSop,
    this.initialSop,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(SOPDocument newSop) onAddSop,
    SOPDocument? initialSop,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: UploadSopBottomSheet(onAddSop: onAddSop, initialSop: initialSop),
      ),
    );
  }

  @override
  State<UploadSopBottomSheet> createState() => _UploadSopBottomSheetState();
}

class _UploadSopBottomSheetState extends State<UploadSopBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late final TextEditingController _versionController;
  late final TextEditingController _sectionHeadingController;
  final List<TextEditingController> _stepControllers = [];

  String _category = 'Operasional Gudang';
  String _duration = '5 mnt baca';
  bool _isUrgentMandatory = false;
  bool _isSubmitting = false;
  bool _isPickingFile = false;
  PickedSopAttachment? _pickedAttachment;
  String? _fileError;

  final List<String> _categories = [
    'Operasional Gudang',
    'Keamanan Kerja (K3)',
    'Customer Service',
    'Finance & HRD',
    'IT Department',
  ];

  final List<String> _durations = [
    '3 mnt baca',
    '5 mnt baca',
    '10 mnt baca',
    '15 mnt baca',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.initialSop;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _codeController = TextEditingController(
      text: existing?.code ?? 'SOP-2025-OPS-05',
    );
    _descController = TextEditingController(text: existing?.description ?? '');
    _versionController = TextEditingController(
      text: existing != null ? _incrementVersion(existing.version) : 'v1.0',
    );

    if (existing != null && _categories.contains(existing.category)) {
      _category = existing.category;
    }
    if (existing?.duration != null && _durations.contains(existing!.duration)) {
      _duration = existing.duration!;
    }
    _isUrgentMandatory = existing?.isUrgentMandatory ?? false;

    final firstSection =
        (existing != null && existing.contentSections.isNotEmpty)
        ? existing.contentSections.first
        : null;
    _sectionHeadingController = TextEditingController(
      text: firstSection?.heading ?? 'Prosedur Pelaksanaan Standar',
    );

    if (firstSection != null && firstSection.items.isNotEmpty) {
      for (final item in firstSection.items) {
        _stepControllers.add(TextEditingController(text: item));
      }
    } else {
      _stepControllers.add(
        TextEditingController(
          text: 'Melakukan pemeriksaan kesiapan operasional sesuai standar ISO dan K3.',
        ),
      );
      _stepControllers.add(
        TextEditingController(
          text: 'Mendokumentasikan dan melaporkan hasil pelaksanaan kepada supervisor.',
        ),
      );
    }
  }

  String _incrementVersion(String currentVersion) {
    final cleaned = currentVersion.toLowerCase().replaceAll('v', '').trim();
    final parts = cleaned.split('.');
    if (parts.length >= 2) {
      final major = int.tryParse(parts[0]) ?? 1;
      final minor = (int.tryParse(parts[1]) ?? 0) + 1;
      return 'v$major.$minor';
    }
    return 'v1.1';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _versionController.dispose();
    _sectionHeadingController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFileFromDevice() async {
    setState(() {
      _isPickingFile = true;
      _fileError = null;
    });
    try {
      final picked = await ReportAndSopExporter.pickSopDocumentFile();
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _pickedAttachment = picked;
          if (_titleController.text.trim().isEmpty) {
            final nameWithoutExt = picked.fileName.replaceAll(
              RegExp(r'\.[a-zA-Z0-9]+$'),
              '',
            );
            _titleController.text = nameWithoutExt.replaceAll('_', ' ');
          }
          if (picked.extractedText != null &&
              picked.extractedText!.isNotEmpty) {
            final lines = picked.extractedText!
                .split(RegExp(r'\r?\n'))
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();
            if (_descController.text.trim().isEmpty && lines.isNotEmpty) {
              _descController.text = lines.first;
            }
            if (lines.length > 1) {
              for (final c in _stepControllers) {
                c.dispose();
              }
              _stepControllers.clear();
              for (final line in lines.skip(1).take(8)) {
                _stepControllers.add(
                  TextEditingController(
                    text: line.replaceFirst(RegExp(r'^[-*•0-9.)\s]+'), ''),
                  ),
                );
              }
            }
          }
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _fileError = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _fileError = 'Gagal memuat berkas dari perangkat. Anda dapat menggunakan tombol "Buat PDF Otomatis".',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  void _generateAutoPdfAttachment() {
    final appState = AppStateScope.maybeOf(context);
    final companyName = appState?.currentCompany.name ?? 'PT Cilalu Sentosa';
    final code = _codeController.text.trim().isNotEmpty
        ? _codeController.text.trim()
        : 'SOP-2025-OPS-05';
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Prosedur Operasional Standar';
    final version = _versionController.text.trim().isNotEmpty
        ? _versionController.text.trim()
        : 'v1.0';
    final desc = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : 'Pedoman operasional standar terbitan internal.';

    final stepItems = _stepControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final generated = ReportAndSopExporter.generateSopAttachmentFromForm(
      code: code,
      title: title,
      category: _category,
      version: version,
      description: desc,
      sections: [
        ContentSection(
          heading: _sectionHeadingController.text.trim().isNotEmpty
              ? _sectionHeadingController.text.trim()
              : 'Prosedur Pelaksanaan Standar',
          items: stepItems.isNotEmpty
              ? stepItems
              : ['Melaksanakan prosedur sesuai standar K3 dan ISO.'],
        ),
      ],
      companyName: companyName,
    );

    setState(() {
      _pickedAttachment = generated;
      _fileError = null;
    });
  }

  void _addStepField() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStepField(int index) {
    if (_stepControllers.length <= 1) return;
    setState(() {
      final ctrl = _stepControllers.removeAt(index);
      ctrl.dispose();
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final appState = AppStateScope.maybeOf(context);
        final totalEmployees =
            (appState != null && appState.employees.isNotEmpty)
            ? appState.employees.length
            : (appState?.isBlankMode == true ? 1 : 6);
        final companyName =
            appState?.currentCompany.name ?? 'PT Cilalu Sentosa';

        final now = DateTime.now().millisecondsSinceEpoch;
        final code = _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : 'SOP-2025-OPS-${now.toString().substring(8)}';
        final title = _titleController.text.trim();
        final version = _versionController.text.trim().isNotEmpty
            ? _versionController.text.trim()
            : 'v1.0';
        final desc = _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : 'Pedoman operasional standar terbitan baru.';

        final stepItems = _stepControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (stepItems.isEmpty) {
          stepItems.add(desc);
          stepItems.add(
            'Melaporkan penyelesaian tugas kepada supervisor terkait.',
          );
        }

        final sections = [
          ContentSection(
            heading: _sectionHeadingController.text.trim().isNotEmpty
                ? _sectionHeadingController.text.trim()
                : 'Prosedur Pelaksanaan Standar',
            items: stepItems,
          ),
        ];

        // Ensure every published SOP has a downloadable PDF/document attachment
        final attachment =
            _pickedAttachment ??
            ReportAndSopExporter.generateSopAttachmentFromForm(
              code: code,
              title: title,
              category: _category,
              version: version,
              description: desc,
              sections: sections,
              companyName: companyName,
            );

        final existing = widget.initialSop;
        final newDoc = SOPDocument(
          id: existing?.id ?? 'sop-$now',
          code: code,
          title: title,
          category: _category,
          version: version,
          description: desc,
          lastUpdatedText: existing != null
              ? 'Revisi baru saja diunggah'
              : 'Baru saja diunggah',
          fileInfo: '${attachment.fileName} (${attachment.formattedSize})',
          checkPoints: '${stepItems.length} Poin Cek',
          duration: _duration,
          isUrgentMandatory: _isUrgentMandatory,
          isNewUpdate: true,
          isBookmarked: existing?.isBookmarked ?? false,
          readProgressPercent: existing?.readProgressPercent ?? 0,
          readTeamCount: existing?.readTeamCount ?? '0/$totalEmployees Tim',
          complianceRatioText:
              existing?.complianceRatioText ?? '0% Karyawan terverifikasi',
          contentSections: sections,
          isReadByMe: false,
          attachmentFileName: attachment.fileName,
          attachmentFileSize: attachment.fileSize,
          attachmentMimeType: attachment.mimeType,
          attachmentBase64: attachment.safeBase64ForStorage,
        );

        widget.onAddSop(newDoc);
        if (mounted) Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRevision = widget.initialSop != null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.upload_file_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRevision
                        ? 'Unggah Revisi Dokumen SOP'
                        : 'Unggah SOP Baru',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Form
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Lampiran Berkas SOP (PDF / DOC / TXT)
                  const Text(
                    'Lampiran Berkas Dokumen (PDF / DOC / TXT)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _pickedAttachment != null
                          ? AppColors.primaryLight.withValues(alpha: 0.45)
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pickedAttachment != null
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_pickedAttachment != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedAttachment!.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Ukuran: ${_pickedAttachment!.formattedSize} • Siap diterbitkan & diunduh tim',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.successDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                tooltip: 'Hapus Lampiran',
                                onPressed: () =>
                                    setState(() => _pickedAttachment = null),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ] else ...[
                          const Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Unggah berkas PDF/DOCX/TXT dari perangkat atau buat PDF otomatis dari instruksi di bawah.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isPickingFile
                                    ? null
                                    : _pickFileFromDevice,
                                icon: _isPickingFile
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.folder_open_rounded,
                                        size: 15,
                                      ),
                                label: const Text(
                                  'Pilih Berkas',
                                  style: TextStyle(fontSize: 11),
                                ),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primaryBorder,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _generateAutoPdfAttachment,
                                icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Buat PDF Otomatis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_fileError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _fileError!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Title
                  const Text(
                    'Judul Dokumen SOP *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Prosedur Pengamanan Data Nasabah',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Judul SOP wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // 3. Kode & Versi
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kode Dokumen',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _codeController,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Versi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _versionController,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Kategori & Estimasi Baca
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori Departemen',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _category,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              items: _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _category = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimasi Baca',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _duration,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              items: _durations
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _duration = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Deskripsi ringkas
                  const Text(
                    'Deskripsi Singkat / Lingkup',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ringkasan panduan dan sasaran pelaksanaan...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Langkah-langkah / Poin Prosedur SOP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Poin Instruksi / Langkah Prosedur',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addStepField,
                        icon: const Icon(Icons.add_circle_outline, size: 15),
                        label: const Text(
                          'Tambah Poin',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  ..._stepControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: ctrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Langkah kerja ke-${idx + 1}...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          if (_stepControllers.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => _removeStepField(idx),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  // 7. Urgent mandatory switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wajib Dibaca & Dikonfirmasi Segera',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                ),
                              ),
                              Text(
                                'Akan memunculkan banner alert prioritas di aplikasi.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isUrgentMandatory,
                          activeColor: AppColors.danger,
                          onChanged: (val) =>
                              setState(() => _isUrgentMandatory = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isRevision
                                  ? 'Simpan & Terbitkan Revisi SOP'
                                  : 'Terbitkan Dokumen SOP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
