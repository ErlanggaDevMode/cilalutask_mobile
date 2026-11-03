import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/notification_item.dart';
import '../data/mock_data.dart';
import '../repositories/cilalu_repository.dart';

/// Dedicated controller for in-app notifications, heads-up banners, and real-time alerts.
class NotificationController extends ChangeNotifier {
  final CilaluRepository _repository;

  List<NotificationItem> _notifications = List.from(kNotificationsData);
  NotificationItem? _activeInAppNotification;
  Timer? _inAppBannerTimer;
  StreamSubscription<List<NotificationItem>>? _notifsSubscription;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  NotificationController({
    CilaluRepository? repository,
    List<NotificationItem>? initialNotifications,
  }) : _repository = repository ?? CilaluRepository() {
    final source = initialNotifications ?? kNotificationsData;
    _notifications = source.where((n) => !_isDirectMessage(n)).toList();
  }

  static bool _isDirectMessage(NotificationItem n) {
    final title = n.title.toLowerCase();
    final type = n.type.toLowerCase();
    final targetId = n.targetId?.toLowerCase() ?? '';
    return title.contains('pesan langsung') ||
        title.contains('direct message') ||
        title.contains('direct') ||
        targetId == 'direct_chat' ||
        targetId.startsWith('direct') ||
        targetId.startsWith('dm') ||
        type == 'direct_chat' ||
        type == 'direct' ||
        type == 'dm';
  }

  List<NotificationItem> get notifications =>
      List.unmodifiable(_notifications.where((n) => !_isDirectMessage(n)));
  NotificationItem? get activeInAppNotification => _activeInAppNotification;
  int get unreadNotificationsCount =>
      notifications.where((n) => n.unread).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Sets notification list directly (e.g. for reset or mock initialization).
  void setNotifications(List<NotificationItem> items) {
    _notifications = items.where((n) => !_isDirectMessage(n)).toList();
    notifyListeners();
  }

  /// Clears notifications and cancels timers/subscriptions (e.g. on logout or company switch).
  void clear() {
    _cancelBannerTimer();
    cancelSubscription();
    _notifications = [];
    _activeInAppNotification = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads notification history for a company.
  Future<void> loadNotifications(String companyCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.getNotifications(companyCode);
      if (loaded.isNotEmpty || companyCode != 'CILALU-88') {
        _notifications = loaded.where((n) => !_isDirectMessage(n)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('NotificationController.loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts real-time stream subscription for company notifications.
  void startSubscription(String companyCode) {
    cancelSubscription();
    if (!_repository.isCloudAvailable) return;

    _notifsSubscription = _repository.streamNotifications(companyCode).listen((
      notifs,
    ) {
      if (notifs.isNotEmpty) {
        _notifications = notifs.where((n) => !_isDirectMessage(n)).toList();
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Notification subscription error: $e'));
  }

  /// Cancels active real-time stream subscription.
  void cancelSubscription() {
    _notifsSubscription?.cancel();
    _notifsSubscription = null;
  }

  /// Pushes a new notification item, triggers heads-up banner with haptic feedback,
  /// and writes to repository.
  void pushNotification(
    String companyCode,
    NotificationItem item, {
    bool showBanner = true,
  }) {
    // Direct messages (pesan langsung) 100% tidak boleh masuk ke Pusat Notifikasi
    if (_isDirectMessage(item)) {
      return;
    }

    _notifications = [item, ..._notifications];

    if (showBanner) {
      _cancelBannerTimer();
      _activeInAppNotification = item;
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}

      _inAppBannerTimer = Timer(const Duration(seconds: 4), () {
        dismissActiveNotification();
      });
    }

    _repository.pushNotification(companyCode, item);
    notifyListeners();
  }

  /// Dismisses active in-app banner immediately.
  void dismissActiveNotification() {
    _cancelBannerTimer();
    _activeInAppNotification = null;
    notifyListeners();
  }

  void _cancelBannerTimer() {
    _inAppBannerTimer?.cancel();
    _inAppBannerTimer = null;
  }

  /// Marks all current notifications as read.
  void markAllNotificationsAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(unread: false))
        .toList();
    notifyListeners();
  }

  /// Marks a specific notification as read.
  void markNotificationAsRead(String id) {
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(unread: false);
      }
      return n;
    }).toList();
    notifyListeners();
  }

  /// Deletes a specific notification from memory and repository.
  Future<void> deleteNotification(String companyCode, String notifId) async {
    _notifications = _notifications.where((n) => n.id != notifId).toList();
    notifyListeners();
    await _repository.deleteNotification(companyCode, notifId);
  }

  /// Clears all notifications from memory and repository.
  Future<void> clearAllNotifications(String companyCode) async {
    final ids = _notifications.map((n) => n.id).toList();
    _notifications = [];
    notifyListeners();
    await _repository.clearAllNotifications(companyCode, ids);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelBannerTimer();
    cancelSubscription();
    super.dispose();
  }
}
