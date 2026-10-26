import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/company.dart';
import '../models/task.dart';
import '../models/sop.dart';
import '../models/employee.dart';
import '../models/chat_model.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import 'data_exception.dart';

/// Thin, unified repository coordinating remote Cloud Firestore and local disk cache.
/// Defines the authoritative Source of Truth (SoT) and enforces deletion propagation.
class CilaluRepository {
  final FirestoreService _firestore;
  final LocalStorageService _storage;

  CilaluRepository({FirestoreService? firestore, LocalStorageService? storage})
    : _firestore = firestore ?? FirestoreService(),
      _storage = storage ?? LocalStorageService();

  SyncStatus _syncStatus = SyncStatus.synced;
  SyncStatus get syncStatus => _syncStatus;

  String? _lastError;
  String? get lastError => _lastError;

  bool get isCloudAvailable => _firestore.isAvailable;

  // ─────────────────────────────────────────────────────────────
  //  INIT & SESSION
  // ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _storage.init();
    try {
      await _firestore.init();
      _syncStatus = _firestore.isAvailable
          ? SyncStatus.synced
          : SyncStatus.offline;
    } catch (e) {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<Map<String, dynamic>> loadSession() => _storage.loadSession();

  Future<void> saveSession({
    required bool isAuthenticated,
    required UserRole role,
    String? employeeId,
    String? customAvatar,
    String? userId,
    String? userEmail,
  }) => _storage.saveSession(
    isAuthenticated: isAuthenticated,
    role: role,
    employeeId: employeeId,
    customAvatar: customAvatar,
    userId: userId,
    userEmail: userEmail,
  );

  Future<void> clearSession() => _storage.clearSession();

  // ─────────────────────────────────────────────────────────────
  //  COMPANIES
  // ─────────────────────────────────────────────────────────────

  Future<List<Company>> getCompanies() async {
    // 1. Try remote if available
    if (_firestore.isAvailable) {
      try {
        final cloudComps = await _firestore.loadCompanies();
        if (cloudComps.isNotEmpty) {
          await _storage.saveCompanies(cloudComps);
          _syncStatus = SyncStatus.synced;
          return cloudComps;
        }
      } catch (e) {
        _handleError(e);
      }
    }

    // 2. Fallback to local cache
    final local = await _storage.loadCompanies();
    return local ?? [];
  }

  Future<void> saveCompany(Company company) async {
    // Local write-through
    final existing = await _storage.loadCompanies() ?? [];
    final updated = [
      company,
      ...existing.where(
        (c) => c.code.toUpperCase() != company.code.toUpperCase(),
      ),
    ];
    await _storage.saveCompanies(updated);
    await _storage.saveCurrentCompanyCode(company.code);

    // Remote sync
    if (_firestore.isAvailable) {
      try {
        await _firestore.saveCompany(company);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<String?> loadCurrentCompanyCode() => _storage.loadCurrentCompanyCode();
  Future<void> saveCurrentCompanyCode(String code) =>
      _storage.saveCurrentCompanyCode(code);

  // ─────────────────────────────────────────────────────────────
  //  TASKS (Granular CRUD)
  // ─────────────────────────────────────────────────────────────

  Future<List<Task>> getTasks(String companyCode, {int limit = 100}) async {
    if (_firestore.isAvailable) {
      try {
        _syncStatus = SyncStatus.syncing;
        final cloudTasks = await _firestore.loadTasks(
          companyCode,
          limit: limit,
        );
        await _storage.saveTasks(companyCode, cloudTasks);
        _syncStatus = SyncStatus.synced;
        return cloudTasks;
      } catch (e) {
        _handleError(e);
        if (e is DataException && e.code == DataErrorCode.permissionDenied) {
          rethrow;
        }
      }
    }

    // Fallback to local cache
    _syncStatus = SyncStatus.offline;
    final cached = await _storage.loadTasks(companyCode);
    return cached ?? [];
  }

  Future<void> createTask(String companyCode, Task task) async {
    // 1. Write local cache
    final local = await _storage.loadTasks(companyCode) ?? [];
    await _storage.saveTasks(companyCode, [task, ...local]);

    // 2. Remote Firestore
    if (_firestore.isAvailable) {
      try {
        await _firestore.createTask(companyCode, task);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
      // Queue write for background reconciliation
      await _storage.savePendingTask(companyCode, task);
    }
  }

  Future<void> updateTask(String companyCode, Task task) async {
    // 1. Update local cache
    final local = await _storage.loadTasks(companyCode) ?? [];
    final updated = local.map((t) => t.id == task.id ? task : t).toList();
    await _storage.saveTasks(companyCode, updated);

    // 2. Remote Firestore
    if (_firestore.isAvailable) {
      try {
        await _firestore.updateTask(companyCode, task);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
      // Queue update for background reconciliation
      await _storage.savePendingTask(companyCode, task);
    }
  }

  Future<void> deleteTask(String companyCode, String taskId) async {
    // 1. Delete from local cache
    await _storage.deleteTask(companyCode, taskId);
    await _storage.removePendingTask(companyCode, taskId);

    // 2. Delete from Cloud Firestore
    if (_firestore.isAvailable) {
      try {
        await _firestore.deleteTask(companyCode, taskId);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  /// Reconciles queued offline writes with Cloud Firestore when connection is restored.
  Future<int> reconcilePendingWrites(String companyCode) async {
    if (!_firestore.isAvailable) return 0;

    final pending = await _storage.loadPendingTasks(companyCode);
    if (pending.isEmpty) return 0;

    int reconciledCount = 0;
    _syncStatus = SyncStatus.syncing;

    for (final task in pending) {
      try {
        await _firestore.updateTask(companyCode, task);
        await _storage.removePendingTask(companyCode, task.id);
        reconciledCount++;
      } catch (e) {
        debugPrint('Failed to reconcile task ${task.id}: $e');
      }
    }

    _syncStatus = SyncStatus.synced;
    return reconciledCount;
  }

  // ─────────────────────────────────────────────────────────────
  //  SOPS (Granular CRUD)
  // ─────────────────────────────────────────────────────────────

  Future<List<SOPDocument>> getSops(String companyCode) async {
    if (_firestore.isAvailable) {
      try {
        _syncStatus = SyncStatus.syncing;
        final cloudSops = await _firestore.loadSops(companyCode);
        await _storage.saveSops(companyCode, cloudSops);
        _syncStatus = SyncStatus.synced;
        return cloudSops;
      } catch (e) {
        _handleError(e);
        if (e is DataException && e.code == DataErrorCode.permissionDenied) {
          rethrow;
        }
      }
    }

    _syncStatus = SyncStatus.offline;
    final cached = await _storage.loadSops(companyCode);
    return cached ?? [];
  }

  Future<void> createSop(String companyCode, SOPDocument sop) async {
    final local = await _storage.loadSops(companyCode) ?? [];
    await _storage.saveSops(companyCode, [sop, ...local]);

    if (_firestore.isAvailable) {
      try {
        await _firestore.createSop(companyCode, sop);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<void> updateSop(String companyCode, SOPDocument sop) async {
    final local = await _storage.loadSops(companyCode) ?? [];
    final updated = local.map((s) => s.id == sop.id ? sop : s).toList();
    await _storage.saveSops(companyCode, updated);

    if (_firestore.isAvailable) {
      try {
        await _firestore.updateSop(companyCode, sop);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<void> deleteSop(String companyCode, String sopId) async {
    await _storage.deleteSop(companyCode, sopId);

    if (_firestore.isAvailable) {
      try {
        await _firestore.deleteSop(companyCode, sopId);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  MEMBERS (Granular CRUD)
  // ─────────────────────────────────────────────────────────────

  Future<List<Assignee>> getMembers(String companyCode) async {
    if (_firestore.isAvailable) {
      try {
        _syncStatus = SyncStatus.syncing;
        final cloudMembers = await _firestore.loadEmployees(companyCode);
        if (cloudMembers.isNotEmpty) {
          await _storage.saveEmployees(companyCode, cloudMembers);
          _syncStatus = SyncStatus.synced;
          return cloudMembers;
        }
      } catch (e) {
        _handleError(e);
      }
    }

    _syncStatus = SyncStatus.offline;
    final cached = await _storage.loadEmployees(companyCode);
    return cached ?? [];
  }

  Future<void> createMember(String companyCode, Assignee member) async {
    final local = await _storage.loadEmployees(companyCode) ?? [];
    await _storage.saveEmployees(companyCode, [...local, member]);

    if (_firestore.isAvailable) {
      try {
        await _firestore.createMember(companyCode, member);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<void> deleteMember(String companyCode, String memberId) async {
    await _storage.deleteEmployee(companyCode, memberId);

    if (_firestore.isAvailable) {
      try {
        await _firestore.deleteMember(companyCode, memberId);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  CHAT (Channels & Messages)
  // ─────────────────────────────────────────────────────────────

  Future<List<ChatChannel>> getChannels(String companyCode) async {
    if (_firestore.isAvailable) {
      try {
        final cloud = await _firestore.loadChannels(companyCode);
        if (cloud.isNotEmpty) {
          await _storage.saveChannels(companyCode, cloud);
          return cloud;
        }
      } catch (e) {
        _handleError(e);
      }
    }
    final local = await _storage.loadChannels(companyCode);
    return local ?? [];
  }

  Future<void> saveChannels(
    String companyCode,
    List<ChatChannel> channels,
  ) async {
    await _storage.saveChannels(companyCode, channels);
    if (_firestore.isAvailable) {
      try {
        await _firestore.saveChannels(companyCode, channels);
      } catch (e) {
        _handleError(e);
      }
    }
  }

  Future<List<ChatMessage>> getMessages(
    String companyCode, {
    String? channelId,
  }) async {
    if (_firestore.isAvailable) {
      try {
        final cloud = await _firestore.loadMessages(
          companyCode,
          channelId: channelId,
        );
        if (cloud.isNotEmpty) {
          await _storage.saveMessages(companyCode, cloud);
          return cloud;
        }
      } catch (e) {
        _handleError(e);
      }
    }
    final local = await _storage.loadMessages(companyCode);
    return local ?? [];
  }

  Future<void> sendMessage(String companyCode, ChatMessage message) async {
    final local = await _storage.loadMessages(companyCode) ?? [];
    await _storage.saveMessages(companyCode, [...local, message]);

    if (_firestore.isAvailable) {
      try {
        await _firestore.saveMessage(companyCode, message);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<void> deleteMessage(String companyCode, String messageId) async {
    await _storage.deleteMessage(companyCode, messageId);

    if (_firestore.isAvailable) {
      try {
        await _firestore.deleteMessage(companyCode, messageId);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Stream<List<ChatMessage>> streamMessages(
    String companyCode, {
    String? channelId,
  }) {
    return _firestore.messagesStream(companyCode, channelId: channelId);
  }

  // ─────────────────────────────────────────────────────────────
  //  NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────

  Future<List<NotificationItem>> getNotifications(String companyCode) async {
    if (_firestore.isAvailable) {
      try {
        final cloud = await _firestore.loadNotifications(companyCode);
        if (cloud.isNotEmpty) {
          await _storage.saveNotifications(companyCode, cloud);
          return cloud;
        }
      } catch (e) {
        _handleError(e);
      }
    }
    final local = await _storage.loadNotifications(companyCode);
    return local ?? [];
  }

  Future<void> pushNotification(
    String companyCode,
    NotificationItem notif,
  ) async {
    final local = await _storage.loadNotifications(companyCode) ?? [];
    await _storage.saveNotifications(companyCode, [notif, ...local]);

    if (_firestore.isAvailable) {
      try {
        await _firestore.saveNotification(companyCode, notif);
      } catch (e) {
        _handleError(e);
      }
    }
  }

  Future<void> deleteNotification(String companyCode, String notifId) async {
    await _storage.deleteNotification(companyCode, notifId);

    if (_firestore.isAvailable) {
      try {
        await _firestore.deleteNotification(companyCode, notifId);
      } catch (e) {
        _handleError(e);
      }
    }
  }

  Future<void> clearAllNotifications(
    String companyCode,
    List<String> notifIds,
  ) async {
    await _storage.saveNotifications(companyCode, []);

    if (_firestore.isAvailable) {
      try {
        await _firestore.clearNotifications(companyCode, notifIds);
      } catch (e) {
        _handleError(e);
      }
    }
  }

  Stream<List<NotificationItem>> streamNotifications(String companyCode) {
    return _firestore.notificationsStream(companyCode);
  }

  // ─────────────────────────────────────────────────────────────
  //  JOIN REQUESTS
  // ─────────────────────────────────────────────────────────────

  Future<List<JoinRequest>> getJoinRequests(String companyCode) async {
    if (_firestore.isAvailable) {
      try {
        final cloud = await _firestore.loadJoinRequests(companyCode);
        if (cloud.isNotEmpty) {
          await _storage.saveJoinRequests(cloud);
          return cloud;
        }
      } catch (e) {
        _handleError(e);
      }
    }
    final local = await _storage.loadJoinRequests();
    return local ?? [];
  }

  Future<void> submitJoinRequest(
    String companyCode,
    JoinRequest request,
  ) async {
    final local = await _storage.loadJoinRequests() ?? [];
    await _storage.saveJoinRequests([request, ...local]);

    if (_firestore.isAvailable) {
      try {
        await _firestore.saveJoinRequest(companyCode, request);
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  /// Atomic batch operation to approve request, enroll member, and notify
  Future<void> acceptJoinRequestBatch({
    required String companyCode,
    required JoinRequest request,
    required Assignee member,
    NotificationItem? welcomeNotif,
  }) async {
    // 1. Update local cache
    final localRequests = await _storage.loadJoinRequests() ?? [];
    final updatedRequests = localRequests.map((r) {
      return r.id == request.id
          ? r.copyWith(status: JoinRequestStatus.approved)
          : r;
    }).toList();
    await _storage.saveJoinRequests(updatedRequests);

    final localEmps = await _storage.loadEmployees(companyCode) ?? [];
    await _storage.saveEmployees(companyCode, [...localEmps, member]);

    if (welcomeNotif != null) {
      final localNotifs = await _storage.loadNotifications(companyCode) ?? [];
      await _storage.saveNotifications(companyCode, [
        welcomeNotif,
        ...localNotifs,
      ]);
    }

    // 2. Cloud batch commit
    if (_firestore.isAvailable) {
      try {
        await _firestore.acceptJoinRequestBatch(
          companyCode: companyCode,
          request: request,
          member: member,
          welcomeNotif: welcomeNotif,
        );
        _syncStatus = SyncStatus.synced;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }
  }

  Future<void> deleteJoinRequest(String companyCode, String requestId) async {
    await _storage.deleteJoinRequest(requestId);

    if (_firestore.isAvailable) {
      try {
        await _firestore.deleteJoinRequest(companyCode, requestId);
      } catch (e) {
        _handleError(e);
      }
    }
  }

  Stream<List<JoinRequest>> streamJoinRequests(String companyCode) {
    return _firestore.joinRequestsStream(companyCode);
  }

  // ─────────────────────────────────────────────────────────────
  //  RESET / PURGE CACHE
  // ─────────────────────────────────────────────────────────────

  Future<void> clearCompanyCache(String companyCode) =>
      _storage.clearCompanyCache(companyCode);

  void _handleError(dynamic e) {
    if (e is DataException) {
      _lastError = e.message;
      _syncStatus =
          e.code == DataErrorCode.permissionDenied ||
              e.code == DataErrorCode.invalidData
          ? SyncStatus.error
          : SyncStatus.offline;
    } else {
      _lastError = e.toString();
      _syncStatus = SyncStatus.error;
    }
    debugPrint('CilaluRepository sync error: $_lastError');
  }
}
