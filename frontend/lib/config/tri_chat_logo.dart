import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Logo TriChat — sử dụng asset PNG từ `assets/trichat_logo.png` (do team
/// thiết kế). Widget này là wrapper để chèn logo kèm tên thương hiệu.
class TriChatLogo extends StatelessWidget {
  /// Kích thước logo (chiều rộng = chiều cao)
  final double size;

  /// Có hiển thị tên "TriChat" bên cạnh logo hay không
  final bool showText;

  /// Cỡ chữ khi [showText] = true
  final double textFontSize;

  /// Màu chữ (mặc định theo theme)
  final Color? textColor;

  const TriChatLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textFontSize = 18,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark ? Colors.white : AppColors.neutralBlack;

    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.primaryOrange)
                .withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/trichat_logo.png',
          fit: BoxFit.contain,
          // PNG có nền trong suốt nên không cần set color
        ),
      ),
    );

    if (!showText) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: size * 0.25),
        Text(
          'TriChat',
          style: TextStyle(
            color: textColor ?? fallbackColor,
            fontSize: textFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

/// Phiên bản logo lớn dùng cho splash/intro
class TriChatLogoLarge extends StatelessWidget {
  final double size;
  const TriChatLogoLarge({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.primaryOrange)
                .withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/trichat_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
