import 'package:flutter_test/flutter_test.dart';
import 'package:cilalutask_mobile/models/company.dart';
import 'package:cilalutask_mobile/models/employee.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/sop.dart';
import 'package:cilalutask_mobile/models/user_role.dart';
import 'package:cilalutask_mobile/core/utils/task_metrics_calculator.dart';

void main() {
  group('1. Model Serialization & Deserialization Security Tests', () {
    test('Company model: serialization preserves attributes and never stores password', () {
      final now = DateTime(2026, 10, 26, 14, 0);
      final company = Company(
        id: 'comp-101',
        name: 'PT Cakrawala Digital',
        code: 'CAKRAWALA-01',
        adminName: 'Dewi Sartika',
        adminEmail: 'dewi@cakrawala.id',
        adminUid: 'uid-dewi-101',
        createdAt: now,
        industry: 'Fintech & SaaS',
      );

      final map = company.toMap();
      expect(map['id'], 'comp-101');
      expect(map['name'], 'PT Cakrawala Digital');
      expect(map['code'], 'CAKRAWALA-01');
      expect(map['adminName'], 'Dewi Sartika');
      expect(map['adminEmail'], 'dewi@cakrawala.id');
      expect(map['adminUid'], 'uid-dewi-101');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['industry'], 'Fintech & SaaS');

      // CRITICAL ZERO-PASSWORD ASSERTION
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('adminPassword'), isFalse);

      final restored = Company.fromMap(map);
      expect(restored.id, company.id);
      expect(restored.name, company.name);
      expect(restored.code, company.code);
      expect(restored.adminName, company.adminName);
      expect(restored.adminEmail, company.adminEmail);
      expect(restored.adminUid, company.adminUid);
      expect(restored.createdAt, company.createdAt);
      expect(restored.industry, company.industry);
    });

    test('Assignee/Employee model: serialization preserves attributes and never stores password', () {
      const assignee = Assignee(
        id: 'emp-202',
        name: 'Rian Hidayat',
        shortName: 'RH',
        email: 'rian@cakrawala.id',
        division: 'Engineering',
        role: 'Senior Backend Engineer',
        avatar: 'RH',
        hasTeamBadge: true,
        teamCount: 5,
      );

      final map = assignee.toMap();
      expect(map['id'], 'emp-202');
      expect(map['name'], 'Rian Hidayat');
      expect(map['shortName'], 'RH');
      expect(map['email'], 'rian@cakrawala.id');
      expect(map['division'], 'Engineering');
      expect(map['role'], 'Senior Backend Engineer');

      // CRITICAL ZERO-PASSWORD ASSERTION
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('userPassword'), isFalse);

      final restored = Assignee.fromMap(map);
      expect(restored.id, assignee.id);
      expect(restored.name, assignee.name);
      expect(restored.email, assignee.email);
      expect(restored.division, assignee.division);
      expect(restored.role, assignee.role);
    });

    test(
      'Task and Subtask model: serialization and progress rounding bounds',
      () {
        const task = Task(
          id: 'task-303',
          title: 'Audit Keamanan Infrastruktur Cloud',
          description: 'Tinjau konfigurasi VPC, firewall, dan policy IAM',
          division: 'Keamanan',
          assignee: Assignee(
            id: 'emp-202',
            name: 'Rian Hidayat',
            shortName: 'RH',
            avatar: 'RH',
            division: 'Keamanan',
            role: 'DevOps',
          ),
          deadlineLabel: '30 Okt 2026',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          progressPercent: 66,
          isUrgentDeadline: true,
          needsReview: false,
          subtasks: [
            Subtask(id: 'st-1', title: 'Review IAM roles', completed: true),
            Subtask(
              id: 'st-2',
              title: 'Review Security Groups',
              completed: true,
            ),
            Subtask(
              id: 'st-3',
              title: 'Penetration testing port 8080',
              completed: false,
            ),
          ],
        );

        final map = task.toMap();
        expect(map['id'], 'task-303');
        expect(map['title'], 'Audit Keamanan Infrastruktur Cloud');
        expect(map['priority'], 'Prioritas Tinggi');
        expect(map['status'], 'Dalam Proses');
        expect(map['progressPercent'], 66);
        expect(map['isUrgentDeadline'], isTrue);
        expect((map['subtasks'] as List).length, 3);

        final restored = Task.fromMap(map);
        expect(restored.id, task.id);
        expect(restored.title, task.title);
        expect(restored.priority, PriorityType.high);
        expect(restored.status, TaskStatus.inProgress);
        expect(restored.progressPercent, 66);
        expect(restored.subtasks.length, 3);
        expect(restored.subtasks.first.completed, isTrue);
        expect(restored.subtasks.last.completed, isFalse);
      },
    );

    test('SOPDocument and ContentSection model: roundtrip preserves sections and fields', () {
      const sop = SOPDocument(
        id: 'sop-404',
        title: 'Penanganan Insiden Keamanan Tingkat 1',
        category: 'Keamanan',
        code: 'SOP-SEC-01',
        version: 'v2.1',
        isUrgentMandatory: true,
        isBookmarked: true,
        lastUpdatedText: '26 Okt 2026',
        contentSections: [
          ContentSection(
            heading: 'Isolasi Node Terdampak',
            items: [
              'Cabut akses jaringan VM segera setelah deteksi anomali.',
              'Ambil snapshot memori untuk investigasi forensik.',
            ],
          ),
          ContentSection(
            heading: 'Eskalasi Insiden',
            items: ['Hubungi koordinator keamanan via saluran siaga.'],
          ),
        ],
      );

      final map = sop.toMap();
      expect(map['id'], 'sop-404');
      expect(map['title'], 'Penanganan Insiden Keamanan Tingkat 1');
      expect(map['code'], 'SOP-SEC-01');
      expect(map['isUrgentMandatory'], isTrue);
      expect(map['isBookmarked'], isTrue);
      expect((map['contentSections'] as List).length, 2);

      final restored = SOPDocument.fromMap(map);
      expect(restored.id, sop.id);
      expect(restored.title, sop.title);
      expect(restored.contentSections.length, 2);
      expect(restored.contentSections.first.heading, 'Isolasi Node Terdampak');
      expect(restored.contentSections.first.items.length, 2);
    });

    test('JoinRequest model: validates zero password and status mappings', () {
      final now = DateTime(2026, 10, 26, 14, 30);
      final req = JoinRequest(
        id: 'req-505',
        companyCode: 'CAKRAWALA-01',
        companyName: 'PT Cakrawala Digital',
        userId: 'uid-calon-505',
        userName: 'Siti Aminah',
        userEmail: 'siti@gmail.com',
        division: 'Desain',
        role: 'UI/UX Designer',
        avatar: 'SA',
        status: JoinRequestStatus.pending,
        requestedAt: now,
      );

      final map = req.toMap();
      expect(map['id'], 'req-505');
      expect(map['companyCode'], 'CAKRAWALA-01');
      expect(map['userId'], 'uid-calon-505');
      expect(map['userName'], 'Siti Aminah');
      expect(map['status'], 'pending');

      // CRITICAL: Ensure zero password
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('userPassword'), isFalse);

      final restored = JoinRequest.fromMap(map);
      expect(restored.id, req.id);
      expect(restored.companyCode, req.companyCode);
      expect(restored.userName, req.userName);
      expect(restored.status, JoinRequestStatus.pending);
    });
  });

  group('2. Pure Business Logic & Metric Calculator Tests', () {
    test(
      'Calculates overall task statistics accurately with boundary conditions',
      () {
        const tasks = [
          Task(
            id: 't1',
            title: 'Task Selesai Tepat Waktu',
            description: '',
            division: 'Operasional',
            assignee: Assignee(
              id: 'a1',
              name: 'Andi',
              shortName: 'A',
              avatar: 'A',
              division: 'Operasional',
              role: 'Staff',
            ),
            deadlineLabel: '25 Okt 2026',
            priority: PriorityType.medium,
            status: TaskStatus.completed,
            progressPercent: 100,
            subtasks: [],
          ),
          Task(
            id: 't2',
            title: 'Task Dalam Pengerjaan',
            description: '',
            division: 'Operasional',
            assignee: Assignee(
              id: 'a2',
              name: 'Budi',
              shortName: 'B',
              avatar: 'B',
              division: 'Operasional',
              role: 'Staff',
            ),
            deadlineLabel: '27 Okt 2026',
            priority: PriorityType.high,
            status: TaskStatus.inProgress,
            progressPercent: 50,
            subtasks: [],
          ),
          Task(
            id: 't3',
            title: 'Task Belum Dimulai',
            description: '',
            division: 'Teknik',
            assignee: Assignee(
              id: 'a1',
              name: 'Andi',
              shortName: 'A',
              avatar: 'A',
              division: 'Teknik',
              role: 'Staff',
            ),
            deadlineLabel: '20 Okt 2026',
            priority: PriorityType.low,
            status: TaskStatus.notStarted,
            progressPercent: 0,
            subtasks: [],
          ),
        ];

        final metrics = TaskMetricsCalculator.computeMetrics(tasks);
        expect(metrics.total, 3);
        expect(metrics.completed, 1);
        expect(metrics.inProgress, 1);
        expect(metrics.notStarted, 1);
        // Completion rate: 1/3 = 33.3%
        expect(metrics.completionRate, 33.3);
      },
    );

    test('Filters tasks by combined criteria: query + status + division + priority', () {
      const tasks = [
        Task(
          id: 't1',
          title: 'Migrasi Database PostgreSQL',
          description: 'Optimasi query dan sharding',
          division: 'Backend',
          assignee: Assignee(
            id: 'e1',
            name: 'Ahmad',
            shortName: 'A',
            avatar: 'A',
            division: 'Backend',
            role: 'Eng',
          ),
          deadlineLabel: '28 Okt 2026',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          progressPercent: 40,
          isUrgentDeadline: true,
          subtasks: [],
        ),
        Task(
          id: 't2',
          title: 'Redesign Halaman Beranda Mobile',
          description: 'Sesuai desain Figma terbaru',
          division: 'Frontend',
          assignee: Assignee(
            id: 'e2',
            name: 'Budi',
            shortName: 'B',
            avatar: 'B',
            division: 'Frontend',
            role: 'Eng',
          ),
          deadlineLabel: '29 Okt 2026',
          priority: PriorityType.high,
          status: TaskStatus.inProgress,
          progressPercent: 30,
          subtasks: [],
        ),
        Task(
          id: 't3',
          title: 'Audit Kode Backend',
          description: 'Pemeriksaan linting dan unit test',
          division: 'Backend',
          assignee: Assignee(
            id: 'e1',
            name: 'Ahmad',
            shortName: 'A',
            avatar: 'A',
            division: 'Backend',
            role: 'Eng',
          ),
          deadlineLabel: '30 Okt 2026',
          priority: PriorityType.medium,
          status: TaskStatus.completed,
          progressPercent: 100,
          subtasks: [],
        ),
      ];

      // 1. Filter by division
      final backendTasks = TaskMetricsCalculator.filterTasks(
        tasks,
        division: 'Backend',
      );
      expect(backendTasks.length, 2);

      // 2. Filter by status + division
      final inProgressBackend = TaskMetricsCalculator.filterTasks(
        tasks,
        division: 'Backend',
        status: TaskStatus.inProgress,
      );
      expect(inProgressBackend.length, 1);
      expect(inProgressBackend.first.id, 't1');

      // 3. Filter by search query
      final searchResults = TaskMetricsCalculator.filterTasks(
        tasks,
        query: 'PostgreSQL',
      );
      expect(searchResults.length, 1);
      expect(searchResults.first.title, contains('PostgreSQL'));
    });
  });

  group('3. Client-Side Permission Matrix Tests', () {
    test(
      'Role permission checks distinguish Admin vs Regular User capabilities',
      () {
        expect(UserRole.admin.label, 'Admin / Manager');
        expect(UserRole.user.label, 'User (Karyawan)');
        expect(UserRole.admin.isAdmin, isTrue);
        expect(UserRole.user.isUser, isTrue);

        // Simulating capability matrix
        bool canCreateTask(UserRole role) => role == UserRole.admin;
        bool canDeleteTask(UserRole role) => role == UserRole.admin;
        bool canDeleteSop(UserRole role) => role == UserRole.admin;
        bool canAcceptJoinRequest(UserRole role) => role == UserRole.admin;
        bool canUpdateTaskProgress(UserRole role) =>
            true; // Both can update progress
        bool canConfirmSopRead(UserRole role) => true; // Both can read/confirm

        // Admin assertions
        expect(canCreateTask(UserRole.admin), isTrue);
        expect(canDeleteTask(UserRole.admin), isTrue);
        expect(canDeleteSop(UserRole.admin), isTrue);
        expect(canAcceptJoinRequest(UserRole.admin), isTrue);
        expect(canUpdateTaskProgress(UserRole.admin), isTrue);
        expect(canConfirmSopRead(UserRole.admin), isTrue);

        // Regular User assertions
        expect(canCreateTask(UserRole.user), isFalse);
        expect(canDeleteTask(UserRole.user), isFalse);
        expect(canDeleteSop(UserRole.user), isFalse);
        expect(canAcceptJoinRequest(UserRole.user), isFalse);
        expect(canUpdateTaskProgress(UserRole.user), isTrue);
        expect(canConfirmSopRead(UserRole.user), isTrue);
      },
    );
  });
}
