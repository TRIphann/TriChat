import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// BẢNG MÀU TRICHAT — Minimalist Black & White
/// ════════════════════════════════════════════════════════════════
///
/// Triết lý thiết kế:
/// - Bảng màu đơn sắc đen / trắng / xám — không gradient, không glassmorphism
/// - Accent duy nhất: cam san hô (chỉ dùng cho CTA chính, badge quan trọng)
/// - Text: charcoal (#0F0F0F) — không dùng pure black
/// - Border: hairline 1px (#E5E5E5)
/// - Surface: pure white hoặc off-white tinh tế
/// - Không shadow nặng — chỉ shadow mỏng 1-2px hoặc không dùng
///
/// **QUY TẮC SỬ DỤNG**:
/// - Tất cả màu trong app PHẢI lấy từ class này. KHÔNG hardcode màu.
/// - Đổi màu toàn bộ app: chỉ cần sửa các const Color bên dưới.
class AppColors {
  // ════════════════════════════════════════════════════════════════
  //  ACCENT — Cam san hô (chỉ dùng cho CTA chính, dot, badge)
  // ════════════════════════════════════════════════════════════════
  /// Cam san hô đậm — button chính, link quan trọng
  static const Color primaryOrange = Color(0xFFE85D2F);
  /// Cam san hô nhạt — tint nhẹ, hover background
  static const Color primaryOrangeLight = Color(0xFFFEF1EA);
  /// Cam san hô đậm hơn — pressed state
  static const Color primaryOrangeDark = Color(0xFFC84A21);

  // ════════════════════════════════════════════════════════════════
  //  SECONDARY — Đỏ tối giản (chỉ dùng cho error / danger)
  // ════════════════════════════════════════════════════════════════
  /// Đỏ tối giản — error, danger
  static const Color accentRed = Color(0xFFB42318);
  /// Đỏ nhạt — error tint
  static const Color accentRedLight = Color(0xFFFEF3F2);

  // ════════════════════════════════════════════════════════════════
  //  TERTIARY — Neutral (text & depth)
  // ════════════════════════════════════════════════════════════════
  /// Charcoal — heading, icon chính, text đậm
  static const Color accentBrown = Color(0xFF0F0F0F);
  /// Xám đậm — secondary heading
  static const Color accentBrownLight = Color(0xFF404040);

  // ════════════════════════════════════════════════════════════════
  //  NEUTRAL — đơn sắc đen / trắng / xám
  // ════════════════════════════════════════════════════════════════
  /// Charcoal đậm — text chính (không dùng pure black)
  static const Color neutralBlack = Color(0xFF0F0F0F);
  /// Xám rất đậm — text đậm phụ
  static const Color neutralGray900 = Color(0xFF171717);
  /// Xám đậm — text phụ
  static const Color neutralGray800 = Color(0xFF262626);
  /// Xám vừa — secondary text
  static const Color neutralGray700 = Color(0xFF404040);
  /// Xám trung bình — placeholder
  static const Color neutralGray500 = Color(0xFF737373);
  /// Xám nhạt — hint, meta
  static const Color neutralGray400 = Color(0xFFA3A3A3);
  /// Xám rất nhạt — divider mỏng
  static const Color neutralGray300 = Color(0xFFD4D4D4);
  /// Xám cực nhạt — border
  static const Color neutralGray200 = Color(0xFFE5E5E5);
  /// Xám gần trắng — hover background
  static const Color neutralGray100 = Color(0xFFF5F5F5);
  /// Off-white — nền phụ
  static const Color neutralGray50 = Color(0xFFFAFAFA);
  /// Trắng tinh — surface / card
  static const Color neutralWhite = Color(0xFFFFFFFF);

  // ════════════════════════════════════════════════════════════════
  //  BACKGROUND — nền tối giản
  // ════════════════════════════════════════════════════════════════
  /// Nền chính — off-white tinh tế
  static const Color creamBackground = Color(0xFFFAFAFA);
  /// Nền phụ — pure white
  static const Color creamLight = Color(0xFFFFFFFF);
  /// Nền card / surface
  static const Color creamWhite = Color(0xFFFFFFFF);

  // ════════════════════════════════════════════════════════════════
  //  CHAT SURFACES — token chuyên dụng cho màn hình chat
  // ════════════════════════════════════════════════════════════════
  /// Nền khu vực chat — trắng tinh
  static const Color chatBackground = Color(0xFFFFFFFF);
  /// Bong bóng tin nhắn của mình — đen
  static const Color chatBubbleMine = neutralBlack;
  /// Bong bóng tin nhắn của người khác — xám rất nhạt
  static const Color chatBubbleTheirs = Color(0xFFF5F5F5);
  /// Viền bong bóng người khác — không dùng, dùng nền nhạt
  static const Color chatBubbleBorder = Color(0xFFFAFAFA);
  /// Bong bóng người khác trong dark mode
  static const Color darkChatBubbleTheirs = Color(0xFF1F1F1F);
  /// Nền chat trong dark mode
  static const Color darkChatBackground = Color(0xFF0A0A0A);

  // ════════════════════════════════════════════════════════════════
  //  STATE — Trạng thái (success/warning/error/info)
  // ════════════════════════════════════════════════════════════════
  /// Xanh lá tối giản — online, success
  static const Color success = Color(0xFF067647);
  static const Color successLight = Color(0xFFECFDF3);
  /// Vàng tối giản — warning
  static const Color warning = Color(0xFFB54708);
  static const Color warningLight = Color(0xFFFFFAEB);
  /// Đỏ — error/danger
  static const Color error = Color(0xFFB42318);
  static const Color errorLight = Color(0xFFFEF3F2);
  /// Xanh dương tối giản — info
  static const Color info = Color(0xFF1849A9);
  static const Color infoLight = Color(0xFFEFF8FF);

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
  static final Color borderGray = neutralGray200;
  static final Color divider = neutralGray200;
  static final Color callRed = accentRed;
  static final Color callGreen = success;
  static final Color callBackground = neutralBlack;
  static final Color whiteOpacity = Colors.white24;

  // ════════════════════════════════════════════════════════════════
  //  DARK MODE — đơn sắc đen tối giản
  // ════════════════════════════════════════════════════════════════
  /// Nền tối — charcoal đậm
  static const Color darkBackground = Color(0xFF0A0A0A);
  /// Surface — đen nhạt hơn một chút
  static const Color darkSurface = Color(0xFF171717);
  /// Card — đen nâng cao
  static const Color darkCard = Color(0xFF1F1F1F);
  static final Color sidebarDark = neutralBlack;
  static final Color sidebarLight = neutralWhite;
  /// Text chính trong dark mode — trắng off
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  /// Text phụ trong dark mode — xám nhạt
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  /// Divider trong dark mode
  static const Color darkDivider = Color(0xFF262626);

  // ════════════════════════════════════════════════════════════════
  //  GRADIENTS — chỉ dùng tối giản, đơn sắc
  // ════════════════════════════════════════════════════════════════
  /// Gradient brand đơn sắc — chỉ dùng khi thật cần
  /// (logo wordmark, splash nền)
  static const List<Color> brandGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF262626),
  ];

  /// Gradient header dark mode
  static const List<Color> darkBrandGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF171717),
  ];

  /// Gradient header newfeed — đơn sắc trắng → xám nhạt
  static const List<Color> headerGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];

  /// Gradient header dark mode
  static const List<Color> darkHeaderGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF171717),
  ];

  /// Gradient app bar nhẹ nhàng — đơn sắc trắng
  static const List<Color> appBarGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];

  /// Gradient story chưa xem — đen đậm → đen nhạt
  static const List<Color> storyUnseenGradient = [
    Color(0xFF262626),
    Color(0xFF0F0F0F),
  ];

  /// Gradient nút "Tạo bài viết" — đen đơn sắc
  static const List<Color> createPostGradient = [
    Color(0xFF171717),
    Color(0xFF0F0F0F),
  ];

  /// Gradient cover profile — đơn sắc đen
  static const List<Color> profileCoverGradient = [
    Color(0xFF262626),
    Color(0xFF0F0F0F),
  ];

  /// Gradient CTA chính — đen đơn sắc (thay cam san hô)
  static const List<Color> primaryButtonGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF171717),
  ];

  /// Gradient CTA phụ (Đã kết nối) — đơn sắc xám
  static const List<Color> successButtonGradient = [
    Color(0xFF404040),
    Color(0xFF262626),
  ];

  /// Gradient CTA cảnh báo
  static const List<Color> warningButtonGradient = [
    Color(0xFFE85D2F),
    Color(0xFFC84A21),
  ];

  /// Gradient CTA phản hồi
  static const List<Color> respondButtonGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF171717),
  ];

  /// Gradient CTA nguy hiểm
  static const List<Color> dangerButtonGradient = [
    Color(0xFFB42318),
    Color(0xFF8A1A12),
  ];

  /// Gradient bong bóng tin nhắn của tôi — đen đơn sắc
  static const List<Color> chatBubbleMineGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF262626),
  ];

  /// Gradient sidebar — đen đơn sắc
  static const List<Color> sidebarBrownGradient = [
    Color(0xFF171717),
    Color(0xFF0F0F0F),
    Color(0xFF0A0A0A),
  ];

  /// Gradient cream background — trắng / off-white
  static const List<Color> creamBackgroundGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
    Color(0xFFFFFFFF),
  ];

  /// Gradient glass trắng — đơn sắc trắng
  static const List<Color> glassWhiteGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];

  // ════════════════════════════════════════════════════════════════
  //  PALETTE AVATAR — đơn sắc đen / trắng / xám
  // ════════════════════════════════════════════════════════════════
  static const List<Color> avatarPalette = [
    Color(0xFF0F0F0F),
    Color(0xFF262626),
    Color(0xFF404040),
    Color(0xFF737373),
    Color(0xFFA3A3A3),
    Color(0xFFE5E5E5),
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
  static Color getDivider(bool isDark) => isDark ? darkDivider : neutralGray200;

  /// Màu avatar sinh theo tên user (hash đơn giản — đơn sắc)
  static Color avatarColorFor(String name) {
    if (name.isEmpty) return avatarPalette.first;
    return avatarPalette[name.codeUnitAt(0) % avatarPalette.length];
  }

  // ════════════════════════════════════════════════════════════════
  //  DARK PREMIUM — Dark mode tối giản (tương thích code cũ)
  // ════════════════════════════════════════════════════════════════

  // ── Nền (Backgrounds) ──
  static const Color darkPremiumVoid = Color(0xFF000000);
  static const Color darkPremiumBackground = Color(0xFF0A0A0A);
  static const Color darkPremiumSurface = Color(0xFF171717);
  static const Color darkPremiumElevated = Color(0xFF1F1F1F);
  static const Color darkPremiumBorder = Color(0xFF262626);
  static const Color darkPremiumDivider = Color(0xFF1F1F1F);
  static const Color darkPremiumHover = Color(0xFF262626);
  static const Color darkPremiumSelected = Color(0xFF1F1F1F);

  // ── Text (Dark) ──
  static const Color darkPremiumTextPrimary = Color(0xFFF5F5F5);
  static const Color darkPremiumTextBody = Color(0xFFD4D4D4);
  static const Color darkPremiumTextSecondary = Color(0xFFA3A3A3);
  static const Color darkPremiumTextHint = Color(0xFF737373);

  // ── Accents (chỉ dùng cho dot/badge, không gradient) ──
  static const Color neonRoyal = Color(0xFFE85D2F);
  static const Color neonRoyalGlow = Color(0xFFE85D2F);
  static const Color neonPink = Color(0xFFE85D2F);
  static const Color neonOrange = Color(0xFFE85D2F);
  static const Color neonOnline = Color(0xFF067647);
  static const Color neonYellow = Color(0xFFB54708);
  static const Color neonPurple = Color(0xFF404040);
  static const Color neonRed = Color(0xFFB42318);

  // ── Gradient: my message (đen đơn sắc) ──
  static const List<Color> darkBubbleMineGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF262626),
  ];

  // ── Gradient: header dark ──
  static const List<Color> darkPremiumHeaderGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF171717),
  ];

  // ── Gradient: button primary ──
  static const List<Color> neonButtonGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF262626),
  ];

  // ── Gradient: button pink ──
  static const List<Color> neonPinkGradient = [
    Color(0xFF0F0F0F),
    Color(0xFF262626),
  ];

  // ── Gradient: button orange ──
  static const List<Color> neonOrangeGradient = [
    Color(0xFFE85D2F),
    Color(0xFFC84A21),
  ];

  // ── Glow shadow color ──
  static const Color neonRoyalShadow = Color(0x00000000);

  // ── Dark bubble (theirs) ──
  static const Color darkPremiumBubbleTheirs = Color(0xFF1F1F1F);
  static const Color darkPremiumBubbleTheirsBorder = Color(0xFF262626);

  // ── Dark chat background ──
  static const List<Color> darkChatSurfaceGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF171717),
  ];

  // ── Slim sidebar selected gradient ──
  static const List<Color> darkSlimSidebarItemActive = [
    Color(0xFFE5E5E5),
    Color(0xFFF5F5F5),
  ];

  // ── Pinned/all message label color ──
  static const Color darkPremiumPinnedLabel = Color(0xFFE85D2F);

  // ── Dark avatar palette ──
  static const List<Color> darkPremiumAvatarPalette = [
    Color(0xFFF5F5F5),
    Color(0xFFD4D4D4),
    Color(0xFFA3A3A3),
    Color(0xFF737373),
    Color(0xFF404040),
    Color(0xFF262626),
  ];

  /// Theme dark chuyên dùng cho giao diện chat
  static ThemeData buildDarkPremiumTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkPremiumBackground,
      colorScheme: const ColorScheme.dark(
        primary: neutralWhite,
        onPrimary: neutralBlack,
        surface: darkPremiumSurface,
        onSurface: darkPremiumTextPrimary,
        secondary: primaryOrange,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: darkPremiumTextPrimary,
        displayColor: darkPremiumTextPrimary,
      ),
      dividerColor: darkPremiumDivider,
    );
  }
}
