import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/company.dart';
import '../models/employee.dart';
import '../models/activity.dart';
import '../models/notification_item.dart';
import '../data/mock_data.dart';
import '../repositories/cilalu_repository.dart';
import '../services/auth_service.dart';

/// Dedicated controller for Multi-Company isolation, company registration,
/// membership, and join requests.
class CompanyController extends ChangeNotifier {
  final CilaluRepository _repository;
  final AuthService _authService;

  List<Company> _companies = [
    Company(
      id: 'comp-1',
      name: 'PT Cilalu Sentosa',
      code: 'CILALU-88',
      adminName: 'Sarah Pratama',
      adminEmail: 'sarah.pratama@cilulataks.id',
      adminUid: 'admin-sarah-default',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      industry: 'Teknologi & Operasional Cloud',
    ),
  ];
  late Company _currentCompany;
  List<JoinRequest> _joinRequests = [];
  List<Assignee> _employees = List.from(kEmployees);
  bool _isBlankMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  StreamSubscription<List<JoinRequest>>? _joinRequestsSubscription;

  final void Function(NotificationItem item, {bool showBanner})? onNotification;
  final void Function(ActivityItem item)? onActivity;

  CompanyController({
    CilaluRepository? repository,
    AuthService? authService,
    this.onNotification,
    this.onActivity,
    List<Company>? initialCompanies,
    List<Assignee>? initialEmployees,
  }) : _repository = repository ?? CilaluRepository(),
       _authService = authService ?? AuthService() {
    if (initialCompanies != null && initialCompanies.isNotEmpty) {
      _companies = List.from(initialCompanies);
    }
    _currentCompany = _companies.first;
    if (initialEmployees != null) {
      _employees = List.from(initialEmployees);
    }
  }

  List<Company> get companies => List.unmodifiable(_companies);
  Company get currentCompany => _currentCompany;
  List<JoinRequest> get joinRequests => List.unmodifiable(_joinRequests);
  List<Assignee> get employees => List.unmodifiable(_employees);
  bool get isBlankMode => _isBlankMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<JoinRequest> get pendingJoinRequests => _joinRequests
      .where(
        (r) =>
            r.status == JoinRequestStatus.pending &&
            r.companyCode.toUpperCase() == _currentCompany.code.toUpperCase(),
      )
      .toList();
  int get pendingJoinRequestsCount => pendingJoinRequests.length;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void setEmployees(List<Assignee> list) {
    _employees = List.from(list);
    notifyListeners();
  }

  void setCompanies(List<Company> list) {
    _companies = List.from(list);
    if (!_companies.any(
      (c) => c.code.toUpperCase() == _currentCompany.code.toUpperCase(),
    )) {
      _currentCompany = _companies.first;
    }
    notifyListeners();
  }

  void setCurrentCompany(Company comp) {
    _currentCompany = comp;
    notifyListeners();
  }

  void setJoinRequests(List<JoinRequest> requests) {
    _joinRequests = List.from(requests);
    notifyListeners();
  }

  void clearMembersAndRequests() {
    cancelJoinRequestsSubscription();
    _employees = [];
    _joinRequests = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initCompanyData() async {
    final savedCompanies = await _repository.getCompanies();
    if (savedCompanies.isNotEmpty) {
      _companies = savedCompanies;
    }

    final activeCode = await _repository.loadCurrentCompanyCode();
    if (activeCode != null) {
      _currentCompany = _companies.firstWhere(
        (c) => c.code.toUpperCase() == activeCode.toUpperCase(),
        orElse: () => _companies.first,
      );
    } else {
      _currentCompany = _companies.first;
    }

    final savedRequests = await _repository.getJoinRequests(
      _currentCompany.code,
    );
    if (savedRequests.isNotEmpty) {
      _joinRequests = savedRequests;
    }
    notifyListeners();
  }

  Future<void> loadCompanyMembersAndRequests(String companyCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedMembers = await _repository.getMembers(companyCode);
      if (loadedMembers.isNotEmpty || companyCode != 'CILALU-88') {
        _employees = loadedMembers;
      }

      final loadedRequests = await _repository.getJoinRequests(companyCode);
      if (loadedRequests.isNotEmpty || companyCode != 'CILALU-88') {
        _joinRequests = loadedRequests;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('CompanyController.loadCompanyMembersAndRequests error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startJoinRequestsSubscription(String companyCode) {
    cancelJoinRequestsSubscription();
    if (!_repository.isCloudAvailable) return;

    _joinRequestsSubscription = _repository
        .streamJoinRequests(companyCode)
        .listen((requests) {
          _joinRequests = requests;
          notifyListeners();
        }, onError: (e) => debugPrint('Join requests subscription error: $e'));
  }

  void cancelJoinRequestsSubscription() {
    _joinRequestsSubscription?.cancel();
    _joinRequestsSubscription = null;
  }

  Future<Company> registerCompany({
    required String name,
    required String code,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    String industry = 'Teknologi & Operasional',
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final cleanEmail = adminEmail.trim();

    String adminUid = 'admin-${DateTime.now().millisecondsSinceEpoch}';
    if (_authService.isAvailable) {
      try {
        final cred = await _authService.signUp(
          email: cleanEmail,
          password: adminPassword,
        );
        adminUid = cred.user?.uid ?? adminUid;
      } catch (e) {
        try {
          final cred = await _authService.signIn(
            email: cleanEmail,
            password: adminPassword,
          );
          adminUid = cred.user?.uid ?? adminUid;
        } catch (_) {
          rethrow;
        }
      }
    }

    final newComp = Company(
      id: 'comp-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      code: cleanCode,
      adminName: adminName.trim(),
      adminEmail: cleanEmail,
      adminUid: adminUid,
      createdAt: DateTime.now(),
      industry: industry,
    );

    _companies = [newComp, ..._companies];
    _currentCompany = newComp;
    _isBlankMode = true;
    _employees = [];
    _joinRequests = [];

    await _repository.saveCompany(newComp);
    await _repository.saveCurrentCompanyCode(cleanCode);

    final welcomeNotif = NotificationItem(
      id: 'notif-welcome-${DateTime.now().millisecondsSinceEpoch}',
      title: '🏢 Perusahaan ${newComp.name} Berhasil Dibuat!',
      description:
          'ID Perusahaan Anda: $cleanCode. Bagikan ke karyawan agar mereka dapat bergabung.',
      time: 'Baru saja',
      type: 'system',
      targetTab: 5,
      timestamp: DateTime.now(),
    );
    onNotification?.call(welcomeNotif, showBanner: true);

    notifyListeners();
    return newComp;
  }

  Future<JoinRequest> submitJoinRequest({
    required String companyCode,
    required String name,
    required String email,
    required String password,
    required String division,
    required String role,
  }) async {
    final cleanCode = companyCode.trim().toUpperCase();
    final cleanEmail = email.trim();

    String userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    if (_authService.isAvailable) {
      try {
        final cred = await _authService.signUp(
          email: cleanEmail,
          password: password,
        );
        userId = cred.user?.uid ?? userId;
      } catch (e) {
        try {
          final cred = await _authService.signIn(
            email: cleanEmail,
            password: password,
          );
          userId = cred.user?.uid ?? userId;
        } catch (_) {
          rethrow;
        }
      }
    }

    final targetComp = _companies.firstWhere(
      (c) => c.code.toUpperCase() == cleanCode,
      orElse: () => Company(
        id: 'comp-ext',
        name: 'Perusahaan $cleanCode',
        code: cleanCode,
        adminName: 'Admin Perusahaan',
        adminEmail: 'admin@${cleanCode.toLowerCase()}.id',
        adminUid: '',
        createdAt: DateTime.now(),
      ),
    );

    final req = JoinRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      companyCode: cleanCode,
      companyName: targetComp.name,
      userId: userId,
      userName: name.trim(),
      userEmail: cleanEmail,
      division: division.trim(),
      role: role.trim(),
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=256',
      status: JoinRequestStatus.pending,
      requestedAt: DateTime.now(),
    );

    _joinRequests = [req, ..._joinRequests];

    final notif = NotificationItem(
      id: 'notif-join-${DateTime.now().millisecondsSinceEpoch}',
      title: '👥 Permintaan Bergabung Baru!',
      description:
          '${req.userName} memohon bergabung ke divisi ${req.division} ($cleanCode).',
      time: 'Baru saja',
      type: 'system',
      targetTab: 5,
      timestamp: DateTime.now(),
    );
    onNotification?.call(notif, showBanner: true);

    await _repository.submitJoinRequest(cleanCode, req);
    notifyListeners();
    return req;
  }

  Future<void> acceptJoinRequest(String requestId) async {
    final found = _joinRequests.where((r) => r.id == requestId).firstOrNull;
    if (found == null) return;

    final acceptedReq = found.copyWith(status: JoinRequestStatus.approved);
    final newEmp = Assignee(
      id: acceptedReq.userId.isNotEmpty
          ? acceptedReq.userId
          : 'emp-${DateTime.now().millisecondsSinceEpoch}',
      name: acceptedReq.userName,
      shortName: acceptedReq.userName.split(' ').first,
      avatar: acceptedReq.avatar,
      division: acceptedReq.division,
      role: acceptedReq.role,
      hasTeamBadge: true,
      teamCount: 1,
      email: acceptedReq.userEmail,
    );

    final welcomeNotif = NotificationItem(
      id: 'notif-member-${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Anggota Tim Baru Bergabung!',
      description:
          '${newEmp.name} resmi bergabung ke divisi ${newEmp.division}.',
      time: 'Baru saja',
      type: 'system',
      targetTab: 5,
      timestamp: DateTime.now(),
    );

    _joinRequests = _joinRequests
        .map((r) => r.id == requestId ? acceptedReq : r)
        .toList();
    _employees = [..._employees, newEmp];
    onNotification?.call(welcomeNotif, showBanner: true);

    try {
      await _repository.acceptJoinRequestBatch(
        companyCode: _currentCompany.code,
        request: acceptedReq,
        member: newEmp,
        welcomeNotif: welcomeNotif,
      );
    } catch (e) {
      debugPrint('CompanyController.acceptJoinRequest error: $e');
    }
    notifyListeners();
  }

  Future<void> rejectJoinRequest(String requestId) async {
    _joinRequests = _joinRequests.map((r) {
      if (r.id == requestId) {
        return r.copyWith(status: JoinRequestStatus.rejected);
      }
      return r;
    }).toList();

    await _repository.deleteJoinRequest(_currentCompany.code, requestId);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancelJoinRequestsSubscription();
    super.dispose();
  }
}
