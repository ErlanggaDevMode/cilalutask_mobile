import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/main.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';
import 'package:cilalutask_mobile/models/user_role.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/employee.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'End-to-End Integration Flow: Launch -> Sign In -> Load Data -> Create/Update/Delete Task -> Switch Company -> Logout',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = AppStateController();
      addTearDown(() => controller.dispose());

      await tester.pumpWidget(CilalutaskApp(controller: controller));
      await tester.pumpAndSettle();

      // ───────────────────────────────────────────────────────────────────────
      // Step 1: Initial Launch (Unauthenticated State)
      // ───────────────────────────────────────────────────────────────────────
      expect(controller.isAuthenticated, isFalse);
      expect(find.text('CILALUTASK'), findsOneWidget);
      expect(find.text('Masuk sebagai Admin'), findsOneWidget);

      // ───────────────────────────────────────────────────────────────────────
      // Step 2: Sign In as Admin
      // ───────────────────────────────────────────────────────────────────────
      final loginBtn = find.text('Masuk sebagai Admin');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.isAdmin, isTrue);
      expect(controller.currentRole, UserRole.admin);
      expect(find.text('Beranda'), findsWidgets);
      expect(find.text('Tugas'), findsWidgets);

      // ───────────────────────────────────────────────────────────────────────
      // Step 3: Load Data & Verify Initial Company
      // ───────────────────────────────────────────────────────────────────────
      expect(controller.currentCompany.code, 'CILALU-88');
      final initialTaskCount = controller.tasks.length;
      expect(initialTaskCount, greaterThan(0));

      // ───────────────────────────────────────────────────────────────────────
      // Step 4: Create Task
      // ───────────────────────────────────────────────────────────────────────
      final newTask = Task(
        id: 'task-e2e-integration',
        title: 'Verifikasi Automated Flow CI/CD',
        description: 'Tugas pengujian end-to-end integration',
        division: 'Teknologi',
        assignee: controller.employees.isNotEmpty
            ? controller.employees.first
            : const Assignee(
                id: 'admin',
                name: 'Administrator',
                shortName: 'AD',
                avatar: 'AD',
                division: 'Manajemen',
                role: 'Admin',
              ),
        deadlineLabel: 'Hari ini',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        progressPercent: 30,
        subtasks: const [
          Subtask(id: 'st-1', title: 'Jalankan unit tests', completed: true),
          Subtask(
            id: 'st-2',
            title: 'Jalankan integration tests',
            completed: false,
          ),
        ],
      );

      await controller.createTask(newTask);
      expect(
        controller.tasks.any((t) => t.id == 'task-e2e-integration'),
        isTrue,
      );

      // ───────────────────────────────────────────────────────────────────────
      // Step 5: Update Task Progress & Subtasks
      // ───────────────────────────────────────────────────────────────────────
      await controller.saveProgress('task-e2e-integration', const [
        Subtask(id: 'st-1', title: 'Jalankan unit tests', completed: true),
        Subtask(
          id: 'st-2',
          title: 'Jalankan integration tests',
          completed: true,
        ),
      ], 100);

      final updatedTask = controller.tasks.firstWhere(
        (t) => t.id == 'task-e2e-integration',
      );
      expect(updatedTask.progressPercent, 100);
      expect(updatedTask.status, TaskStatus.completed);

      // ───────────────────────────────────────────────────────────────────────
      // Step 6: Delete Task (Admin Destructive Action)
      // ───────────────────────────────────────────────────────────────────────
      await controller.deleteTask('task-e2e-integration');
      expect(
        controller.tasks.any((t) => t.id == 'task-e2e-integration'),
        isFalse,
      );

      // ───────────────────────────────────────────────────────────────────────
      // Step 7: Multi-Company Isolation (Switch/Register new Company)
      // ───────────────────────────────────────────────────────────────────────
      await controller.registerCompany(
        name: 'PT Integrasi Nusantara',
        code: 'NUSANTARA-88',
        adminName: 'Hendro Kusumo',
        adminEmail: 'hendro@nusantara.id',
        adminPassword: 'Password123!',
        industry: 'Manufaktur & Logistik',
      );

      expect(controller.currentCompany.code, 'NUSANTARA-88');
      expect(controller.currentCompany.name, 'PT Integrasi Nusantara');
      expect(controller.isBlankMode, isTrue);
      expect(controller.tasks.isEmpty, isTrue);
      expect(controller.sops.isEmpty, isTrue);

      // ───────────────────────────────────────────────────────────────────────
      // Step 8: Logout
      // ───────────────────────────────────────────────────────────────────────
      await controller.logout();
      await tester.pumpWidget(CilalutaskApp(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.isAuthenticated, isFalse);
      expect(find.text('Masuk sebagai Admin'), findsOneWidget);
    },
  );
}
