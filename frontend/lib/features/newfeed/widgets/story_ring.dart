import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

/// StoryRing với gradient multi-stop đẹp mắt kiểu Instagram.
/// - isOwner: cam gradient
/// - hasUnseen: gradient hồng-cam-vàng kiểu Instagram
/// - seen: xám nhạt
class StoryRing extends StatelessWidget {
  final bool hasUnseen;
  final bool isOwner;
  final double size;
  final Widget child;

  const StoryRing({
    super.key,
    required this.hasUnseen,
    required this.isOwner,
    this.size = 58,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (hasUnseen && !isOwner) {
      // Instagram-style gradient
      return Container(
        width: size + 5,
        height: size + 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.primaryOrangeLight,
              AppColors.accentRed,
              AppColors.accentBrown,
            ],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRed.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(child: child),
        ),
      );
    }

    if (isOwner) {
      return Container(
        width: size + 5,
        height: size + 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFA63D), AppColors.primaryOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(child: child),
        ),
      );
    }

    // Đã xem: gradient xám
    return Container(
      width: size + 5,
      height: size + 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD0D2D6),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(child: child),
      ),
    );
  }
}
