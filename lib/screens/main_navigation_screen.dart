import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/custom_avatar.dart';
import '../core/widgets/in_app_notification_banner.dart';
import '../repositories/data_exception.dart';
import '../state/app_state_scope.dart';
import '../widgets/modals/notification_center_bottom_sheet.dart';
import '../widgets/modals/profile_bottom_sheet.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'sop/sop_screen.dart';
import 'reports/reports_screen.dart';
import 'chat/chat_screen.dart';
import 'team/team_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  String _getSubTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Beranda';
      case 1:
        return 'Tugas';
      case 2:
        return 'Sop';
      case 3:
        return 'Laporan';
      case 4:
        return 'Chat Tim';
      case 5:
        return 'Tim';
      default:
        return 'Beranda';
    }
  }

  Widget _buildSyncBadge(SyncStatus status) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_rounded;
        color = AppColors.success;
        tooltip = 'Cloud Firestore Tersinkron';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = AppColors.primary;
        tooltip = 'Menyinkronkan...';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_rounded;
        color = AppColors.warning;
        tooltip = 'Mode Offline (Cache Tersimpan)';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off_rounded;
        color = AppColors.danger;
        tooltip = 'Sinkronisasi Gagal';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 11, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final currentTab = state.currentTabIndex;
    final unreadNotifs = state.unreadNotificationsCount;
    final activeReviewCount = state.activeReviewCount;

    final screens = const [
      HomeScreen(),
      TasksScreen(),
      SopScreen(),
      ReportsScreen(),
      ChatScreen(),
      TeamScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Shield Logo
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Brand Text & Subtitle & Role Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text(
                                'CILALUTASK',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: state.isAdmin
                                      ? AppColors.primaryLight
                                      : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  state.isAdmin ? 'ADMIN' : 'USER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: state.isAdmin
                                        ? AppColors.primary
                                        : AppColors.successDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              _buildSyncBadge(state.syncStatus),
                            ],
                          ),
                        ),
                        Text(
                          _getSubTitle(currentTab),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Notification Bell (opens real-time notification sheet)
                  IconButton(
                    onPressed: () =>
                        NotificationCenterBottomSheet.show(context),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                        if (unreadNotifs > 0)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),

                  // Profile Avatar
                  InkWell(
                    onTap: () {
                      ProfileBottomSheet.show(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: CustomAvatar(
                      imageUrl: state.currentUserAvatar,
                      fallbackText: state.currentUserName,
                      radius: 16,
                      borderColor: state.isAdmin
                          ? AppColors.primaryBorder
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(index: currentTab, children: screens),
          if (state.isLoadingCompanyData)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          const InAppNotificationBanner(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.primaryLight,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  );
                }
                return const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: currentTab,
              onDestinationSelected: (index) => state.setTab(index),
              backgroundColor: Colors.white,
              elevation: 0,
              height: 64,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(
                    Icons.home_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Badge(
                    label: Text('$activeReviewCount'),
                    isLabelVisible: activeReviewCount > 0,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.assignment_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text('$activeReviewCount'),
                    isLabelVisible: activeReviewCount > 0,
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  label: 'Tugas',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'SOP',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Laporan',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(
                    Icons.chat_bubble_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Chat',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(
                    Icons.group_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Tim',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
