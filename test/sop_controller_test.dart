import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/sop.dart';
import 'package:cilalutask_mobile/state/sop_controller.dart';

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

    test('Add and delete SOP updates state and notifies', () async {
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

      // Test Delete
      await controller.deleteSop('TEST-CO', 'sop-test-1');
      expect(controller.sops.any((s) => s.id == 'sop-test-1'), isFalse);
    });

    test('Confirm read and toggle bookmark update state properly', () async {
      SOPDocument? capturedReadSop;
      final controller = SopController(
        onSopRead: (sop) => capturedReadSop = sop,
      );
      addTearDown(() => controller.dispose());

      final firstSopId = controller.sops.first.id;

      // Confirm Read
      await controller.confirmReadSop('TEST-CO', firstSopId);
      final readSop = controller.sops.firstWhere((s) => s.id == firstSopId);
      expect(readSop.isReadByMe, isTrue);
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
}
