import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/modals/sop_detail_bottom_sheet.dart';
import '../../widgets/modals/upload_sop_bottom_sheet.dart';
import '../../widgets/modals/sop_filter_bottom_sheet.dart';

class SopScreen extends StatefulWidget {
  const SopScreen({super.key});

  @override
  State<SopScreen> createState() => _SopScreenState();
}

class _SopScreenState extends State<SopScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _sortOrder = 'Versi Terbaru';
  bool _mandatoryOnly = false;
  bool _bookmarkOnly = false;
  bool _unreadOnly = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  final List<String> _categories = [
    'Semua',
    'Operasional Gudang',
    'Keamanan Kerja (K3)',
    'Customer Service',
    'Finance & HRD',
    'IT Department',
  ];

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = val);
      }
    });
  }

  void _resetSopFilters() {
    _searchDebounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'Semua';
      _sortOrder = 'Versi Terbaru';
      _mandatoryOnly = false;
      _bookmarkOnly = false;
      _unreadOnly = false;
    });
  }

  bool get _hasActiveSopFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != 'Semua' ||
      _sortOrder != 'Versi Terbaru' ||
      _mandatoryOnly ||
      _bookmarkOnly ||
      _unreadOnly;

  IconData _getCategoryIcon(String category) {
    if (category.contains('Customer Service')) {
      return Icons.headset_mic_rounded;
    }
    if (category.contains('Finance') || category.contains('HRD')) {
      return Icons.receipt_long_rounded;
    }
    if (category.contains('IT')) {
      return Icons.security_rounded;
    }
    return Icons.build_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final sops = state.sops;

    final urgentSop = sops.where((s) => s.isUrgentMandatory).isNotEmpty
        ? sops.firstWhere((s) => s.isUrgentMandatory)
        : null;

    final filteredSops = sops.where((sop) {
      if (_selectedCategory != 'Semua') {
        if (!sop.category.toLowerCase().contains(
          _selectedCategory.toLowerCase().substring(0, 5),
        )) {
          return false;
        }
      }

      if (_mandatoryOnly && !sop.isUrgentMandatory) {
        return false;
      }

      if (_bookmarkOnly && !sop.isBookmarked) {
        return false;
      }

      if (_unreadOnly && sop.isReadByMe) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = sop.title.toLowerCase().contains(q);
        final matchCode = sop.code.toLowerCase().contains(q);
        final matchCat = sop.category.toLowerCase().contains(q);
        final matchDesc =
            (sop.description != null &&
            sop.description!.toLowerCase().contains(q));
        return matchTitle || matchCode || matchCat || matchDesc;
      }

      return true;
    }).toList();

    // Apply sorting
    if (_sortOrder == 'Kode SOP (A-Z)') {
      filteredSops.sort((a, b) => a.code.compareTo(b.code));
    } else if (_sortOrder == 'Estimasi Baca') {
      filteredSops.sort(
        (a, b) => (a.duration ?? '').compareTo(b.duration ?? ''),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'KNOWLEDGE BASE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pusat Standar Operasional',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildHeaderIconButton(
                  icon: Icons.bookmark_border_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menampilkan SOP tersimpan.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _buildHeaderIconButton(
                  icon: Icons.history_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menampilkan riwayat revisi SOP.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Search Bar
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari SOP, pedoman kerja, kode dokumen...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchDebounceTimer?.cancel();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                final result = await SopFilterBottomSheet.show(
                  context,
                  initialSortOrder: _sortOrder,
                  initialMandatoryOnly: _mandatoryOnly,
                  initialBookmarkOnly: _bookmarkOnly,
                  initialUnreadOnly: _unreadOnly,
                );
                if (result != null) {
                  setState(() {
                    _sortOrder = result.sortOrder;
                    _mandatoryOnly = result.mandatoryOnly;
                    _bookmarkOnly = result.bookmarkOnly;
                    _unreadOnly = result.unreadOnly;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hasActiveSopFilters
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasActiveSopFilters
                        ? AppColors.primaryDark
                        : AppColors.primaryBorder,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: _hasActiveSopFilters
                          ? Colors.white
                          : AppColors.primary,
                      size: 20,
                    ),
                    if (_hasActiveSopFilters)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6EE7B7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. Manager Banner (Kelola Dokumen)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                Color(0xFF1E3A8A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Kelola Dokumen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.5),
                            ),
                          ),
                          child: const Text(
                            'MANAGER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6EE7B7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Unggah revisi PDF/Doc atau buat instruksi baru',
                      style: TextStyle(fontSize: 11, color: Color(0xFFBFDBFE)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  UploadSopBottomSheet.show(
                    context,
                    onAddSop: (newSop) {
                      state.addSop(newSop);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Dokumen "${newSop.title}" berhasil diterbitkan!',
                          ),
                          backgroundColor: AppColors.primaryDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Category Filters
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _categories.map((cat) {
              final isActive = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 5. Urgent SOP Alert Card
        if (urgentSop != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerLight.withOpacity(0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top tag
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'WAJIB DIBACA & DIKONFIRMASI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: const Text(
                        '1 Belum Diverifikasi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Code & Due
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      urgentSop.code,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          urgentSop.deadlineWarning ?? '2 hari lagi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  urgentSop.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Action Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 16,
                          color: AppColors.successDark,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            urgentSop.complianceTag ??
                                'Kepatuhan K3 Divisi Alat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        SopDetailBottomSheet.show(
                          context,
                          sop: urgentSop,
                          isAdmin: state.isAdmin,
                          onDelete: () {
                            state.deleteSop(urgentSop.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'SOP "${urgentSop.title}" berhasil dihapus.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onConfirmRead: (id) {
                            state.confirmReadSop(id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Konfirmasi verifikasi SOP berhasil dicatat!',
                                ),
                                backgroundColor: AppColors.primaryDark,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text(
                        'Baca & Setujui',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 6. Direktori Dokumen Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Direktori Dokumen',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredSops.length} Aktif',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _sortOrder = _sortOrder == 'Versi Terbaru'
                      ? 'Terpopuler'
                      : 'Versi Terbaru';
                });
              },
              child: Row(
                children: [
                  Text(
                    'Urutkan: $_sortOrder',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // SOP List Cards
        if (filteredSops.isEmpty) ...[
          AppEmptyState(
            icon: sops.isEmpty
                ? Icons.note_add_outlined
                : Icons.find_in_page_outlined,
            title: sops.isEmpty
                ? 'Belum Ada Dokumen SOP di ${state.currentCompany.name}'
                : 'Tidak Ada Dokumen yang Cocok',
            description: sops.isEmpty
                ? 'Perusahaan dalam status blank. Anda dapat mengunggah SOP dan panduan kerja untuk tim.'
                : 'Coba ubah kata kunci pencarian atau ganti filter divisi.',
            actionLabel: sops.isEmpty && state.isAdmin
                ? 'Unggah SOP Baru'
                : (sops.isNotEmpty ? 'Reset Filter' : null),
            actionIcon: sops.isEmpty && state.isAdmin
                ? Icons.upload_file_rounded
                : Icons.refresh_rounded,
            isActionPrimary: sops.isEmpty && state.isAdmin,
            onAction: sops.isEmpty && state.isAdmin
                ? () {
                    UploadSopBottomSheet.show(
                      context,
                      onAddSop: (newSop) {
                        state.addSop(newSop);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'SOP "${newSop.title}" berhasil diunggah!',
                            ),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                    );
                  }
                : (sops.isNotEmpty ? _resetSopFilters : null),
          ),
        ] else ...[
          ...filteredSops.map((sop) {
            final isBookmarked = sop.isBookmarked;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Category + Code + Bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryBorder,
                                ),
                              ),
                              child: Icon(
                                _getCategoryIcon(sop.category),
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${sop.code} • ${sop.category}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sop.isNewUpdate
                                          ? AppColors.successLight
                                          : AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sop.isNewUpdate
                                          ? 'Update Baru'
                                          : sop.version,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: sop.isNewUpdate
                                            ? AppColors.successDark
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => state.toggleBookmarkSop(sop.id),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title & Description
                  Text(
                    sop.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (sop.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sop.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Reading progress if available
                  if (sop.readProgressPercent != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sop.complianceRatioText ??
                                    '${sop.readProgressPercent}% Karyawan verifikasi',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                sop.readTeamCount ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (sop.readProgressPercent ?? 0) / 100,
                              minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Checkpoints / Duration
                  if (sop.checkPoints != null || sop.duration != null) ...[
                    Wrap(
                      spacing: 6,
                      children: [
                        if (sop.checkPoints != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: AppColors.successDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sop.checkPoints!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (sop.duration != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sop.duration!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 8),

                  // Footer: Date + Share + Buka SOP
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        sop.fileInfo ?? sop.lastUpdatedText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.share_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tautan dokumen ${sop.code} disalin ke papan klip!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          if (state.isAdmin) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              tooltip: 'Hapus Dokumen SOP',
                              onPressed: () async {
                                final confirmed = await AppConfirmDialog.show(
                                  context,
                                  title: 'Hapus SOP?',
                                  message:
                                      'Dokumen "${sop.title}" (${sop.code}) akan dihapus secara permanen.',
                                  confirmLabel: 'Hapus SOP',
                                  isDestructive: true,
                                  icon: Icons.delete_outline_rounded,
                                );
                                if (confirmed == true && context.mounted) {
                                  state.deleteSop(sop.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'SOP "${sop.title}" berhasil dihapus.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              SopDetailBottomSheet.show(
                                context,
                                sop: sop,
                                isAdmin: state.isAdmin,
                                onDelete: () {
                                  state.deleteSop(sop.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'SOP "${sop.title}" berhasil dihapus.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                onConfirmRead: (id) {
                                  state.confirmReadSop(id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Konfirmasi verifikasi SOP berhasil dicatat!',
                                      ),
                                      backgroundColor: AppColors.primaryDark,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.menu_book_rounded, size: 14),
                            label: const Text(
                              'Buka SOP',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
