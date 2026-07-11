import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Logo TriChat — Phiên bản mới "Chat + Bạn Bè"
///
/// Kết hợp biểu tượng chat bubble và biểu tượng friend trong một
/// hình tròn gradient cam san hô + nâu socola sữa.
///
/// Phong cách: hiện đại, tối giản, tinh tế.
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
          AppColors.primaryOrangeLight, // cam san hô sáng
          AppColors.primaryOrange, // cam san hô
          AppColors.accentBrown, // nâu socola
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

/// Vẽ icon TriChat mới:
/// - Bong bóng chat lớn ở phía sau (đại diện cho chat/tin nhắn)
/// - Hai chấm tròn nhỏ bên trong (mắt người / chat dots)
/// - Bong bóng nhỏ hơn ở góc dưới phải (đại diện cho bạn bè)
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

    // Bong bóng chat chính — hình tròn lớn ở giữa-trên
    final mainBubbleRadius = w * 0.30;
    final mainBubbleCenter = Offset(w * 0.45, h * 0.45);
    canvas.drawCircle(mainBubbleCenter, mainBubbleRadius, paint);

    // Đuôi bong bóng (tail) — tam giác nhỏ dưới bong bóng chính
    final tailPath = Path()
      ..moveTo(w * 0.36, h * 0.62)
      ..lineTo(w * 0.42, h * 0.74)
      ..lineTo(w * 0.46, h * 0.62)
      ..close();
    canvas.drawPath(tailPath, paint);

    // Bong bóng phụ (bạn bè) — nhỏ hơn ở góc dưới phải
    final smallBubbleRadius = w * 0.20;
    final smallBubbleCenter = Offset(w * 0.74, h * 0.74);
    canvas.drawCircle(smallBubbleCenter, smallBubbleRadius, paint);

    // Đuôi bong bóng phụ
    final tailPath2 = Path()
      ..moveTo(w * 0.68, h * 0.86)
      ..lineTo(w * 0.71, h * 0.93)
      ..lineTo(w * 0.74, h * 0.86)
      ..close();
    canvas.drawPath(tailPath2, paint);

    // Chấm tròn (chat dots) — 2 chấm trong bong bóng chính
    final dotPaint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(w * 0.40, h * 0.43),
      w * 0.04,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.43),
      w * 0.04,
      dotPaint,
    );

    // Chấm trong bong bóng phụ
    canvas.drawCircle(
      Offset(w * 0.74, h * 0.72),
      w * 0.03,
      dotPaint,
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
        gradient: const LinearGradient(
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