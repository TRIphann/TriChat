import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// STATES — Empty / Error / Loading chuẩn
/// ════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = subtitle ?? message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.12),
                    AppColors.accentRed.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (text != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String? error;
  final String? message;
  final String? subtitle;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String? title;

  const ErrorStateView({
    super.key,
    this.error,
    this.message,
    this.subtitle,
    this.onRetry,
    this.icon,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyText = subtitle ?? message ?? error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title ?? 'Đã có lỗi xảy ra',
              style: AppTypography.titleMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (bodyText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                bodyText,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryButtonGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: onRetry,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Thử lại',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final double size;
  const LoadingView({super.key, this.message, this.icon, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size, color: AppColors.primaryOrange),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Section heading — dùng cho tiêu đề section trong list, settings, profile.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool upperCase;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    this.upperCase = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              upperCase ? title.toUpperCase() : title,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.getTextSecondary(isDark),
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card surface có shadow mềm + bo góc — dùng cho mọi card trong app.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.background,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = background ?? theme.colorScheme.surface;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
          width: 0.6,
        ),
        boxShadow: AppShadows.xs,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}