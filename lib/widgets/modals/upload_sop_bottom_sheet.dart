import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/sop.dart';

class UploadSopBottomSheet extends StatefulWidget {
  final void Function(SOPDocument newSop) onAddSop;

  const UploadSopBottomSheet({super.key, required this.onAddSop});

  static Future<void> show(
    BuildContext context, {
    required void Function(SOPDocument newSop) onAddSop,
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
        child: UploadSopBottomSheet(onAddSop: onAddSop),
      ),
    );
  }

  @override
  State<UploadSopBottomSheet> createState() => _UploadSopBottomSheetState();
}

class _UploadSopBottomSheetState extends State<UploadSopBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController(text: 'SOP-2025-OPS-05');
  final _descController = TextEditingController();
  final _versionController = TextEditingController(text: 'v1.0');

  String _category = 'Operasional Gudang';
  bool _isUrgentMandatory = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Operasional Gudang',
    'Keamanan Kerja (K3)',
    'Customer Service',
    'Finance & HRD',
    'IT Department',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        final newDoc = SOPDocument(
          id: 'sop-$now',
          code: _codeController.text.trim().isNotEmpty
              ? _codeController.text.trim()
              : 'SOP-2025-OPS-${now.toString().substring(8)}',
          title: _titleController.text.trim(),
          category: _category,
          version: _versionController.text.trim().isNotEmpty
              ? _versionController.text.trim()
              : 'v1.0',
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : 'Pedoman operasional standar terbitan baru.',
          lastUpdatedText: 'Baru saja diunggah',
          fileInfo: 'Dokumen Digital Terbitan Internal',
          isUrgentMandatory: _isUrgentMandatory,
          isNewUpdate: true,
          readProgressPercent: 0,
          readTeamCount: '0/34 Tim',
          complianceRatioText: '0% Karyawan terverifikasi',
          contentSections: [
            ContentSection(
              heading: 'Prosedur Pelaksanaan Standar',
              items: [
                _descController.text.trim().isNotEmpty
                    ? _descController.text.trim()
                    : 'Melakukan instruksi operasional sesuai standar ISO dan K3.',
                'Melaporkan penyelesaian tugas kepada supervisor terkait.',
              ],
            ),
          ],
          isReadByMe: true,
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                const Text(
                  'Unggah SOP Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
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
                  // Title
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

                  // Kode & Versi
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

                  // Kategori
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Deskripsi ringkas
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
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ringkasan panduan dan sasaran pelaksanaan...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Urgent mandatory switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight.withOpacity(0.4),
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
                  const SizedBox(height: 24),

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
                          : const Text(
                              'Terbitkan Dokumen SOP',
                              style: TextStyle(
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
