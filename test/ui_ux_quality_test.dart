import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cilalutask_mobile/core/widgets/app_confirm_dialog.dart';
import 'package:cilalutask_mobile/core/widgets/app_empty_state.dart';
import 'package:cilalutask_mobile/main.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/screens/auth/login_screen.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';
import 'package:cilalutask_mobile/state/app_state_scope.dart';
import 'package:cilalutask_mobile/widgets/modals/create_task_bottom_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UI/UX Quality - Reusable AppEmptyState Tests', () {
    testWidgets(
      'AppEmptyState renders icon, title, description, and semantics',
      (tester) async {
        bool actionTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Tidak Ada Tugas',
                description: 'Semua tugas telah diselesaikan dengan baik.',
                actionLabel: 'Tambah Tugas',
                actionIcon: Icons.add_rounded,
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        );

        // Verify semantics container exists with label
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'Tidak Ada Tugas. Semua tugas telah diselesaikan dengan baik.',
          ),
          findsOneWidget,
        );

        // Verify text
        expect(find.text('Tidak Ada Tugas'), findsOneWidget);
        expect(
          find.text('Semua tugas telah diselesaikan dengan baik.'),
          findsOneWidget,
        );
        expect(find.text('Tambah Tugas'), findsOneWidget);

        // Tap action button
        await tester.tap(find.text('Tambah Tugas'));
        expect(actionTapped, isTrue);
      },
    );

    testWidgets('AppEmptyState works in compact mode without action button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Hasil Pencarian Kosong',
              message: 'Tidak ada data ditemukan.',
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('Hasil Pencarian Kosong'), findsOneWidget);
      expect(find.text('Tidak ada data ditemukan.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('UI/UX Quality - AppConfirmDialog Destructive Action Tests', () {
    testWidgets('AppConfirmDialog cancel returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmDialog.show(
                    context,
                    title: 'Hapus Item?',
                    message: 'Item ini akan dihapus secara permanen.',
                    confirmLabel: 'Ya, Hapus',
                    cancelLabel: 'Batal',
                    isDestructive: true,
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Hapus Item?'), findsOneWidget);
      expect(
        find.text('Item ini akan dihapus secara permanen.'),
        findsOneWidget,
      );

      // Tap cancel
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('AppConfirmDialog confirm returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmDialog.show(
                    context,
                    title: 'Konfirmasi Keluar',
                    message: 'Apakah Anda yakin ingin keluar dari akun?',
                    confirmLabel: 'Keluar',
                    isDestructive: true,
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Tap confirm
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group(
    'UI/UX Quality - Form Validation & Double Submission Prevention Tests',
    () {
      testWidgets(
        'LoginScreen validates email and password before submitting',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final controller = AppStateController();

          await tester.pumpWidget(
            AppStateScope(
              controller: controller,
              child: const MaterialApp(home: Scaffold(body: LoginScreen())),
            ),
          );
          await tester.pumpAndSettle();

          // Enter valid company code first
          final companyCodeField = find.widgetWithText(
            TextField,
            'Contoh: CILALU-88',
          );
          await tester.enterText(companyCodeField, 'CILALU-88');

          // Enter invalid email
          final emailField = find.widgetWithText(TextField, 'Email');
          await tester.enterText(emailField, 'email-salah');

          final passField = find.widgetWithText(TextField, 'Password');
          await tester.enterText(passField, '123'); // < 6 chars

          final loginBtn = find.text('Masuk sebagai Admin');
          await tester.ensureVisible(loginBtn);
          await tester.tap(loginBtn);
          await tester.pumpAndSettle();

          // Verify validation snackbar displayed and auth not triggered
          expect(
            find.text('Format email tidak valid. Masukkan email yang benar.'),
            findsOneWidget,
          );
          expect(controller.isAuthenticated, isFalse);

          // Fix email, but keep short password
          await tester.enterText(emailField, 'admin@cilalutask.com');
          await tester.tap(loginBtn);
          await tester.pumpAndSettle();

          expect(find.text('Password minimal 6 karakter.'), findsOneWidget);
          expect(controller.isAuthenticated, isFalse);
        },
      );

      testWidgets(
        'CreateTaskBottomSheet safeguards empty employees list without crash',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          Task? createdTask;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      CreateTaskBottomSheet.show(
                        context,
                        employees: const [], // Empty company test!
                        onCreateTask: (task) => createdTask = task,
                      );
                    },
                    child: const Text('Buat Tugas'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Buat Tugas'));
          await tester.pumpAndSettle();

          // Verify bottom sheet opened without throwing StateError
          expect(find.text('Buat Tugas Baru'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Form validation UX: Submitting without title shows validation error
          final submitBtn = find.text('Terbitkan Tugas Sekarang');
          await tester.ensureVisible(submitBtn);
          await tester.tap(submitBtn);
          await tester.pumpAndSettle();

          expect(find.text('Judul tugas wajib diisi'), findsOneWidget);
          expect(createdTask, isNull);

          // Now fill title and create
          final titleField = find.byType(TextFormField).first;
          await tester.enterText(titleField, 'Audit Keamanan Sistem');
          await tester.pumpAndSettle();

          await tester.tap(submitBtn);
          await tester.pumpAndSettle();

          expect(createdTask, isNotNull);
          expect(createdTask!.title, 'Audit Keamanan Sistem');
        },
      );
    },
  );

  group(
    'UI/UX Quality - Destructive Task & SOP Confirmation and Role Safety',
    () {
      testWidgets(
        'Admin can delete task with confirmation dialog; Cancel preserves task',
        (tester) async {
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

          // Navigate to Tugas tab (index 1)
          await tester.tap(find.text('Tugas'));
          await tester.pumpAndSettle();

          final initialCount = controller.tasks.length;
          expect(initialCount, greaterThan(0));

          // Locate first delete task icon button
          final deleteIconFinder = find.byTooltip('Hapus Tugas').first;
          await tester.ensureVisible(deleteIconFinder);
          await tester.tap(deleteIconFinder);
          await tester.pumpAndSettle();

          // Verify destructive confirmation dialog is presented
          expect(find.text('Hapus Tugas?'), findsOneWidget);

          // Cancel deletion
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();

          // Task count unchanged
          expect(controller.tasks.length, initialCount);

          // Re-trigger and confirm deletion
          await tester.tap(deleteIconFinder);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ya, Hapus'));
          await tester.pumpAndSettle();

          // Task count decreased
          expect(controller.tasks.length, initialCount - 1);
        },
      );

      testWidgets(
        'Admin can delete SOP with confirmation dialog; Cancel preserves SOP',
        (tester) async {
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

          // Navigate to SOP tab (index 2)
          await tester.tap(find.text('SOP'));
          await tester.pumpAndSettle();

          final initialSopCount = controller.sops.length;
          expect(initialSopCount, greaterThan(0));

          // Locate first delete SOP icon button
          final deleteSopFinder = find.byTooltip('Hapus Dokumen SOP').first;
          await tester.ensureVisible(deleteSopFinder);
          await tester.tap(deleteSopFinder);
          await tester.pumpAndSettle();

          // Verify confirmation dialog
          expect(find.text('Hapus SOP?'), findsOneWidget);

          // Cancel deletion
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();

          // SOP count unchanged
          expect(controller.sops.length, initialSopCount);

          // Re-trigger and confirm deletion
          await tester.tap(deleteSopFinder);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Hapus SOP'));
          await tester.pumpAndSettle();

          // SOP count decreased
          expect(controller.sops.length, initialSopCount - 1);
        },
      );

      testWidgets(
        'Non-admin Karyawan does NOT see admin destructive delete buttons',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final controller = AppStateController();
          await tester.pumpWidget(CilalutaskApp(controller: controller));
          await tester.pumpAndSettle();

          // Select Karyawan role and login
          await tester.tap(find.text('User (Karyawan)'));
          await tester.pumpAndSettle();

          final loginUserFinder = find.text('Masuk sebagai Karyawan');
          await tester.ensureVisible(loginUserFinder);
          await tester.tap(loginUserFinder);
          await tester.pumpAndSettle();

          // In Tugas tab, verify no delete button for regular employee
          await tester.tap(find.text('Tugas'));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Hapus Tugas'), findsNothing);

          // In SOP tab, verify no delete button for regular employee
          await tester.tap(find.text('SOP'));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Hapus Dokumen SOP'), findsNothing);
        },
      );
    },
  );

  group('UI/UX Quality - Small Viewport & Overflow Resilience', () {
    testWidgets(
      'Renders properly without overflow on small mobile screen (320x480)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = AppStateController();
        await tester.pumpWidget(CilalutaskApp(controller: controller));
        await tester.pumpAndSettle();

        // Verify no RenderFlex overflow on LoginScreen
        expect(tester.takeException(), isNull);

        // Login as Admin
        final loginAdminFinder = find.text('Masuk sebagai Admin');
        await tester.ensureVisible(loginAdminFinder);
        await tester.tap(loginAdminFinder);
        await tester.pumpAndSettle();

        // Verify no RenderFlex overflow on Main Shell / Dashboard
        expect(tester.takeException(), isNull);

        // Check Tasks screen
        await tester.tap(find.text('Tugas'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Check SOP screen
        await tester.tap(find.text('SOP'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Check Reports screen
        await tester.tap(find.text('Laporan'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Check Chat screen
        await tester.tap(find.text('Chat'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Check Team screen
        await tester.tap(find.text('Tim'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
