import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task.dart';

class UpdateProgressBottomSheet extends StatefulWidget {
  final Task task;
  final void Function(
    String taskId,
    List<Subtask> updatedSubtasks,
    int progressPercent,
  )
  onSaveProgress;

  const UpdateProgressBottomSheet({
    super.key,
    required this.task,
    required this.onSaveProgress,
  });

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required void Function(
      String taskId,
      List<Subtask> updatedSubtasks,
      int progressPercent,
    )
    onSaveProgress,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          UpdateProgressBottomSheet(task: task, onSaveProgress: onSaveProgress),
    );
  }

  @override
  State<UpdateProgressBottomSheet> createState() =>
      _UpdateProgressBottomSheetState();
}

class _UpdateProgressBottomSheetState extends State<UpdateProgressBottomSheet> {
  late List<Subtask> _subtasks;

  @override
  void initState() {
    super.initState();
    _subtasks = widget.task.subtasks.map((st) => st.copyWith()).toList();
  }

  void _toggleSubtask(int index) {
    setState(() {
      final current = _subtasks[index];
      _subtasks[index] = current.copyWith(completed: !current.completed);
    });
  }

  int get _completedCount => _subtasks.where((s) => s.completed).length;
  int get _totalCount => _subtasks.length;
  int get _computedPercent =>
      _totalCount > 0 ? ((_completedCount / _totalCount) * 100).round() : 100;

  void _save() {
    widget.onSaveProgress(widget.task.id, _subtasks, _computedPercent);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final is100 = _computedPercent == 100;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Update Progres Tugas',
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

          // Content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Divisi & PIC
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.task.division,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PIC: ${widget.task.assignee.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Task Title
                Text(
                  widget.task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Indicator Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tingkat Penyelesaian Subtask',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$_completedCount / $_totalCount ($_computedPercent%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: is100
                                  ? AppColors.successDark
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _totalCount > 0
                              ? _completedCount / _totalCount
                              : 1.0,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            is100 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Checklist Subtask Title
                const Text(
                  'Centang subtask yang sudah diselesaikan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                ..._subtasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final st = entry.value;

                  return InkWell(
                    onTap: () => _toggleSubtask(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: st.completed
                            ? AppColors.successLight.withOpacity(0.7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: st.completed
                              ? AppColors.success.withOpacity(0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            st.completed
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: st.completed
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              st.title,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: st.completed
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                decoration: st.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: st.completed
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Simpan Pembaruan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
