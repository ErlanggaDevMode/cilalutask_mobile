import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/task_metrics_calculator.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/custom_badge.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../models/task.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/modals/create_task_bottom_sheet.dart';
import '../../widgets/modals/update_progress_bottom_sheet.dart';
import '../../widgets/modals/review_task_bottom_sheet.dart';
import '../../widgets/modals/task_filter_bottom_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _searchQuery = '';
  String _selectedDivision = 'Semua Divisi';
  String _selectedEmployeeId = 'ALL';
  TaskStatus? _selectedStatus; // null means 'Semua' (All tasks visible)
  PriorityType? _selectedPriority;
  TaskSortOption _selectedSort = TaskSortOption.none;
  bool _urgentOnly = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  final List<String> _divisions = [
    'Semua Divisi',
    'Operasional',
    'IT & Tech',
    'Pemasaran',
    'Finance & Akuntansi',
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

  void _resetAllFilters() {
    _searchDebounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedDivision = 'Semua Divisi';
      _selectedEmployeeId = 'ALL';
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedSort = TaskSortOption.none;
      _urgentOnly = false;
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedDivision != 'Semua Divisi' ||
      _selectedEmployeeId != 'ALL' ||
      _selectedStatus != null ||
      _selectedPriority != null ||
      _selectedSort != TaskSortOption.none ||
      _urgentOnly;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tasks = state.tasks;
    final employees = state.employees;

    // Counts for status tabs
    final notStartedCount = tasks
        .where((t) => t.status == TaskStatus.notStarted)
        .length;
    final inProgressCount = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final completedCount = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;

    // Filter tasks using pure TaskMetricsCalculator
    final filteredTasks = TaskMetricsCalculator.filterTasks(
      tasks,
      status: _selectedStatus,
      division: _selectedDivision,
      employeeId: _selectedEmployeeId,
      query: _searchQuery,
      priority: _selectedPriority,
      urgentOnly: _urgentOnly,
      sort: _selectedSort,
    );

    final hasAdvancedFilter =
        _selectedPriority != null ||
        _selectedSort != TaskSortOption.none ||
        _urgentOnly;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // 1. Search Bar & Filter Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari tugas atau nama karyawan...',
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    final result = await TaskFilterBottomSheet.show(
                      context,
                      initialPriority: _selectedPriority,
                      initialSort: _selectedSort,
                      initialUrgentOnly: _urgentOnly,
                    );
                    if (result != null) {
                      setState(() {
                        _selectedPriority = result.priority;
                        _selectedSort = result.sort;
                        _urgentOnly = result.urgentOnly;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasAdvancedFilter
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasAdvancedFilter
                            ? AppColors.primaryDark
                            : AppColors.primaryBorder,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: hasAdvancedFilter
                              ? Colors.white
                              : AppColors.primary,
                          size: 20,
                        ),
                        if (hasAdvancedFilter)
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

            // 2. Division Filters (Horizontal scroll)
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _divisions.map((div) {
                  final isActive = _selectedDivision == div;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDivision = div),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primaryDark
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          div,
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
            const SizedBox(height: 10),

            // 3. Employee Filters (Horizontal scroll)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // ALL chip
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedEmployeeId = 'ALL'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedEmployeeId == 'ALL'
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedEmployeeId == 'ALL'
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'ALL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _selectedEmployeeId == 'ALL'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Semua',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _selectedEmployeeId == 'ALL'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Member chips
                  ...employees.map((emp) {
                    final isSelected = _selectedEmployeeId == emp.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedEmployeeId = emp.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomAvatar(
                                imageUrl: emp.avatar,
                                fallbackText: emp.name,
                                radius: 9,
                                hasBorder: false,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                emp.shortName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Status Tabs (Semua, Belum Dimulai, Dalam Proses, Selesai)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildStatusTab('Semua', null, tasks.length),
                  _buildStatusTab(
                    'Belum Dimulai',
                    TaskStatus.notStarted,
                    notStartedCount,
                  ),
                  _buildStatusTab(
                    'Dalam Proses',
                    TaskStatus.inProgress,
                    inProgressCount,
                    isBadge: true,
                  ),
                  _buildStatusTab(
                    'Selesai',
                    TaskStatus.completed,
                    completedCount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Active Filter Chips Summary (if any filter is applied)
            if (_hasActiveFilters) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Filter aktif:',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  if (_selectedStatus != null)
                    _buildActiveFilterChip(
                      _selectedStatus!.label,
                      () => setState(() => _selectedStatus = null),
                    ),
                  if (_selectedDivision != 'Semua Divisi')
                    _buildActiveFilterChip(
                      _selectedDivision,
                      () => setState(() => _selectedDivision = 'Semua Divisi'),
                    ),
                  if (_selectedEmployeeId != 'ALL')
                    _buildActiveFilterChip(
                      employees
                          .firstWhere(
                            (e) => e.id == _selectedEmployeeId,
                            orElse: () => employees.first,
                          )
                          .name,
                      () => setState(() => _selectedEmployeeId = 'ALL'),
                    ),
                  if (_selectedPriority != null)
                    _buildActiveFilterChip(
                      _selectedPriority!.label,
                      () => setState(() => _selectedPriority = null),
                    ),
                  if (_selectedSort != TaskSortOption.none)
                    _buildActiveFilterChip(
                      _selectedSort.label,
                      () => setState(() => _selectedSort = TaskSortOption.none),
                    ),
                  if (_urgentOnly)
                    _buildActiveFilterChip(
                      'Mendesak',
                      () => setState(() => _urgentOnly = false),
                    ),
                  TextButton(
                    onPressed: _resetAllFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Reset Semua',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // 5. Task Cards List
            if (filteredTasks.isEmpty) ...[
              AppEmptyState(
                icon: tasks.isEmpty
                    ? Icons.assignment_add
                    : Icons.inbox_rounded,
                title: tasks.isEmpty
                    ? 'Belum Ada Tugas di ${state.currentCompany.name}'
                    : 'Tidak Ada Tugas yang Cocok',
                message: tasks.isEmpty
                    ? 'Perusahaan siap diinput secara manual. Mulai dengan membuat tugas baru untuk tim Anda.'
                    : 'Coba ubah kata kunci pencarian atau reset filter divisi, status, dan prioritas.',
                actionLabel: (tasks.isEmpty && state.isAdmin)
                    ? 'Buat Tugas Baru'
                    : (tasks.isNotEmpty ? 'Reset Semua Filter' : null),
                actionIcon: (tasks.isEmpty && state.isAdmin)
                    ? Icons.add_rounded
                    : Icons.refresh_rounded,
                onAction: (tasks.isEmpty && state.isAdmin)
                    ? () {
                        CreateTaskBottomSheet.show(
                          context,
                          employees: employees,
                          onCreateTask: (newTask) {
                            state.createTask(newTask);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tugas "${newTask.title}" berhasil dibuat!',
                                ),
                                backgroundColor: AppColors.primaryDark,
                              ),
                            );
                          },
                        );
                      }
                    : (tasks.isNotEmpty ? _resetAllFilters : null),
              ),
            ] else ...[
              ...filteredTasks.map((task) {
                final completedSubtasks = task.subtasks
                    .where((s) => s.completed)
                    .length;
                final totalSubtasks = task.subtasks.length;
                final isDone =
                    task.status == TaskStatus.completed ||
                    task.progressPercent >= 100;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Tags
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                DivisionBadge(division: task.division),
                                PriorityBadge(priority: task.priority),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (state.isAdmin)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  tooltip: 'Hapus Tugas',
                                  onPressed: () async {
                                    final confirmed = await AppConfirmDialog.show(
                                      context,
                                      title: 'Hapus Tugas?',
                                      message:
                                          'Tugas "${task.title}" akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
                                      confirmLabel: 'Ya, Hapus',
                                      cancelLabel: 'Batal',
                                      isDestructive: true,
                                      icon: Icons.delete_forever_rounded,
                                    );
                                    if (confirmed && context.mounted) {
                                      state.deleteTask(task.id);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Tugas "${task.title}" berhasil dihapus.',
                                          ),
                                          backgroundColor:
                                              AppColors.primaryDark,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                tooltip: 'Detail & Review',
                                onPressed: () {
                                  ReviewTaskBottomSheet.show(
                                    context,
                                    task: task,
                                    onApproveTask: (id) {
                                      state.approveTask(id);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Tugas telah disetujui & ditandai selesai!',
                                          ),
                                          backgroundColor:
                                              AppColors.primaryDark,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  );
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title & Description
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtasks Progress Box
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_box_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Subtask Checklist',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Flexible(
                            child: Text(
                              '$completedSubtasks / $totalSubtasks (${task.progressPercent}%)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDone
                                    ? AppColors.successDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.progressPercent / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      const SizedBox(height: 10),

                      // Assignee & Deadline Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CustomAvatar(
                                  imageUrl: task.assignee.avatar,
                                  fallbackText: task.assignee.name,
                                  radius: 12,
                                  teamCount: task.assignee.hasTeamBadge
                                      ? task.assignee.teamCount
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${task.assignee.name} ${task.assignee.hasTeamBadge ? '& Tim' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: task.isUrgentDeadline
                                  ? AppColors.dangerLight
                                  : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.isUrgentDeadline
                                      ? Icons.access_time_rounded
                                      : Icons.calendar_today_rounded,
                                  size: 12,
                                  color: task.isUrgentDeadline
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.deadlineLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: task.isUrgentDeadline
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons (RBAC: Only User can Update Progres, Only Admin can Review)
                      if (state.isUser)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              UpdateProgressBottomSheet.show(
                                context,
                                task: task,
                                onSaveProgress: (id, subtasks, pct) {
                                  state.saveProgress(id, subtasks, pct);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Progres tugas berhasil diperbarui!',
                                      ),
                                      backgroundColor: AppColors.primaryDark,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Update Progres Tugas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        )
                      else if (state.isAdmin)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ReviewTaskBottomSheet.show(
                                context,
                                task: task,
                                onApproveTask: (id) {
                                  state.approveTask(id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tugas telah disetujui & ditandai selesai!',
                                      ),
                                      backgroundColor: AppColors.primaryDark,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 16,
                            ),
                            label: const Text('Review & Persetujuan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),

        // 6. Floating Action Button (+ Tugas) - Only Admin can assign/create tasks
        if (state.isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                CreateTaskBottomSheet.show(
                  context,
                  employees: state.employees,
                  onCreateTask: (newTask) {
                    state.createTask(newTask);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tugas "${newTask.title}" berhasil diterbitkan!',
                        ),
                        backgroundColor: AppColors.primaryDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Tugas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusTab(
    String label,
    TaskStatus? status,
    int count, {
    bool isBadge = false,
  }) {
    final isActive = _selectedStatus == status;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = status),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isBadge
                      ? AppColors.primary
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isBadge ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
