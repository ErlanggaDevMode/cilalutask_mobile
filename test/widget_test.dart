import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/main.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';
import 'package:cilalutask_mobile/models/user_role.dart';
import 'package:cilalutask_mobile/models/notification_item.dart';
import 'package:cilalutask_mobile/models/company.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('Cilalutask initial launch shows LoginScreen with 3 tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = AppStateController();
    await tester.pumpWidget(CilalutaskApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify brand header and login tabs exist
    expect(find.text('CILALUTASK'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Daftar PT'), findsWidgets);
    expect(find.text('Gabung Tim'), findsWidgets);
    expect(find.text('Masuk sebagai Admin'), findsWidgets);
  });

  testWidgets('Logging in as Admin shows 6 navigation tabs including Chat', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = AppStateController();
    await tester.pumpWidget(CilalutaskApp(controller: controller));
    await tester.pumpAndSettle();

    // Click login as Admin
    final loginAdminFinder = find.text('Masuk sebagai Admin');
    expect(loginAdminFinder, findsOneWidget);
    await tester.ensureVisible(loginAdminFinder);
    await tester.pumpAndSettle();
    await tester.tap(loginAdminFinder);
    await tester.pumpAndSettle();

    // Verify authenticated state
    expect(controller.isAuthenticated, isTrue);
    expect(controller.isAdmin, isTrue);
    expect(controller.currentRole, UserRole.admin);

    // Verify all 6 navigation tabs exist
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Tugas'), findsWidgets);
    expect(find.text('SOP'), findsWidgets);
    expect(find.text('Laporan'), findsWidgets);
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Tim'), findsWidgets);
  });

  testWidgets('Logging in as User/Karyawan has user role permissions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = AppStateController();
    await tester.pumpWidget(CilalutaskApp(controller: controller));
    await tester.pumpAndSettle();

    // Switch to Karyawan role and login
    final userRoleFinder = find.text('User (Karyawan)');
    expect(userRoleFinder, findsOneWidget);
    await tester.ensureVisible(userRoleFinder);
    await tester.pumpAndSettle();
    await tester.tap(userRoleFinder);
    await tester.pumpAndSettle();

    final loginUserFinder = find.text('Masuk sebagai Karyawan');
    expect(loginUserFinder, findsOneWidget);
    await tester.ensureVisible(loginUserFinder);
    await tester.pumpAndSettle();
    await tester.tap(loginUserFinder);
    await tester.pumpAndSettle();

    // Verify user role
    expect(controller.isAuthenticated, isTrue);
    expect(controller.isUser, isTrue);
    expect(controller.isAdmin, isFalse);

    // Switch to Chat tab (Tab 4)
    controller.setTab(4);
    await tester.pumpAndSettle();

    // Verify chat channels exist
    expect(find.text('#umum'), findsOneWidget);
  });

  test(
    'Multi-Company: Company registration starts in pure blank state',
    () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());
      expect(controller.currentCompany.code, 'CILALU-88');

      // Register a new company
      await controller.registerCompany(
        name: 'PT Sinergi Abadi',
        code: 'SINERGI-01',
        adminName: 'Bambang Sudiro',
        adminEmail: 'bambang@sinergi.id',
        adminPassword: 'password123',
        industry: 'Logistik & Distribusi',
      );

      expect(controller.currentCompany.name, 'PT Sinergi Abadi');
      expect(controller.currentCompany.code, 'SINERGI-01');
      expect(controller.isAdmin, isTrue);
      expect(controller.isBlankMode, isTrue);
      // Tasks, sops, and employees should start completely blank
      expect(controller.tasks.isEmpty, isTrue);
      expect(controller.sops.isEmpty, isTrue);
      expect(controller.employees.isEmpty, isTrue);
    },
  );

  test(
    'Join Company Flow: Employee requests with Company ID, Admin accepts',
    () async {
      final controller = AppStateController();
      addTearDown(() => controller.dispose());

      // Register a fresh company
      await controller.registerCompany(
        name: 'PT Nusantara Prima',
        code: 'NUSANTARA-99',
        adminName: 'Hendra Gunawan',
        adminEmail: 'hendra@nusantara.id',
        adminPassword: 'pass',
      );

      expect(controller.pendingJoinRequestsCount, 0);

      // Prospective employee submits join request with Company ID
      final req = await controller.submitJoinRequest(
        companyCode: 'NUSANTARA-99',
        name: 'Ahmad Fauzi',
        email: 'ahmad@gmail.com',
        password: 'password123',
        division: 'IT & Engineering',
        role: 'Mobile Developer',
      );

      expect(req.status, JoinRequestStatus.pending);
      expect(controller.pendingJoinRequestsCount, 1);
      expect(controller.pendingJoinRequests.first.userName, 'Ahmad Fauzi');
      expect(controller.employees.isEmpty, isTrue);

      // Admin reviews and accepts the request
      await controller.acceptJoinRequest(req.id);

      expect(controller.pendingJoinRequestsCount, 0);
      expect(controller.employees.length, 1);
      expect(controller.employees.first.name, 'Ahmad Fauzi');
      expect(controller.employees.first.role, 'Mobile Developer');
    },
  );

  testWidgets('Real-time notification engine triggers heads-up banner', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = AppStateController();
    await tester.pumpWidget(CilalutaskApp(controller: controller));
    await tester.pumpAndSettle();

    // Login as Admin
    final loginAdminFinder = find.text('Masuk sebagai Admin');
    await tester.ensureVisible(loginAdminFinder);
    await tester.tap(loginAdminFinder);
    await tester.pumpAndSettle();

    // Dispatch a real-time notification
    controller.pushNotification(
      const NotificationItem(
        id: 'test-realtime-1',
        title: '💬 Pesan Realtime Baru',
        description: 'Kevin Maulana: Server Aurora telah aktif tanpa downtime.',
        time: 'Baru saja',
        type: 'chat',
        targetTab: 4,
      ),
      showBanner: true,
    );

    // Pump to render banner animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify banner content is rendered
    expect(find.text('💬 Pesan Realtime Baru'), findsOneWidget);
    expect(find.text('CHAT TIM'), findsOneWidget);

    // Dismiss active notification and elapse any remaining timers
    controller.dismissActiveNotification();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test('Local Persistence restores registered company, chat messages, and tasks across restarts', () async {
    // 1. First app launch: register new company and send a chat message
    final controller1 = AppStateController();
    await controller1.initStorage();

    await controller1.registerCompany(
      name: 'PT Maju Bersama',
      code: 'MAJU-77',
      adminName: 'Budi Santoso',
      adminEmail: 'budi@maju.com',
      adminPassword: 'Password123!',
      industry: 'Teknologi',
    );

    // Send a message in default channel
    controller1.sendChatMessage(
      content: 'Selamat datang di server internal!',
      channelId: 'dev-team',
    );

    // Verify in controller 1
    expect(controller1.currentCompany.code, 'MAJU-77');
    expect(controller1.currentCompany.name, 'PT Maju Bersama');
    expect(
      controller1.messages.any((m) => m.content.contains('internal')),
      isTrue,
    );

    // 2. Simulate app kill & fresh restart with Controller 2
    final controller2 = AppStateController();
    await controller2.initStorage();

    // Verify data restored from storage
    expect(controller2.currentCompany.code, 'MAJU-77');
    expect(controller2.currentCompany.name, 'PT Maju Bersama');
    expect(controller2.currentCompany.adminName, 'Budi Santoso');
    expect(
      controller2.messages.any(
        (m) => m.content == 'Selamat datang di server internal!',
      ),
      isTrue,
    );

    controller1.dispose();
    controller2.dispose();
  });
}
