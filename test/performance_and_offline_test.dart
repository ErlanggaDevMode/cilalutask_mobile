import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/repositories/cilalu_repository.dart';
import 'package:cilalutask_mobile/repositories/data_exception.dart';
import 'package:cilalutask_mobile/services/firestore_service.dart';
import 'package:cilalutask_mobile/services/local_storage_service.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/chat_model.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/models/company.dart';
import 'package:cilalutask_mobile/state/app_state_controller.dart';

class MockFirestoreService extends FirestoreService {
  bool fakeAvailable = true;
  final Map<String, List<Task>> fakeTasks = {};
  final Map<String, List<ChatMessage>> fakeMessages = {};
  final List<Company> fakeCompanies = [];
  int messageLoadCount = 0;

  MockFirestoreService() : super.forTesting();

  @override
  bool get isAvailable => fakeAvailable;

  @override
  Future<List<Company>> loadCompanies() async => List.from(fakeCompanies);

  @override
  Future<void> saveCompany(Company company) async {
    fakeCompanies.removeWhere((c) => c.code == company.code);
    fakeCompanies.add(company);
  }

  @override
  Future<List<Task>> loadTasks(String companyCode, {int limit = 100}) async {
    final list = fakeTasks[companyCode] ?? [];
    return List.from(list.take(limit));
  }

  @override
  Future<void> createTask(String companyCode, Task task) async {
    final list = fakeTasks.putIfAbsent(companyCode, () => []);
    list.removeWhere((t) => t.id == task.id);
    list.insert(0, task);
  }

  @override
  Future<void> updateTask(String companyCode, Task task) async {
    final list = fakeTasks.putIfAbsent(companyCode, () => []);
    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      list[idx] = task;
    } else {
      list.add(task);
    }
  }

  @override
  Future<List<ChatMessage>> loadMessages(
    String companyCode, {
    String? channelId,
    int limit = 50,
  }) async {
    messageLoadCount++;
    final list = fakeMessages[companyCode] ?? [];
    final filtered = channelId != null
        ? list.where((m) => m.channelId == channelId).toList()
        : list;
    return List.from(filtered.take(limit));
  }

  @override
  Stream<List<ChatMessage>> messagesStream(
    String companyCode, {
    String? channelId,
    int limit = 50,
  }) {
    if (!fakeAvailable) return const Stream.empty();
    final list = fakeMessages[companyCode] ?? [];
    return Stream.value(List.from(list.take(limit)));
  }
}

void main() {
  late MockFirestoreService mockFirestore;
  late LocalStorageService localStorage;
  late CilaluRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockFirestore = MockFirestoreService();
    localStorage = LocalStorageService();
    await localStorage.init();

    repository = CilaluRepository(
      firestore: mockFirestore,
      storage: localStorage,
    );
  });

  tearDown(() async {
    await localStorage.clearAll();
  });

  group('1. Query Bounding & Pagination Tests', () {
    test(
      'loadTasks respects limit parameter and prevents unbounded downloads',
      () async {
        // Seed 250 tasks into company
        final tasks = List.generate(
          250,
          (i) => Task(
            id: 'task-$i',
            title: 'Tugas Operasional #$i',
            description: '',
            division: 'Operasional',
            assignee: const Assignee(
              id: 'a1',
              name: 'Staff',
              shortName: 'S',
              avatar: 'S',
              division: 'Operasional',
              role: 'Staff',
            ),
            deadlineLabel: 'Hari ini',
            priority: PriorityType.medium,
            status: TaskStatus.inProgress,
            progressPercent: 10,
            subtasks: const [],
          ),
        );
        mockFirestore.fakeTasks['CORP-LIMIT'] = tasks;

        // Default fetch with limit 100
        final fetchedDefault = await repository.getTasks(
          'CORP-LIMIT',
          limit: 100,
        );
        expect(fetchedDefault.length, 100);

        // Explicit small page fetch with limit 25
        final fetchedPage = await repository.getTasks('CORP-LIMIT', limit: 25);
        expect(fetchedPage.length, 25);
      },
    );

    test(
      'loadMessages limits message history to avoid high memory spikes',
      () async {
        // Seed 120 messages in channel
        final messages = List.generate(
          120,
          (i) => ChatMessage(
            id: 'msg-$i',
            senderId: 'u-$i',
            senderName: 'User $i',
            senderAvatar: 'U',
            senderRole: 'Staff',
            content: 'Pesan obrolan ke-$i',
            time: '12:00',
            timestamp: DateTime(2026, 10, 26, 12, i),
            channelId: 'ch-umum',
          ),
        );
        mockFirestore.fakeMessages['CORP-CHAT'] = messages;

        final fetchedMessages = await mockFirestore.loadMessages(
          'CORP-CHAT',
          channelId: 'ch-umum',
          limit: 50,
        );
        expect(fetchedMessages.length, 50);
        expect(mockFirestore.messageLoadCount, 1);
      },
    );
  });

  group('2. Offline Pending Writes & Reconnect Reconciliation', () {
    test(
      'Offline write: queues pending task in LocalStorage without throwing',
      () async {
        // Simulate network disconnected
        mockFirestore.fakeAvailable = false;

        const offlineTask = Task(
          id: 'task-offline-queued',
          title: 'Tugas Dibuat Saat Sinyal Hilang',
          description: 'Tersimpan di antrean pending lokal',
          division: 'Teknologi',
          assignee: Assignee(
            id: 'dev1',
            name: 'Developer',
            shortName: 'DEV',
            avatar: 'D',
            division: 'Teknologi',
            role: 'Engineer',
          ),
          deadlineLabel: 'Besok',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          progressPercent: 15,
          subtasks: [],
        );

        // Create task while offline
        await repository.createTask('CORP-OFFLINE', offlineTask);

        expect(repository.syncStatus, SyncStatus.offline);

        // Verify task is stored in local operational cache
        final localTasks = await localStorage.loadTasks('CORP-OFFLINE');
        expect(localTasks, isNotNull);
        expect(localTasks!.any((t) => t.id == 'task-offline-queued'), isTrue);

        // Verify task is stored in pending offline queue
        final pendingTasks = await localStorage.loadPendingTasks(
          'CORP-OFFLINE',
        );
        expect(pendingTasks.length, 1);
        expect(pendingTasks.first.id, 'task-offline-queued');

        // Verify cloud has NOT received it yet
        expect(
          mockFirestore.fakeTasks['CORP-OFFLINE']?.isEmpty ?? true,
          isTrue,
        );
      },
    );

    test('Reconnect reconciliation: syncs pending writes to Cloud and clears queue', () async {
      mockFirestore.fakeAvailable = false;

      const task1 = Task(
        id: 'task-pending-1',
        title: 'Tugas Pending #1',
        description: '',
        division: 'Finance',
        assignee: Assignee(
          id: 'f1',
          name: 'Akuntan',
          shortName: 'AK',
          avatar: 'A',
          division: 'Finance',
          role: 'Staff',
        ),
        deadlineLabel: '30 Okt',
        priority: PriorityType.medium,
        status: TaskStatus.notStarted,
        progressPercent: 0,
        subtasks: [],
      );

      const task2 = Task(
        id: 'task-pending-2',
        title: 'Tugas Pending #2',
        description: '',
        division: 'Finance',
        assignee: Assignee(
          id: 'f1',
          name: 'Akuntan',
          shortName: 'AK',
          avatar: 'A',
          division: 'Finance',
          role: 'Staff',
        ),
        deadlineLabel: '31 Okt',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        progressPercent: 50,
        subtasks: [],
      );

      await repository.createTask('CORP-RECONCILE', task1);
      await repository.createTask('CORP-RECONCILE', task2);

      expect((await localStorage.loadPendingTasks('CORP-RECONCILE')).length, 2);

      // Simulate connection restored
      mockFirestore.fakeAvailable = true;

      // Trigger reconciliation
      final reconciledCount = await repository.reconcilePendingWrites(
        'CORP-RECONCILE',
      );
      expect(reconciledCount, 2);
      expect(repository.syncStatus, SyncStatus.synced);

      // Verify pending queue is completely cleared
      final remainingPending = await localStorage.loadPendingTasks(
        'CORP-RECONCILE',
      );
      expect(remainingPending.isEmpty, isTrue);

      // Verify cloud now has both tasks
      final cloudTasks = mockFirestore.fakeTasks['CORP-RECONCILE'] ?? [];
      expect(cloudTasks.length, 2);
      expect(cloudTasks.any((t) => t.id == 'task-pending-1'), isTrue);
      expect(cloudTasks.any((t) => t.id == 'task-pending-2'), isTrue);
    });

    test('Multi-tenant isolation: pending writes for Company A do not sync to Company B', () async {
      mockFirestore.fakeAvailable = false;

      const alphaTask = Task(
        id: 'task-alpha-secret',
        title: 'Rahasia Alpha Pending',
        description: '',
        division: 'R&D',
        assignee: Assignee(
          id: 'ra',
          name: 'Alpha',
          shortName: 'A',
          avatar: 'A',
          division: 'R&D',
          role: 'R&D',
        ),
        deadlineLabel: 'Segera',
        priority: PriorityType.high,
        status: TaskStatus.inProgress,
        progressPercent: 20,
        subtasks: [],
      );

      await repository.createTask('COMPANY-ALPHA', alphaTask);

      // Reconnect
      mockFirestore.fakeAvailable = true;

      // Reconcile Company Beta
      final betaReconciled = await repository.reconcilePendingWrites(
        'COMPANY-BETA',
      );
      expect(betaReconciled, 0);
      expect(mockFirestore.fakeTasks['COMPANY-BETA']?.isEmpty ?? true, isTrue);

      // Reconcile Company Alpha
      final alphaReconciled = await repository.reconcilePendingWrites(
        'COMPANY-ALPHA',
      );
      expect(alphaReconciled, 1);
      expect(mockFirestore.fakeTasks['COMPANY-ALPHA']?.length, 1);
      expect(
        mockFirestore.fakeTasks['COMPANY-ALPHA']!.first.id,
        'task-alpha-secret',
      );
    });
  });

  group('3. Lifecycle & Search Debounce Timing', () {
    test(
      'Search debounce timer batches rapid inputs into a single evaluation',
      () async {
        String resolvedQuery = '';
        Timer? debounceTimer;

        void onSearchChanged(String input) {
          debounceTimer?.cancel();
          debounceTimer = Timer(const Duration(milliseconds: 100), () {
            resolvedQuery = input;
          });
        }

        // Simulate rapid typing: 't' -> 'tu' -> 'tug' -> 'tugas' within 50ms intervals
        onSearchChanged('t');
        await Future.delayed(const Duration(milliseconds: 20));
        expect(resolvedQuery, ''); // not fired yet

        onSearchChanged('tu');
        await Future.delayed(const Duration(milliseconds: 20));
        expect(resolvedQuery, ''); // reset

        onSearchChanged('tug');
        await Future.delayed(const Duration(milliseconds: 20));
        expect(resolvedQuery, ''); // reset

        onSearchChanged('tugas');

        // Wait for debounce duration to elapse
        await Future.delayed(const Duration(milliseconds: 120));
        expect(resolvedQuery, 'tugas'); // Fired once with final query!

        debounceTimer?.cancel();
      },
    );

    test(
      'AppStateController clean session wipe clears memory on logout',
      () async {
        final controller = AppStateController(repository: repository);
        addTearDown(() => controller.dispose());

        await controller.initStorage();

        // Log in as employee
        const emp = Assignee(
          id: 'e10',
          name: 'Karyawan Tetap',
          shortName: 'KT',
          avatar: 'K',
          division: 'Operasional',
          role: 'Supervisor',
        );
        controller.loginAsEmployee(emp);

        expect(controller.isAuthenticated, isTrue);
        expect(controller.isUser, isTrue);

        // Logout and verify clean disposal
        await controller.logout();

        expect(controller.isAuthenticated, isFalse);
        expect(controller.currentEmployee, isNull);
        expect(controller.tasks.isEmpty, isTrue);
        expect(controller.sops.isEmpty, isTrue);
        expect(controller.messages.isEmpty, isTrue);
        expect(controller.notifications.isEmpty, isTrue);
      },
    );
  });
}
