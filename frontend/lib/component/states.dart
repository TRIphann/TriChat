import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END STATES — Premium Empty/Error/Loading Components
/// ════════════════════════════════════════════════════════════════
///
/// Design Language:
/// - Generous whitespace
/// - Soft gradient backgrounds
/// - Premium icon containers with shadows
/// - Smooth animations

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
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium icon container with shadow
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.darkElevated,
                          AppColors.darkSurface,
                        ]
                      : [
                          AppColors.creamWhite,
                          AppColors.creamSurface,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (text != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
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
    final isDark = theme.brightness == Brightness.dark;
    final bodyText = subtitle ?? message ?? error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium error icon with gradient background
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.errorLight,
                    Color(0xFFFEE2E2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title ?? 'Đã có lỗi xảy ra',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (bodyText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                bodyText,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAmber.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
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

  const LoadingView({
    super.key,
    this.message,
    this.icon,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: size,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ] else ...[
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? AppColors.primaryAmber : AppColors.primaryAmber,
                ),
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium section header with eyebrow text
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool upperCase;
  final bool isDark;
  final String? eyebrow;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    this.upperCase = true,
    this.isDark = false,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ||
        Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.micro,
              ),
              decoration: BoxDecoration(
                color: effectiveIsDark
                    ? AppColors.darkElevated
                    : AppColors.primaryAmberLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                eyebrow!.toUpperCase(),
                style: AppTypography.eyebrow.copyWith(
                  color: AppColors.primaryAmber,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  upperCase ? title.toUpperCase() : title,
                  style: AppTypography.labelMedium.copyWith(
                    color: effectiveIsDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

/// Premium card with soft shadows and rounded corners
class SoftCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final double radius;
  final bool elevated;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.background,
    this.radius = AppRadius.xl,
    this.elevated = true,
  });

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = widget.background ??
        (isDark ? AppColors.darkCard : AppColors.creamWhite);

    return AnimatedContainer(
      duration: AppCurves.durationFast,
      curve: AppCurves.snappy,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
          width: 1,
        ),
        boxShadow: widget.elevated && !_isPressed
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(widget.radius),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

/// Premium shimmer loading placeholder
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppRadius.md,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? [
                      AppColors.darkSurface,
                      AppColors.darkElevated,
                      AppColors.darkSurface,
                    ]
                  : [
                      AppColors.creamSurface,
                      AppColors.creamElevated,
                      AppColors.creamSurface,
                    ],
            ),
          ),
        );
      },
    );
  }
}
