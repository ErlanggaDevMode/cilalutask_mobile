import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/state/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskController Unit Tests', () {
    test('Initializes with default tasks', () {
      final controller = TaskController();
      addTearDown(() => controller.dispose());

      expect(controller.tasks.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('createTask adds task and triggers onTaskCreated', () async {
      Task? capturedTask;
      final controller = TaskController(
        onTaskCreated: (task) => capturedTask = task,
      );
      addTearDown(() => controller.dispose());

      final newTask = Task(
        id: 'task-test-99',
        title: 'Verifikasi Backup AWS S3',
        description: 'Pastikan snapshot terenkripsi KMS.',
        division: 'IT Core',
        deadlineLabel: 'Besok',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        progressPercent: 20,
        subtasks: const [
          Subtask(id: 'st-sub-1', title: 'Cek log KMS', completed: false),
        ],
        assignee: const Assignee(
          id: 'emp-3',
          name: 'Kevin Maulana',
          shortName: 'Kevin',
          avatar: '',
          division: 'IT Core',
          role: 'Tech Lead',
        ),
      );

      await controller.createTask('TEST-CO', newTask);

      expect(controller.tasks.first.id, 'task-test-99');
      expect(capturedTask?.id, 'task-test-99');
    });

    test('deleteTask removes task from memory and repository', () async {
      final controller = TaskController();
      addTearDown(() => controller.dispose());

      final firstId = controller.tasks.first.id;
      await controller.deleteTask('TEST-CO', firstId);

      expect(controller.tasks.any((t) => t.id == firstId), isFalse);
    });

    test('saveProgress updates subtasks and completion status', () async {
      int? reportedProgress;
      final controller = TaskController(
        onTaskProgressUpdated: (t, p) => reportedProgress = p,
      );
      addTearDown(() => controller.dispose());

      final firstId = controller.tasks.first.id;
      final updated = await controller.saveProgress('TEST-CO', firstId, const [
        Subtask(id: 'st-1', title: 'Subtask 1', completed: true),
      ], 100);

      expect(updated?.status, TaskStatus.completed);
      expect(updated?.progressPercent, 100);
      expect(reportedProgress, 100);
    });

    test('approveTask marks task completed and needsReview false', () async {
      Task? approved;
      final controller = TaskController(onTaskApproved: (t) => approved = t);
      addTearDown(() => controller.dispose());

      final firstId = controller.tasks.first.id;
      final result = await controller.approveTask('TEST-CO', firstId);

      expect(result?.status, TaskStatus.completed);
      expect(result?.needsReview, isFalse);
      expect(approved?.id, firstId);
    });

    test('clear resets task list', () {
      final controller = TaskController();
      addTearDown(() => controller.dispose());

      controller.clear();
      expect(controller.tasks.isEmpty, isTrue);
    });
  });
}
