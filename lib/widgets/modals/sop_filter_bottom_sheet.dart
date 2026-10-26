import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SopFilterResult {
  final String sortOrder;
  final bool mandatoryOnly;
  final bool bookmarkOnly;
  final bool unreadOnly;

  const SopFilterResult({
    this.sortOrder = 'Versi Terbaru',
    this.mandatoryOnly = false,
    this.bookmarkOnly = false,
    this.unreadOnly = false,
  });

  bool get hasActiveFilter =>
      sortOrder != 'Versi Terbaru' ||
      mandatoryOnly ||
      bookmarkOnly ||
      unreadOnly;
}

class SopFilterBottomSheet extends StatefulWidget {
  final String initialSortOrder;
  final bool initialMandatoryOnly;
  final bool initialBookmarkOnly;
  final bool initialUnreadOnly;

  const SopFilterBottomSheet({
    super.key,
    this.initialSortOrder = 'Versi Terbaru',
    this.initialMandatoryOnly = false,
    this.initialBookmarkOnly = false,
    this.initialUnreadOnly = false,
  });

  static Future<SopFilterResult?> show(
    BuildContext context, {
    String initialSortOrder = 'Versi Terbaru',
    bool initialMandatoryOnly = false,
    bool initialBookmarkOnly = false,
    bool initialUnreadOnly = false,
  }) {
    return showModalBottomSheet<SopFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SopFilterBottomSheet(
        initialSortOrder: initialSortOrder,
        initialMandatoryOnly: initialMandatoryOnly,
        initialBookmarkOnly: initialBookmarkOnly,
        initialUnreadOnly: initialUnreadOnly,
      ),
    );
  }

  @override
  State<SopFilterBottomSheet> createState() => _SopFilterBottomSheetState();
}

class _SopFilterBottomSheetState extends State<SopFilterBottomSheet> {
  late String _sortOrder;
  late bool _mandatoryOnly;
  late bool _bookmarkOnly;
  late bool _unreadOnly;

  final List<String> _sortOptions = [
    'Versi Terbaru',
    'Kode SOP (A-Z)',
    'Estimasi Baca',
  ];

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.initialSortOrder;
    _mandatoryOnly = widget.initialMandatoryOnly;
    _bookmarkOnly = widget.initialBookmarkOnly;
    _unreadOnly = widget.initialUnreadOnly;
  }

  void _reset() {
    setState(() {
      _sortOrder = 'Versi Terbaru';
      _mandatoryOnly = false;
      _bookmarkOnly = false;
      _unreadOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      SopFilterResult(
        sortOrder: _sortOrder,
        mandatoryOnly: _mandatoryOnly,
        bookmarkOnly: _bookmarkOnly,
        unreadOnly: _unreadOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Filter & Pengurutan SOP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _reset,
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // 1. Sort Order
          const Text(
            'Urutkan Dokumen',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((opt) {
              final isSelected = _sortOrder == opt;
              return ChoiceChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceSecondary,
                onSelected: (val) {
                  setState(() => _sortOrder = opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 2. Filter Toggles
          const Text(
            'Kriteria Khusus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          _buildToggleTile(
            title: 'Hanya SOP Wajib (Mandatory K3)',
            icon: Icons.shield_rounded,
            iconColor: AppColors.danger,
            value: _mandatoryOnly,
            onChanged: (val) => setState(() => _mandatoryOnly = val),
          ),
          const SizedBox(height: 8),

          _buildToggleTile(
            title: 'Hanya Dokumen Ditandai (Bookmark)',
            icon: Icons.bookmark_rounded,
            iconColor: AppColors.primary,
            value: _bookmarkOnly,
            onChanged: (val) => setState(() => _bookmarkOnly = val),
          ),
          const SizedBox(height: 8),

          _buildToggleTile(
            title: 'Hanya yang Belum Saya Baca',
            icon: Icons.mark_email_unread_rounded,
            iconColor: AppColors.warning,
            value: _unreadOnly,
            onChanged: (val) => setState(() => _unreadOnly = val),
          ),
          const SizedBox(height: 20),

          // 3. Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Terapkan Filter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Switch.adaptive(
              value: value,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
