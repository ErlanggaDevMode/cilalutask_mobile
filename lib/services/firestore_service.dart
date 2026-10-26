import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/data_parser.dart';
import '../models/company.dart';
import '../models/task.dart';
import '../models/sop.dart';
import '../models/employee.dart';
import '../models/chat_model.dart';
import '../models/notification_item.dart';
import '../repositories/data_exception.dart';

/// Cloud Firestore service providing granular, secure, and multi-tenant operations.
/// All corporate collections are strictly partitioned under `/companies/{companyCode}/...`.
class FirestoreService {
  static FirestoreService? _instance;
  factory FirestoreService() => _instance ??= FirestoreService._();
  FirestoreService._();

  @visibleForTesting
  FirestoreService.forTesting();

  FirebaseFirestore? _db;
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Check if Firestore is reachable and initialize instance
  Future<void> init() async {
    try {
      _db = FirebaseFirestore.instance;
      _isAvailable = true;
      // Quick connectivity check against healthcheck doc
      await _db!
          .collection('_ping')
          .doc('status')
          .get()
          .timeout(const Duration(seconds: 4));
      debugPrint('☁️ Firestore: Connected and ready');
    } catch (e) {
      _isAvailable = _db != null;
      debugPrint('☁️ Firestore: Initialized (offline mode enabled) — $e');
    }
  }

  DataException _mapError(dynamic e) {
    if (e is DataException) return e;
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return DataException(
          message: 'Akses ditolak oleh Security Rules Firestore.',
          code: DataErrorCode.permissionDenied,
          originalError: e,
        );
      } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return DataException(
          message: 'Server Firestore tidak dapat dihubungi atau perangkat sedang offline.',
          code: DataErrorCode.networkUnavailable,
          originalError: e,
        );
      } else if (e.code == 'not-found') {
        return DataException(
          message: 'Dokumen tidak ditemukan di Firestore.',
          code: DataErrorCode.notFound,
          originalError: e,
        );
      }
    }
    return DataException(
      message: e.toString(),
      code: DataErrorCode.unknown,
      originalError: e,
    );
  }

  // ───────────────────────────────────────────────────
  //  Companies (Global Collection)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _companiesRef =>
      _db!.collection('companies');

  Future<void> saveCompany(Company company) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore tidak tersedia (offline)',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _companiesRef.doc(company.code).set(company.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<Company>> loadCompanies() async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _companiesRef.get();
      return snap.docs.map((doc) => Company.fromMap(doc.data())).toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<Company?> loadCompanyByCode(String code) async {
    if (!_isAvailable || _db == null) return null;
    try {
      final doc = await _companiesRef.doc(code).get();
      if (doc.exists && doc.data() != null) {
        return Company.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteCompany(String code) async {
    if (!_isAvailable || _db == null) return;
    try {
      await _companiesRef.doc(code).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ───────────────────────────────────────────────────
  //  Tasks (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _tasksRef(String companyCode) =>
      _companiesRef.doc(companyCode).collection('tasks');

  Future<void> createTask(String companyCode, Task task) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _tasksRef(companyCode).doc(task.id).set(task.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> updateTask(String companyCode, Task task) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _tasksRef(companyCode)
          .doc(task.id)
          .set(task.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteTask(String companyCode, String taskId) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _tasksRef(companyCode).doc(taskId).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<Task>> loadTasks(String companyCode, {int limit = 100}) async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _tasksRef(companyCode).limit(limit).get();
      return snap.docs
          .map((doc) => Task.fromMap(DataParser.parseMap(doc.data())))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> saveTasks(String companyCode, List<Task> tasks) async {
    if (!_isAvailable || _db == null) return;
    try {
      final batch = _db!.batch();
      for (final task in tasks) {
        batch.set(_tasksRef(companyCode).doc(task.id), task.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ───────────────────────────────────────────────────
  //  SOPs (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _sopsRef(String companyCode) =>
      _companiesRef.doc(companyCode).collection('sops');

  Future<void> createSop(String companyCode, SOPDocument sop) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _sopsRef(companyCode).doc(sop.id).set(sop.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> updateSop(String companyCode, SOPDocument sop) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _sopsRef(companyCode)
          .doc(sop.id)
          .set(sop.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteSop(String companyCode, String sopId) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _sopsRef(companyCode).doc(sopId).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<SOPDocument>> loadSops(String companyCode) async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _sopsRef(companyCode).get();
      return snap.docs
          .map((doc) => SOPDocument.fromMap(DataParser.parseMap(doc.data())))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> saveSops(String companyCode, List<SOPDocument> sops) async {
    if (!_isAvailable || _db == null) return;
    try {
      final batch = _db!.batch();
      for (final sop in sops) {
        batch.set(_sopsRef(companyCode).doc(sop.id), sop.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ───────────────────────────────────────────────────
  //  Employees / Members (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _membersRef(String companyCode) =>
      _companiesRef.doc(companyCode).collection('members');

  Future<void> createMember(String companyCode, Assignee member) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _membersRef(companyCode).doc(member.id).set(member.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> updateMember(String companyCode, Assignee member) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _membersRef(companyCode)
          .doc(member.id)
          .set(member.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteMember(String companyCode, String memberId) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _membersRef(companyCode).doc(memberId).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<Assignee>> loadEmployees(String companyCode) async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _membersRef(companyCode).get();
      return snap.docs
          .map((doc) => Assignee.fromMap(DataParser.parseMap(doc.data())))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> saveEmployees(
    String companyCode,
    List<Assignee> employees,
  ) async {
    if (!_isAvailable || _db == null) return;
    try {
      final batch = _db!.batch();
      for (final emp in employees) {
        batch.set(_membersRef(companyCode).doc(emp.id), emp.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ───────────────────────────────────────────────────
  //  Chat Channels (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _channelsRef(String companyCode) =>
      _companiesRef.doc(companyCode).collection('channels');

  Future<void> saveChannels(
    String companyCode,
    List<ChatChannel> channels,
  ) async {
    if (!_isAvailable || _db == null) return;
    try {
      final batch = _db!.batch();
      for (final ch in channels) {
        batch.set(_channelsRef(companyCode).doc(ch.id), ch.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<ChatChannel>> loadChannels(String companyCode) async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _channelsRef(companyCode).get();
      return snap.docs
          .map((doc) => ChatChannel.fromMap(DataParser.parseMap(doc.data())))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ───────────────────────────────────────────────────
  //  Chat Messages (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _messagesRef(String companyCode) =>
      _companiesRef.doc(companyCode).collection('messages');

  Future<void> saveMessage(String companyCode, ChatMessage message) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _messagesRef(companyCode).doc(message.id).set(message.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteMessage(String companyCode, String messageId) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _messagesRef(companyCode).doc(messageId).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<ChatMessage>> loadMessages(
    String companyCode, {
    String? channelId,
    int limit = 50,
  }) async {
    if (!_isAvailable || _db == null) return [];
    try {
      Query<Map<String, dynamic>> query = _messagesRef(companyCode);
      if (channelId != null) {
        query = query.where('channelId', isEqualTo: channelId);
      }
      final snap = await query.orderBy('timestamp').limit(limit).get();
      return snap.docs
          .map((doc) => ChatMessage.fromMap(DataParser.parseMap(doc.data())))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Listen to real-time chat messages with bounded limit
  Stream<List<ChatMessage>> messagesStream(
    String companyCode, {
    String? channelId,
    int limit = 50,
  }) {
    if (!_isAvailable || _db == null) return const Stream.empty();
    Query<Map<String, dynamic>> query = _messagesRef(companyCode);
    if (channelId != null) {
      query = query.where('channelId', isEqualTo: channelId);
    }
    return query
        .orderBy('timestamp')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ChatMessage.fromMap(DataParser.parseMap(doc.data())),
              )
              .toList(),
        );
  }

  // ───────────────────────────────────────────────────
  //  Join Requests (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _joinRequestsRef(
    String companyCode,
  ) => _companiesRef.doc(companyCode).collection('join_requests');

  Future<void> saveJoinRequest(String companyCode, JoinRequest request) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _joinRequestsRef(companyCode).doc(request.id).set(request.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> updateJoinRequestStatus(
    String companyCode,
    String requestId,
    JoinRequestStatus status,
  ) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _joinRequestsRef(companyCode)
          .doc(requestId)
          .update({'status': status.name});
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteJoinRequest(String companyCode, String requestId) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      await _joinRequestsRef(companyCode).doc(requestId).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<JoinRequest>> loadJoinRequests(String companyCode) async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _joinRequestsRef(companyCode).get();
      return snap.docs
          .map((doc) => JoinRequest.fromMap(DataParser.parseMap(doc.data())))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Atomic Batch: Approve join request, add member, and post welcome notification
  Future<void> acceptJoinRequestBatch({
    required String companyCode,
    required JoinRequest request,
    required Assignee member,
    NotificationItem? welcomeNotif,
  }) async {
    if (!_isAvailable || _db == null) {
      throw const DataException(
        message: 'Firestore offline',
        code: DataErrorCode.networkUnavailable,
      );
    }
    try {
      final batch = _db!.batch();
      // 1. Mark request approved
      batch.update(_joinRequestsRef(companyCode).doc(request.id), {
        'status': JoinRequestStatus.approved.name,
      });
      // 2. Add member
      batch.set(_membersRef(companyCode).doc(member.id), member.toMap());
      // 3. Post notification
      if (welcomeNotif != null) {
        batch.set(
          _notifsRef(companyCode).doc(welcomeNotif.id),
          welcomeNotif.toMap(),
        );
      }
      await batch.commit();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Stream<List<JoinRequest>> joinRequestsStream(String companyCode) {
    if (!_isAvailable || _db == null) return const Stream.empty();
    return _joinRequestsRef(companyCode).snapshots().map(
      (snap) => snap.docs
          .map((doc) => JoinRequest.fromMap(DataParser.parseMap(doc.data())))
          .toList(),
    );
  }

  // ───────────────────────────────────────────────────
  //  Notifications (Sub-collection per company)
  // ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _notifsRef(String companyCode) =>
      _companiesRef.doc(companyCode).collection('notifications');

  Future<void> saveNotification(
    String companyCode,
    NotificationItem notif,
  ) async {
    if (!_isAvailable || _db == null) return;
    try {
      await _notifsRef(companyCode).doc(notif.id).set(notif.toMap());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteNotification(String companyCode, String notifId) async {
    if (!_isAvailable || _db == null) return;
    try {
      await _notifsRef(companyCode).doc(notifId).delete();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> clearNotifications(
    String companyCode,
    List<String> notifIds,
  ) async {
    if (!_isAvailable || _db == null || notifIds.isEmpty) return;
    try {
      final batch = _db!.batch();
      for (final id in notifIds) {
        batch.delete(_notifsRef(companyCode).doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<NotificationItem>> loadNotifications(
    String companyCode, {
    int limit = 50,
  }) async {
    if (!_isAvailable || _db == null) return [];
    try {
      final snap = await _notifsRef(companyCode).limit(limit).get();
      return snap.docs
          .map(
            (doc) => NotificationItem.fromMap(DataParser.parseMap(doc.data())),
          )
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Stream<List<NotificationItem>> notificationsStream(String companyCode) {
    if (!_isAvailable || _db == null) return const Stream.empty();
    return _notifsRef(companyCode).snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) => NotificationItem.fromMap(DataParser.parseMap(doc.data())),
          )
          .toList(),
    );
  }
}
