import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../models/notification_item.dart';
import '../../state/app_state_scope.dart';

class InAppNotificationBanner extends StatefulWidget {
  const InAppNotificationBanner({super.key});

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  NotificationItem? _displayedNotification;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, -1.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNotificationChange(NotificationItem? currentNotif) {
    if (currentNotif != null) {
      _displayedNotification = currentNotif;
      _controller.forward();
    } else {
      _controller.reverse().then((_) {
        if (mounted && currentNotif == null) {
          setState(() {
            _displayedNotification = null;
          });
        }
      });
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'chat':
        return const Color(0xFF4F46E5); // Indigo
      case 'task':
        return AppColors.primary;
      case 'review':
        return const Color(0xFF9333EA); // Purple
      case 'sop':
        return const Color(0xFFD97706); // Amber
      case 'deadline':
        return AppColors.warning;
      case 'urgent':
        return AppColors.danger;
      case 'system':
      default:
        return const Color(0xFF0284C7); // Cyan
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'task':
        return Icons.assignment_rounded;
      case 'review':
        return Icons.verified_user_rounded;
      case 'sop':
        return Icons.menu_book_rounded;
      case 'deadline':
        return Icons.alarm_rounded;
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'system':
      default:
        return Icons.campaign_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'chat':
        return 'CHAT TIM';
      case 'task':
        return 'TUGAS';
      case 'review':
        return 'PERSETUJUAN';
      case 'sop':
        return 'KEPATUHAN SOP';
      case 'deadline':
        return 'BATAS WAKTU';
      case 'urgent':
        return 'DARURAT';
      case 'system':
      default:
        return 'SISTEM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final currentNotif = state.activeInAppNotification;

    // Reactively trigger animations based on current notification
    if (currentNotif != _displayedNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleNotificationChange(currentNotif);
      });
    }

    final item = currentNotif ?? _displayedNotification;
    if (item == null) return const SizedBox.shrink();

    final accentColor = _getTypeColor(item.type);
    final iconData = _getTypeIcon(item.type);
    final label = _getTypeLabel(item.type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                state.dismissActiveNotification();
              }
            },
            onTap: () {
              final targetTab = item.targetTab;
              state.dismissActiveNotification();
              if (targetTab != null) {
                state.setTab(targetTab);
              }
            },
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Tag & Pulse
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => state.dismissActiveNotification(),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Title
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // Description
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
