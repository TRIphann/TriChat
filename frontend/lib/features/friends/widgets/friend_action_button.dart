import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

enum FriendActionStyle { primary, secondary, danger, ghost }

/// Nút hành động chuẩn dùng trong danh sách bạn bè / tìm kiếm.
/// Hỗ trợ loading state và 4 style khác nhau.
/// Hỗ trợ dark mode với tham số isDark.
class FriendActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final FriendActionStyle style;
  final double height;
  final double? minWidth;
  final bool isDark;

  const FriendActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.style = FriendActionStyle.primary,
    this.height = 32,
    this.minWidth,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _styleConfig();

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cfg.bg,
          border: cfg.border,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cfg.fg),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 15, color: cfg.fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cfg.fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BtnConfig _styleConfig() {
    if (isDark) {
      switch (style) {
        case FriendActionStyle.primary:
          return _BtnConfig(bg: AppColors.neonRoyal, fg: Colors.white);
        case FriendActionStyle.secondary:
          return _BtnConfig(
            bg: AppColors.neonRoyal.withValues(alpha: 0.15),
            fg: AppColors.neonRoyal,
          );
        case FriendActionStyle.danger:
          return _BtnConfig(
            bg: AppColors.neonRed.withValues(alpha: 0.15),
            fg: AppColors.neonRed,
          );
        case FriendActionStyle.ghost:
          return _BtnConfig(
            bg: Colors.transparent,
            fg: AppColors.darkPremiumTextSecondary,
            border: Border.all(color: AppColors.darkPremiumBorder, width: 1),
          );
      }
    }
    switch (style) {
      case FriendActionStyle.primary:
        return _BtnConfig(bg: AppColors.primaryOrange, fg: Colors.white);
      case FriendActionStyle.secondary:
        return _BtnConfig(
          bg: const Color(0xFFEBF2FF),
          fg: AppColors.primaryOrange,
        );
      case FriendActionStyle.danger:
        return _BtnConfig(
          bg: const Color(0xFFFFEBEB),
          fg: AppColors.accentRed,
        );
      case FriendActionStyle.ghost:
        return _BtnConfig(
          bg: Colors.transparent,
          fg: AppColors.textSecondary,
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
        );
    }
  }
}

class _BtnConfig {
  final Color bg;
  final Color fg;
  final BoxBorder? border;
  const _BtnConfig({required this.bg, required this.fg, this.border});
}
