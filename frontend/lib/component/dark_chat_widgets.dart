import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

/// Nút CTA bo tròn dạng neon — gradient phát sáng + hover glow
/// Dùng cho "Thử lại", "Kết bạn", "Tạo nhóm"...
class NeonGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color> gradient;
  final double height;
  final double horizontalPadding;
  final double fontSize;
  final bool expanded;
  final bool showGlow; // toggle phát sáng hover

  const NeonGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.neonButtonGradient,
    this.height = 44,
    this.horizontalPadding = 22,
    this.fontSize = 14,
    this.expanded = true,
    this.showGlow = true,
  });

  @override
  State<NeonGradientButton> createState() => _NeonGradientButtonState();
}

class _NeonGradientButtonState extends State<NeonGradientButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final glowOn = widget.showGlow && _hovering;
    final gradientColors = glowOn
        ? widget.gradient
            .map((c) => Color.lerp(c, Colors.white, 0.18) ?? c)
            .toList()
        : widget.gradient;

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: widget.height,
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: glowOn
            ? [
                BoxShadow(
                  color: widget.gradient.first.withValues(alpha: 0.55),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: widget.gradient.first.withValues(alpha: 0.30),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: widget.gradient.first.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: widget.fontSize,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );

    final inner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        onHover: (v) {
          if (mounted) setState(() => _hovering = v);
        },
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: btn,
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: inner)
        : inner;
  }
}

/// Outline neon button — ghost style cho hành động phụ
class NeonOutlineButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color accent;
  final double height;
  final double horizontalPadding;
  final double fontSize;

  const NeonOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.accent,
    this.icon,
    this.height = 44,
    this.horizontalPadding = 22,
    this.fontSize = 14,
  });

  @override
  State<NeonOutlineButton> createState() => _NeonOutlineButtonState();
}

class _NeonOutlineButtonState extends State<NeonOutlineButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHover: (v) {
            if (mounted) setState(() => _hovering = v);
          },
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: _hovering
                    ? widget.accent
                    : widget.accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.accent, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: widget.fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Thẻ" neon outline icon — khung lớn có icon phát sáng ở giữa, dùng
/// cho empty/error state hoặc quick action.
class NeonOutlineIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;
  final double borderRadius;
  final double iconSize;
  final double glowStrength;

  const NeonOutlineIcon({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 96,
    this.borderRadius = 24,
    this.iconSize = 40,
    this.glowStrength = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.10),
            accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: glowStrength),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: accent.withValues(alpha: glowStrength * 0.6),
            blurRadius: 60,
            spreadRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: accent,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Thẻ trống rỗng dark premium — dùng làm empty-state, error-state trong
/// các cột của dashboard tối.
class DarkEmptyState extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final List<Color>? actionGradient;

  const DarkEmptyState({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeonOutlineIcon(
              icon: icon,
              accent: accentColor,
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkPremiumTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkPremiumTextSecondary,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              NeonGradientButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                gradient: actionGradient ??
                    [
                      accentColor,
                      Color.lerp(accentColor, Colors.white, 0.2) ??
                          accentColor,
                    ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thẻ neon outline dùng trong sidebar slim — dùng để highlight active
/// icon với glow phát sáng.
class NeonActiveCircle extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowBlur;
  final double size;
  final double borderRadius;

  const NeonActiveCircle({
    super.key,
    required this.child,
    this.glowColor = AppColors.neonRoyal,
    this.glowBlur = 18,
    this.size = 46,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.darkPremiumElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.55),
            blurRadius: glowBlur,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// Bo tròn góc lớn cho thẻ nội dung theo design — 18-22px
class DarkPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool showBorder;
  final List<BoxShadow>? boxShadow;

  const DarkPanel({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
    this.color,
    this.showBorder = true,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: AppColors.darkPremiumBorder,
                width: 1,
              )
            : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// Divider tinh tế cho dark premium — dùng ngăn cách sections
class DarkSectionDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  const DarkSectionDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(
        height: 1,
        color: AppColors.darkPremiumDivider,
      ),
    );
  }
}

/// Bo góc outline neon dùng cho thẻ pin nổi bật như "PINNED"
class NeonLabelChip extends StatelessWidget {
  final String text;
  final Color accent;
  const NeonLabelChip({
    super.key,
    required this.text,
    this.accent = AppColors.darkPremiumPinnedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: accent.withValues(alpha: 0.95),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Active state pill cho danh sách conversation — gradient blue + glow
class DarkActiveConversationTile extends StatelessWidget {
  final Widget child;
  const DarkActiveConversationTile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSelected,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonRoyal.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonRoyal.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Online dot — chấm tròn xanh neon phát sáng ở góc avatar
class NeonOnlineDot extends StatelessWidget {
  final double size;
  final bool showBorder;

  const NeonOnlineDot({
    super.key,
    this.size = 11,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.neonOnline,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: AppColors.darkPremiumBackground,
                width: 1.6,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.neonOnline.withValues(alpha: 0.8),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "statistic" dạng vuông bo góc dùng cho Files / Links trong panel Details.
/// Có icon và số lượng lớn hiển thị đậm.
class DarkStatTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String label;
  final int count;

  const DarkStatTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkPremiumSurface,
            Color.lerp(
                  AppColors.darkPremiumSurface,
                  accentColor,
                  0.05,
                ) ??
                AppColors.darkPremiumSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkPremiumBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.22),
                  accentColor.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.darkPremiumTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkPremiumTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "file type" (Documents / Photos / Movies) — vuông bo góc có icon neon.
class DarkFileTypeTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String label;
  final int count;

  const DarkFileTypeTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkPremiumBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkPremiumTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.darkPremiumTextSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "media tile" cho grid ảnh — bo góc nhỏ, hiển thị n + badge.
class DarkMediaTile extends StatelessWidget {
  final Widget child;
  final String? badge;
  const DarkMediaTile({super.key, required this.child, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
        if (badge != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
