import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cilalutask_mobile/main.dart';
import 'package:cilalutask_mobile/models/chat_model.dart';
import 'package:cilalutask_mobile/models/company.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/models/notification_item.dart';
import 'package:cilalutask_mobile/models/sop.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/user_role.dart';
import 'package:cilalutask_mobile/repositories/cilalu_repository.dart';
import 'package:cilalutask_mobile/repositories/data_exception.dart';
import 'package:cilalutask_mobile/screens/splash_screen.dart';
import 'package:cilalutask_mobile/services/auth_service.dart';
import 'package:cilalutask_mobile/services/firestore_service.dart';
import 'package:cilalutask_mobile/services/local_storage_service.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';

/// In-memory test double for [FirestoreService] to verify database CRUD,
/// batch operations, offline fallback, and reconciliation.
class MockCloudDatabaseService extends FirestoreService {
  bool cloudOnline = true;
  bool denyPermission = false;

  final Map<String, Company> companiesDb = {};
  final Map<String, Map<String, Task>> tasksDb = {};
  final Map<String, Map<String, SOPDocument>> sopsDb = {};
  final Map<String, Map<String, Assignee>> membersDb = {};
  final Map<String, Map<String, JoinRequest>> joinRequestsDb = {};
  final Map<String, Map<String, NotificationItem>> notificationsDb = {};
  final Map<String, Map<String, ChatMessage>> messagesDb = {};

  MockCloudDatabaseService() : super.forTesting();

  @override
  bool get isAvailable => cloudOnline;

  @override
  Future<void> init() async {
    if (!cloudOnline) {
      throw const DataException(
        message: 'Cloud offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
  }

  void _guard() {
    if (!cloudOnline) {
      throw const DataException(
        message: 'Database offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    if (denyPermission) {
      throw const DataException(
        message: 'Akses ditolak oleh Security Rules Firestore.',
        code: DataErrorCode.permissionDenied,
      );
    }
  }

  @override
  Future<void> saveCompany(Company company) async {
    _guard();
    companiesDb[company.code] = company;
  }

  @override
  Future<List<Company>> loadCompanies() async {
    _guard();
    return companiesDb.values.toList();
  }

  @override
  Future<void> createTask(String companyCode, Task task) async {
    _guard();
    tasksDb.putIfAbsent(companyCode, () => {})[task.id] = task;
  }

  @override
  Future<void> updateTask(String companyCode, Task task) async {
    _guard();
    tasksDb.putIfAbsent(companyCode, () => {})[task.id] = task;
  }

  @override
  Future<void> deleteTask(String companyCode, String taskId) async {
    _guard();
    tasksDb[companyCode]?.remove(taskId);
  }

  @override
  Future<List<Task>> loadTasks(String companyCode, {int limit = 100}) async {
    _guard();
    return (tasksDb[companyCode]?.values ?? const <Task>[])
        .take(limit)
        .toList();
  }

  @override
  Future<void> createSop(String companyCode, SOPDocument sop) async {
    _guard();
    sopsDb.putIfAbsent(companyCode, () => {})[sop.id] = sop;
  }

  @override
  Future<void> updateSop(String companyCode, SOPDocument sop) async {
    _guard();
    sopsDb.putIfAbsent(companyCode, () => {})[sop.id] = sop;
  }

  @override
  Future<void> deleteSop(String companyCode, String sopId) async {
    _guard();
    sopsDb[companyCode]?.remove(sopId);
  }

  @override
  Future<List<SOPDocument>> loadSops(String companyCode) async {
    _guard();
    return sopsDb[companyCode]?.values.toList() ?? [];
  }

  @override
  Future<void> createMember(String companyCode, Assignee member) async {
    _guard();
    membersDb.putIfAbsent(companyCode, () => {})[member.id] = member;
  }

  @override
  Future<List<Assignee>> loadEmployees(String companyCode) async {
    _guard();
    return membersDb[companyCode]?.values.toList() ?? [];
  }

  @override
  Future<void> saveJoinRequest(String companyCode, JoinRequest request) async {
    _guard();
    joinRequestsDb.putIfAbsent(companyCode, () => {})[request.id] = request;
  }

  @override
  Future<List<JoinRequest>> loadJoinRequests(String companyCode) async {
    _guard();
    return joinRequestsDb[companyCode]?.values.toList() ?? [];
  }

  @override
  Future<void> acceptJoinRequestBatch({
    required String companyCode,
    required JoinRequest request,
    required Assignee member,
    NotificationItem? welcomeNotif,
  }) async {
    _guard();
    joinRequestsDb.putIfAbsent(companyCode, () => {})[request.id] = request
        .copyWith(status: JoinRequestStatus.approved);
    membersDb.putIfAbsent(companyCode, () => {})[member.id] = member;
    if (welcomeNotif != null) {
      notificationsDb.putIfAbsent(companyCode, () => {})[welcomeNotif.id] =
          welcomeNotif;
    }
  }

  @override
  Future<void> saveMessage(String companyCode, ChatMessage message) async {
    _guard();
    messagesDb.putIfAbsent(companyCode, () => {})[message.id] = message;
  }

  @override
  Future<List<ChatMessage>> loadMessages(
    String companyCode, {
    String? channelId,
    int limit = 50,
  }) async {
    _guard();
    final all = messagesDb[companyCode]?.values ?? const <ChatMessage>[];
    if (channelId != null) {
      return all.where((m) => m.channelId == channelId).take(limit).toList();
    }
    return all.take(limit).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 1. SPLASH SCREEN ANIMATION (FADE IN & OUT + LOADING INDICATOR)
  // ─────────────────────────────────────────────────────────────────────────
  group('1. SPLASH SCREEN — LOGO FADE IN & OUT + LOADING INDICATOR', () {
    testWidgets(
      'SplashScreen renders cilalutask_logo.png on white background, animates fade-in -> hold -> fade-out with synchronized loading indicator, and triggers onCompleted',
      (WidgetTester tester) async {
        bool completed = false;

        await tester.pumpWidget(
          MaterialApp(home: SplashScreen(onCompleted: () => completed = true)),
        );
        await tester.pump();

        // Verify white background Scaffold
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.white);

        // Verify centered logo and loading indicators are present
        final logoFinder = find.byKey(const ValueKey('splash_logo_image'));
        final linearIndicatorFinder = find.byKey(
          const ValueKey('splash_loading_indicator'),
        );
        final circularIndicatorFinder = find.byKey(
          const ValueKey('splash_circular_indicator'),
        );

        expect(logoFinder, findsOneWidget);
        expect(linearIndicatorFinder, findsOneWidget);
        expect(circularIndicatorFinder, findsOneWidget);

        final imageWidget = tester.widget<Image>(logoFinder);
        expect(imageWidget.image, isA<AssetImage>());
        expect(
          (imageWidget.image as AssetImage).assetName,
          'cilalutask_logo.png',
        );

        // At t = 0ms: Opacity starts at 0.0, progress starts at 0.0
        Opacity opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        LinearProgressIndicator linearProgress = tester.widget(
          linearIndicatorFinder,
        );
        expect(opacityWidget.opacity, closeTo(0.0, 0.01));
        expect(linearProgress.value, closeTo(0.0, 0.01));
        expect(completed, isFalse);

        // At t = 450ms (mid fade-in phase of 900ms): Opacity is between 0 and 1
        await tester.pump(const Duration(milliseconds: 450));
        opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        linearProgress = tester.widget(linearIndicatorFinder);
        expect(opacityWidget.opacity, greaterThan(0.1));
        expect(opacityWidget.opacity, lessThan(1.0));
        expect(linearProgress.value!, greaterThan(0.0));

        // At t = 1200ms (inside hold phase 900ms..1700ms): Opacity is 1.0
        await tester.pump(const Duration(milliseconds: 750));
        opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        linearProgress = tester.widget(linearIndicatorFinder);
        expect(opacityWidget.opacity, closeTo(1.0, 0.01));
        expect(linearProgress.value!, greaterThan(0.3));
        expect(linearProgress.value!, lessThan(0.8));
        expect(completed, isFalse);

        // At t = 2100ms (mid fade-out phase 1700ms..2500ms): Opacity is decreasing
        await tester.pump(const Duration(milliseconds: 900));
        opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacityWidget.opacity, lessThan(0.9));
        expect(opacityWidget.opacity, greaterThan(0.0));
        expect(completed, isFalse);

        // At t = 2500ms+ (end of 2.5s cycle): Opacity reaches 0.0, progress reaches 1.0, onCompleted fires
        await tester.pump(const Duration(milliseconds: 500));
        opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        linearProgress = tester.widget(linearIndicatorFinder);
        expect(opacityWidget.opacity, closeTo(0.0, 0.01));
        expect(linearProgress.value, closeTo(1.0, 0.01));
        expect(completed, isTrue);
      },
    );

    testWidgets(
      'CilalutaskApp launches with SplashScreen and automatically transitions to LoginScreen or MainNavigationScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = AppStateController();
        addTearDown(() => controller.dispose());
        await controller.initStorage();

        await tester.pumpWidget(CilalutaskApp(controller: controller));

        // Initially displays SplashScreen
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('splash_logo_image')), findsOneWidget);

        // After splash animation completes (pumpAndSettle), transitions to LoginScreen
        await tester.pumpAndSettle();
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.text('CILALUTASK'), findsOneWidget);
        expect(find.text('Masuk sebagai Admin'), findsOneWidget);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. AUTH & LOGIN VERIFICATION
  // ─────────────────────────────────────────────────────────────────────────
  group('2. AUTHENTICATION & LOGIN FLOWS', () {
    test('Admin and Employee loginWithCredentials authenticate and authorize roles accurately', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      await controller.initStorage();

      // 1. Login as Admin of default company CILALU-88
      await controller.loginWithCredentials(
        companyCode: 'cilalu-88', // case-insensitive & trimmed
        email: '  sarah.pratama@cilulataks.id ',
        password: 'AdminPassword123!',
        role: UserRole.admin,
      );

      expect(controller.isAuthenticated, isTrue);
      expect(controller.isAdmin, isTrue);
      expect(controller.currentUserRole, UserRole.admin);
      expect(controller.currentCompany.code, 'CILALU-88');

      // Logout and verify session cleared
      await controller.logout();
      expect(controller.isAuthenticated, isFalse);

      // 2. Login as registered Employee of CILALU-88
      await controller.loginWithCredentials(
        companyCode: 'CILALU-88',
        email: 'budi.santoso@cilulataks.id',
        password: 'EmployeePassword123!',
        role: UserRole.user,
      );

      expect(controller.isAuthenticated, isTrue);
      expect(controller.isUser, isTrue);
      expect(controller.isAdmin, isFalse);
      expect(controller.currentEmployee, isNotNull);
      expect(controller.currentEmployee!.email, 'budi.santoso@cilulataks.id');
    });

    test('loginWithCredentials rejects unregistered employee and unauthorized admin email', () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      await controller.initStorage();

      // Unauthorized email trying to login as Admin
      await expectLater(
        controller.loginWithCredentials(
          companyCode: 'CILALU-88',
          email: 'intruder@hacker.com',
          password: 'Password123!',
          role: UserRole.admin,
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'tidak memiliki hak akses sebagai Administrator',
            ),
          ),
        ),
      );

      // Unregistered employee email trying to login as User
      await expectLater(
        controller.loginWithCredentials(
          companyCode: 'CILALU-88',
          email: 'not.member@cilalutask.id',
          password: 'Password123!',
          role: UserRole.user,
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains('belum terdaftar sebagai anggota'),
          ),
        ),
      );
    });

    test('AuthService maps all FirebaseAuthException codes to safe user-facing messages', () {
      expect(
        AuthService.getReadableAuthError(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        'Email atau password tidak valid.',
      );
      expect(
        AuthService.getReadableAuthError(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        contains('Email ini sudah terdaftar'),
      );
      expect(
        AuthService.getReadableAuthError(
          FirebaseAuthException(code: 'weak-password'),
        ),
        contains('minimal 6 karakter'),
      );
      expect(
        AuthService.getReadableAuthError(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        contains('Koneksi internet bermasalah'),
      );
      expect(
        AuthService.getReadableAuthError(
          FirebaseAuthException(code: 'too-many-requests'),
        ),
        contains('Terlalu banyak percobaan gagal'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. LOCAL STORAGE PERSISTENCE & CACHE MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────
  group(
    '3. LOCAL STORAGE SERVICE (SESSION, MULTI-TENANT CACHE & OFFLINE QUEUE)',
    () {
      test('LocalStorageService persists and clears auth session, company data, and pending offline tasks', () async {
        final storage = LocalStorageService();
        await storage.init();

        // 1. Save & Load Auth Session
        await storage.saveSession(
          isAuthenticated: true,
          role: UserRole.user,
          employeeId: 'emp-42',
          customAvatar: 'https://example.com/avatar.png',
          userId: 'uid-firebase-42',
          userEmail: 'emp42@cilalutask.id',
        );

        final loadedSession = await storage.loadSession();
        expect(loadedSession['isAuthenticated'], isTrue);
        expect(loadedSession['role'], UserRole.user);
        expect(loadedSession['employeeId'], 'emp-42');
        expect(loadedSession['customAvatar'], 'https://example.com/avatar.png');
        expect(loadedSession['userId'], 'uid-firebase-42');
        expect(loadedSession['userEmail'], 'emp42@cilalutask.id');

        // 2. Save & Load Pending Offline Tasks Queue
        const pendingTask = Task(
          id: 'task-pending-1',
          title: 'Sinkronisasi Saat Online',
          description: 'Dibuat saat perangkat offline',
          division: 'Operasional',
          assignee: Assignee(
            id: 'emp-42',
            name: 'Karyawan 42',
            shortName: 'K42',
            avatar: '',
            division: 'Operasional',
            role: 'Staf',
          ),
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          deadlineLabel: 'Besok',
          subtasks: [],
          progressPercent: 40,
        );

        await storage.savePendingTask('COMP-01', pendingTask);
        final queued = await storage.loadPendingTasks('COMP-01');
        expect(queued.length, 1);
        expect(queued.first.id, 'task-pending-1');

        await storage.removePendingTask('COMP-01', 'task-pending-1');
        expect(await storage.loadPendingTasks('COMP-01'), isEmpty);

        // 3. Clear Session
        await storage.clearSession();
        final clearedSession = await storage.loadSession();
        expect(clearedSession['isAuthenticated'], isFalse);
        expect(clearedSession['employeeId'], isNull);
        expect(clearedSession['userId'], isNull);
      });
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 4. DATABASE & REPOSITORY (CLOUD SYNC, OFFLINE QUEUE & RECONCILIATION)
  // ─────────────────────────────────────────────────────────────────────────
  group('4. DATABASE & REPOSITORY SYNC, OFFLINE QUEUE & ATOMIC BATCH', () {
    late MockCloudDatabaseService mockDb;
    late LocalStorageService localStorage;
    late CilaluRepository repository;

    setUp(() async {
      mockDb = MockCloudDatabaseService();
      localStorage = LocalStorageService();
      await localStorage.init();
      repository = CilaluRepository(firestore: mockDb, storage: localStorage);
      await repository.init();
    });

    test('Offline task creation queues write locally and reconciles to cloud database when back online', () async {
      // Simulate offline mode
      mockDb.cloudOnline = false;

      const offlineTask = Task(
        id: 'task-offline-sync-1',
        title: 'Audit Gudang Cabang',
        description: 'Dibuat ketika koneksi terputus',
        division: 'Logistik',
        assignee: Assignee(
          id: 'emp-log-1',
          name: 'Rian Logistik',
          shortName: 'Rian',
          avatar: '',
          division: 'Logistik',
          role: 'Supervisor',
        ),
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        deadlineLabel: 'Hari Ini',
        subtasks: [],
        progressPercent: 50,
      );

      // Create task while offline
      await repository.createTask('CILALU-88', offlineTask);
      expect(repository.syncStatus, SyncStatus.offline);

      // Verify saved in local storage and pending queue, but not yet in cloud DB
      final localTasks = await localStorage.loadTasks('CILALU-88');
      final pendingTasks = await localStorage.loadPendingTasks('CILALU-88');
      expect(localTasks?.any((t) => t.id == 'task-offline-sync-1'), isTrue);
      expect(pendingTasks.any((t) => t.id == 'task-offline-sync-1'), isTrue);
      expect(mockDb.tasksDb['CILALU-88'], isNull);

      // Restore cloud database connection and reconcile
      mockDb.cloudOnline = true;
      final reconciledCount = await repository.reconcilePendingWrites(
        'CILALU-88',
      );

      expect(reconciledCount, 1);
      expect(repository.syncStatus, SyncStatus.synced);
      expect(
        mockDb.tasksDb['CILALU-88']?['task-offline-sync-1']?.title,
        'Audit Gudang Cabang',
      );
      expect(await localStorage.loadPendingTasks('CILALU-88'), isEmpty);
    });

    test('Atomic acceptJoinRequestBatch updates join request, enrolls member, and stores notification in both Cloud DB and LocalStorage', () async {
      final req = JoinRequest(
        id: 'req-atomic-1',
        companyCode: 'CILALU-88',
        companyName: 'PT Cilalu Nusantara',
        userId: 'uid-new-emp',
        userName: 'Dina Pratiwi',
        userEmail: 'dina@cilalutask.id',
        division: 'Kualitas',
        role: 'QA Specialist',
        avatar: '',
        requestedAt: DateTime.now(),
      );

      await repository.submitJoinRequest('CILALU-88', req);
      expect(
        mockDb.joinRequestsDb['CILALU-88']?['req-atomic-1']?.status,
        JoinRequestStatus.pending,
      );

      const newMember = Assignee(
        id: 'uid-new-emp',
        name: 'Dina Pratiwi',
        shortName: 'Dina',
        avatar: '',
        division: 'Kualitas',
        role: 'QA Specialist',
        email: 'dina@cilalutask.id',
      );

      final welcomeNotif = NotificationItem(
        id: 'notif-welcome-1',
        title: '🎉 Anggota Baru Bergabung',
        description: 'Dina Pratiwi telah bergabung ke tim Kualitas.',
        time: 'Baru saja',
        type: 'team',
        timestamp: DateTime.now(),
      );

      await repository.acceptJoinRequestBatch(
        companyCode: 'CILALU-88',
        request: req,
        member: newMember,
        welcomeNotif: welcomeNotif,
      );

      // Verify Cloud Database state
      expect(
        mockDb.joinRequestsDb['CILALU-88']?['req-atomic-1']?.status,
        JoinRequestStatus.approved,
      );
      expect(
        mockDb.membersDb['CILALU-88']?['uid-new-emp']?.name,
        'Dina Pratiwi',
      );
      expect(
        mockDb.notificationsDb['CILALU-88']?['notif-welcome-1'],
        isNotNull,
      );

      // Verify Local Storage state
      final cachedMembers = await localStorage.loadEmployees('CILALU-88');
      final cachedRequests = await localStorage.loadJoinRequests();
      expect(cachedMembers?.any((m) => m.id == 'uid-new-emp'), isTrue);
      expect(
        cachedRequests?.firstWhere((r) => r.id == 'req-atomic-1').status,
        JoinRequestStatus.approved,
      );
    });
  });
}
