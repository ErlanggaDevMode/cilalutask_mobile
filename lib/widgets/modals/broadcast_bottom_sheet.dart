import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BroadcastBottomSheet extends StatefulWidget {
  final void Function(String message, String targetDivision) onSendBroadcast;

  const BroadcastBottomSheet({super.key, required this.onSendBroadcast});

  static Future<void> show(
    BuildContext context, {
    required void Function(String message, String targetDivision)
    onSendBroadcast,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BroadcastBottomSheet(onSendBroadcast: onSendBroadcast),
      ),
    );
  }

  @override
  State<BroadcastBottomSheet> createState() => _BroadcastBottomSheetState();
}

class _BroadcastBottomSheetState extends State<BroadcastBottomSheet> {
  final _messageController = TextEditingController();
  String _targetDivision = 'Semua Divisi';
  bool _sent = false;

  final List<String> _divisions = [
    'Semua Divisi',
    'Operasional',
    'IT & Tech',
    'Pemasaran',
    'Finance & Akuntansi',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    widget.onSendBroadcast(msg, _targetDivision);
    setState(() => _sent = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengumuman berhasil disiarkan ke $_targetDivision!'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
              const Icon(
                Icons.campaign_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Kirim Pengumuman Tim',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
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
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Target Divisi
          const Text(
            'Target Penerima',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _targetDivision,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: _divisions
                .map(
                  (div) => DropdownMenuItem(
                    value: div,
                    child: Text(
                      div == 'Semua Divisi'
                          ? '$div (Broadcast Menyeluruh)'
                          : 'Divisi $div',
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _targetDivision = val);
            },
          ),
          const SizedBox(height: 14),

          // Pesan
          const Text(
            'Pesan Pengumuman',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _messageController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Ketik instruksi mendesak atau briefing harian untuk anggota tim...',
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sent ? null : _submit,
                  icon: Icon(
                    _sent ? Icons.check_rounded : Icons.send_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _sent ? 'Terkirim!' : 'Kirim Sekarang',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
