import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/employee.dart';
import '../../models/task.dart';

class CreateTaskBottomSheet extends StatefulWidget {
  final List<Assignee> employees;
  final Assignee? defaultAssignee;
  final void Function(Task newTask) onCreateTask;

  const CreateTaskBottomSheet({
    super.key,
    required this.employees,
    this.defaultAssignee,
    required this.onCreateTask,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Assignee> employees,
    Assignee? defaultAssignee,
    required void Function(Task newTask) onCreateTask,
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
        child: CreateTaskBottomSheet(
          employees: employees,
          defaultAssignee: defaultAssignee,
          onCreateTask: onCreateTask,
        ),
      ),
    );
  }

  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskController = TextEditingController();

  String _division = 'IT & Tech';
  PriorityType _priority = PriorityType.high;
  late String _assigneeId;
  String _deadline = 'Besok, 17:00';

  final List<String> _subtasks = [
    'Tahap 1: Analisis kebutuhan & dokumen acuan',
    'Tahap 2: Eksekusi implementasi sistem',
  ];

  final List<String> _divisions = [
    'IT & Tech',
    'Operasional',
    'Pemasaran',
    'Finance & Akuntansi',
  ];

  static const _fallbackAdminAssignee = Assignee(
    id: 'admin-pic',
    name: 'Admin Perusahaan',
    shortName: 'AP',
    avatar: '',
    division: 'Manajemen',
    role: 'Admin',
  );

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _assigneeId =
        widget.defaultAssignee?.id ??
        (widget.employees.isNotEmpty
            ? widget.employees.first.id
            : _fallbackAdminAssignee.id);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(text);
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  Assignee _getSelectedAssignee() {
    if (widget.employees.isEmpty) {
      return _fallbackAdminAssignee;
    }
    return widget.employees.firstWhere(
      (e) => e.id == _assigneeId,
      orElse: () => widget.employees.first,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final selectedAssignee = _getSelectedAssignee();

        final now = DateTime.now().millisecondsSinceEpoch;
        final newTask = Task(
          id: 'tsk-$now',
          title: _titleController.text.trim(),
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : 'Instruksi operasional telah ditentukan.',
          division: _division,
          priority: _priority,
          status: TaskStatus.inProgress,
          deadlineLabel: _deadline,
          isUrgentDeadline: _priority == PriorityType.high,
          progressPercent: 0,
          assignee: selectedAssignee,
          subtasks: _subtasks
              .asMap()
              .entries
              .map(
                (entry) => Subtask(
                  id: 'st-$now-${entry.key}',
                  title: entry.value,
                  completed: false,
                ),
              )
              .toList(),
          needsReview: true,
        );

        widget.onCreateTask(newTask);
        if (mounted) Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAssignee = _getSelectedAssignee();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Buat Tugas Baru',
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

          // Form Body
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Judul Tugas
                  const Text(
                    'Judul Tugas *',
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
                      hintText: 'Misal: Migrasi Database ke Cloud',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Judul tugas wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Deskripsi
                  const Text(
                    'Deskripsi Operasional',
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
                      hintText: 'Tuliskan rincian instruksi dan parameter yang diharapkan...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Divisi & Prioritas
                  Row(
                    children: [
                      // Divisi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Divisi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _division,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: _divisions
                                  .map(
                                    (div) => DropdownMenuItem(
                                      value: div,
                                      child: Text(
                                        div,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _division = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Prioritas
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prioritas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<PriorityType>(
                              value: _priority,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: PriorityType.values
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _priority = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Penanggung Jawab (Assignee)
                  const Text(
                    'Pilih Penanggung Jawab (PIC)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CustomAvatar(
                          imageUrl: selectedAssignee.avatar,
                          fallbackText: selectedAssignee.name,
                          radius: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _assigneeId,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              items:
                                  (widget.employees.isNotEmpty
                                          ? widget.employees
                                          : [_fallbackAdminAssignee])
                                      .map((emp) {
                                        return DropdownMenuItem(
                                          value: emp.id,
                                          child: Text(
                                            '${emp.name} (${emp.division})',
                                          ),
                                        );
                                      })
                                      .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _assigneeId = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tenggat Waktu
                  const Text(
                    'Tenggat Waktu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: _deadline,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      hintText: 'Contoh: Besok, 17:00 / 3 hari lagi',
                    ),
                    onChanged: (val) => _deadline = val,
                  ),
                  const SizedBox(height: 16),

                  // Subtasks Checklist Dinamis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtask Checklist',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_subtasks.length} subtask',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._subtasks.asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            onPressed: () => _removeSubtask(entry.key),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add Subtask Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Ketik subtask baru...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSubtask,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tombol Buat Tugas
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              'Terbitkan Tugas Sekarang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
