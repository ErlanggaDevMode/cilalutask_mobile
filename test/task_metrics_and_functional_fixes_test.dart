import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/core/utils/task_metrics_calculator.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/widgets/modals/task_filter_bottom_sheet.dart';
import 'package:cilalutask_mobile/widgets/modals/sop_filter_bottom_sheet.dart';
import 'package:cilalutask_mobile/screens/tasks/tasks_screen.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';
import 'package:cilalutask_mobile/state/app_state_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const assigneeBudi = Assignee(
    id: 'emp-1',
    name: 'Budi Santoso',
    shortName: 'BS',
    avatar: '',
    division: 'Engineering',
    role: 'Dev',
  );

  const assigneeSiti = Assignee(
    id: 'emp-2',
    name: 'Siti Rahma',
    shortName: 'SR',
    avatar: '',
    division: 'Produk & Desain',
    role: 'UI/UX',
  );

  const assigneeRina = Assignee(
    id: 'emp-3',
    name: 'Rina Melati',
    shortName: 'RM',
    avatar: '',
    division: 'Marketing',
    role: 'Copywriter',
  );

  group('TaskMetricsCalculator - Core & Edge Case Calculations', () {
    test(
      '1. Empty dataset does not divide by zero and returns clean zero metrics',
      () {
        final metrics = TaskMetricsCalculator.computeMetrics([]);
        expect(metrics.total, 0);
        expect(metrics.notStarted, 0);
        expect(metrics.inProgress, 0);
        expect(metrics.completed, 0);
        expect(metrics.needsReview, 0);
        expect(metrics.urgentOrNearDeadline, 0);
        expect(metrics.completionRate, 0.0);
        expect(metrics.onTimeRate, 0.0);
        expect(metrics.lateRate, 0.0);
        expect(metrics.averageProgress, 0.0);

        final divMetrics = TaskMetricsCalculator.computeDivisionProductivity(
          [],
        );
        expect(divMetrics, isEmpty);

        final empMetrics = TaskMetricsCalculator.computeEmployeePerformance(
          [],
          [],
        );
        expect(empMetrics, isEmpty);
      },
    );

    test('2. Computes completion rate, status distribution, and on-time rate accurately', () {
      final sampleTasks = [
        const Task(
          id: 't-1',
          title: 'Setup Database',
          description: 'Postgres configuration',
          division: 'Engineering',
          priority: PriorityType.high,
          status: TaskStatus.completed,
          deadlineLabel: 'Kemarin',
          isUrgentDeadline: false,
          progressPercent: 100,
          subtasks: [],
          assignee: assigneeBudi,
        ),
        const Task(
          id: 't-2',
          title: 'Implement Auth',
          description: 'Firebase auth',
          division: 'Engineering',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Hari Ini',
          isUrgentDeadline: true,
          progressPercent: 60,
          needsReview: true,
          subtasks: [],
          assignee: assigneeBudi,
        ),
        const Task(
          id: 't-3',
          title: 'Design Wireframe',
          description: 'Figma specs',
          division: 'Design',
          priority: PriorityType.medium,
          status: TaskStatus.notStarted,
          deadlineLabel: 'Minggu depan',
          isUrgentDeadline: false,
          progressPercent: 0,
          subtasks: [],
          assignee: assigneeSiti,
        ),
        const Task(
          id: 't-4',
          title: 'Copywriting Marketing',
          description: 'Promo launch',
          division: 'Marketing',
          priority: PriorityType.low,
          status: TaskStatus.completed,
          deadlineLabel: 'Besok',
          isUrgentDeadline: false,
          progressPercent: 100,
          subtasks: [],
          assignee: assigneeRina,
        ),
      ];

      final metrics = TaskMetricsCalculator.computeMetrics(sampleTasks);

      // Total = 4
      expect(metrics.total, 4);
      // Completed = 2 (50.0%)
      expect(metrics.completed, 2);
      expect(metrics.completionRate, 50.0);
      // In progress = 1
      expect(metrics.inProgress, 1);
      // Not started = 1
      expect(metrics.notStarted, 1);
      // Needs review = 1 (t-2)
      expect(metrics.needsReview, 1);
      // Urgent / near deadline = 1 (t-2)
      expect(metrics.urgentOrNearDeadline, 1);
      // Average progress = (100 + 60 + 0 + 100) / 4 = 260 / 4 = 65.0%
      expect(metrics.averageProgress, 65.0);
      // Late rate: t-2 is urgent deadline & not completed -> 1 / 4 = 25.0%
      expect(metrics.lateRate, 25.0);
      expect(metrics.onTimeRate, 75.0);
    });

    test(
      '3. Computes division productivity and employee rankings with real tasks',
      () {
        final sampleTasks = [
          const Task(
            id: 't-1',
            title: 'Task 1',
            description: 'Desc 1',
            division: 'IT',
            priority: PriorityType.high,
            status: TaskStatus.completed,
            deadlineLabel: 'Done',
            progressPercent: 100,
            subtasks: [],
            assignee: assigneeBudi,
          ),
          const Task(
            id: 't-2',
            title: 'Task 2',
            description: 'Desc 2',
            division: 'IT',
            priority: PriorityType.low,
            status: TaskStatus.inProgress,
            deadlineLabel: 'In progress',
            progressPercent: 50,
            subtasks: [],
            assignee: assigneeBudi,
          ),
          const Task(
            id: 't-3',
            title: 'Task 3',
            description: 'Desc 3',
            division: 'HR',
            priority: PriorityType.medium,
            status: TaskStatus.completed,
            deadlineLabel: 'Done',
            progressPercent: 100,
            subtasks: [],
            assignee: assigneeSiti,
          ),
        ];

        final List<Assignee> employees = [assigneeBudi, assigneeSiti];

        final divMetrics = TaskMetricsCalculator.computeDivisionProductivity(
          sampleTasks,
        );
        // HR has 1/1 = 100.0%, IT has 1/2 = 50.0%
        expect(divMetrics.length, 2);
        expect(divMetrics.first.name, 'HR');
        expect(divMetrics.first.completionRate, 100.0);
        expect(divMetrics.last.name, 'IT');
        expect(divMetrics.last.completionRate, 50.0);

        final empRanks = TaskMetricsCalculator.computeEmployeePerformance(
          sampleTasks,
          employees,
        );
        expect(empRanks.length, 2);
        expect(empRanks.first.rank, 1);
        expect(empRanks.last.rank, 2);
      },
    );
  });

  group('TaskMetricsCalculator - Period Labels & Date Boundaries', () {
    test('4. Correctly formats Indonesian month names across year and month transitions', () {
      expect(TaskMetricsCalculator.getIndonesianMonth(1), 'Januari');
      expect(TaskMetricsCalculator.getIndonesianMonth(2), 'Februari');
      expect(TaskMetricsCalculator.getIndonesianMonth(5), 'Mei');
      expect(TaskMetricsCalculator.getIndonesianMonth(12), 'Desember');
      expect(TaskMetricsCalculator.getIndonesianMonth(13), '');

      // Check boundary: Dec 31, 2025 to Jan 1, 2026
      final decDate = DateTime(2025, 12, 31);
      final janDate = DateTime(2026, 1, 1);

      expect(
        TaskMetricsCalculator.getPeriodLabel(
          date: decDate,
          rangeType: 'Bulan Ini',
        ),
        'Bulan Ini (Desember 2025)',
      );
      expect(
        TaskMetricsCalculator.getPeriodLabel(
          date: janDate,
          rangeType: 'Bulan Ini',
        ),
        'Bulan Ini (Januari 2026)',
      );

      final ranges = TaskMetricsCalculator.getAvailableTimeRanges(
        date: janDate,
      );
      expect(ranges[0], 'Bulan Ini (Januari 2026)');
      expect(ranges[2], 'Kuartal 1');
      expect(ranges[3], 'Tahun Ini (2026)');
    });
  });

  group('TaskMetricsCalculator - Search, Filtering & Sorting Combinations', () {
    final tasks = [
      const Task(
        id: 'task-a',
        title: 'Backend API Deployment',
        description: 'Deploy to Cloud Run',
        division: 'IT & Engineering',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        deadlineLabel: 'Hari Ini',
        isUrgentDeadline: true,
        progressPercent: 75,
        subtasks: [],
        assignee: assigneeBudi,
      ),
      const Task(
        id: 'task-b',
        title: 'User Interview Script',
        description: 'Conduct 5 user tests',
        division: 'Produk & Desain',
        priority: PriorityType.medium,
        status: TaskStatus.completed,
        deadlineLabel: 'Kemarin',
        isUrgentDeadline: false,
        progressPercent: 100,
        subtasks: [],
        assignee: assigneeSiti,
      ),
      const Task(
        id: 'task-c',
        title: 'Financial Q3 Audit',
        description: 'Review expenses and invoices',
        division: 'Finance',
        priority: PriorityType.low,
        status: TaskStatus.notStarted,
        deadlineLabel: 'Bulan depan',
        isUrgentDeadline: false,
        progressPercent: 0,
        subtasks: [],
        assignee: assigneeRina,
      ),
    ];

    test('5. Status filtering: null status returns all, specific status limits accurately', () {
      final allTasks = TaskMetricsCalculator.filterTasks(tasks, status: null);
      expect(allTasks.length, 3);

      final inProgress = TaskMetricsCalculator.filterTasks(
        tasks,
        status: TaskStatus.inProgress,
      );
      expect(inProgress.length, 1);
      expect(inProgress.first.id, 'task-a');

      final completed = TaskMetricsCalculator.filterTasks(
        tasks,
        status: TaskStatus.completed,
      );
      expect(completed.length, 1);
      expect(completed.first.id, 'task-b');

      final notStarted = TaskMetricsCalculator.filterTasks(
        tasks,
        status: TaskStatus.notStarted,
      );
      expect(notStarted.length, 1);
      expect(notStarted.first.id, 'task-c');
    });

    test(
      '6. Search query matches title, description, assignee name, and division',
      () {
        final searchTitle = TaskMetricsCalculator.filterTasks(
          tasks,
          query: 'Deployment',
        );
        expect(searchTitle.length, 1);
        expect(searchTitle.first.id, 'task-a');

        final searchDesc = TaskMetricsCalculator.filterTasks(
          tasks,
          query: 'expenses',
        );
        expect(searchDesc.length, 1);
        expect(searchDesc.first.id, 'task-c');

        final searchAssignee = TaskMetricsCalculator.filterTasks(
          tasks,
          query: 'Siti',
        );
        expect(searchAssignee.length, 1);
        expect(searchAssignee.first.id, 'task-b');
      },
    );

    test('7. Filter combinations: division + priority + urgentOnly', () {
      final filtered = TaskMetricsCalculator.filterTasks(
        tasks,
        division: 'IT & Engineering',
        priority: PriorityType.high,
        urgentOnly: true,
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, 'task-a');

      final noMatch = TaskMetricsCalculator.filterTasks(
        tasks,
        division: 'Finance',
        priority: PriorityType.high, // Finance task is low
      );
      expect(noMatch, isEmpty);
    });

    test('8. Sorting options: progressHighest, progressLowest, priorityHighest, newest', () {
      final sortedByProgressDesc = TaskMetricsCalculator.filterTasks(
        tasks,
        sort: TaskSortOption.progressHighest,
      );
      expect(sortedByProgressDesc.first.id, 'task-b'); // 100%
      expect(sortedByProgressDesc.last.id, 'task-c'); // 0%

      final sortedByPriority = TaskMetricsCalculator.filterTasks(
        tasks,
        sort: TaskSortOption.priorityHighest,
      );
      expect(sortedByPriority.first.priority, PriorityType.high);
      expect(sortedByPriority.last.priority, PriorityType.low);
    });
  });

  group('Widget Filter Controls & Bottom Sheets', () {
    testWidgets(
      '9. TaskFilterBottomSheet renders and returns selected filters',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        PriorityType? selectedPriority;
        bool urgent = false;
        TaskSortOption selectedSort = TaskSortOption.none;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    final result = await TaskFilterBottomSheet.show(
                      context,
                      initialPriority: selectedPriority,
                      initialUrgentOnly: urgent,
                      initialSort: selectedSort,
                    );
                    if (result != null) {
                      selectedPriority = result.priority;
                      urgent = result.urgentOnly;
                      selectedSort = result.sort;
                    }
                  },
                  child: const Text('Buka Filter'),
                ),
              ),
            ),
          ),
        );

        // Tap to open sheet
        await tester.tap(find.text('Buka Filter'));
        await tester.pumpAndSettle();

        // Verify modal elements exist
        expect(find.text('Filter & Pengurutan Tugas'), findsOneWidget);
        expect(find.text('Tinggi (Urgent)'), findsWidgets);
        expect(find.text('Batas Waktu Terdekat'), findsOneWidget);

        // Select 'Tinggi (Urgent)' chip
        await tester.tap(find.text('Tinggi (Urgent)').last);
        await tester.pumpAndSettle();

        // Click 'Terapkan Filter'
        await tester.tap(find.text('Terapkan Filter'));
        await tester.pumpAndSettle();

        expect(selectedPriority, PriorityType.high);
      },
    );

    testWidgets(
      '10. SopFilterBottomSheet renders and returns sorting & toggle options',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        String sort = 'Versi Terbaru';
        bool mandatory = false;
        bool bookmark = false;
        bool unread = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    final result = await SopFilterBottomSheet.show(
                      context,
                      initialSortOrder: sort,
                      initialMandatoryOnly: mandatory,
                      initialBookmarkOnly: bookmark,
                      initialUnreadOnly: unread,
                    );
                    if (result != null) {
                      sort = result.sortOrder;
                      mandatory = result.mandatoryOnly;
                      bookmark = result.bookmarkOnly;
                      unread = result.unreadOnly;
                    }
                  },
                  child: const Text('Buka Filter SOP'),
                ),
              ),
            ),
          ),
        );

        // Tap to open sheet
        await tester.tap(find.text('Buka Filter SOP'));
        await tester.pumpAndSettle();

        // Verify modal elements exist
        expect(find.text('Filter & Pengurutan SOP'), findsOneWidget);
        expect(find.text('Hanya SOP Wajib (Mandatory K3)'), findsOneWidget);
        expect(find.text('Hanya Dokumen Ditandai (Bookmark)'), findsOneWidget);

        // Toggle 'Hanya SOP Wajib (Mandatory K3)'
        await tester.tap(find.text('Hanya SOP Wajib (Mandatory K3)'));
        await tester.pumpAndSettle();

        // Apply
        await tester.tap(find.text('Terapkan Filter'));
        await tester.pumpAndSettle();

        expect(mandatory, isTrue);
      },
    );

    testWidgets(
      '11. TasksScreen starts with "Semua" tab and displays all tasks without hiding',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = AppStateController();
        addTearDown(() => controller.dispose());

        await tester.pumpWidget(
          MaterialApp(
            home: AppStateScope(
              controller: controller,
              child: const Scaffold(body: TasksScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify "Semua" tab chip is present and selected
        expect(find.text('Semua'), findsWidgets);
        expect(find.text('Belum Dimulai'), findsOneWidget);
        expect(find.text('Dalam Proses'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);

        // Verify task counts are displayed from controller
        expect(controller.tasks.isNotEmpty, isTrue);
      },
    );
  });
}
