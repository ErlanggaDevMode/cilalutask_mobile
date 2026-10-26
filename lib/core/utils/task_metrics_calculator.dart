import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/employee.dart';
import '../theme/app_colors.dart';

enum TaskSortOption {
  none('Standar'),
  deadlineNearest('Batas Waktu Terdekat'),
  progressHighest('Progres Tertinggi'),
  progressLowest('Progres Terendah'),
  priorityHighest('Prioritas Tertinggi'),
  newest('Terbaru');

  final String label;
  const TaskSortOption(this.label);
}

class TaskMetrics {
  final int total;
  final int notStarted;
  final int inProgress;
  final int completed;
  final int needsReview;
  final int urgentOrNearDeadline;
  final double completionRate;
  final double onTimeRate;
  final double lateRate;
  final double averageProgress;

  const TaskMetrics({
    required this.total,
    required this.notStarted,
    required this.inProgress,
    required this.completed,
    required this.needsReview,
    required this.urgentOrNearDeadline,
    required this.completionRate,
    required this.onTimeRate,
    required this.lateRate,
    required this.averageProgress,
  });

  static const empty = TaskMetrics(
    total: 0,
    notStarted: 0,
    inProgress: 0,
    completed: 0,
    needsReview: 0,
    urgentOrNearDeadline: 0,
    completionRate: 0.0,
    onTimeRate: 0.0,
    lateRate: 0.0,
    averageProgress: 0.0,
  );
}

class DivisionMetric {
  final String name;
  final int total;
  final int completed;
  final double completionRate;
  final Color color;

  const DivisionMetric({
    required this.name,
    required this.total,
    required this.completed,
    required this.completionRate,
    required this.color,
  });
}

class EmployeeRankItem {
  final Assignee employee;
  final int assignedCount;
  final int completedCount;
  final double completionRate;
  final int rank;
  final int score;
  final String statusBadge;

  const EmployeeRankItem({
    required this.employee,
    required this.assignedCount,
    required this.completedCount,
    required this.completionRate,
    required this.rank,
    required this.score,
    required this.statusBadge,
  });
}

/// Pure business logic functions for metrics, calculations, filtering, and periods.
class TaskMetricsCalculator {
  static const List<String> indonesianMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String getIndonesianMonth(int month) {
    if (month < 1 || month > 12) return '';
    return indonesianMonths[month - 1];
  }

  /// Calculates dynamic period string based on local DateTime.
  static String getPeriodLabel({
    DateTime? date,
    String rangeType = 'Bulan Ini',
  }) {
    final now = date ?? DateTime.now();
    final monthName = getIndonesianMonth(now.month);
    final year = now.year;

    switch (rangeType) {
      case 'Minggu Ini':
        return 'Minggu Ini ($monthName $year)';
      case 'Kuartal 1':
      case 'Kuartal 2':
      case 'Kuartal 3':
      case 'Kuartal 4':
        return '$rangeType $year';
      case 'Tahun Ini':
        return 'Tahun $year';
      case 'Bulan Ini':
      default:
        return 'Bulan Ini ($monthName $year)';
    }
  }

  /// Returns localized available period options.
  static List<String> getAvailableTimeRanges({DateTime? date}) {
    final now = date ?? DateTime.now();
    final monthName = getIndonesianMonth(now.month);
    final quarter = ((now.month - 1) ~/ 3) + 1;

    return [
      'Bulan Ini ($monthName ${now.year})',
      'Minggu Ini',
      'Kuartal $quarter',
      'Tahun Ini (${now.year})',
    ];
  }

  /// Pure computation of aggregate task metrics with safe division-by-zero protection.
  static TaskMetrics computeMetrics(List<Task> tasks) {
    if (tasks.isEmpty) {
      return TaskMetrics.empty;
    }

    final total = tasks.length;
    int notStarted = 0;
    int inProgress = 0;
    int completed = 0;
    int needsReview = 0;
    int urgentOrNearDeadline = 0;
    int totalProgress = 0;
    int lateCount = 0;

    for (final task in tasks) {
      totalProgress += task.progressPercent;

      if (task.status == TaskStatus.completed || task.progressPercent >= 100) {
        completed++;
      } else if (task.status == TaskStatus.notStarted) {
        notStarted++;
      } else {
        inProgress++;
      }

      if (task.needsReview) {
        needsReview++;
      }

      if (task.isUrgentDeadline || task.isToday) {
        urgentOrNearDeadline++;
      }

      // Check overdue heuristic: if high priority with urgent deadline and not completed
      if (task.isUrgentDeadline && task.status != TaskStatus.completed) {
        lateCount++;
      }
    }

    final completionRate = double.parse(
      ((completed / total) * 100).toStringAsFixed(1),
    );
    final averageProgress = double.parse(
      (totalProgress / total).toStringAsFixed(1),
    );

    final lateRate = double.parse(
      ((lateCount / total) * 100).toStringAsFixed(1),
    );
    final onTimeRate = double.parse(
      (100.0 - lateRate).clamp(0.0, 100.0).toStringAsFixed(1),
    );

    return TaskMetrics(
      total: total,
      notStarted: notStarted,
      inProgress: inProgress,
      completed: completed,
      needsReview: needsReview,
      urgentOrNearDeadline: urgentOrNearDeadline,
      completionRate: completionRate,
      onTimeRate: onTimeRate,
      lateRate: lateRate,
      averageProgress: averageProgress,
    );
  }

  /// Computes division productivity dynamically from actual company tasks.
  static List<DivisionMetric> computeDivisionProductivity(List<Task> tasks) {
    if (tasks.isEmpty) return const [];

    final Map<String, List<Task>> grouped = {};
    for (final task in tasks) {
      final div = task.division.trim().isEmpty ? 'Umum' : task.division.trim();
      grouped.putIfAbsent(div, () => []).add(task);
    }

    final colors = [
      AppColors.primary,
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
    ];

    int colorIdx = 0;
    final List<DivisionMetric> result = [];

    grouped.forEach((divName, divTasks) {
      final total = divTasks.length;
      final completed = divTasks
          .where(
            (t) => t.status == TaskStatus.completed || t.progressPercent >= 100,
          )
          .length;
      final rate = total > 0 ? ((completed / total) * 100) : 0.0;

      result.add(
        DivisionMetric(
          name: divName,
          total: total,
          completed: completed,
          completionRate: double.parse(rate.toStringAsFixed(1)),
          color: colors[colorIdx % colors.length],
        ),
      );
      colorIdx++;
    });

    result.sort((a, b) => b.completionRate.compareTo(a.completionRate));
    return result;
  }

  /// Computes individual employee performance metrics and rankings from actual tasks.
  static List<EmployeeRankItem> computeEmployeePerformance(
    List<Task> tasks,
    List<Assignee> employees,
  ) {
    if (employees.isEmpty) return const [];

    final List<EmployeeRankItem> items = [];

    for (final emp in employees) {
      final empTasks = tasks.where((t) => t.assignee.id == emp.id).toList();
      final assigned = empTasks.length;
      final completed = empTasks
          .where(
            (t) => t.status == TaskStatus.completed || t.progressPercent >= 100,
          )
          .length;
      final rate = assigned > 0 ? ((completed / assigned) * 100) : 0.0;

      // Base score derived from completion and active contributions
      int score = 0;
      if (assigned > 0) {
        score = (rate * 0.8 + (assigned * 2).clamp(0, 20)).round().clamp(
          0,
          100,
        );
      }

      String badge = 'Performa Standar';
      if (score >= 90) {
        badge = 'Performa Terbaik';
      } else if (score >= 75) {
        badge = 'Sangat Baik';
      } else if (assigned == 0) {
        badge = 'Belum Ada Tugas';
      }

      items.add(
        EmployeeRankItem(
          employee: emp,
          assignedCount: assigned,
          completedCount: completed,
          completionRate: double.parse(rate.toStringAsFixed(1)),
          rank: 0, // Assigned after sorting
          score: score,
          statusBadge: badge,
        ),
      );
    }

    // Sort by score descending, then completedCount descending
    items.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return b.completedCount.compareTo(a.completedCount);
    });

    // Assign 1-based ranks
    return items.asMap().entries.map((entry) {
      final item = entry.value;
      return EmployeeRankItem(
        employee: item.employee,
        assignedCount: item.assignedCount,
        completedCount: item.completedCount,
        completionRate: item.completionRate,
        rank: entry.key + 1,
        score: item.score,
        statusBadge: item.statusBadge,
      );
    }).toList();
  }

  /// Pure filtering and sorting function for Task list.
  static List<Task> filterTasks(
    List<Task> tasks, {
    TaskStatus? status,
    String division = 'Semua Divisi',
    String employeeId = 'ALL',
    String query = '',
    PriorityType? priority,
    bool urgentOnly = false,
    TaskSortOption sort = TaskSortOption.none,
  }) {
    final filtered = tasks.where((task) {
      // 1. Status match (null = all statuses)
      if (status != null && task.status != status) {
        return false;
      }

      // 2. Division match
      if (division != 'Semua Divisi') {
        final queryDiv = division.replaceAll(' & Tech', '');
        if (!task.division.contains(queryDiv)) return false;
      }

      // 3. Employee match
      if (employeeId != 'ALL' && task.assignee.id != employeeId) {
        return false;
      }

      // 4. Priority filter
      if (priority != null && task.priority != priority) {
        return false;
      }

      // 5. Urgent / Near deadline filter
      if (urgentOnly && !(task.isUrgentDeadline || task.isToday)) {
        return false;
      }

      // 6. Search query
      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        final matchAssignee = task.assignee.name.toLowerCase().contains(q);
        final matchDiv = task.division.toLowerCase().contains(q);
        return matchTitle || matchDesc || matchAssignee || matchDiv;
      }

      return true;
    }).toList();

    // Sorting
    switch (sort) {
      case TaskSortOption.progressHighest:
        filtered.sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
        break;
      case TaskSortOption.progressLowest:
        filtered.sort((a, b) => a.progressPercent.compareTo(b.progressPercent));
        break;
      case TaskSortOption.priorityHighest:
        filtered.sort((a, b) {
          final priorityOrder = {
            PriorityType.high: 3,
            PriorityType.medium: 2,
            PriorityType.low: 1,
          };
          final pA = priorityOrder[a.priority] ?? 0;
          final pB = priorityOrder[b.priority] ?? 0;
          return pB.compareTo(pA);
        });
        break;
      case TaskSortOption.deadlineNearest:
        filtered.sort((a, b) {
          final aUrgent = a.isUrgentDeadline || a.isToday ? 1 : 0;
          final bUrgent = b.isUrgentDeadline || b.isToday ? 1 : 0;
          return bUrgent.compareTo(aUrgent);
        });
        break;
      case TaskSortOption.newest:
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case TaskSortOption.none:
        break;
    }

    return filtered;
  }
}
