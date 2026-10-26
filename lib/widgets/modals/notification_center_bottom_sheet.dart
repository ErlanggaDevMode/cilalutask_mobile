import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../state/app_state_scope.dart';

class NotificationCenterBottomSheet extends StatefulWidget {
  const NotificationCenterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationCenterBottomSheet(),
    );
  }

  @override
  State<NotificationCenterBottomSheet> createState() =>
      _NotificationCenterBottomSheetState();
}

class _NotificationCenterBottomSheetState
    extends State<NotificationCenterBottomSheet> {
  String _selectedFilter = 'all'; // 'all' | 'unread' | 'task' | 'chat' | 'sop'

  Color _getTypeColor(String type) {
    switch (type) {
      case 'chat':
        return const Color(0xFF4F46E5);
      case 'task':
        return AppColors.primary;
      case 'review':
        return const Color(0xFF9333EA);
      case 'sop':
        return const Color(0xFFD97706);
      case 'deadline':
        return AppColors.warning;
      case 'urgent':
        return AppColors.danger;
      case 'system':
      default:
        return const Color(0xFF0284C7);
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

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final allNotifs = state.notifications;
    final unreadCount = state.unreadNotificationsCount;

    final filteredNotifs = allNotifs.where((n) {
      if (_selectedFilter == 'unread') {
        return n.unread;
      }
      if (_selectedFilter == 'task') {
        return n.type == 'task' || n.type == 'review' || n.type == 'deadline';
      }
      if (_selectedFilter == 'chat') {
        return n.type == 'chat';
      }
      if (_selectedFilter == 'sop') {
        return n.type == 'sop';
      }
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pusat Notifikasi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => state.markAllNotificationsAsRead(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Tandai Baca ($unreadCount)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua (${allNotifs.length})'),
                const SizedBox(width: 6),
                _buildFilterChip('unread', 'Belum Dibaca ($unreadCount)'),
                const SizedBox(width: 6),
                _buildFilterChip('chat', 'Chat'),
                const SizedBox(width: 6),
                _buildFilterChip('task', 'Tugas'),
                const SizedBox(width: 6),
                _buildFilterChip('sop', 'SOP'),
              ],
            ),
          ),
          const Divider(height: 20, color: AppColors.border),

          // Notification List
          Expanded(
            child: filteredNotifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada notifikasi di kategori ini',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredNotifs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredNotifs[index];
                      final color = _getTypeColor(item.type);
                      final icon = _getTypeIcon(item.type);

                      return InkWell(
                        onTap: () {
                          state.markNotificationAsRead(item.id);
                          Navigator.of(context).pop();
                          if (item.targetTab != null) {
                            state.setTab(item.targetTab!);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.unread
                                ? const Color(0xFFF8FAFC)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.unread
                                  ? color.withValues(alpha: 0.35)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, size: 18, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: item.unread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (item.unread)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            margin: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      item.time,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

          // Bottom Button: View Full Tab
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                state.openNotificationsTab();
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'Buka Tab Tim & Notifikasi Lengkap',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBorder : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
