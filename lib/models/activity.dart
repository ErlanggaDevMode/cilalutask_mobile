class ActivityItem {
  final String id;
  final String userName;
  final String userAvatar;
  final String actionPrefix;
  final String targetObject;
  final String? actionSuffix;
  final String timeAgo;
  final String department;
  final String type; // 'sop' | 'task'

  const ActivityItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.actionPrefix,
    required this.targetObject,
    this.actionSuffix,
    required this.timeAgo,
    required this.department,
    required this.type,
  });
}
