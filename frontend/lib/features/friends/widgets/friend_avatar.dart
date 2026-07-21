import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

/// Avatar tròn có badge online, dùng chung khắp màn hình bạn bè.
class FriendAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final bool? isOnline;
  final Color? backgroundColor;

  const FriendAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 22,
    this.isOnline,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? _colorFromName(name),
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Text(
                  _initials(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: isOnline!
                    ? AppColors.success
                    : AppColors.neutralGray500,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBackground, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  Color _colorFromName(String n) {
    final colors = [
      AppColors.success,
      AppColors.primaryOrange,
      AppColors.accentRed,
      AppColors.textPrimary,
      AppColors.primaryOrangeLight,
      AppColors.textSecondary,
      AppColors.textSecondary,
      AppColors.textTertiary,
      const Color(0xFFFF5722),
      AppColors.primaryOrange,
    ];
    return colors[n.codeUnitAt(0) % colors.length];
  }
}
