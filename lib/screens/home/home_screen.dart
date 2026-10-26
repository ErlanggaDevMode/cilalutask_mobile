import 'package:flutter/material.dart';

import '../../core/utils/task_metrics_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/modals/create_task_bottom_sheet.dart';
import '../../widgets/modals/upload_sop_bottom_sheet.dart';
import '../../widgets/modals/broadcast_bottom_sheet.dart';
import '../../widgets/modals/update_progress_bottom_sheet.dart';
import '../../widgets/modals/review_task_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.currentUser;
    final tasks = state.tasks;
    final activities = state.activities;

    final metrics = TaskMetricsCalculator.computeMetrics(tasks);
    final activeCount = metrics.inProgress;
    final completedCount = metrics.completed;
    final reviewCount = metrics.needsReview;
    final nearDeadlineCount = metrics.urgentOrNearDeadline;

    final approachingTasks = tasks
        .where(
          (t) =>
              t.isUrgentDeadline ||
              t.deadlineLabel.contains('Hari') ||
              t.deadlineLabel.contains('Besok'),
        )
        .take(3)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Hero Welcome Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.currentUserRoleTitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Greeting
                        Text(
                          'Halo, ${state.currentUserName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          '${state.currentCompany.name} (${state.currentCompany.code}) • Operasional berjalan lancar',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashboard quick button
                  InkWell(
                    onTap: () => state.setTab(3), // Jump to Laporan
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFBFDBFE)),
              const SizedBox(height: 10),

              // Footer: Efisiensi Tim & Lihat Performa
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: AppColors.successDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Efisiensi Tim: ${user.teamEfficiencyPercent}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successDark,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => state.setTab(3),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Performa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Aksi Cepat (Quick Actions)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pintasan',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (state.isAdmin)
          Row(
            children: [
              // Buat Tugas Baru (Admin Only)
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Buat Tugas Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Unggah SOP
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () {
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
                  icon: const Icon(
                    Icons.file_upload_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text('Unggah SOP'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Megaphone Broadcast
              InkWell(
                onTap: () {
                  BroadcastBottomSheet.show(
                    context,
                    onSendBroadcast: (msg, div) =>
                        state.sendBroadcast(msg, div),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              // Update Progres Tugas (User Only)
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () => state.setTab(1),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('Update Progres'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Chat Tim
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () => state.setTab(4),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text('Chat Tim'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // SOP Shortcut
              InkWell(
                onTap: () => state.setTab(2),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),

        // 3. Ringkasan Beban Kerja (2x2 Grid)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Ringkasan Beban Kerja',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Minggu Ini',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Card 1: Tugas Aktif
            _buildMetricCard(
              title: 'Tugas Aktif',
              count: '$activeCount',
              subtext: '4 tugas baru',
              subtextColor: AppColors.primary,
              icon: Icons.calendar_today_rounded,
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary,
              onTap: () => state.setTab(1),
            ),

            // Card 2: Selesai
            _buildMetricCard(
              title: 'Selesai',
              count: '$completedCount',
              subtext: metrics.total > 0
                  ? '${metrics.completionRate}% selesai'
                  : '0 tugas',
              subtextColor: AppColors.successDark,
              icon: Icons.check_circle_outline_rounded,
              iconBg: AppColors.successLight,
              iconColor: AppColors.success,
              onTap: () => state.setTab(1),
            ),

            // Card 3: Menunggu Review
            _buildMetricCard(
              title: 'Menunggu Review',
              count: '$reviewCount',
              subtext: 'Butuh persetujuan',
              subtextColor: AppColors.textMuted,
              icon: Icons.assignment_late_outlined,
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primaryDark,
              onTap: () => state.setTab(1),
            ),

            // Card 4: Mendekati Batas
            _buildMetricCard(
              title: 'Mendekati Batas',
              count: '$nearDeadlineCount',
              subtext: 'Tindakan segera',
              subtextColor: AppColors.danger,
              countColor: AppColors.danger,
              icon: Icons.warning_amber_rounded,
              iconBg: AppColors.dangerLight,
              iconColor: AppColors.danger,
              borderColor: AppColors.dangerBorder,
              onTap: () => state.setTab(1),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 4. Mendekati Batas Waktu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                SizedBox(width: 6),
                Text(
                  'Mendekati Batas Waktu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => state.setTab(1),
              child: Text(
                'Lihat Semua (${approachingTasks.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (approachingTasks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tasks.isEmpty
                            ? 'Belum Ada Tugas Aktif'
                            : 'Semua Tugas Terkendali',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tasks.isEmpty
                            ? 'Klik "+ Buat Tugas Baru" di atas untuk menambahkan tugas perdana.'
                            : 'Tidak ada tugas yang mendekati batas waktu hari ini.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...approachingTasks.map((task) {
            return InkWell(
              onTap: () {
                if (state.isUser) {
                  UpdateProgressBottomSheet.show(
                    context,
                    task: task,
                    onSaveProgress: (id, subtasks, pct) {
                      state.saveProgress(id, subtasks, pct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Progres tugas berhasil diperbarui!'),
                          backgroundColor: AppColors.primaryDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                } else if (state.isAdmin) {
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
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deadline tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: task.isUrgentDeadline
                                ? AppColors.dangerLight
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: task.isUrgentDeadline
                                      ? AppColors.danger
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.deadlineLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: task.isUrgentDeadline
                                      ? AppColors.danger
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Penyelesaian',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${task.progressPercent}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progressPercent / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 8),

                    // Assignee & Division
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomAvatar(
                              imageUrl: task.assignee.avatar,
                              fallbackText: task.assignee.name,
                              radius: 10,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.assignee.shortName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.division.contains('Finance')
                                ? 'Div. Finance'
                                : 'Div. IT Core',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 16),

        // 5. Aktivitas Terbaru
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Langsung',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum Ada Aktivitas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aktivitas pembuatan tugas, penyelesaian subtask, dan SOP akan tercatat di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: activities.asMap().entries.map((entry) {
                final index = entry.key;
                final act = entry.value;
                final isSop = act.type == 'sop';

                return Column(
                  children: [
                    if (index > 0)
                      const Divider(height: 18, color: AppColors.borderSubtle),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomAvatar(
                              imageUrl: act.userAvatar,
                              fallbackText: act.userName,
                              radius: 16,
                            ),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isSop
                                      ? Icons.check_circle_rounded
                                      : Icons.refresh_rounded,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${act.userName} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: '${act.actionPrefix} '),
                                    TextSpan(
                                      text: act.targetObject,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (act.actionSuffix != null)
                                      TextSpan(text: ' ${act.actionSuffix}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${act.timeAgo} • ${act.department}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtext,
    required Color subtextColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    Color? countColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
              ],
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: countColor ?? AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
