import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/data_parser.dart';
import '../models/company.dart';
import '../models/task.dart';
import '../models/sop.dart';
import '../models/employee.dart';
import '../models/chat_model.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';

/// Local offline cache and session storage service using SharedPreferences.
/// Operates as a fast, write-through/read-through cache for operational data partitioned by company code.
class LocalStorageService {
  static const String _keyCompanies = 'cilalu_companies';
  static const String _keyCurrentCompanyCode = 'cilalu_current_company_code';
  static const String _keyIsAuthenticated = 'cilalu_is_authenticated';
  static const String _keyUserRole = 'cilalu_user_role';
  static const String _keyCurrentEmployeeId = 'cilalu_current_employee_id';
  static const String _keyCustomAvatar = 'cilalu_custom_avatar';
  static const String _keyJoinRequests = 'cilalu_join_requests';
  static const String _keyUserId = 'cilalu_user_id';
  static const String _keyUserEmail = 'cilalu_user_email';

  static const String _prefixTasks = 'cilalu_tasks_';
  static const String _prefixSops = 'cilalu_sops_';
  static const String _prefixEmployees = 'cilalu_employees_';
  static const String _prefixChannels = 'cilalu_channels_';
  static const String _prefixMessages = 'cilalu_messages_';
  static const String _prefixNotifs = 'cilalu_notifs_';
  static const String _prefixPendingTasks = 'cilalu_pending_tasks_';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Companies ---
  Future<void> saveCompanies(List<Company> companies) async {
    await init();
    final jsonList = companies.map((c) => c.toMap()).toList();
    await _prefs?.setString(_keyCompanies, jsonEncode(jsonList));
  }

  Future<List<Company>?> loadCompanies() async {
    await init();
    final raw = _prefs?.getString(_keyCompanies);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<Company>(decoded, (m) => Company.fromMap(m));
    } catch (_) {
      return null;
    }
  }

  // --- Active Company Code ---
  Future<void> saveCurrentCompanyCode(String code) async {
    await init();
    await _prefs?.setString(_keyCurrentCompanyCode, code);
  }

  Future<String?> loadCurrentCompanyCode() async {
    await init();
    return _prefs?.getString(_keyCurrentCompanyCode);
  }

  // --- Auth & Session ---
  Future<void> saveSession({
    required bool isAuthenticated,
    required UserRole role,
    String? employeeId,
    String? customAvatar,
    String? userId,
    String? userEmail,
  }) async {
    await init();
    await _prefs?.setBool(_keyIsAuthenticated, isAuthenticated);
    await _prefs?.setString(_keyUserRole, role.name);
    if (employeeId != null) {
      await _prefs?.setString(_keyCurrentEmployeeId, employeeId);
    } else {
      await _prefs?.remove(_keyCurrentEmployeeId);
    }
    if (customAvatar != null) {
      await _prefs?.setString(_keyCustomAvatar, customAvatar);
    } else {
      await _prefs?.remove(_keyCustomAvatar);
    }
    if (userId != null) {
      await _prefs?.setString(_keyUserId, userId);
    } else {
      await _prefs?.remove(_keyUserId);
    }
    if (userEmail != null) {
      await _prefs?.setString(_keyUserEmail, userEmail);
    } else {
      await _prefs?.remove(_keyUserEmail);
    }
  }

  Future<void> clearSession() async {
    await init();
    await _prefs?.remove(_keyIsAuthenticated);
    await _prefs?.remove(_keyUserRole);
    await _prefs?.remove(_keyCurrentEmployeeId);
    await _prefs?.remove(_keyCustomAvatar);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyUserEmail);
  }

  Future<Map<String, dynamic>> loadSession() async {
    await init();
    final isAuth = _prefs?.getBool(_keyIsAuthenticated) ?? false;
    final roleName = _prefs?.getString(_keyUserRole) ?? 'admin';
    final role = roleName == 'user' ? UserRole.user : UserRole.admin;
    final employeeId = _prefs?.getString(_keyCurrentEmployeeId);
    final customAvatar = _prefs?.getString(_keyCustomAvatar);
    final userId = _prefs?.getString(_keyUserId);
    final userEmail = _prefs?.getString(_keyUserEmail);
    return {
      'isAuthenticated': isAuth,
      'role': role,
      'employeeId': employeeId,
      'customAvatar': customAvatar,
      'userId': userId,
      'userEmail': userEmail,
    };
  }

  // --- Join Requests ---
  Future<void> saveJoinRequests(List<JoinRequest> requests) async {
    await init();
    final jsonList = requests.map((r) => r.toMap()).toList();
    await _prefs?.setString(_keyJoinRequests, jsonEncode(jsonList));
  }

  Future<void> deleteJoinRequest(String requestId) async {
    final existing = await loadJoinRequests() ?? [];
    existing.removeWhere((r) => r.id == requestId);
    await saveJoinRequests(existing);
  }

  Future<List<JoinRequest>?> loadJoinRequests() async {
    await init();
    final raw = _prefs?.getString(_keyJoinRequests);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<JoinRequest>(
        decoded,
        (m) => JoinRequest.fromMap(m),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Tasks per Company ---
  Future<void> saveTasks(String companyCode, List<Task> tasks) async {
    await init();
    final jsonList = tasks.map((t) => t.toMap()).toList();
    await _prefs?.setString('$_prefixTasks$companyCode', jsonEncode(jsonList));
  }

  Future<void> deleteTask(String companyCode, String taskId) async {
    final existing = await loadTasks(companyCode) ?? [];
    existing.removeWhere((t) => t.id == taskId);
    await saveTasks(companyCode, existing);
  }

  Future<List<Task>?> loadTasks(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixTasks$companyCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<Task>(decoded, (m) => Task.fromMap(m));
    } catch (_) {
      return null;
    }
  }

  // --- SOPs per Company ---
  Future<void> saveSops(String companyCode, List<SOPDocument> sops) async {
    await init();
    final jsonList = sops.map((s) => s.toMap()).toList();
    await _prefs?.setString('$_prefixSops$companyCode', jsonEncode(jsonList));
  }

  Future<void> deleteSop(String companyCode, String sopId) async {
    final existing = await loadSops(companyCode) ?? [];
    existing.removeWhere((s) => s.id == sopId);
    await saveSops(companyCode, existing);
  }

  Future<List<SOPDocument>?> loadSops(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixSops$companyCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<SOPDocument>(
        decoded,
        (m) => SOPDocument.fromMap(m),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Employees per Company ---
  Future<void> saveEmployees(
    String companyCode,
    List<Assignee> employees,
  ) async {
    await init();
    final jsonList = employees.map((e) => e.toMap()).toList();
    await _prefs?.setString(
      '$_prefixEmployees$companyCode',
      jsonEncode(jsonList),
    );
  }

  Future<void> deleteEmployee(String companyCode, String empId) async {
    final existing = await loadEmployees(companyCode) ?? [];
    existing.removeWhere((e) => e.id == empId);
    await saveEmployees(companyCode, existing);
  }

  Future<List<Assignee>?> loadEmployees(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixEmployees$companyCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<Assignee>(
        decoded,
        (m) => Assignee.fromMap(m),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Channels per Company ---
  Future<void> saveChannels(
    String companyCode,
    List<ChatChannel> channels,
  ) async {
    await init();
    final jsonList = channels.map((c) => c.toMap()).toList();
    await _prefs?.setString(
      '$_prefixChannels$companyCode',
      jsonEncode(jsonList),
    );
  }

  Future<List<ChatChannel>?> loadChannels(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixChannels$companyCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<ChatChannel>(
        decoded,
        (m) => ChatChannel.fromMap(m),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Messages per Company ---
  Future<void> saveMessages(
    String companyCode,
    List<ChatMessage> messages,
  ) async {
    await init();
    final jsonList = messages.map((m) => m.toMap()).toList();
    await _prefs?.setString(
      '$_prefixMessages$companyCode',
      jsonEncode(jsonList),
    );
  }

  Future<void> deleteMessage(String companyCode, String messageId) async {
    final existing = await loadMessages(companyCode) ?? [];
    existing.removeWhere((m) => m.id == messageId);
    await saveMessages(companyCode, existing);
  }

  Future<List<ChatMessage>?> loadMessages(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixMessages$companyCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<ChatMessage>(
        decoded,
        (m) => ChatMessage.fromMap(m),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Notifications per Company ---
  Future<void> saveNotifications(
    String companyCode,
    List<NotificationItem> notifs,
  ) async {
    await init();
    final jsonList = notifs.map((n) => n.toMap()).toList();
    await _prefs?.setString('$_prefixNotifs$companyCode', jsonEncode(jsonList));
  }

  Future<void> deleteNotification(String companyCode, String notifId) async {
    final existing = await loadNotifications(companyCode) ?? [];
    existing.removeWhere((n) => n.id == notifId);
    await saveNotifications(companyCode, existing);
  }

  Future<List<NotificationItem>?> loadNotifications(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixNotifs$companyCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<NotificationItem>(
        decoded,
        (m) => NotificationItem.fromMap(m),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Offline Pending Writes Queue ---
  Future<void> savePendingTask(String companyCode, Task task) async {
    await init();
    final existing = await loadPendingTasks(companyCode);
    final updated = [task, ...existing.where((t) => t.id != task.id)];
    final jsonList = updated.map((t) => t.toMap()).toList();
    await _prefs?.setString(
      '$_prefixPendingTasks$companyCode',
      jsonEncode(jsonList),
    );
  }

  Future<List<Task>> loadPendingTasks(String companyCode) async {
    await init();
    final raw = _prefs?.getString('$_prefixPendingTasks$companyCode');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      return DataParser.parseList<Task>(decoded, (m) => Task.fromMap(m));
    } catch (_) {
      return [];
    }
  }

  Future<void> removePendingTask(String companyCode, String taskId) async {
    await init();
    final existing = await loadPendingTasks(companyCode);
    final updated = existing.where((t) => t.id != taskId).toList();
    if (updated.isEmpty) {
      await _prefs?.remove('$_prefixPendingTasks$companyCode');
    } else {
      final jsonList = updated.map((t) => t.toMap()).toList();
      await _prefs?.setString(
        '$_prefixPendingTasks$companyCode',
        jsonEncode(jsonList),
      );
    }
  }

  Future<void> clearPendingTasks(String companyCode) async {
    await init();
    await _prefs?.remove('$_prefixPendingTasks$companyCode');
  }

  // --- Reset Cache per Company ---
  Future<void> clearCompanyCache(String companyCode) async {
    await init();
    await _prefs?.remove('$_prefixTasks$companyCode');
    await _prefs?.remove('$_prefixSops$companyCode');
    await _prefs?.remove('$_prefixEmployees$companyCode');
    await _prefs?.remove('$_prefixChannels$companyCode');
    await _prefs?.remove('$_prefixMessages$companyCode');
    await _prefs?.remove('$_prefixNotifs$companyCode');
    await _prefs?.remove('$_prefixPendingTasks$companyCode');
  }

  // --- Reset All (Factory Reset) ---
  Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
  }
}
