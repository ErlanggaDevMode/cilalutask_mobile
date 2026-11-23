import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/report_and_sop_exporter.dart';
import '../../data/mock_data.dart';
import '../../models/company.dart';
import '../../state/app_state_scope.dart';

class ExportReportBottomSheet extends StatefulWidget {
  final String? period;
  final String? initialDivisionFilter;

  const ExportReportBottomSheet({
    super.key,
    this.period,
    this.initialDivisionFilter,
  });

  static Future<void> show(
    BuildContext context, {
    String? period,
    String? initialDivisionFilter,
  }) {
    final callerState = AppStateScope.maybeOf(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        final sheet = ExportReportBottomSheet(
          period: period,
          initialDivisionFilter: initialDivisionFilter,
        );
        if (callerState != null &&
            AppStateScope.maybeOf(modalContext) == null) {
          return AppStateScope(controller: callerState, child: sheet);
        }
        return sheet;
      },
    );
  }

  @override
  State<ExportReportBottomSheet> createState() =>
      _ExportReportBottomSheetState();
}

class _ExportReportBottomSheetState extends State<ExportReportBottomSheet> {
  String _selectedFormat = 'pdf';
  late String _divisionFilter;
  bool _includeExecutiveSummary = true;
  bool _includeDivisionProductivity = true;
  bool _includeEmployeeLeaderboard = true;
  bool _includeTaskDetails = true;
  bool _includeSopCompliance = true;

  bool _isExporting = false;
  bool _showPreview = false;
  ExportResult? _lastExportResult;

  final List<String> _divisions = [
    'Semua Divisi',
    'Operasional',
    'IT & Tech',
    'Pemasaran',
    'Finance & Akuntansi',
  ];

  @override
  void initState() {
    super.initState();
    final initDiv = widget.initialDivisionFilter ?? 'Semua Divisi';
    _divisionFilter = _divisions.contains(initDiv) ? initDiv : 'Semua Divisi';
  }

  ReportExportOptions get _currentOptions => ReportExportOptions(
    format: _selectedFormat,
    period: widget.period ?? 'Periode Berjalan',
    divisionFilter: _divisionFilter,
    includeExecutiveSummary: _includeExecutiveSummary,
    includeDivisionProductivity: _includeDivisionProductivity,
    includeEmployeeLeaderboard: _includeEmployeeLeaderboard,
    includeTaskDetails: _includeTaskDetails,
    includeSopCompliance: _includeSopCompliance,
  );

  static final Company _fallbackCompany = Company(
    id: 'comp-default',
    name: 'PT Cilalu Operasional',
    code: 'CILALU-88',
    adminName: 'Sarah Pratama',
    adminEmail: 'sarah.pratama@cilulataks.id',
    createdAt: DateTime(2025, 1, 1),
  );

  Future<void> _generatePreviewOnly() async {
    final appState = AppStateScope.maybeOf(context);
    final result = await ReportAndSopExporter.exportPerformanceReport(
      company: appState?.currentCompany ?? _fallbackCompany,
      tasks: appState?.tasks ?? kInitialTasks,
      employees: appState?.employees ?? kEmployees,
      sops: appState?.sops ?? kInitialSops,
      options: _currentOptions,
      saveFile: false,
    );
    if (mounted) {
      setState(() {
        _lastExportResult = result;
        _showPreview = true;
      });
    }
  }

  Future<void> _export() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final appState = AppStateScope.maybeOf(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      final navigator = Navigator.of(context);

      final result = await ReportAndSopExporter.exportPerformanceReport(
        company: appState?.currentCompany ?? _fallbackCompany,
        tasks: appState?.tasks ?? kInitialTasks,
        employees: appState?.employees ?? kEmployees,
        sops: appState?.sops ?? kInitialSops,
        options: _currentOptions,
        saveFile: true,
      );

      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _lastExportResult = result;
      });

      navigator.pop();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'Laporan kinerja berhasil diekspor (${_selectedFormat.toUpperCase()}) — ${result.fileName} (${result.formattedSize})!',
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Salin Isi',
            textColor: const Color(0xFF6EE7B7),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.textPreview));
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor laporan: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ekspor Laporan Kinerja',
                      style: TextStyle(
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
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),

              Text(
                'Unduh rekapitulasi data tingkat penyelesaian tugas, SLA divisi, dan skor karyawan untuk ${widget.period ?? 'periode berjalan'}.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // 1. Format Berkas
              const Text(
                'Pilih Format Berkas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFormatCard(
                    'pdf',
                    'PDF Eksekutif',
                    Icons.picture_as_pdf_rounded,
                    AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  _buildFormatCard(
                    'xlsx',
                    'Excel XLSX',
                    Icons.table_chart_rounded,
                    AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildFormatCard(
                    'csv',
                    'CSV Data',
                    Icons.description_outlined,
                    AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Filter Divisi
              const Text(
                'Cakupan Divisi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _divisionFilter,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                items: _divisions
                    .map(
                      (div) => DropdownMenuItem(value: div, child: Text(div)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _divisionFilter = val;
                      _showPreview = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // 3. Komponen Laporan
              const Text(
                'Komponen Data yang Disertakan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildSectionChip(
                    label: 'Ringkasan & SLA',
                    selected: _includeExecutiveSummary,
                    onTap: () => setState(
                      () =>
                          _includeExecutiveSummary = !_includeExecutiveSummary,
                    ),
                  ),
                  _buildSectionChip(
                    label: 'Produktivitas Divisi',
                    selected: _includeDivisionProductivity,
                    onTap: () => setState(
                      () => _includeDivisionProductivity =
                          !_includeDivisionProductivity,
                    ),
                  ),
                  _buildSectionChip(
                    label: 'Leaderboard Karyawan',
                    selected: _includeEmployeeLeaderboard,
                    onTap: () => setState(
                      () => _includeEmployeeLeaderboard =
                          !_includeEmployeeLeaderboard,
                    ),
                  ),
                  _buildSectionChip(
                    label: 'Rincian Tugas',
                    selected: _includeTaskDetails,
                    onTap: () => setState(
                      () => _includeTaskDetails = !_includeTaskDetails,
                    ),
                  ),
                  _buildSectionChip(
                    label: 'Kepatuhan SOP',
                    selected: _includeSopCompliance,
                    onTap: () => setState(
                      () => _includeSopCompliance = !_includeSopCompliance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Preview Toggle / Box
              if (_showPreview && _lastExportResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Pratinjau: ${_lastExportResult!.fileName} (${_lastExportResult!.formattedSize})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: _lastExportResult!.textPreview,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Isi laporan berhasil disalin ke papan klip!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 13),
                            label: const Text(
                              'Salin',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 130),
                        child: SingleChildScrollView(
                          child: Text(
                            _lastExportResult!.textPreview,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _generatePreviewOnly,
                    icon: const Icon(Icons.visibility_outlined, size: 15),
                    label: const Text(
                      'Lihat Pratinjau Isi Laporan',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _export,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 16),
                      label: Text(
                        _isExporting ? 'Mengunduh...' : 'Unduh Berkas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 14,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard(
    String id,
    String label,
    IconData icon,
    Color iconColor,
  ) {
    final isSelected = _selectedFormat == id;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedFormat = id;
          _showPreview = false;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : iconColor,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
