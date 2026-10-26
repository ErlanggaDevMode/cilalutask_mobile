import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/sop.dart';
import 'package:cilalutask_mobile/repositories/data_exception.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DATA ARCHITECTURE & MULTI-TENANT ISOLATION', () {
    test('1. Company A and Company B data isolation on switch', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      await controller.initStorage();

      // Register Company A
      await controller.registerCompany(
        name: 'PT Maju Terus',
        code: 'MAJU-01',
        adminName: 'Admin Maju',
        adminEmail: 'admin@maju.id',
        adminPassword: 'Password123!',
      );

      // Create Task for Company A
      await controller.createTask(
        const Task(
          id: 'task-maju-1',
          title: 'Tugas Internal Maju',
          description: 'Rahasia Perusahaan Maju',
          division: 'Operasional',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Hari Ini',
          subtasks: [],
          assignee: Assignee(
            id: 'emp-maju-1',
            name: 'Staf Maju',
            shortName: 'Staf',
            avatar: '',
            division: 'Operasional',
            role: 'Staf',
          ),
          progressPercent: 20,
        ),
      );

      expect(controller.currentCompany.code, 'MAJU-01');
      expect(controller.tasks.any((t) => t.id == 'task-maju-1'), isTrue);

      // Register Company B
      await controller.registerCompany(
        name: 'PT Sukses Mandiri',
        code: 'SUKSES-02',
        adminName: 'Admin Sukses',
        adminEmail: 'admin@sukses.id',
        adminPassword: 'Password123!',
      );

      // Verify Company B starts pure blank and does NOT have Company A's task
      expect(controller.currentCompany.code, 'SUKSES-02');
      expect(controller.tasks.any((t) => t.id == 'task-maju-1'), isFalse);
      expect(controller.tasks.isEmpty, isTrue);

      // Switch back to Company A
      final compA = controller.companies.firstWhere((c) => c.code == 'MAJU-01');
      await controller.switchCompany(compA);

      // Verify Company A has its own task restored
      expect(controller.currentCompany.code, 'MAJU-01');
      expect(controller.tasks.any((t) => t.id == 'task-maju-1'), isTrue);
    });

    test(
      '2. Deleted tasks do NOT resurrect after restart or re-sync',
      () async {
        // Step 1: Controller 1 creates and deletes a task
        final controller1 = AppStateController();
        await controller1.initStorage();

        await controller1.registerCompany(
          name: 'PT Hapus Data',
          code: 'HAPUS-99',
          adminName: 'Admin Hapus',
          adminEmail: 'admin@hapus.id',
          adminPassword: 'Password123!',
        );

        const taskToKeep = Task(
          id: 'task-keep',
          title: 'Tugas yang dipertahankan',
          description: 'Tugas valid',
          division: 'Operasional',
          priority: PriorityType.medium,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Besok',
          subtasks: [],
          assignee: Assignee(
            id: 'emp-1',
            name: 'Staf',
            shortName: 'Staf',
            avatar: '',
            division: 'Operasional',
            role: 'Staf',
          ),
          progressPercent: 10,
        );

        const taskToDelete = Task(
          id: 'task-obsolete',
          title: 'Tugas Usang yang Harus Dihapus',
          description: 'Akan dihapus',
          division: 'Operasional',
          priority: PriorityType.low,
          status: TaskStatus.notStarted,
          deadlineLabel: 'Minggu Depan',
          subtasks: [],
          assignee: Assignee(
            id: 'emp-1',
            name: 'Staf',
            shortName: 'Staf',
            avatar: '',
            division: 'Operasional',
            role: 'Staf',
          ),
          progressPercent: 0,
        );

        await controller1.createTask(taskToKeep);
        await controller1.createTask(taskToDelete);

        expect(controller1.tasks.length, 2);
        expect(controller1.tasks.any((t) => t.id == 'task-obsolete'), isTrue);

        // Explicit delete
        await controller1.deleteTask('task-obsolete');

        expect(controller1.tasks.length, 1);
        expect(controller1.tasks.any((t) => t.id == 'task-obsolete'), isFalse);
        expect(controller1.tasks.first.id, 'task-keep');

        controller1.dispose();

        // Step 2: Fresh Controller 2 reloads from storage
        final controller2 = AppStateController();
        addTearDown(() => controller2.dispose());
        await controller2.initStorage();

        // Verify deleted task does NOT resurrect from cache/storage
        expect(controller2.tasks.any((t) => t.id == 'task-obsolete'), isFalse);
        expect(controller2.tasks.any((t) => t.id == 'task-keep'), isTrue);
      },
    );

    test(
      '3. SOP and Chat deletion propagate to local cache correctly',
      () async {
        final controller = AppStateController();
        addTearDown(() => controller.dispose());
        await controller.initStorage();

        await controller.registerCompany(
          name: 'PT Dokumen Sop',
          code: 'SOP-33',
          adminName: 'Admin SOP',
          adminEmail: 'admin@sop.id',
          adminPassword: 'Password123!',
        );

        const newSop = SOPDocument(
          id: 'sop-test-1',
          code: 'SOP/01/TEST',
          title: 'SOP Prosedur Keamanan',
          category: 'Operasional',
          version: '1.0',
          lastUpdatedText: 'Hari Ini',
        );

        await controller.addSop(newSop);
        expect(controller.sops.any((s) => s.id == 'sop-test-1'), isTrue);

        // Delete SOP
        await controller.deleteSop('sop-test-1');
        expect(controller.sops.any((s) => s.id == 'sop-test-1'), isFalse);

        // Send and Delete Chat Message
        await controller.sendChatMessage(content: 'Pesan rahasia sementara');
        expect(
          controller.messages.any(
            (m) => m.content == 'Pesan rahasia sementara',
          ),
          isTrue,
        );

        final msgId = controller.messages
            .firstWhere((m) => m.content == 'Pesan rahasia sementara')
            .id;
        await controller.deleteChatMessage(msgId);
        expect(controller.messages.any((m) => m.id == msgId), isFalse);
      },
    );

    test('4. Logout clears cache and state; prevents lingering data', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      await controller.initStorage();

      await controller.registerCompany(
        name: 'PT Logout Test',
        code: 'LOGOUT-11',
        adminName: 'Sarah',
        adminEmail: 'sarah@logout.id',
        adminPassword: 'Password123!',
      );

      await controller.createTask(
        const Task(
          id: 'task-sec',
          title: 'Top Secret Data',
          description: '',
          division: 'Operasional',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: '',
          subtasks: [],
          assignee: Assignee(
            id: 'e1',
            name: 'Sarah',
            shortName: 'Sarah',
            avatar: '',
            division: 'Operasional',
            role: 'Admin',
          ),
          progressPercent: 0,
        ),
      );

      expect(controller.isAuthenticated, isTrue);
      expect(controller.tasks.isNotEmpty, isTrue);

      // Execute Logout
      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.tasks.isEmpty, isTrue);
      expect(controller.sops.isEmpty, isTrue);
      expect(controller.employees.isEmpty, isTrue);
      expect(controller.messages.isEmpty, isTrue);
      expect(controller.notifications.isEmpty, isTrue);
      expect(controller.activities.isEmpty, isTrue);
    });

    test('5. Atomic Join Request acceptance creates employee and notification atomically', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      await controller.initStorage();

      await controller.registerCompany(
        name: 'PT Batch Test',
        code: 'BATCH-55',
        adminName: 'Admin Batch',
        adminEmail: 'admin@batch.id',
        adminPassword: 'Password123!',
      );

      final req = await controller.submitJoinRequest(
        companyCode: 'BATCH-55',
        name: 'Bambang Kusuma',
        email: 'bambang@gmail.com',
        password: 'Password123!',
        division: 'Teknologi',
        role: 'Frontend Dev',
      );

      expect(controller.pendingJoinRequestsCount, 1);
      expect(controller.employees.isEmpty, isTrue);

      // Accept join request (Atomic Batch)
      await controller.acceptJoinRequest(req.id);

      expect(controller.pendingJoinRequestsCount, 0);
      expect(controller.employees.length, 1);
      expect(controller.employees.first.name, 'Bambang Kusuma');
      expect(controller.employees.first.role, 'Frontend Dev');
      expect(
        controller.notifications.any((n) => n.title.contains('Baru Bergabung')),
        isTrue,
      );
    });

    test(
      '6. DataException handles and surfaces error classifications explicitly',
      () {
        const permError = DataException(
          message: 'Akses ditolak oleh Security Rules Firestore.',
          code: DataErrorCode.permissionDenied,
        );

        expect(permError.code, DataErrorCode.permissionDenied);
        expect(permError.toString(), contains('permissionDenied'));

        const netError = DataException(
          message: 'Server offline',
          code: DataErrorCode.networkUnavailable,
        );

        expect(netError.code, DataErrorCode.networkUnavailable);
      },
    );
  });
}
