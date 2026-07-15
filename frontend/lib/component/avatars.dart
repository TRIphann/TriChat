import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END AVATARS — Premium Avatar System
/// ════════════════════════════════════════════════════════════════
///
/// Design Language:
/// - Premium gradient backgrounds for initials
/// - Soft shadows for depth
/// - Animated story ring with gradient
/// - Smooth hover/focus states

class TriAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;
  final bool storyRing;
  final bool storySeen;
  final IconData? overlayIcon;
  final int? overlayCount;
  final bool online;
  final bool elevated;

  const TriAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 48,
    this.storyRing = false,
    this.storySeen = false,
    this.overlayIcon,
    this.overlayCount,
    this.online = false,
    this.elevated = false,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Color get _bgColor {
    const palette = [
      Color(0xFFD97706),
      Color(0xFF16A34A),
      Color(0xFF2563EB),
      Color(0xFFDC2626),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
    ];
    if (name.isEmpty) return palette.first;
    return palette[name.codeUnitAt(0) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double inner = size;
    final double ringWidth = storyRing ? size * 0.055 : 0;
    final double outerSize = inner + ringWidth * 2 + 4;
    final borderColor = isDark ? AppColors.darkBackground : AppColors.cream;

    Widget avatarContent = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageUrl.isEmpty ? _bgColor : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: inner * 0.38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _bgColor,
                  child: Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: inner * 0.38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _bgColor.withValues(alpha: 0.2),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: inner * 0.3,
                      height: inner * 0.3,
                      child: CircularProgressIndicator(
                        color: _bgColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
      ),
    );

    Widget wrap = avatarContent;

    if (storyRing) {
      wrap = Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: storySeen
                ? [
                    isDark ? AppColors.darkBorder : AppColors.borderStrong,
                    isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ]
                : [
                    AppColors.primaryAmber,
                    AppColors.accentWarm,
                  ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(ringWidth + 2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: borderColor,
            ),
            padding: const EdgeInsets.all(2),
            child: avatarContent,
          ),
        ),
      );
    }

    final overlays = <Widget>[];

    if (overlayCount != null) {
      overlays.add(
        Positioned(
          left: -2,
          bottom: -2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryAmber,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${overlayCount!}',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (overlayIcon != null) {
      overlays.add(
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: inner * 0.38,
            height: inner * 0.38,
            decoration: BoxDecoration(
              color: AppColors.primaryAmber,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              overlayIcon,
              color: Colors.white,
              size: inner * 0.2,
            ),
          ),
        ),
      );
    }

    if (online) {
      overlays.add(
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: inner * 0.3,
            height: inner * 0.3,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (overlays.isEmpty) return wrap;
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(clipBehavior: Clip.none, children: [wrap, ...overlays]),
    );
  }
}

/// Premium unread badge with amber accent
class UnreadBadge extends StatelessWidget {
  final int count;
  final double size;

  const UnreadBadge({
    super.key,
    required this.count,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAmber,
            AppColors.accentWarm,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAmber.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Online indicator dot with premium styling
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppCurves.durationNormal,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppColors.success : AppColors.textTertiary,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}
