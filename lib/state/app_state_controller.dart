import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/sop.dart';
import '../models/activity.dart';
import '../models/employee.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';
import '../models/chat_model.dart';
import '../models/company.dart';
import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../repositories/cilalu_repository.dart';
import '../repositories/data_exception.dart';
import 'sop_controller.dart';
import 'task_controller.dart';
import 'chat_controller.dart';
import 'notification_controller.dart';
import 'company_controller.dart';

/// Root AppStateController coordinating domain controllers:
/// - [CompanyController] (Multi-tenant company, membership, join requests)
/// - [TaskController] (Tasks, subtasks, progress, review)
/// - [SopController] (SOPs, read confirmations, bookmarks)
/// - [ChatController] (Channels, messages, real-time chat)
/// - [NotificationController] (Notifications, heads-up banner, stream)
///
/// Acts as a unified Facade maintaining 100% backward compatibility for existing screens.
class AppStateController extends ChangeNotifier {
  final CilaluRepository _repository;
  final AuthService _authService;

  // Domain Sub-Controllers
  late final CompanyController _companyController;
  late final TaskController _taskController;
  late final SopController _sopController;
  late final ChatController _chatController;
  late final NotificationController _notificationController;

  bool _isStorageLoaded = false;
  bool get isStorageLoaded => _isStorageLoaded;
  bool get isCloudConnected => _repository.isCloudAvailable;
  SyncStatus get syncStatus => _repository.syncStatus;
  String? get lastSyncError => _repository.lastError;

  bool _isLoadingCompanyData = false;
  bool get isLoadingCompanyData => _isLoadingCompanyData;

  Future<int> reconcilePendingWrites() async {
    final count = await _repository.reconcilePendingWrites(
      _companyController.currentCompany.code,
    );
    if (count > 0) notifyListeners();
    return count;
  }

  AuthService get authService => _authService;
  CilaluRepository get repository => _repository;

  // Sub-controller getters for direct modular access
  CompanyController get companyController => _companyController;
  TaskController get taskController => _taskController;
  SopController get sopController => _sopController;
  ChatController get chatController => _chatController;
  NotificationController get notificationController => _notificationController;

  // Authentication & Role
  bool _isAuthenticated = false;
  UserRole _currentUserRole = UserRole.admin;
  Assignee? _currentEmployee; // null if Admin
  String? _customUserAvatar;
  final CurrentUser _currentUser = kCurrentUser;

  // Activities & Navigation UI state
  List<ActivityItem> _activities = List.from(kInitialActivities);
  int _currentTabIndex = 0;
  String _teamSubTab = 'tim'; // 'tim' | 'notif'

  AppStateController({
    CilaluRepository? repository,
    AuthService? authService,
    CompanyController? companyController,
    TaskController? taskController,
    SopController? sopController,
    ChatController? chatController,
    NotificationController? notificationController,
  }) : _repository = repository ?? CilaluRepository(),
       _authService = authService ?? AuthService() {
    _companyController =
        companyController ??
        CompanyController(
          repository: _repository,
          authService: _authService,
          onNotification: (item, {bool showBanner = true}) =>
              pushNotification(item, showBanner: showBanner),
        );

    _taskController = taskController ?? TaskController(repository: _repository);

    _sopController = sopController ?? SopController(repository: _repository);

    _chatController = chatController ?? ChatController(repository: _repository);

    _notificationController =
        notificationController ??
        NotificationController(repository: _repository);

    // Forward change notifications to root listeners
    _companyController.addListener(_onSubControllerChanged);
    _taskController.addListener(_onSubControllerChanged);
    _sopController.addListener(_onSubControllerChanged);
    _chatController.addListener(_onSubControllerChanged);
    _notificationController.addListener(_onSubControllerChanged);
  }

  void _onSubControllerChanged() {
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  //  LIFECYCLE & INITIALIZATION
  // ─────────────────────────────────────────────────────────────

  Future<void> initStorage() async {
    await _repository.init();

    // 1. Initialize Company & Join Requests
    await _companyController.initCompanyData();

    // 2. Load Auth / Session
    final session = await _repository.loadSession();
    _isAuthenticated = session['isAuthenticated'] as bool? ?? false;
    _currentUserRole = session['role'] as UserRole? ?? UserRole.admin;
    _customUserAvatar = session['customAvatar'] as String?;
    final savedEmpId = session['employeeId'] as String?;

    // 3. Load Company Data sequentially
    await _loadCompanyData(
      _companyController.currentCompany.code,
      savedEmpId: savedEmpId,
    );

    _isStorageLoaded = true;
    notifyListeners();
  }

  Future<void> _loadCompanyData(
    String companyCode, {
    String? savedEmpId,
  }) async {
    _isLoadingCompanyData = true;
    _cancelSubscriptions();

    try {
      await Future.wait([
        _taskController.loadTasks(companyCode),
        _sopController.loadSops(companyCode),
        _companyController.loadCompanyMembersAndRequests(companyCode),
        _chatController.loadChatData(companyCode),
        _notificationController.loadNotifications(companyCode),
      ]);

      if (savedEmpId != null && _companyController.employees.isNotEmpty) {
        _currentEmployee = _companyController.employees.firstWhere(
          (e) => e.id == savedEmpId,
          orElse: () => _companyController.employees.first,
        );
      }

      // Start real-time subscriptions for the active company
      _startSubscriptions(companyCode);
    } catch (e) {
      debugPrint('Error loading company data: $e');
    } finally {
      _isLoadingCompanyData = false;
      notifyListeners();
    }
  }

  void _cancelSubscriptions() {
    _chatController.cancelSubscription();
    _notificationController.cancelSubscription();
    _companyController.cancelJoinRequestsSubscription();
  }

  void _startSubscriptions(String companyCode) {
    _chatController.startSubscription(companyCode);
    _notificationController.startSubscription(companyCode);
    if (isAdmin) {
      _companyController.startJoinRequestsSubscription(companyCode);
    }
  }

  void _persistSession() {
    _repository.saveSession(
      isAuthenticated: _isAuthenticated,
      role: _currentUserRole,
      employeeId: _currentEmployee?.id,
      customAvatar: _customUserAvatar,
      userId: _authService.currentUid,
      userEmail: _authService.currentEmail,
    );
  }

  void _persistCompanies() {
    _repository.saveCompany(_companyController.currentCompany);
  }

  // ─────────────────────────────────────────────────────────────
  //  AUTH & PROFILE GETTERS / METHODS
  // ─────────────────────────────────────────────────────────────

  bool get isAuthenticated => _isAuthenticated;
  UserRole get currentUserRole => _currentUserRole;
  Assignee? get currentEmployee => _currentEmployee;
  bool get isAdmin => _currentUserRole == UserRole.admin;
  bool get isUser => _currentUserRole == UserRole.user;
  UserRole get currentRole => _currentUserRole;

  String get currentUserName => isAdmin
      ? _companyController.currentCompany.adminName
      : (_currentEmployee?.name ?? _currentUser.name);

  String get currentUserEmail => isAdmin
      ? _companyController.currentCompany.adminEmail
      : (_currentEmployee?.email ?? _currentUser.email);

  String get currentUserRoleTitle => isAdmin
      ? 'Admin / Manager'
      : (_currentEmployee?.role ?? _currentUser.role);

  String get currentUserAvatar =>
      _customUserAvatar ??
      (isAdmin
          ? 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=256'
          : (_currentEmployee?.avatar ?? _currentUser.avatar));

  String get currentUserDivision => _currentUserRole == UserRole.admin
      ? _currentUser.division
      : (_currentEmployee?.division ?? 'Operasional');

  void updateCustomAvatar(String url) {
    _customUserAvatar = url;
    _persistSession();
    notifyListeners();
  }

  void updateUserAvatar(String newAvatar) {
    updateCustomAvatar(newAvatar);
  }

  Future<void> loginWithCredentials({
    required String companyCode,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cleanCode = companyCode.trim().toUpperCase();
    final cleanEmail = email.trim();

    // 1. Verify Company Existence
    final foundCompany = _companyController.companies
        .where((c) => c.code.toUpperCase() == cleanCode)
        .firstOrNull;

    if (foundCompany == null) {
      throw Exception('ID Perusahaan "$cleanCode" tidak ditemukan.');
    }

    // 2. Authenticate with Firebase Auth if available
    String uid = 'uid-${cleanEmail.hashCode}';
    if (_authService.isAvailable) {
      final cred = await _authService.signIn(
        email: cleanEmail,
        password: password,
      );
      uid = cred.user?.uid ?? uid;
    }

    // 3. Verify Membership and Role Authorization
    if (role == UserRole.admin) {
      final isAdmin =
          foundCompany.adminEmail.toLowerCase() == cleanEmail.toLowerCase() ||
          (foundCompany.adminUid.isNotEmpty && foundCompany.adminUid == uid);
      if (!isAdmin) {
        throw Exception(
          'Akun ini tidak memiliki hak akses sebagai Administrator di $cleanCode.',
        );
      }
      _companyController.setCurrentCompany(foundCompany);
      _currentUserRole = UserRole.admin;
      _currentEmployee = null;
    } else {
      if (foundCompany.code != _companyController.currentCompany.code) {
        _companyController.setCurrentCompany(foundCompany);
      }
      await _loadCompanyData(foundCompany.code);
      final emp = _companyController.employees
          .where(
            (e) =>
                e.email.toLowerCase() == cleanEmail.toLowerCase() ||
                e.id == uid,
          )
          .firstOrNull;
      if (emp == null) {
        throw Exception(
          'Akun Anda belum terdaftar sebagai anggota di $cleanCode. Silakan ajukan melalui "Gabung Tim".',
        );
      }
      _currentUserRole = UserRole.user;
      _currentEmployee = emp;
    }

    _isAuthenticated = true;
    _currentTabIndex = 0;
    _persistSession();
    _persistCompanies();
    notifyListeners();
  }

  void loginAsAdmin({Company? company}) {
    if (company != null) {
      _companyController.setCurrentCompany(company);
    }
    _currentUserRole = UserRole.admin;
    _currentEmployee = null;
    _isAuthenticated = true;
    _currentTabIndex = 0;
    _persistSession();
    _persistCompanies();
    notifyListeners();
  }

  void loginAsEmployee(Assignee employee, {Company? company}) {
    if (company != null) {
      _companyController.setCurrentCompany(company);
    }
    _currentUserRole = UserRole.user;
    _currentEmployee = employee;
    _isAuthenticated = true;
    _currentTabIndex = 0;
    _persistSession();
    _persistCompanies();
    notifyListeners();
  }

  Future<void> logout() async {
    _cancelSubscriptions();

    if (_authService.isAvailable) {
      await _authService.signOut();
    }
    _isAuthenticated = false;
    _currentUserRole = UserRole.admin;
    _currentEmployee = null;
    _currentTabIndex = 0;

    // Reset sensitive data completely
    _taskController.clear();
    _sopController.clear();
    _companyController.clearMembersAndRequests();
    _chatController.clear();
    _notificationController.clear();
    _activities = [];

    await _repository.clearSession();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  //  COMPANY & JOIN REQUESTS (Delegation to CompanyController)
  // ─────────────────────────────────────────────────────────────

  List<Company> get companies => _companyController.companies;
  Company get currentCompany => _companyController.currentCompany;
  List<JoinRequest> get joinRequests => _companyController.joinRequests;
  List<JoinRequest> get pendingJoinRequests =>
      _companyController.pendingJoinRequests;
  int get pendingJoinRequestsCount =>
      _companyController.pendingJoinRequestsCount;
  bool get isBlankMode => _companyController.isBlankMode;
  List<Assignee> get employees => _companyController.employees;

  Future<void> switchCompany(Company comp) async {
    _companyController.setCurrentCompany(comp);

    // 1. Immediately clear in-memory lists to prevent data leaks across companies
    _taskController.clear();
    _sopController.clear();
    _companyController.clearMembersAndRequests();
    _chatController.clear();
    _notificationController.clear();
    _activities = [];
    _isLoadingCompanyData = true;
    notifyListeners();

    // 2. Persist active code and load target company data sequentially
    await _repository.saveCurrentCompanyCode(comp.code);
    await _loadCompanyData(comp.code);
  }

  Future<void> registerCompany({
    required String name,
    required String code,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    String industry = 'Teknologi & Operasional',
  }) async {
    final newComp = await _companyController.registerCompany(
      name: name,
      code: code,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      industry: industry,
    );

    // Clear operational lists for the new company
    _taskController.clear();
    _sopController.clear();
    _activities = [];
    _chatController.setChannels([
      ChatChannel(
        id: 'ch-umum',
        name: '#umum',
        description: 'Saluran pengumuman dan diskusi ${newComp.name}',
        lastMessage:
            'Selamat datang di ${newComp.name}! Bagikan Kode ID ${newComp.code} untuk mengundang tim.',
        lastMessageTime: 'Baru saja',
        unreadCount: 0,
      ),
    ]);
    await _repository.saveChannels(newComp.code, _chatController.channels);

    _currentUserRole = UserRole.admin;
    _currentEmployee = null;
    _isAuthenticated = true;
    _currentTabIndex = 0;

    _persistSession();
    notifyListeners();
  }

  Future<JoinRequest> submitJoinRequest({
    required String companyCode,
    required String name,
    required String email,
    required String password,
    required String division,
    required String role,
  }) async {
    return _companyController.submitJoinRequest(
      companyCode: companyCode,
      name: name,
      email: email,
      password: password,
      division: division,
      role: role,
    );
  }

  Future<void> acceptJoinRequest(String requestId) async {
    await _companyController.acceptJoinRequest(requestId);
  }

  Future<void> rejectJoinRequest(String requestId) async {
    await _companyController.rejectJoinRequest(requestId);
  }

  // ─────────────────────────────────────────────────────────────
  //  TASK METHODS (Delegation to TaskController)
  // ─────────────────────────────────────────────────────────────

  List<Task> get tasks => _taskController.tasks;
  int get activeReviewCount => _taskController.activeReviewCount;

  Future<void> createTask(Task newTask) async {
    if (!isAdmin) return;

    final newActivity = ActivityItem(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      userName: currentUserName,
      userAvatar: currentUserAvatar,
      actionPrefix: 'menerbitkan tugas baru',
      targetObject: newTask.title,
      timeAgo: 'Baru saja',
      department: newTask.division,
      type: 'task',
    );
    _activities = [newActivity, ..._activities];

    pushNotification(
      NotificationItem(
        id: 'notif-task-${DateTime.now().millisecondsSinceEpoch}',
        title: '📋 Tugas Baru Diterbitkan',
        description:
            'Tugas "${newTask.title}" telah ditugaskan untuk ${newTask.assignee.name}.',
        time: 'Baru saja',
        type: 'task',
        targetTab: 1,
        targetId: newTask.id,
        timestamp: DateTime.now(),
      ),
      showBanner: true,
    );

    await _taskController.createTask(
      _companyController.currentCompany.code,
      newTask,
    );
  }

  Future<void> deleteTask(String taskId) async {
    if (!isAdmin) return;
    await _taskController.deleteTask(
      _companyController.currentCompany.code,
      taskId,
    );
  }

  Future<void> saveProgress(
    String taskId,
    List<Subtask> updatedSubtasks,
    int progressPercent,
  ) async {
    final updated = await _taskController.saveProgress(
      _companyController.currentCompany.code,
      taskId,
      updatedSubtasks,
      progressPercent,
    );

    if (updated != null) {
      final newActivity = ActivityItem(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        userName: currentUserName,
        userAvatar: currentUserAvatar,
        actionPrefix: 'memperbarui progres tugas',
        targetObject: updated.title,
        actionSuffix: 'ke $progressPercent%.',
        timeAgo: 'Baru saja',
        department: updated.division,
        type: 'task',
      );
      _activities = [newActivity, ..._activities];

      pushNotification(
        NotificationItem(
          id: 'notif-prog-${DateTime.now().millisecondsSinceEpoch}',
          title: '📈 Progres Tugas Diperbarui ($progressPercent%)',
          description:
              '$currentUserName memperbarui "${updated.title}" ke $progressPercent%.',
          time: 'Baru saja',
          type: 'task',
          targetTab: 1,
          targetId: updated.id,
          timestamp: DateTime.now(),
        ),
        showBanner: true,
      );
    }
  }

  Future<void> approveTask(String taskId) async {
    if (!isAdmin) return;

    final approved = await _taskController.approveTask(
      _companyController.currentCompany.code,
      taskId,
    );

    if (approved != null) {
      final newActivity = ActivityItem(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        userName: currentUserName,
        userAvatar: currentUserAvatar,
        actionPrefix: 'menyetujui & menyelesaikan tugas',
        targetObject: approved.title,
        timeAgo: 'Baru saja',
        department: approved.division,
        type: 'task',
      );
      _activities = [newActivity, ..._activities];

      pushNotification(
        NotificationItem(
          id: 'notif-appr-${DateTime.now().millisecondsSinceEpoch}',
          title: '✅ Tugas Telah Disetujui & Selesai',
          description:
              '$currentUserName telah menyetujui tugas "${approved.title}".',
          time: 'Baru saja',
          type: 'review',
          targetTab: 1,
          targetId: approved.id,
          timestamp: DateTime.now(),
        ),
        showBanner: true,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  SOP METHODS (Delegation to SopController)
  // ─────────────────────────────────────────────────────────────

  List<SOPDocument> get sops => _sopController.sops;

  Future<void> addSop(SOPDocument newSop) async {
    if (!isAdmin) return;

    final newActivity = ActivityItem(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      userName: currentUserName,
      userAvatar: currentUserAvatar,
      actionPrefix: 'menerbitkan SOP baru',
      targetObject: newSop.title,
      timeAgo: 'Baru saja',
      department: newSop.category,
      type: 'sop',
    );
    _activities = [newActivity, ..._activities];

    pushNotification(
      NotificationItem(
        id: 'notif-sop-${DateTime.now().millisecondsSinceEpoch}',
        title: '📑 SOP Baru: ${newSop.code}',
        description: '${newSop.title} telah diterbitkan dan wajib dipatuhi.',
        time: 'Baru saja',
        type: 'sop',
        targetTab: 2,
        targetId: newSop.id,
        timestamp: DateTime.now(),
      ),
      showBanner: true,
    );

    await _sopController.addSop(_companyController.currentCompany.code, newSop);
  }

  Future<void> deleteSop(String sopId) async {
    if (!isAdmin) return;
    await _sopController.deleteSop(
      _companyController.currentCompany.code,
      sopId,
    );
  }

  Future<void> confirmReadSop(String sopId) async {
    await _sopController.confirmReadSop(
      _companyController.currentCompany.code,
      sopId,
    );
    final sop = _sopController.sops.firstWhere(
      (s) => s.id == sopId,
      orElse: () => _sopController.sops.first,
    );
    final newActivity = ActivityItem(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      userName: currentUserName,
      userAvatar: currentUserAvatar,
      actionPrefix: 'mengonfirmasi membaca',
      targetObject: sop.code,
      timeAgo: 'Baru saja',
      department: sop.category,
      type: 'sop',
    );
    _activities = [newActivity, ..._activities];
    notifyListeners();
  }

  Future<void> toggleBookmarkSop(String sopId) async {
    await _sopController.toggleBookmarkSop(
      _companyController.currentCompany.code,
      sopId,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  CHAT METHODS (Delegation to ChatController)
  // ─────────────────────────────────────────────────────────────

  List<ChatChannel> get channels => _chatController.channels;
  List<ChatMessage> get messages => _chatController.messages;

  List<ChatMessage> getMessagesForChannel(String channelId) {
    return _chatController.getMessagesForChannel(channelId);
  }

  List<ChatMessage> getDirectMessagesWith(String otherUserId) {
    final myId = _currentUserRole == UserRole.admin
        ? 'admin-1'
        : (_currentEmployee?.id ?? 'emp-1');
    return _chatController.getDirectMessagesWith(otherUserId, myId);
  }

  List<ChatMessage> messagesForChannel(String? channelId) {
    return _chatController.messagesForChannel(channelId);
  }

  Future<void> addChannel(String name, String description) async {
    await _chatController.addChannel(
      _companyController.currentCompany.code,
      name,
      description,
    );
  }

  Future<void> sendChatMessage({
    required String content,
    String? channelId,
    String? receiverId,
  }) async {
    if (content.trim().isEmpty) return;

    final now = DateTime.now();
    final timeFormatted =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final myId = _currentUserRole == UserRole.admin
        ? 'admin-1'
        : (_currentEmployee?.id ?? 'emp-1');

    final newMsg = ChatMessage(
      id: 'msg-${now.millisecondsSinceEpoch}',
      channelId: channelId,
      receiverId: receiverId,
      senderId: myId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      senderRole: currentUserRoleTitle,
      content: content.trim(),
      time: timeFormatted,
      timestamp: now,
    );

    await _chatController.sendChatMessage(
      _companyController.currentCompany.code,
      newMsg,
    );

    final channelName = channelId != null
        ? (_chatController.channels
              .firstWhere(
                (c) => c.id == channelId,
                orElse: () => _chatController.channels.first,
              )
              .name)
        : 'Pesan Langsung';

    pushNotification(
      NotificationItem(
        id: 'notif-chat-${DateTime.now().millisecondsSinceEpoch}',
        title: '💬 $currentUserName di $channelName',
        description: content.trim(),
        time: 'Baru saja',
        type: 'chat',
        senderName: currentUserName,
        senderAvatar: currentUserAvatar,
        targetTab: 4,
        targetId: channelId ?? receiverId,
        timestamp: DateTime.now(),
      ),
      showBanner: true,
    );
  }

  Future<void> deleteChatMessage(String messageId) async {
    await _chatController.deleteChatMessage(
      _companyController.currentCompany.code,
      messageId,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  NOTIFICATIONS & BROADCASTS (Delegation to NotificationController)
  // ─────────────────────────────────────────────────────────────

  List<NotificationItem> get notifications =>
      _notificationController.notifications;
  int get unreadNotificationsCount =>
      _notificationController.unreadNotificationsCount;
  NotificationItem? get activeInAppNotification =>
      _notificationController.activeInAppNotification;

  void pushNotification(NotificationItem item, {bool showBanner = true}) {
    _notificationController.pushNotification(
      _companyController.currentCompany.code,
      item,
      showBanner: showBanner,
    );
  }

  void dismissActiveNotification() {
    _notificationController.dismissActiveNotification();
  }

  void markAllNotificationsAsRead() {
    _notificationController.markAllNotificationsAsRead();
  }

  void markNotificationAsRead(String id) {
    _notificationController.markNotificationAsRead(id);
  }

  Future<void> deleteNotification(String notifId) async {
    await _notificationController.deleteNotification(
      _companyController.currentCompany.code,
      notifId,
    );
  }

  Future<void> clearAllNotifications() async {
    await _notificationController.clearAllNotifications(
      _companyController.currentCompany.code,
    );
  }

  void sendBroadcast(String message, String targetDivision) {
    if (!isAdmin) return;

    final preview = message.length > 35
        ? '${message.substring(0, 35)}...'
        : message;
    final newActivity = ActivityItem(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      userName: currentUserName,
      userAvatar: currentUserAvatar,
      actionPrefix: 'mengirim broadcast ($targetDivision):',
      targetObject: '"$preview"',
      timeAgo: 'Baru saja',
      department: targetDivision,
      type: 'task',
    );
    _activities = [newActivity, ..._activities];

    pushNotification(
      NotificationItem(
        id: 'notif-bc-${DateTime.now().millisecondsSinceEpoch}',
        title: '📢 Siaran Pengumuman ($targetDivision)',
        description: message,
        time: 'Baru saja',
        type: 'system',
        targetTab: 5,
        timestamp: DateTime.now(),
      ),
      showBanner: true,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  UI NAVIGATION & GENERAL GETTERS
  // ─────────────────────────────────────────────────────────────

  int get currentTabIndex => _currentTabIndex;
  List<ActivityItem> get activities => List.unmodifiable(_activities);
  CurrentUser get currentUser => _currentUser;
  String get teamSubTab => _teamSubTab;

  void setTeamSubTab(String subTab) {
    if (_teamSubTab != subTab) {
      _teamSubTab = subTab;
      notifyListeners();
    }
  }

  void openNotificationsTab() {
    _teamSubTab = 'notif';
    setTab(5);
  }

  void setTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void resetToInitialData() {
    _taskController.clear();
    _sopController.clear();
    _companyController.clearMembersAndRequests();
    _activities = [];
    _notificationController.clear();
    _chatController.clear();
    notifyListeners();
  }

  void loadSampleDemoData() {
    _taskController.setTasks(List.from(kInitialTasks));
    _sopController.setSops(List.from(kInitialSops));
    _companyController.setEmployees(List.from(kEmployees));
    _notificationController.setNotifications(List.from(kNotificationsData));
    _activities = List.from(kInitialActivities);
    notifyListeners();
  }

  int _simIndex = 0;
  void simulateIncomingRealtimeEvent() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final events = [
      NotificationItem(
        id: 'sim-${now.millisecondsSinceEpoch}-1',
        title: '💬 Pesan Masuk (#it-tech-core)',
        description: 'Kevin M: Database transaksi Aurora berhasil sinkron tanpa downtime.',
        time: 'Baru saja ($timeStr)',
        type: 'chat',
        senderName: 'Kevin Maulana',
        senderAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=256',
        targetTab: 4,
        targetId: 'ch-it',
        timestamp: now,
      ),
      NotificationItem(
        id: 'sim-${now.millisecondsSinceEpoch}-2',
        title: '📋 Update Subtask Operasional',
        description:
            'Budi Santoso telah menyelesaikan checklist Pallet B4 di Cikarang.',
        time: 'Baru saja ($timeStr)',
        type: 'task',
        senderName: 'Budi Santoso',
        senderAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=256',
        targetTab: 1,
        timestamp: now,
      ),
    ];

    final event = events[_simIndex % events.length];
    _simIndex++;
    pushNotification(event, showBanner: true);
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelSubscriptions();

    _companyController.removeListener(_onSubControllerChanged);
    _taskController.removeListener(_onSubControllerChanged);
    _sopController.removeListener(_onSubControllerChanged);
    _chatController.removeListener(_onSubControllerChanged);
    _notificationController.removeListener(_onSubControllerChanged);

    _companyController.dispose();
    _taskController.dispose();
    _sopController.dispose();
    _chatController.dispose();
    _notificationController.dispose();

    super.dispose();
  }
}
