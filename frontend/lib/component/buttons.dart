import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// BUTTONS — Bộ nút bấm thống nhất cho toàn app
/// ════════════════════════════════════════════════════════════════
///
/// Thay thế các nút ElevatedButton/OutlinedButton/TextButton rải rác
/// để giữ phong cách đồng nhất.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expanded;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.4,
            ),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          );

    final btn = Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : const LinearGradient(
                colors: AppColors.chatBubbleMineGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: disabled ? AppColors.neutralGray300 : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Center(child: child),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );

    final btn = Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.creamWhite,
        border: Border.all(
          color: AppColors.neutralGray300,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBrown.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Center(child: child),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final FontWeight? fontWeight;

  const TextLinkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryOrange;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTypography.labelMedium.copyWith(
          color: c,
          fontWeight: fontWeight,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Nút icon tròn nhỏ — dùng trong input bar chat, dialog action.
class IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? background;
  final Gradient? gradient;
  final double size;
  final double iconSize;

  const IconCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.background,
    this.gradient,
    this.size = 40,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).iconTheme.color;
    final hasGradient = gradient != null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasGradient ? null : (background ?? Colors.transparent),
        gradient: gradient,
        boxShadow: hasGradient
            ? [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, color: fg, size: iconSize),
          ),
        ),
      ),
    );
  }
}