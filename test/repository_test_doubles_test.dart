import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/repositories/cilalu_repository.dart';
import 'package:cilalutask_mobile/repositories/data_exception.dart';
import 'package:cilalutask_mobile/services/firestore_service.dart';
import 'package:cilalutask_mobile/services/local_storage_service.dart';
import 'package:cilalutask_mobile/models/company.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/sop.dart';
import 'package:cilalutask_mobile/models/employee.dart';

/// Test double: In-Memory Fake Firestore Service simulating network and security states.
class FakeFirestoreService extends FirestoreService {
  bool fakeAvailable = true;
  bool shouldThrowPermissionDenied = false;
  bool shouldThrowNetworkError = false;

  final Map<String, List<Task>> fakeTasks = {};
  final Map<String, List<SOPDocument>> fakeSops = {};
  final List<Company> fakeCompanies = [];

  FakeFirestoreService() : super.forTesting();

  @override
  bool get isAvailable => fakeAvailable;

  @override
  Future<void> init() async {}

  @override
  Future<List<Company>> loadCompanies() async {
    _checkFaults();
    return List.from(fakeCompanies);
  }

  @override
  Future<void> saveCompany(Company company) async {
    _checkFaults();
    fakeCompanies.removeWhere((c) => c.code == company.code);
    fakeCompanies.add(company);
  }

  @override
  Future<List<Task>> loadTasks(String companyCode, {int limit = 100}) async {
    _checkFaults();
    final all = fakeTasks[companyCode] ?? [];
    return List.from(all.take(limit));
  }

  @override
  Future<void> createTask(String companyCode, Task task) async {
    _checkFaults();
    final list = fakeTasks.putIfAbsent(companyCode, () => []);
    list.removeWhere((t) => t.id == task.id);
    list.insert(0, task);
  }

  @override
  Future<void> updateTask(String companyCode, Task task) async {
    _checkFaults();
    final list = fakeTasks[companyCode];
    if (list != null) {
      final idx = list.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        list[idx] = task;
      }
    }
  }

  @override
  Future<void> deleteTask(String companyCode, String taskId) async {
    _checkFaults();
    fakeTasks[companyCode]?.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<List<SOPDocument>> loadSops(String companyCode) async {
    _checkFaults();
    return List.from(fakeSops[companyCode] ?? []);
  }

  @override
  Future<void> createSop(String companyCode, SOPDocument sop) async {
    _checkFaults();
    final list = fakeSops.putIfAbsent(companyCode, () => []);
    list.removeWhere((s) => s.id == sop.id);
    list.add(sop);
  }

  @override
  Future<void> updateSop(String companyCode, SOPDocument sop) async {
    _checkFaults();
    final list = fakeSops[companyCode];
    if (list != null) {
      final idx = list.indexWhere((s) => s.id == sop.id);
      if (idx != -1) {
        list[idx] = sop;
      }
    }
  }

  @override
  Future<void> deleteSop(String companyCode, String sopId) async {
    _checkFaults();
    fakeSops[companyCode]?.removeWhere((s) => s.id == sopId);
  }

  void _checkFaults() {
    if (shouldThrowPermissionDenied) {
      throw const DataException(
        message: 'Akses ditolak oleh Security Rules Firestore.',
        code: DataErrorCode.permissionDenied,
      );
    }
    if (shouldThrowNetworkError) {
      throw const DataException(
        message: 'Koneksi jaringan terputus.',
        code: DataErrorCode.networkUnavailable,
      );
    }
  }
}

void main() {
  late FakeFirestoreService fakeFirestore;
  late LocalStorageService localStorage;
  late CilaluRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirestoreService();
    localStorage = LocalStorageService();
    await localStorage.init();

    repository = CilaluRepository(
      firestore: fakeFirestore,
      storage: localStorage,
    );
  });

  tearDown(() async {
    await localStorage.clearAll();
  });

  group('CilaluRepository with Test Doubles', () {
    test('1. Remote sync succeeds and updates local disk cache', () async {
      const task = Task(
        id: 'task-cloud-1',
        title: 'Tugas Pertama dari Cloud',
        description: 'Verifikasi sinkronisasi otomatis',
        division: 'Operasional',
        assignee: Assignee(
          id: 'u1',
          name: 'Budi',
          shortName: 'B',
          avatar: 'B',
          division: 'Operasional',
          role: 'Staff',
        ),
        deadlineLabel: '28 Okt 2026',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        progressPercent: 25,
        subtasks: [],
      );

      // Create task via repository
      await repository.createTask('PT-TEST-01', task);

      expect(repository.syncStatus, SyncStatus.synced);
      expect(fakeFirestore.fakeTasks['PT-TEST-01']?.length, 1);

      // Verify that local storage also has the task cached
      final cachedTasks = await localStorage.loadTasks('PT-TEST-01');
      expect(cachedTasks, isNotNull);
      expect(cachedTasks!.length, 1);
      expect(cachedTasks.first.title, 'Tugas Pertama dari Cloud');
    });

    test('2. Offline fallback: when cloud is unavailable, serves cached data without crashing', () async {
      // Seed local storage with a cached task
      const cachedTask = Task(
        id: 'task-offline-1',
        title: 'Tugas Cache Offline',
        description: 'Tersimpan di disk lokal',
        division: 'Teknik',
        assignee: Assignee(
          id: 'u2',
          name: 'Dewi',
          shortName: 'D',
          avatar: 'D',
          division: 'Teknik',
          role: 'Teknisi',
        ),
        deadlineLabel: '29 Okt 2026',
        priority: PriorityType.medium,
        status: TaskStatus.notStarted,
        progressPercent: 0,
        subtasks: [],
      );
      await localStorage.saveTasks('PT-OFFLINE', [cachedTask]);

      // Simulate cloud unavailable
      fakeFirestore.fakeAvailable = false;

      final tasks = await repository.getTasks('PT-OFFLINE');
      expect(repository.syncStatus, SyncStatus.offline);
      expect(tasks.length, 1);
      expect(tasks.first.id, 'task-offline-1');
      expect(tasks.first.title, 'Tugas Cache Offline');
    });

    test('3. Permission denied from security rules rethrows and stops unauthorized access', () async {
      fakeFirestore.shouldThrowPermissionDenied = true;

      const sensitiveTask = Task(
        id: 'task-hacked',
        title: 'Percobaan Akses Tanpa Izin',
        description: '',
        division: 'Admin',
        assignee: Assignee(
          id: 'hacker',
          name: 'Attacker',
          shortName: 'AT',
          avatar: 'A',
          division: 'None',
          role: 'None',
        ),
        deadlineLabel: 'Today',
        priority: PriorityType.high,
        status: TaskStatus.notStarted,
        progressPercent: 0,
        subtasks: [],
      );

      expect(
        () async => await repository.createTask('PT-PROTECTED', sensitiveTask),
        throwsA(
          isA<DataException>().having(
            (e) => e.code,
            'code',
            DataErrorCode.permissionDenied,
          ),
        ),
      );
    });

    test('4. Deletion propagation: Deleting task removes from both cloud and local cache', () async {
      const task = Task(
        id: 'task-delete-me',
        title: 'Tugas yang akan dihapus',
        description: '',
        division: 'Umum',
        assignee: Assignee(
          id: 'u1',
          name: 'Budi',
          shortName: 'B',
          avatar: 'B',
          division: 'Umum',
          role: 'Staff',
        ),
        deadlineLabel: '30 Okt 2026',
        priority: PriorityType.low,
        status: TaskStatus.notStarted,
        progressPercent: 0,
        subtasks: [],
      );

      await repository.createTask('PT-TEST-DEL', task);
      expect((await repository.getTasks('PT-TEST-DEL')).length, 1);

      // Delete task
      await repository.deleteTask('PT-TEST-DEL', 'task-delete-me');

      // Verify deletion in both layers
      expect((await repository.getTasks('PT-TEST-DEL')).isEmpty, isTrue);
      expect(fakeFirestore.fakeTasks['PT-TEST-DEL']?.isEmpty ?? true, isTrue);
      expect(
        (await localStorage.loadTasks('PT-TEST-DEL'))?.isEmpty ?? true,
        isTrue,
      );
    });

    test('5. Multi-tenant partitioning: Company A data is completely isolated from Company B', () async {
      const taskA = Task(
        id: 'task-a',
        title: 'Rahasia Perusahaan A',
        description: 'Hanya untuk PT Alpha',
        division: 'Operasional',
        assignee: Assignee(
          id: 'uA',
          name: 'Alpha Staff',
          shortName: 'A',
          avatar: 'A',
          division: 'Operasional',
          role: 'Staff',
        ),
        deadlineLabel: '1 Nov 2026',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        progressPercent: 50,
        subtasks: [],
      );

      const taskB = Task(
        id: 'task-b',
        title: 'Operasional Perusahaan B',
        description: 'Hanya untuk PT Beta',
        division: 'Logistik',
        assignee: Assignee(
          id: 'uB',
          name: 'Beta Staff',
          shortName: 'B',
          avatar: 'B',
          division: 'Logistik',
          role: 'Staff',
        ),
        deadlineLabel: '2 Nov 2026',
        priority: PriorityType.medium,
        status: TaskStatus.notStarted,
        progressPercent: 0,
        subtasks: [],
      );

      await repository.createTask('COMPANY-ALPHA', taskA);
      await repository.createTask('COMPANY-BETA', taskB);

      // Verify Company A only sees taskA
      final alphaTasks = await repository.getTasks('COMPANY-ALPHA');
      expect(alphaTasks.length, 1);
      expect(alphaTasks.first.title, 'Rahasia Perusahaan A');
      expect(alphaTasks.any((t) => t.id == 'task-b'), isFalse);

      // Verify Company B only sees taskB
      final betaTasks = await repository.getTasks('COMPANY-BETA');
      expect(betaTasks.length, 1);
      expect(betaTasks.first.title, 'Operasional Perusahaan B');
      expect(betaTasks.any((t) => t.id == 'task-a'), isFalse);
    });
  });
}
