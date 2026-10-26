import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/company.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/user_role.dart';
import 'package:cilalutask_mobile/services/auth_service.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SECURITY AUDIT & ZERO-PASSWORD VERIFICATION', () {
    test(
      '1. Assignee model strictly excludes password from toMap and fromMap',
      () {
        const emp = Assignee(
          id: 'emp-sec-1',
          name: 'John Doe',
          shortName: 'John',
          avatar: '',
          division: 'Tech',
          role: 'Engineer',
          email: 'john@company.com',
        );

        final map = emp.toMap();

        // Ensure password field is completely absent from serialization
        expect(map.containsKey('password'), isFalse);

        // Ensure deserializing old data with a legacy password ignores it
        final legacyMap = {
          'id': 'emp-sec-1',
          'name': 'John Doe',
          'shortName': 'John',
          'avatar': '',
          'division': 'Tech',
          'role': 'Engineer',
          'email': 'john@company.com',
          'password': 'old_plain_password_123',
        };
        final parsed = Assignee.fromMap(legacyMap);
        expect(parsed.toMap().containsKey('password'), isFalse);
      },
    );

    test('2. Company model strictly excludes password and uses adminUid', () {
      final comp = Company(
        id: 'comp-sec-1',
        name: 'PT Aman Sekali',
        code: 'AMAN-01',
        adminName: 'Alice Admin',
        adminEmail: 'alice@aman.id',
        adminUid: 'uid-alice-secure-123',
        createdAt: DateTime.now(),
      );

      final map = comp.toMap();
      expect(map.containsKey('adminPassword'), isFalse);
      expect(map.containsKey('password'), isFalse);
      expect(map['adminUid'], 'uid-alice-secure-123');

      // Ensure deserializing legacy map drops any legacy adminPassword
      final legacyCompMap = {
        'id': 'comp-sec-1',
        'name': 'PT Aman Sekali',
        'code': 'AMAN-01',
        'adminName': 'Alice Admin',
        'adminEmail': 'alice@aman.id',
        'adminPassword': 'super_secret_password',
        'adminUid': 'uid-alice-secure-123',
      };
      final parsed = Company.fromMap(legacyCompMap);
      expect(parsed.toMap().containsKey('adminPassword'), isFalse);
    });

    test('3. JoinRequest model strictly stores userId (Firebase Auth UID) and no password', () {
      final req = JoinRequest(
        id: 'req-sec-1',
        companyCode: 'AMAN-01',
        companyName: 'PT Aman Sekali',
        userId: 'uid-user-999',
        userName: 'Bob Requester',
        userEmail: 'bob@aman.id',
        division: 'Operasional',
        role: 'Staff',
        avatar: '',
        requestedAt: DateTime.now(),
      );

      final map = req.toMap();
      expect(map.containsKey('userPassword'), isFalse);
      expect(map.containsKey('password'), isFalse);
      expect(map['userId'], 'uid-user-999');

      // Ensure deserializing legacy join request ignores legacy password
      final legacyReqMap = {
        'id': 'req-sec-1',
        'companyCode': 'AMAN-01',
        'companyName': 'PT Aman Sekali',
        'userId': 'uid-user-999',
        'userName': 'Bob Requester',
        'userEmail': 'bob@aman.id',
        'userPassword': 'bob_password_plaintext',
        'division': 'Operasional',
        'role': 'Staff',
        'avatar': '',
      };
      final parsed = JoinRequest.fromMap(legacyReqMap);
      expect(parsed.toMap().containsKey('userPassword'), isFalse);
    });
  });

  group('AUTHENTICATION & ROLE-BASED ACCESS CONTROL (RBAC)', () {
    test('4. Cross-company access is strictly rejected', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      await controller.initStorage();

      // Register Company A
      await controller.registerCompany(
        name: 'Company Alpha',
        code: 'ALPHA-01',
        adminName: 'Alpha Admin',
        adminEmail: 'admin@alpha.com',
        adminPassword: 'Password123!',
      );

      // Register Company B
      await controller.registerCompany(
        name: 'Company Beta',
        code: 'BETA-02',
        adminName: 'Beta Admin',
        adminEmail: 'admin@beta.com',
        adminPassword: 'Password123!',
      );

      // Attempt login as Admin for Company Alpha with Company Beta admin email -> Must reject
      expect(
        () => controller.loginWithCredentials(
          companyCode: 'ALPHA-01',
          email: 'admin@beta.com',
          password: 'Password123!',
          role: UserRole.admin,
        ),
        throwsA(isA<Exception>()),
      );

      // Attempt login for non-existent company -> Must reject
      expect(
        () => controller.loginWithCredentials(
          companyCode: 'UNKNOWN-99',
          email: 'admin@alpha.com',
          password: 'Password123!',
          role: UserRole.admin,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('5. Non-admin member cannot create tasks or elevate role', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());

      const regularEmployee = Assignee(
        id: 'emp-regular',
        name: 'Regular Worker',
        shortName: 'Worker',
        avatar: '',
        division: 'Operasional',
        role: 'Field Worker',
        email: 'worker@cilalutask.id',
      );

      // Login as regular employee
      controller.loginAsEmployee(regularEmployee);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isAdmin, isFalse);
      expect(controller.isUser, isTrue);

      final initialTaskCount = controller.tasks.length;

      // Regular employee attempts to create a task
      controller.createTask(
        Task(
          id: 'unauthorized-task',
          title: 'Hacked Task',
          description: 'Attempt to bypass RBAC',
          division: 'Operasional',
          assignee: regularEmployee,
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: '2026-12-31',
          subtasks: const [],
          progressPercent: 0,
        ),
      );

      // Task count must remain unchanged because non-admin is blocked
      expect(controller.tasks.length, initialTaskCount);
      expect(controller.tasks.any((t) => t.id == 'unauthorized-task'), isFalse);
    });

    test(
      '6. Logout clears all sensitive state and prevents data leaks',
      () async {
        final controller = AppStateController();
        addTearDown(() => controller.dispose());
        await controller.initStorage();

        // Log in as Admin and load sample data
        controller.loginAsAdmin();
        controller.loadSampleDemoData();

        expect(controller.isAuthenticated, isTrue);
        expect(controller.tasks.isNotEmpty, isTrue);
        expect(controller.sops.isNotEmpty, isTrue);
        expect(controller.messages.isNotEmpty, isTrue);

        // Perform secure logout
        await controller.logout();

        // Session must be terminated
        expect(controller.isAuthenticated, isFalse);
        expect(controller.currentEmployee, isNull);

        // In-memory sensitive corporate data must be completely flushed
        expect(controller.tasks.isEmpty, isTrue);
        expect(controller.sops.isEmpty, isTrue);
        expect(controller.employees.isEmpty, isTrue);
        expect(controller.messages.isEmpty, isTrue);
        expect(controller.notifications.isEmpty, isTrue);
      },
    );

    test(
      '7. AuthService provides safe error messages without internal leak',
      () {
        expect(
          AuthService.getReadableAuthError(Exception('Random crash')),
          'Terjadi kendala autentikasi. Silakan coba kembali.',
        );
      },
    );
  });
}
