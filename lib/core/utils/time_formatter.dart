/// Formats timestamps into human-readable Indonesian relative time.
/// Returns `'-'` when timestamp is null (legacy records without timestamp).
class TimeFormatter {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String formatRelative(DateTime? timestamp, {DateTime? now}) {
    if (timestamp == null) return '-';
    final ref = now ?? DateTime.now();
    final diff = ref.difference(timestamp);

    if (diff.isNegative || diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} minggu lalu';

    final local = timestamp.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
