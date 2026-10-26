import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/company.dart';
import 'package:cilalutask_mobile/state/company_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CompanyController Unit Tests', () {
    test('Initializes with default company and employees', () {
      final controller = CompanyController();
      addTearDown(() => controller.dispose());

      expect(controller.companies.isNotEmpty, isTrue);
      expect(controller.currentCompany.code, 'CILALU-88');
      expect(controller.employees.isNotEmpty, isTrue);
    });

    test('registerCompany creates company in blank mode', () async {
      final controller = CompanyController();
      addTearDown(() => controller.dispose());

      final newComp = await controller.registerCompany(
        name: 'PT Maju Bersama',
        code: 'MAJU-99',
        adminName: 'Budi Admin',
        adminEmail: 'budi@maju.id',
        adminPassword: 'password123',
      );

      expect(newComp.code, 'MAJU-99');
      expect(controller.currentCompany.code, 'MAJU-99');
      expect(controller.isBlankMode, isTrue);
      expect(controller.employees.isEmpty, isTrue);
      expect(controller.companies.first.code, 'MAJU-99');
    });

    test('submitJoinRequest adds pending request', () async {
      final controller = CompanyController();
      addTearDown(() => controller.dispose());

      final req = await controller.submitJoinRequest(
        companyCode: 'CILALU-88',
        name: 'Ahmad Faisal',
        email: 'ahmad@cilalu.id',
        password: 'password123',
        division: 'Operasional',
        role: 'Staf Gudang',
      );

      expect(req.status, JoinRequestStatus.pending);
      expect(controller.pendingJoinRequests.any((r) => r.id == req.id), isTrue);
    });

    test('acceptJoinRequest promotes user to employee', () async {
      final controller = CompanyController();
      addTearDown(() => controller.dispose());

      final req = await controller.submitJoinRequest(
        companyCode: 'CILALU-88',
        name: 'Siti Rahma',
        email: 'siti@cilalu.id',
        password: 'password123',
        division: 'Pemasaran',
        role: 'Desainer Grafis',
      );

      await controller.acceptJoinRequest(req.id);

      expect(
        controller.employees.any((e) => e.email == 'siti@cilalu.id'),
        isTrue,
      );
      expect(
        controller.pendingJoinRequests.any((r) => r.id == req.id),
        isFalse,
      );
    });

    test('rejectJoinRequest updates status to rejected', () async {
      final controller = CompanyController();
      addTearDown(() => controller.dispose());

      final req = await controller.submitJoinRequest(
        companyCode: 'CILALU-88',
        name: 'Doni Pratama',
        email: 'doni@cilalu.id',
        password: 'password123',
        division: 'IT Core',
        role: 'DevOps',
      );

      await controller.rejectJoinRequest(req.id);

      final found = controller.joinRequests.firstWhere((r) => r.id == req.id);
      expect(found.status, JoinRequestStatus.rejected);
    });
  });
}
