import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/task_metrics_calculator.dart';
import '../../models/task.dart';

class TaskFilterResult {
  final PriorityType? priority;
  final TaskSortOption sort;
  final bool urgentOnly;

  const TaskFilterResult({
    this.priority,
    this.sort = TaskSortOption.none,
    this.urgentOnly = false,
  });

  bool get hasActiveFilter =>
      priority != null || sort != TaskSortOption.none || urgentOnly;
}

class TaskFilterBottomSheet extends StatefulWidget {
  final PriorityType? initialPriority;
  final TaskSortOption initialSort;
  final bool initialUrgentOnly;

  const TaskFilterBottomSheet({
    super.key,
    this.initialPriority,
    this.initialSort = TaskSortOption.none,
    this.initialUrgentOnly = false,
  });

  static Future<TaskFilterResult?> show(
    BuildContext context, {
    PriorityType? initialPriority,
    TaskSortOption initialSort = TaskSortOption.none,
    bool initialUrgentOnly = false,
  }) {
    return showModalBottomSheet<TaskFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFilterBottomSheet(
        initialPriority: initialPriority,
        initialSort: initialSort,
        initialUrgentOnly: initialUrgentOnly,
      ),
    );
  }

  @override
  State<TaskFilterBottomSheet> createState() => _TaskFilterBottomSheetState();
}

class _TaskFilterBottomSheetState extends State<TaskFilterBottomSheet> {
  PriorityType? _selectedPriority;
  late TaskSortOption _selectedSort;
  late bool _urgentOnly;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialPriority;
    _selectedSort = widget.initialSort;
    _urgentOnly = widget.initialUrgentOnly;
  }

  void _reset() {
    setState(() {
      _selectedPriority = null;
      _selectedSort = TaskSortOption.none;
      _urgentOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      TaskFilterResult(
        priority: _selectedPriority,
        sort: _selectedSort,
        urgentOnly: _urgentOnly,
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
                    'Filter & Pengurutan Tugas',
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

          // 1. Prioritas Tugas
          const Text(
            'Prioritas Tugas',
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
            children: [
              _buildPriorityChip(null, 'Semua Prioritas'),
              _buildPriorityChip(PriorityType.high, 'Tinggi (Urgent)'),
              _buildPriorityChip(PriorityType.medium, 'Sedang'),
              _buildPriorityChip(PriorityType.low, 'Rendah'),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Pengurutan (Sorting)
          const Text(
            'Urutkan Berdasarkan',
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
            children: TaskSortOption.values.map((sort) {
              final isSelected = _selectedSort == sort;
              return ChoiceChip(
                label: Text(
                  sort.label,
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
                  setState(() => _selectedSort = sort);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () => setState(() => _urgentOnly = !_urgentOnly),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hanya Tugas Mendesak / Hari Ini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _urgentOnly,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _urgentOnly = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Apply Button
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

  Widget _buildPriorityChip(PriorityType? priority, String label) {
    final isSelected = _selectedPriority == priority;
    return ChoiceChip(
      label: Text(
        label,
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
        setState(() => _selectedPriority = priority);
      },
    );
  }
}
