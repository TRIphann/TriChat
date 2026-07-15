import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END BUTTONS — Premium Button System
/// ════════════════════════════════════════════════════════════════
///
/// Design Language:
/// - Amber primary accent for CTAs
/// - Soft diffused shadows for depth
/// - Large squircle radii (20-24px) for premium feel
/// - Fluid spring animations on interaction
/// - Nested architecture for icon buttons

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expanded;
  final bool secondary;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expanded = true,
    this.secondary = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppCurves.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.snappy),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onPressed == null || widget.loading;

    final bgColor = disabled
        ? (isDark ? AppColors.darkBorder : AppColors.borderDefault)
        : widget.secondary
            ? Colors.transparent
            : AppColors.primaryAmber;

    final borderColor = disabled
        ? (isDark ? AppColors.darkBorder : AppColors.borderStrong)
        : widget.secondary
            ? AppColors.textPrimary
            : Colors.transparent;

    final textColor = disabled
        ? (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)
        : widget.secondary
            ? AppColors.textPrimary
            : AppColors.textWhite;

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: disabled ? null : widget.onPressed,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: widget.secondary
                ? Border.all(color: borderColor, width: 1.5)
                : null,
            boxShadow: disabled || widget.secondary
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryAmber.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2.5,
                  ),
                ),
              ] else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: textColor),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  widget.label,
                  style: AppTypography.labelLarge.copyWith(color: textColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: content)
        : content;
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
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      expanded: expanded,
      secondary: true,
    );
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
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.primaryAmber,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.micro,
        ),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTypography.labelMedium.copyWith(
          color: color ?? AppColors.primaryAmber,
          fontWeight: fontWeight,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Premium icon button with nested circle
class IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? background;
  final double size;
  final double iconSize;

  const IconCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.background,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final bg = background ??
        (isDark ? AppColors.darkElevated : AppColors.creamSurface);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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

/// Floating action button with premium styling
class PremiumFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;

  const PremiumFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAmber.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label!),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAmber.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
