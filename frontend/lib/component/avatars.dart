import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// AVATAR — Thống nhất mọi avatar trong app
/// ════════════════════════════════════════════════════════════════

class TriAvatar extends StatelessWidget {
  /// URL ảnh đại diện (rỗng = dùng initials).
  final String imageUrl;

  /// Tên người dùng (dùng để lấy chữ cái đầu và màu nền).
  final String name;

  /// Kích thước đường kính (mặc định 48).
  final double size;

  /// Có viền gradient kiểu story hay không.
  final bool storyRing;

  /// Story đã xem hay chưa (chỉ ý nghĩa khi [storyRing] = true).
  final bool storySeen;

  /// Icon overlay (vd: icon group).
  final IconData? overlayIcon;

  /// Số overlay ở góc (vd: số thành viên group).
  final int? overlayCount;

  /// Có hiển thị chấm online ở góc hay không.
  final bool online;

  /// Có shadow hay không.
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

  Color get _bgColor => AppColors.avatarColorFor(name);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double inner = size;
    final double ringWidth = storyRing ? size * 0.07 : 0;
    final double outerSize = inner + ringWidth * 2;

    Widget avatarContent = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl.isEmpty
            ? LinearGradient(
                colors: [_bgColor, Color.lerp(_bgColor, Colors.black, 0.15)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _bgColor,
                        Color.lerp(_bgColor, Colors.black, 0.15)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
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
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: storySeen
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : AppColors.storyUnseenGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkSurface : AppColors.creamWhite,
          ),
          padding: const EdgeInsets.all(2.5),
          child: avatarContent,
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
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.chatBubbleMineGradient,
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isDark ? AppColors.darkSurface : AppColors.creamWhite,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${overlayCount!}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
            width: inner * 0.36,
            height: inner * 0.36,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkSurface : AppColors.creamWhite,
                width: 2,
              ),
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
            width: inner * 0.28,
            height: inner * 0.28,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkSurface : AppColors.creamWhite,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
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

/// Badge số nhỏ (unread count) — pill màu cam-đỏ gradient.
class UnreadBadge extends StatelessWidget {
  final int count;
  final double size;
  const UnreadBadge({super.key, required this.count, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.chatBubbleMineGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
          ),
        ),
      ),
    );
  }
}