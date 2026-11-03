import 'package:flutter_test/flutter_test.dart';
import 'package:cilalutask_mobile/core/utils/task_metrics_calculator.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/employee.dart';

void main() {
  group('Adversarial Stress & Boundary Testing - TaskMetricsCalculator', () {
    const dummyAssignee = Assignee(
      id: 'emp-stress-1',
      name: 'Stress Tester 1',
      shortName: 'ST1',
      avatar: 'https://avatar.test/1.png',
      division: 'IT & Tech',
      role: 'QA Specialist',
    );

    const dummyAssignee2 = Assignee(
      id: 'emp-stress-2',
      name: 'Stress Tester 2',
      shortName: 'ST2',
      avatar: 'https://avatar.test/2.png',
      division: 'Operasional',
      role: 'Backend Dev',
    );

    test('1. Boundary: Empty dataset zero division & NaN immunity', () {
      final metrics = TaskMetricsCalculator.computeMetrics([]);
      expect(metrics.total, 0);
      expect(metrics.completed, 0);
      expect(metrics.notStarted, 0);
      expect(metrics.inProgress, 0);
      expect(metrics.needsReview, 0);
      expect(metrics.urgentOrNearDeadline, 0);
      expect(metrics.completionRate, 0.0);
      expect(metrics.onTimeRate, 0.0);
      expect(metrics.lateRate, 0.0);
      expect(metrics.averageProgress, 0.0);
      expect(metrics.completionRate.isNaN, isFalse);
      expect(metrics.onTimeRate.isNaN, isFalse);

      expect(TaskMetricsCalculator.computeDivisionProductivity([]), isEmpty);
      expect(
        TaskMetricsCalculator.computeEmployeePerformance([], [dummyAssignee]),
        hasLength(1),
      );
      final emptyEmpMetrics =
          TaskMetricsCalculator.computeEmployeePerformance([], [dummyAssignee]);
      expect(emptyEmpMetrics.first.assignedCount, 0);
      expect(emptyEmpMetrics.first.completedCount, 0);
      expect(emptyEmpMetrics.first.completionRate, 0.0);
      expect(emptyEmpMetrics.first.score, 0);
      expect(emptyEmpMetrics.first.statusBadge, 'Belum Ada Tugas');

      expect(
        TaskMetricsCalculator.computeEmployeePerformance([], []),
        isEmpty,
      );
      expect(TaskMetricsCalculator.filterTasks([]), isEmpty);
    });

    test('2. Boundary: 100% completed tasks (500 items)', () {
      final tasks = List.generate(
        500,
        (i) => Task(
          id: 'task-comp-$i',
          title: 'Completed Task $i',
          description: 'Description $i',
          division: 'IT & Tech',
          priority: PriorityType.medium,
          status: TaskStatus.completed,
          deadlineLabel: '2026-12-31',
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 100,
        ),
      );

      final metrics = TaskMetricsCalculator.computeMetrics(tasks);
      expect(metrics.total, 500);
      expect(metrics.completed, 500);
      expect(metrics.notStarted, 0);
      expect(metrics.inProgress, 0);
      expect(metrics.completionRate, 100.0);
      expect(metrics.onTimeRate, 100.0);
      expect(metrics.lateRate, 0.0);
      expect(metrics.averageProgress, 100.0);
    });

    test('3. Boundary: 100% in-progress tasks (500 items)', () {
      final tasks = List.generate(
        500,
        (i) => Task(
          id: 'task-prog-$i',
          title: 'Progress Task $i',
          description: 'Description $i',
          division: 'Operasional',
          priority: PriorityType.low,
          status: TaskStatus.inProgress,
          deadlineLabel: '2026-12-31',
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 50,
        ),
      );

      final metrics = TaskMetricsCalculator.computeMetrics(tasks);
      expect(metrics.total, 500);
      expect(metrics.completed, 0);
      expect(metrics.notStarted, 0);
      expect(metrics.inProgress, 500);
      expect(metrics.completionRate, 0.0);
      expect(metrics.averageProgress, 50.0);
    });

    test('4. Boundary: 100% not-started tasks (500 items)', () {
      final tasks = List.generate(
        500,
        (i) => Task(
          id: 'task-not-$i',
          title: 'Not Started $i',
          description: 'Description $i',
          division: 'Pemasaran',
          priority: PriorityType.low,
          status: TaskStatus.notStarted,
          deadlineLabel: '2026-12-31',
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 0,
        ),
      );

      final metrics = TaskMetricsCalculator.computeMetrics(tasks);
      expect(metrics.total, 500);
      expect(metrics.completed, 0);
      expect(metrics.notStarted, 500);
      expect(metrics.inProgress, 0);
      expect(metrics.completionRate, 0.0);
      expect(metrics.averageProgress, 0.0);
    });

    test('5. Boundary: All overdue and urgent tasks (100% late)', () {
      final tasks = List.generate(
        100,
        (i) => Task(
          id: 'task-late-$i',
          title: 'Late Task $i',
          description: 'Description $i',
          division: 'Finance & Akuntansi',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Hari ini',
          isUrgentDeadline: true,
          isToday: true,
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 20,
        ),
      );

      final metrics = TaskMetricsCalculator.computeMetrics(tasks);
      expect(metrics.total, 100);
      expect(metrics.urgentOrNearDeadline, 100);
      expect(metrics.lateRate, 100.0);
      expect(metrics.onTimeRate, 0.0);
    });

    test('6. In-progress status with progressPercent >= 100 counts as completed', () {
      final tasks = [
        Task(
          id: 'task-pct100',
          title: 'Almost completed status mismatch',
          description: 'Desc',
          division: 'IT & Tech',
          priority: PriorityType.medium,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Besok',
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 100,
        ),
      ];

      final metrics = TaskMetricsCalculator.computeMetrics(tasks);
      expect(metrics.completed, 1);
      expect(metrics.inProgress, 0);
      expect(metrics.completionRate, 100.0);
    });

    test('7. High volume stress: 10,000 tasks compute in sub-second without overflow', () {
      final stopwatch = Stopwatch()..start();
      final largeTaskList = List.generate(
        10000,
        (i) => Task(
          id: 'bulk-task-$i',
          title: 'Task $i',
          description: 'Desc $i',
          division: i % 4 == 0
              ? 'IT & Tech'
              : i % 4 == 1
                  ? 'Operasional'
                  : i % 4 == 2
                      ? 'Pemasaran'
                      : 'Finance & Akuntansi',
          priority: i % 3 == 0
              ? PriorityType.high
              : i % 3 == 1
                  ? PriorityType.medium
                  : PriorityType.low,
          status: i % 2 == 0 ? TaskStatus.completed : TaskStatus.inProgress,
          deadlineLabel: '2026-11-30',
          isUrgentDeadline: i % 10 == 0,
          isToday: i % 20 == 0,
          needsReview: i % 5 == 0,
          subtasks: const [],
          assignee: i % 2 == 0 ? dummyAssignee : dummyAssignee2,
          progressPercent: i % 2 == 0 ? 100 : 30,
        ),
      );

      final metrics = TaskMetricsCalculator.computeMetrics(largeTaskList);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(metrics.total, 10000);
      expect(metrics.completed, 5000);
      expect(metrics.completionRate, 50.0);
      expect(metrics.total, metrics.completed + metrics.inProgress + metrics.notStarted);
      expect(metrics.averageProgress, greaterThan(0.0));

      final divMetrics = TaskMetricsCalculator.computeDivisionProductivity(largeTaskList);
      expect(divMetrics.length, 4);

      final empMetrics = TaskMetricsCalculator.computeEmployeePerformance(
        largeTaskList,
        <Assignee>[dummyAssignee, dummyAssignee2],
      );
      expect(empMetrics.length, 2);
      expect(empMetrics[0].assignedCount, 5000);
      expect(empMetrics[1].assignedCount, 5000);
    });

    test('8. Edge case: blank or whitespace division names fall back to Umum', () {
      final tasks = [
        Task(
          id: 'task-empty-div',
          title: 'No Div',
          description: 'Desc',
          division: '',
          priority: PriorityType.low,
          status: TaskStatus.completed,
          deadlineLabel: 'Besok',
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 100,
        ),
        Task(
          id: 'task-ws-div',
          title: 'Whitespace Div',
          description: 'Desc',
          division: '   ',
          priority: PriorityType.low,
          status: TaskStatus.notStarted,
          deadlineLabel: 'Besok',
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 0,
        ),
      ];

      final divMetrics = TaskMetricsCalculator.computeDivisionProductivity(tasks);
      expect(divMetrics.length, 1);
      expect(divMetrics.first.name, 'Umum');
      expect(divMetrics.first.total, 2);
      expect(divMetrics.first.completed, 1);
      expect(divMetrics.first.completionRate, 50.0);
    });

    test('9. Employee Performance: score clamping, rank ties, and status badges', () {
      final tasks = <Task>[
        // dummyAssignee has 5 completed tasks
        for (int i = 0; i < 5; i++)
          Task(
            id: 'task-a-$i',
            title: 'Task A$i',
            description: 'Desc',
            division: 'IT & Tech',
            priority: PriorityType.medium,
            status: TaskStatus.completed,
            deadlineLabel: '2026-11-30',
            subtasks: const [],
            assignee: dummyAssignee,
            progressPercent: 100,
          ),
      ];

      final employees = <Assignee>[dummyAssignee, dummyAssignee2];
      final ranking = TaskMetricsCalculator.computeEmployeePerformance(tasks, employees);

      expect(ranking.length, 2);
      // dummyAssignee: 100% rate * 0.8 = 80 + (5*2) = 10 -> score 90 -> 'Performa Terbaik'
      expect(ranking[0].employee.id, dummyAssignee.id);
      expect(ranking[0].rank, 1);
      expect(ranking[0].score, 90);
      expect(ranking[0].statusBadge, 'Performa Terbaik');

      // dummyAssignee2 has 0 tasks
      expect(ranking[1].employee.id, dummyAssignee2.id);
      expect(ranking[1].rank, 2);
      expect(ranking[1].score, 0);
      expect(ranking[1].statusBadge, 'Belum Ada Tugas');
    });

    test('10. Boundary: Month index out-of-range protection', () {
      expect(TaskMetricsCalculator.getIndonesianMonth(0), '');
      expect(TaskMetricsCalculator.getIndonesianMonth(-1), '');
      expect(TaskMetricsCalculator.getIndonesianMonth(13), '');
      expect(TaskMetricsCalculator.getIndonesianMonth(1), 'Januari');
      expect(TaskMetricsCalculator.getIndonesianMonth(12), 'Desember');

      final period = TaskMetricsCalculator.getPeriodLabel(
        date: DateTime(2026, 11, 3),
        rangeType: 'Bulan Ini',
      );
      expect(period, 'Bulan Ini (November 2026)');

      final quarterPeriod = TaskMetricsCalculator.getPeriodLabel(
        date: DateTime(2026, 11, 3),
        rangeType: 'Kuartal 4',
      );
      expect(quarterPeriod, 'Kuartal 4 2026');
    });

    test('11. Task filtering and sorting robustness', () {
      final tasks = [
        Task(
          id: 'task-sort-1',
          title: 'Fix Database Auth',
          description: 'Fix the SQL connection',
          division: 'IT & Tech',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Hari ini',
          isUrgentDeadline: true,
          isToday: true,
          subtasks: const [],
          assignee: dummyAssignee,
          progressPercent: 75,
        ),
        Task(
          id: 'task-sort-2',
          title: 'Design Brochure',
          description: 'Marketing campaign',
          division: 'Pemasaran',
          priority: PriorityType.low,
          status: TaskStatus.completed,
          deadlineLabel: '2026-12-01',
          subtasks: const [],
          assignee: dummyAssignee2,
          progressPercent: 100,
        ),
      ];

      // Query filter
      final qResult = TaskMetricsCalculator.filterTasks(tasks, query: 'database');
      expect(qResult.length, 1);
      expect(qResult.first.id, 'task-sort-1');

      // Division filter
      final divResult = TaskMetricsCalculator.filterTasks(tasks, division: 'IT & Tech');
      expect(divResult.length, 1);
      expect(divResult.first.id, 'task-sort-1');

      // Priority sort
      final prioSort = TaskMetricsCalculator.filterTasks(
        tasks,
        sort: TaskSortOption.priorityHighest,
      );
      expect(prioSort.first.priority, PriorityType.high);

      // Progress sort
      final progLowest = TaskMetricsCalculator.filterTasks(
        tasks,
        sort: TaskSortOption.progressLowest,
      );
      expect(progLowest.first.progressPercent, 75);
    });
  });
}
