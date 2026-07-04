import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// BẢNG MÀU TRICHAT — Tông trầm ấm: đen, cam, đỏ, nâu, trắng ngà
/// ════════════════════════════════════════════════════════════════
///
/// **QUY TẮC SỬ DỤNG**:
/// - Tất cả màu trong app PHẢI lấy từ class này. KHÔNG hardcode màu.
/// - Đổi màu toàn bộ app: chỉ cần sửa các const Color bên dưới.
/// - Khi cần thêm màu mới, hãy thêm vào đây thay vì nhúng inline.
///
/// **DARK MODE**: dùng các helper `getBackground()`, `getSurface()`, etc.
class AppColors {
  // ════════════════════════════════════════════════════════════════
  //  PRIMARY — Cam cháy (Burnt Orange) — màu chủ đạo
  // ════════════════════════════════════════════════════════════════
  /// Cam đậm — button chính, AppBar, tab active, link
  static const Color primaryOrange = Color(0xFFE25822);
  /// Cam vừa — gradient và highlight
  static const Color primaryOrangeLight = Color(0xFFF4845F);
  /// Cam nhạt — tint, hover background
  static const Color primaryOrangePale = Color(0xFFFFE4D6);

  // ════════════════════════════════════════════════════════════════
  //  SECONDARY — Đỏ rượu vang (Wine Red) — nhấn mạnh
  // ════════════════════════════════════════════════════════════════
  /// Đỏ trầm — notification, like, badge quan trọng
  static const Color accentRed = Color(0xFF9B1B30);
  /// Đỏ đậm hơn — danger, error
  static const Color accentRedDark = Color(0xFF6B0F1F);

  // ════════════════════════════════════════════════════════════════
  //  TERTIARY — Nâu chocolate (Chocolate Brown) — text & depth
  // ════════════════════════════════════════════════════════════════
  /// Nâu đậm — heading, icon chính
  static const Color accentBrown = Color(0xFF5D2F0F);
  /// Nâu vừa — secondary text
  static const Color accentBrownLight = Color(0xFF8B4513);

  // ════════════════════════════════════════════════════════════════
  //  NEUTRAL — Đen ấm & Trắng ngà
  // ════════════════════════════════════════════════════════════════
  /// Đen ấm — text chính (không quá tối như #000)
  static const Color neutralBlack = Color(0xFF1A0F0A);
  /// Xám đậm — text phụ
  static const Color neutralGray900 = Color(0xFF2D1F15);
  /// Xám vừa — placeholder
  static const Color neutralGray700 = Color(0xFF6B5D54);
  /// Xám nhạt — hint
  static const Color neutralGray500 = Color(0xFFA89A8E);
  /// Xám rất nhạt — border
  static const Color neutralGray300 = Color(0xFFE5DDD3);
  /// Xám nền — background
  static const Color neutralGray100 = Color(0xFFF5EFE7);
  /// Trắng ngà — surface/card (ấm hơn #FFFFFF)
  static const Color neutralWhite = Color(0xFFFFFAF3);

  // ════════════════════════════════════════════════════════════════
  //  STATE — Trạng thái (success/warning/error/info)
  // ════════════════════════════════════════════════════════════════
  /// Xanh lá trầm — online, success
  static const Color success = Color(0xFF2D7A4F);
  static const Color successLight = Color(0xFF52B381);
  /// Vàng cam — warning
  static const Color warning = Color(0xFFE89B30);
  /// Đỏ — error/danger
  static const Color error = Color(0xFFB91C1C);
  /// Xanh dương đậm — info
  static const Color info = Color(0xFF1E5B7A);

  // ════════════════════════════════════════════════════════════════
  //  ALIAS GIỮ TƯƠNG THÍCH (legacy)
  // ════════════════════════════════════════════════════════════════
  // Lưu ý: KHÔNG dùng const vì sẽ gây recursive_compile_time_constant
  // khi tham chiếu đến field khác trong cùng class.
  static final Color primaryBlue = primaryOrange;
  static final Color lightBlue = primaryOrangeLight;
  static final Color darkBlue = accentBrown;
  static final Color backgroundWhite = neutralWhite;
  static final Color backgroundGray = neutralGray100;
  static final Color textPrimary = neutralBlack;
  static final Color textSecondary = neutralGray700;
  static final Color textHint = neutralGray500;
  static final Color textWhite = Colors.white;
  static final Color textBlue = primaryOrange;
  static final Color borderGray = neutralGray300;
  static final Color divider = neutralGray100;
  static final Color callRed = accentRed;
  static final Color callGreen = success;
  static final Color callBackground = neutralBlack;
  static final Color whiteOpacity = Colors.white24;

  // ════════════════════════════════════════════════════════════════
  //  DARK MODE
  // ════════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF1A0F0A);
  static const Color darkSurface = Color(0xFF2D1F15);
  static const Color darkCard = Color(0xFF3D2B1F);
  static final Color sidebarDark = accentBrown;
  static final Color sidebarLight = primaryOrange;
  static const Color darkTextPrimary = Color(0xFFF5EFE7);
  static const Color darkTextSecondary = Color(0xFFA89A8E);
  static const Color darkDivider = Color(0xFF3D2B1F);

  // ════════════════════════════════════════════════════════════════
  //  GRADIENTS — dùng chung cho tất cả giao diện tương tự
  // ════════════════════════════════════════════════════════════════
  /// Gradient header / hero — cam cháy → đỏ rượu → nâu chocolate
  /// Dùng cho: AppBar newfeed, splash, header profile, header chat list
  static const List<Color> brandGradient = [
    Color(0xFFE25822),
    Color(0xFFC73E1D),
    Color(0xFF9B1B30),
    Color(0xFF5D2F0F),
  ];

  /// Gradient header dark mode
  static const List<Color> darkBrandGradient = [
    Color(0xFF3D2B1F),
    Color(0xFF2D1F15),
    Color(0xFF1A0F0A),
  ];

  /// Gradient header newfeed (cam cháy → nâu)
  static const List<Color> headerGradient = [
    Color(0xFFE25822),
    Color(0xFFB8341A),
    Color(0xFF5D2F0F),
  ];

  /// Gradient header dark mode
  static const List<Color> darkHeaderGradient = [
    Color(0xFF3D2B1F),
    Color(0xFF1A0F0A),
    Color(0xFF0A0604),
  ];

  /// Gradient story chưa xem — cam → đỏ
  static const List<Color> storyUnseenGradient = [
    Color(0xFFF4845F),
    Color(0xFFE25822),
    Color(0xFF9B1B30),
  ];

  /// Gradient nút "Tạo bài viết" — cam cháy
  static const List<Color> createPostGradient = [
    Color(0xFFF4845F),
    Color(0xFFE25822),
  ];

  /// Gradient cover profile — cam → đỏ → nâu
  static const List<Color> profileCoverGradient = [
    Color(0xFFE25822),
    Color(0xFF9B1B30),
    Color(0xFF5D2F0F),
    Color(0xFF2D1F15),
  ];

  /// Gradient CTA chính (Kết bạn, Đăng bài) — cam cháy
  static const List<Color> primaryButtonGradient = [
    Color(0xFFF4845F),
    Color(0xFFE25822),
  ];

  /// Gradient CTA phụ (Đã kết nối) — xanh lá trầm
  static const List<Color> successButtonGradient = [
    Color(0xFF52B381),
    Color(0xFF2D7A4F),
  ];

  /// Gradient CTA cảnh báo — cam cháy đậm
  static const List<Color> warningButtonGradient = [
    Color(0xFFF4845F),
    Color(0xFFB8341A),
  ];

  /// Gradient CTA phản hồi — cam
  static const List<Color> respondButtonGradient = [
    Color(0xFFF4845F),
    Color(0xFFE25822),
  ];

  /// Gradient CTA nguy hiểm — đỏ rượu
  static const List<Color> dangerButtonGradient = [
    Color(0xFFB91C1C),
    Color(0xFF6B0F1F),
  ];

  // ════════════════════════════════════════════════════════════════
  //  PALETTE AVATAR — 6 màu ấm cho avatar tự sinh theo tên
  // ════════════════════════════════════════════════════════════════
  static const List<Color> avatarPalette = [
    Color(0xFFE25822), // cam cháy
    Color(0xFF9B1B30), // đỏ rượu
    Color(0xFFB8341A), // cam đỏ
    Color(0xFF5D2F0F), // nâu chocolate
    Color(0xFF2D7A4F), // xanh lá trầm
    Color(0xFF8B4513), // nâu saddle
  ];

  // ════════════════════════════════════════════════════════════════
  //  HELPER METHODS — dùng cho cả light/dark mode
  // ════════════════════════════════════════════════════════════════
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : backgroundGray;
  static Color getSurface(bool isDark) =>
      isDark ? darkSurface : backgroundWhite;
  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : textPrimary;
  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : textSecondary;
  static Color getDivider(bool isDark) => isDark ? darkDivider : divider;

  /// Màu avatar sinh theo tên user (hash đơn giản)
  static Color avatarColorFor(String name) {
    if (name.isEmpty) return avatarPalette.first;
    return avatarPalette[name.codeUnitAt(0) % avatarPalette.length];
  }
}