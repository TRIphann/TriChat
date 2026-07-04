import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Logo TriChat
///
/// SVG-style icon: chữ "T" cách điệu trong hình tròn gradient cam-nâu.
/// Dùng cho app icon, splash screen, navigation drawer header, v.v.
class TriChatLogo extends StatelessWidget {
  /// Kích thước logo (chiều rộng = chiều cao)
  final double size;

  /// Có hiển thị tên "TriChat" bên cạnh logo hay không
  final bool showText;

  /// Cỡ chữ khi [showText] = true
  final double textFontSize;

  /// Màu chữ (mặc định theo theme)
  final Color? textColor;

  /// Màu nền của vòng tròn
  final List<Color>? gradientColors;

  const TriChatLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textFontSize = 18,
    this.textColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        const [
          AppColors.primaryOrangeLight, // cam sáng
          AppColors.primaryOrange, // cam đậm
          AppColors.accentBrown, // nâu cam
          AppColors.accentBrown, // nâu đậm
        ];

    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TriChatMarkPainter(
          color: Colors.white,
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
            color: textColor ?? AppColors.neutralBlack,
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

/// Vẽ chữ "T" cách điệu — dấu gạch ngang phía trên và thân chữ T
class _TriChatMarkPainter extends CustomPainter {
  final Color color;

  _TriChatMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Thanh ngang phía trên (chiếm ~70% chiều rộng)
    final barHeight = h * 0.14;
    final barWidth = w * 0.62;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (w - barWidth) / 2,
        h * 0.20,
        barWidth,
        barHeight,
      ),
      Radius.circular(barHeight / 2),
    );
    canvas.drawRRect(barRect, paint);

    // Thân chữ T (giữa)
    final stemWidth = w * 0.20;
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (w - stemWidth) / 2,
        h * 0.28,
        stemWidth,
        h * 0.55,
      ),
      Radius.circular(stemWidth / 2),
    );
    canvas.drawRRect(stemRect, paint);

    // Điểm chấm nhỏ ở dưới (biểu tượng cho "chat" / tin nhắn)
    final dotRadius = w * 0.075;
    canvas.drawCircle(
      Offset(w / 2, h * 0.92),
      dotRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TriChatMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Phiên bản logo lớn dùng cho splash/intro
class TriChatLogoLarge extends StatelessWidget {
  final double size;
  const TriChatLogoLarge({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrangeLight,
            AppColors.primaryOrange,
            AppColors.accentBrown,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TriChatMarkPainter(color: Colors.white),
      ),
    );
  }
}
