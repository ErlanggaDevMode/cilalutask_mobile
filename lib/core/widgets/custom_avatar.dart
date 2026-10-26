import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  final double radius;
  final bool hasBorder;
  final Color borderColor;
  final int? teamCount;
  final List<Color>? customGradient;

  const CustomAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 18,
    this.hasBorder = true,
    this.borderColor = AppColors.border,
    this.teamCount,
    this.customGradient,
  });

  static const List<List<Color>> gradientPalettes = [
    [Color(0xFF1D4ED8), Color(0xFF3B82F6)], // Blue
    [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo-Purple
    [Color(0xFF059669), Color(0xFF10B981)], // Emerald
    [Color(0xFFD97706), Color(0xFFF59E0B)], // Amber
    [Color(0xFFE11D48), Color(0xFFFB7185)], // Rose
    [Color(0xFF0284C7), Color(0xFF06B6D4)], // Cyan
    [Color(0xFF0F172A), Color(0xFF334155)], // Slate
    [Color(0xFF7C2D12), Color(0xFFEA580C)], // Orange Brown
  ];

  static List<Color> getGradientForName(String name) {
    if (name.trim().isEmpty) return gradientPalettes[0];
    final hash = name.trim().codeUnits.fold(0, (prev, elem) => prev + elem);
    return gradientPalettes[hash % gradientPalettes.length];
  }

  static String getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final single = parts[0];
      return single.substring(0, single.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(fallbackText);
    final gradientColors = customGradient ?? getGradientForName(fallbackText);
    final hasValidUrl =
        imageUrl.trim().startsWith('http://') ||
        imageUrl.trim().startsWith('https://');

    Widget avatarCircle = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasBorder ? Border.all(color: borderColor, width: 1.5) : null,
        gradient: !hasValidUrl
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: hasValidUrl
          ? ClipOval(
              child: Image.network(
                imageUrl.trim(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialsWidget(initials, gradientColors),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildInitialsWidget(initials, gradientColors);
                },
              ),
            )
          : _buildInitialsWidget(initials, gradientColors),
    );

    if (teamCount != null && teamCount! > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCircle,
          Positioned(
            right: -4,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: Text(
                '+$teamCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatarCircle;
  }

  Widget _buildInitialsWidget(String initials, List<Color> colors) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
