import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// BẢNG MÀU TRICHAT — Phong cách "Giao Diện Thấu Kính"
/// ════════════════════════════════════════════════════════════════
///
/// Triết lý thiết kế mới:
/// - Nền chính: be cực nhạt / trắng kem (cream)
/// - Accent: cam san hô + nâu socola sữa
/// - Glass effect: trắng trong suốt + blur + shadow nhẹ
/// - Text: xám đậm (title), xám nhạt (desc), đen (body)
///
/// **QUY TẮC SỬ DỤNG**:
/// - Tất cả màu trong app PHẢI lấy từ class này. KHÔNG hardcode màu.
/// - Đổi màu toàn bộ app: chỉ cần sửa các const Color bên dưới.
class AppColors {
  // ════════════════════════════════════════════════════════════════
  //  PRIMARY — Cam san hô (Coral) — màu chủ đạo, dịu & hiện đại
  // ════════════════════════════════════════════════════════════════
  /// Cam san hô đậm — button chính, AppBar, tab active, link
  static const Color primaryOrange = Color(0xFFFF7F5C);
  /// Cam san hô vừa — gradient và highlight
  static const Color primaryOrangeLight = Color(0xFFFFA689);
  /// Cam san hô nhạt — tint, hover background
  static const Color primaryOrangePale = Color(0xFFFFE3D6);

  // ════════════════════════════════════════════════════════════════
  //  SECONDARY — Đỏ san hô ấm — nhấn mạnh
  // ════════════════════════════════════════════════════════════════
  /// Đỏ ấm — notification, like, badge quan trọng
  static const Color accentRed = Color(0xFFE85A6A);
  /// Đỏ đậm hơn — danger, error
  static const Color accentRedDark = Color(0xFFC73E55);

  // ════════════════════════════════════════════════════════════════
  //  TERTIARY — Nâu socola sữa (Milk Chocolate) — text & depth
  // ════════════════════════════════════════════════════════════════
  /// Nâu socola đậm — heading, icon chính
  static const Color accentBrown = Color(0xFF7B4F35);
  /// Nâu vừa — secondary text
  static const Color accentBrownLight = Color(0xFFA87657);

  // ════════════════════════════════════════════════════════════════
  //  NEUTRAL — Be cực nhạt & đen ấm (Cream & warm black)
  // ════════════════════════════════════════════════════════════════
  /// Đen ấm — text chính
  static const Color neutralBlack = Color(0xFF2A1F1A);
  /// Xám rất đậm — text on dark bg
  static const Color neutralGray900 = Color(0xFF3D2F28);
  /// Xám đậm — secondary text
  static const Color neutralGray800 = Color(0xFF564539);
  /// Xám vừa — placeholder
  static const Color neutralGray700 = Color(0xFF8A7565);
  /// Xám nhạt — hint
  static const Color neutralGray500 = Color(0xFFB5A698);
  /// Xám rất nhạt — border
  static const Color neutralGray300 = Color(0xFFE8DED2);
  /// Be rất nhạt — nền phụ
  static const Color neutralGray100 = Color(0xFFFAF4EC);
  /// Trắng kem — surface/card (ấm hơn #FFFFFF)
  static const Color neutralWhite = Color(0xFFFFFCF6);

  // ════════════════════════════════════════════════════════════════
  //  BACKGROUND GRADIENT — Cream tones
  // ════════════════════════════════════════════════════════════════
  /// Nền cream chính — dùng cho scaffold
  static const Color creamBackground = Color(0xFFFAF4EC);
  /// Nền cream nhạt hơn
  static const Color creamLight = Color(0xFFFFF8EC);
  /// Nền kem trắng
  static const Color creamWhite = Color(0xFFFFFCF6);

  // ════════════════════════════════════════════════════════════════
  //  GLASS EFFECT — Trắng trong suốt cho backdrop-filter
  // ════════════════════════════════════════════════════════════════
  /// Glass trắng — sidebar, header, modal
  static const Color glassWhite = Color(0xCCFFFFFF);
  /// Glass trắng nhẹ — list items, chips
  static const Color glassWhiteSoft = Color(0x99FFFFFF);
  /// Glass nâu — sidebar nâu socola
  static const Color glassBrown = Color(0xE67B4F35);
  /// Glass nâu đậm — sidebar overlay
  static const Color glassBrownDeep = Color(0xFF5A3825);

  // ════════════════════════════════════════════════════════════════
  //  CHAT SURFACES — token chuyên dụng cho màn hình chat
  // ════════════════════════════════════════════════════════════════
  /// Nền khu vực chat — cream tone
  static const Color chatBackground = Color(0xFFF7EFE3);
  /// Bong bóng tin nhắn của mình
  static const Color chatBubbleMine = primaryOrange;
  /// Bong bóng tin nhắn của người khác (trắng kem)
  static const Color chatBubbleTheirs = Color(0xFFFFFFFF);
  /// Viền bong bóng người khác
  static const Color chatBubbleBorder = Color(0xFFEFE5D6);
  /// Bong bóng người khác trong dark mode
  static const Color darkChatBubbleTheirs = Color(0xFF3D2B1F);
  /// Nền chat trong dark mode
  static const Color darkChatBackground = Color(0xFF1F1612);

  // ════════════════════════════════════════════════════════════════
  //  STATE — Trạng thái (success/warning/error/info)
  // ════════════════════════════════════════════════════════════════
  /// Xanh lá trầm — online, success
  static const Color success = Color(0xFF4FA876);
  static const Color successLight = Color(0xFF7BC79E);
  /// Vàng cam — warning
  static const Color warning = Color(0xFFE8A040);
  /// Đỏ — error/danger
  static const Color error = Color(0xFFD64545);
  /// Xanh dương đậm — info
  static const Color info = Color(0xFF3D7A99);

  // ════════════════════════════════════════════════════════════════
  //  ALIAS GIỮ TƯƠNG THÍCH (legacy) — giữ để code cũ không lỗi
  // ════════════════════════════════════════════════════════════════
  static final Color primaryBlue = primaryOrange;
  static final Color lightBlue = primaryOrangeLight;
  static final Color darkBlue = accentBrown;
  static final Color backgroundWhite = creamWhite;
  static final Color backgroundGray = neutralGray100;
  static final Color textPrimary = neutralBlack;
  static final Color textSecondary = neutralGray700;
  static final Color textHint = neutralGray500;
  static final Color textWhite = Colors.white;
  static final Color textBlue = primaryOrange;
  static final Color borderGray = neutralGray300;
  static final Color divider = neutralGray300;
  static final Color callRed = accentRed;
  static final Color callGreen = success;
  static final Color callBackground = neutralBlack;
  static final Color whiteOpacity = Colors.white24;

  // ════════════════════════════════════════════════════════════════
  //  DARK MODE
  // ════════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF1F1612);
  static const Color darkSurface = Color(0xFF2A1F1A);
  static const Color darkCard = Color(0xFF3D2B1F);
  static final Color sidebarDark = accentBrown;
  static final Color sidebarLight = primaryOrange;
  static const Color darkTextPrimary = Color(0xFFF5EFE7);
  static const Color darkTextSecondary = Color(0xFFB5A698);
  static const Color darkDivider = Color(0xFF3D2B1F);

  // ════════════════════════════════════════════════════════════════
  //  GRADIENTS — dùng chung cho tất cả giao diện tương tự
  // ════════════════════════════════════════════════════════════════
  /// Gradient brand — cam san hô → đỏ ấm → nâu socola
  /// Dùng cho: AppBar newfeed, splash, header profile, header chat list
  static const List<Color> brandGradient = [
    Color(0xFFFFA689), // cam san hô sáng
    Color(0xFFFF7F5C), // cam san hô
    Color(0xFFE85A6A), // đỏ ấm
    Color(0xFF7B4F35), // nâu socola
  ];

  /// Gradient header dark mode
  static const List<Color> darkBrandGradient = [
    Color(0xFF3D2B1F),
    Color(0xFF2A1F1A),
    Color(0xFF1F1612),
  ];

  /// Gradient header newfeed (cam san hô → nâu)
  static const List<Color> headerGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
    Color(0xFF7B4F35),
  ];

  /// Gradient header dark mode
  static const List<Color> darkHeaderGradient = [
    Color(0xFF3D2B1F),
    Color(0xFF1F1612),
    Color(0xFF0F0807),
  ];

  /// Gradient app bar nhẹ nhàng (cam san hô → cam đậm)
  static const List<Color> appBarGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
  ];

  /// Gradient story chưa xem — cam san hô → đỏ
  static const List<Color> storyUnseenGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
    Color(0xFFE85A6A),
  ];

  /// Gradient nút "Tạo bài viết"
  static const List<Color> createPostGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
  ];

  /// Gradient cover profile — cam san hô → đỏ → nâu
  static const List<Color> profileCoverGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
    Color(0xFFE85A6A),
    Color(0xFF7B4F35),
  ];

  /// Gradient CTA chính (Kết bạn, Đăng bài)
  static const List<Color> primaryButtonGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
  ];

  /// Gradient CTA phụ (Đã kết nối)
  static const List<Color> successButtonGradient = [
    Color(0xFF7BC79E),
    Color(0xFF4FA876),
  ];

  /// Gradient CTA cảnh báo
  static const List<Color> warningButtonGradient = [
    Color(0xFFFFA689),
    Color(0xFFE85A40),
  ];

  /// Gradient CTA phản hồi
  static const List<Color> respondButtonGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
  ];

  /// Gradient CTA nguy hiểm
  static const List<Color> dangerButtonGradient = [
    Color(0xFFD64545),
    Color(0xFFA02828),
  ];

  /// Gradient bong bóng tin nhắn của tôi — cam sáng → cam đậm
  static const List<Color> chatBubbleMineGradient = [
    Color(0xFFFFA689),
    Color(0xFFFF7F5C),
  ];

  /// Gradient glass nâu cho sidebar — nâu socola sữa
  static const List<Color> sidebarBrownGradient = [
    Color(0xFFA87657),
    Color(0xFF7B4F35),
    Color(0xFF5A3825),
  ];

  /// Gradient glass cream cho background — kem → trắng kem
  static const List<Color> creamBackgroundGradient = [
    Color(0xFFFFF8EC),
    Color(0xFFFFFCF6),
    Color(0xFFFAF4EC),
  ];

  /// Gradient glass trắng cho header cột 2 — chuyển từ trắng → cream
  static const List<Color> glassWhiteGradient = [
    Color(0xFFFFFCF6),
    Color(0xFFFFFFFF),
  ];

  // ════════════════════════════════════════════════════════════════
  //  PALETTE AVATAR — 6 màu ấm cho avatar tự sinh theo tên
  // ════════════════════════════════════════════════════════════════
  static const List<Color> avatarPalette = [
    Color(0xFFFF7F5C), // cam san hô
    Color(0xFFE85A6A), // đỏ ấm
    Color(0xFFD4805A), // cam đất
    Color(0xFF7B4F35), // nâu socola
    Color(0xFF4FA876), // xanh lá trầm
    Color(0xFFA87657), // nâu sữa
  ];

  // ════════════════════════════════════════════════════════════════
  //  HELPER METHODS — dùng cho cả light/dark mode
  // ════════════════════════════════════════════════════════════════
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : creamBackground;
  static Color getSurface(bool isDark) =>
      isDark ? darkSurface : creamWhite;
  static Color getCard(bool isDark) => isDark ? darkCard : creamWhite;
  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : neutralBlack;
  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : neutralGray700;
  static Color getDivider(bool isDark) => isDark ? darkDivider : neutralGray300;

  /// Màu avatar sinh theo tên user (hash đơn giản)
  static Color avatarColorFor(String name) {
    if (name.isEmpty) return avatarPalette.first;
    return avatarPalette[name.codeUnitAt(0) % avatarPalette.length];
  }
}