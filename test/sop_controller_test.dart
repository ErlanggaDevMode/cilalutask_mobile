import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Cilulatask_mobile/core/utils/report_and_sop_exporter.dart';
import 'package:Cilulatask_mobile/data/mock_data.dart';
import 'package:Cilulatask_mobile/models/company.dart';
import 'package:Cilulatask_mobile/models/sop.dart';
import 'package:Cilulatask_mobile/state/app_state_controller.dart';
import 'package:Cilulatask_mobile/state/app_state_scope.dart';
import 'package:Cilulatask_mobile/state/sop_controller.dart';
import 'package:Cilulatask_mobile/widgets/modals/export_report_bottom_sheet.dart';
import 'package:Cilulatask_mobile/widgets/modals/upload_sop_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SopController Unit Tests', () {
    test('Initializes with default SOPs and loads correctly', () async {
      final controller = SopController();
      addTearDown(() => controller.dispose());

      expect(controller.sops.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('Add, revise, and delete SOP updates state and notifies', () async {
      SOPDocument? capturedAddedSop;
      final controller = SopController(
        onSopAdded: (sop) => capturedAddedSop = sop,
      );
      addTearDown(() => controller.dispose());

      final newSop = SOPDocument(
        id: 'sop-test-1',
        title: 'Prosedur Uji Coba K3',
        code: 'SOP-K3-999',
        category: 'Operasional',
        lastUpdatedText: '26 Okt 2026',
        version: 'v1.0',
        description: 'Panduan keselamatan kerja di area server.',
        duration: '5 menit',
        readTeamCount: '0/6 Tim',
        readProgressPercent: 0,
        isUrgentMandatory: true,
        contentSections: const [
          ContentSection(
            heading: 'Persiapan',
            items: ['Gunakan rompi dan sepatu safety.'],
          ),
        ],
      );

      await controller.addSop('TEST-CO', newSop);

      expect(controller.sops.first.id, 'sop-test-1');
      expect(capturedAddedSop?.id, 'sop-test-1');

      // Test Revision Update
      final revisedSop = newSop.copyWith(version: 'v1.1');
      await controller.updateSop('TEST-CO', revisedSop);
      expect(
        controller.sops.firstWhere((s) => s.id == 'sop-test-1').version,
        'v1.1',
      );

      // Test Delete
      await controller.deleteSop('TEST-CO', 'sop-test-1');
      expect(controller.sops.any((s) => s.id == 'sop-test-1'), isFalse);
    });

    test('Confirm read updates verification progress and clears urgent mandatory flag', () async {
      SOPDocument? capturedReadSop;
      final controller = SopController(
        onSopRead: (sop) => capturedReadSop = sop,
      );
      addTearDown(() => controller.dispose());

      final firstSopId = controller.sops.first.id;

      // Confirm Read
      await controller.confirmReadSop('TEST-CO', firstSopId, totalEmployees: 6);
      final readSop = controller.sops.firstWhere((s) => s.id == firstSopId);
      expect(readSop.isReadByMe, isTrue);
      expect(readSop.isUrgentMandatory, isFalse);
      expect(readSop.readProgressPercent, isNotNull);
      expect(capturedReadSop?.id, firstSopId);

      // Bookmark Toggle
      final initialBookmark = readSop.isBookmarked;
      await controller.toggleBookmarkSop('TEST-CO', firstSopId);
      final bookmarkedSop = controller.sops.firstWhere(
        (s) => s.id == firstSopId,
      );
      expect(bookmarkedSop.isBookmarked, !initialBookmark);
    });

    test('Clear resets SOP list and error state', () {
      final controller = SopController();
      addTearDown(() => controller.dispose());

      expect(controller.sops.isNotEmpty, isTrue);
      controller.clear();
      expect(controller.sops.isEmpty, isTrue);
    });
  });

  group('ReportAndSopExporter Security & File Generation Tests', () {
    test(
      'Sanitizes filenames against path traversal and validates extensions',
      () {
        expect(
          ReportAndSopExporter.sanitizeFileName('../../etc/passwd'),
          'passwd',
        );
        expect(
          ReportAndSopExporter.sanitizeFileName(
            r'..\..\Windows\System32\cmd.exe',
          ),
          'cmd.exe',
        );
        expect(ReportAndSopExporter.isAllowedSopExtension('cmd.exe'), isFalse);
        expect(
          ReportAndSopExporter.isAllowedSopExtension('SOP_Gudang_2026.pdf'),
          isTrue,
        );
        expect(
          ReportAndSopExporter.sanitizeCsvCell('=cmd|\' /C calc\'!A0'),
          '"\'=cmd|\' /C calc\'!A0"',
        );
      },
    );

    test('Generates valid PDF-1.4, Excel XML, and UTF-8 CSV reports', () async {
      final pdfRes = await ReportAndSopExporter.exportPerformanceReport(
        company: Company(
          id: 'comp-1',
          name: 'PT Cilalu Operasional',
          code: 'CILALU-88',
          adminName: 'Sarah Pratama',
          adminEmail: 'sarah@cilalu.id',
          createdAt: DateTime(2025, 1, 1),
        ),
        tasks: kInitialTasks,
        employees: kEmployees,
        sops: kInitialSops,
        options: const ReportExportOptions(format: 'pdf', period: 'Bulan Ini'),
        saveFile: false,
      );
      expect(pdfRes.fileName.endsWith('.pdf'), isTrue);
      final pdfHeader = latin1.decode(pdfRes.bytes.take(8).toList());
      expect(pdfHeader.startsWith('%PDF-1.4'), isTrue);

      final xlsRes = await ReportAndSopExporter.exportPerformanceReport(
        company: Company(
          id: 'comp-1',
          name: 'PT Cilalu Operasional',
          code: 'CILALU-88',
          adminName: 'Sarah Pratama',
          adminEmail: 'sarah@cilalu.id',
          createdAt: DateTime(2025, 1, 1),
        ),
        tasks: kInitialTasks,
        employees: kEmployees,
        sops: kInitialSops,
        options: const ReportExportOptions(format: 'xlsx', period: 'Bulan Ini'),
        saveFile: false,
      );
      expect(xlsRes.fileName.endsWith('.xls'), isTrue);
      final xlsText = utf8.decode(xlsRes.bytes);
      expect(xlsText.contains('<Workbook'), isTrue);

      final csvRes = await ReportAndSopExporter.exportPerformanceReport(
        company: Company(
          id: 'comp-1',
          name: 'PT Cilalu Operasional',
          code: 'CILALU-88',
          adminName: 'Sarah Pratama',
          adminEmail: 'sarah@cilalu.id',
          createdAt: DateTime(2025, 1, 1),
        ),
        tasks: kInitialTasks,
        employees: kEmployees,
        sops: kInitialSops,
        options: const ReportExportOptions(format: 'csv', period: 'Bulan Ini'),
        saveFile: false,
      );
      expect(csvRes.fileName.endsWith('.csv'), isTrue);
      // Verify UTF-8 BOM
      expect(csvRes.bytes[0], 0xEF);
      expect(csvRes.bytes[1], 0xBB);
      expect(csvRes.bytes[2], 0xBF);
    });

    testWidgets('UploadSopBottomSheet generates auto PDF and submits new SOP', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appController = AppStateController();
      addTearDown(() => appController.dispose());
      SOPDocument? createdSop;

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            controller: appController,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UploadSopBottomSheet.show(
                      context,
                      onAddSop: (sop) => createdSop = sop,
                    );
                  },
                  child: const Text('Open Upload SOP'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Upload SOP'));
      await tester.pumpAndSettle();

      // Generate auto PDF attachment
      await tester.tap(find.text('Buat PDF Otomatis'));
      await tester.pumpAndSettle();

      // Enter SOP title
      await tester.enterText(
        find.byType(TextFormField).first,
        'SOP Keamanan Jaringan Cloud',
      );
      await tester.pumpAndSettle();

      // Tap Terbitkan Dokumen SOP
      await tester.tap(find.text('Terbitkan Dokumen SOP'));
      await tester.pumpAndSettle();

      expect(createdSop, isNotNull);
      expect(createdSop!.title, 'SOP Keamanan Jaringan Cloud');
      expect(createdSop!.attachmentFileName, isNotNull);
      expect(createdSop!.attachmentBase64, isNotNull);
      expect(createdSop!.isReadByMe, isFalse);
    });

    testWidgets('ExportReportBottomSheet previews report and exports', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appController = AppStateController();
      addTearDown(() => appController.dispose());

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            controller: appController,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ExportReportBottomSheet.show(
                      context,
                      period: 'November 2026',
                    );
                  },
                  child: const Text('Open Export Report'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Export Report'));
      await tester.pumpAndSettle();

      expect(find.text('Ekspor Laporan Kinerja'), findsOneWidget);

      // Tap preview
      await tester.ensureVisible(find.text('Lihat Pratinjau Isi Laporan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat Pratinjau Isi Laporan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pratinjau:'), findsOneWidget);
    });
  });
}
