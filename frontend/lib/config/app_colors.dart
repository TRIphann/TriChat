import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// TRI CHAT — HIGH-END VISUAL DESIGN SYSTEM
/// ════════════════════════════════════════════════════════════════
///
/// Design Philosophy:
/// - Premium Editorial Luxury aesthetic with warm cream tones
/// - Soft Structuralism with highly diffused ambient shadows
/// - Cinematic spatial rhythm with generous macro-whitespace
/// - Double-Bezel nested architecture for all cards/containers
/// - Fluid spring physics for all animations
///
/// Color Palette: Warm neutrals, soft amber accent, muted pastels
/// Typography: Wide geometric sans-serif, high-contrast
/// Spacing: Generous 8pt grid with exaggerated section gaps
/// Radius: Large squircle (24-32px) for premium feel
///
/// **RULES**:
/// - All colors MUST come from this class. NO hardcoded values.
/// - To re-theme: edit these constants only.

class AppColors {
  AppColors._();

  // ════════════════════════════════════════════════════════════════
  //  BRAND — Warm Amber Accent
  // ════════════════════════════════════════════════════════════════
  /// Primary amber — CTA, interactive elements
  static const Color primaryAmber = Color(0xFFD97706);
  /// Amber light — tints, hover states
  static const Color primaryAmberLight = Color(0xFFFEF3C7);
  /// Amber dark — pressed states
  static const Color primaryAmberDark = Color(0xFFB45309);

  /// Warm orange — highlights, badges
  static const Color accentWarm = Color(0xFFEA580C);
  static const Color accentWarmLight = Color(0xFFFFEDD5);

  /// Avatar palette - for avatar color generation
  static const List<Color> avatarPalette = [
    Color(0xFFD97706),
    Color(0xFF16A34A),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
  ];

  // ════════════════════════════════════════════════════════════════
  //  SURFACE — Warm Cream Tones
  // ════════════════════════════════════════════════════════════════
  /// Primary background — warm cream
  static const Color cream = Color(0xFFFAF8F5);
  /// Card background — warm white
  static const Color creamWhite = Color(0xFFFFFFFF);
  /// Elevated surface — warm off-white
  static const Color creamElevated = Color(0xFFFFFCF9);
  /// Secondary surface — light warm gray
  static const Color creamSurface = Color(0xFFF5F2EE);
  /// Tertiary surface — slightly darker warm
  static const Color creamTertiary = Color(0xFFEDE9E3);

  // ════════════════════════════════════════════════════════════════
  //  TEXT — High Contrast Warm Neutrals
  // ════════════════════════════════════════════════════════════════
  /// Primary text — warm charcoal
  static const Color textPrimary = Color(0xFF1C1917);
  /// Secondary text — warm gray
  static const Color textSecondary = Color(0xFF57534E);
  /// Tertiary text — muted warm
  static const Color textTertiary = Color(0xFFA8A29E);
  /// Placeholder text
  static const Color textPlaceholder = Color(0xFFCCC7C0);
  /// Pure white for dark backgrounds
  static const Color textWhite = Color(0xFFFFFFFF);

  // ════════════════════════════════════════════════════════════════
  //  BORDER — Hairline Warm Borders
  // ════════════════════════════════════════════════════════════════
  /// Default border — subtle warm
  static const Color borderDefault = Color(0xFFE7E5E4);
  /// Strong border — visible separation
  static const Color borderStrong = Color(0xFFD6D3D1);
  /// Subtle divider
  static const Color divider = Color(0xFFF5F2EE);

  // ════════════════════════════════════════════════════════════════
  //  STATE — Success/Warning/Error/Info
  // ════════════════════════════════════════════════════════════════
  /// Success — muted green
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  /// Warning — amber
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  /// Error — warm red
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  /// Info — muted blue
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // ════════════════════════════════════════════════════════════════
  //  CHAT — Warm Bubble Colors
  // ════════════════════════════════════════════════════════════════
  /// Chat background — warm white
  static const Color chatBackground = Color(0xFFFFFFFF);
  /// My message bubble — warm charcoal
  static const Color chatBubbleMine = Color(0xFF1C1917);
  /// Their message bubble — warm light
  static const Color chatBubbleTheirs = Color(0xFFF5F2EE);
  /// Their message text
  static const Color chatBubbleTheirsText = Color(0xFF1C1917);

  // ════════════════════════════════════════════════════════════════
  //  DARK MODE — Premium Dark
  // ════════════════════════════════════════════════════════════════
  /// Dark background — warm black
  static const Color darkBackground = Color(0xFF0C0A09);
  /// Dark surface — warm charcoal
  static const Color darkSurface = Color(0xFF1C1917);
  /// Dark elevated — slightly lighter
  static const Color darkElevated = Color(0xFF292524);
  /// Dark card
  static const Color darkCard = Color(0xFF1C1917);
  /// Dark border
  static const Color darkBorder = Color(0xFF292524);
  /// Dark text primary — warm white
  static const Color darkTextPrimary = Color(0xFFFAF8F5);
  /// Dark text secondary
  static const Color darkTextSecondary = Color(0xFFA8A29E);
  /// Dark text tertiary
  static const Color darkTextTertiary = Color(0xFF78716C);

  // ════════════════════════════════════════════════════════════════
  //  DARK CHAT
  // ════════════════════════════════════════════════════════════════
  /// Dark chat background
  static const Color darkChatBackground = Color(0xFF0C0A09);
  /// Dark bubble mine
  static const Color darkChatBubbleMine = Color(0xFF292524);
  /// Dark bubble theirs
  static const Color darkChatBubbleTheirs = Color(0xFF1C1917);

  // ════════════════════════════════════════════════════════════════
  //  GRADIENTS — Premium Soft Gradients
  // ════════════════════════════════════════════════════════════════
  /// Hero gradient — warm cream to white
  static const List<Color> heroGradient = [
    Color(0xFFFAF8F5),
    Color(0xFFFFFFFF),
  ];

  /// Primary CTA gradient — amber
  static const List<Color> primaryGradient = [
    Color(0xFFD97706),
    Color(0xFFB45309),
  ];

  /// Dark primary gradient
  static const List<Color> darkPrimaryGradient = [
    Color(0xFFB45309),
    Color(0xFF92400E),
  ];

  /// Card hover gradient
  static const List<Color> cardHoverGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAF8F5),
  ];

  /// Dark card gradient
  static const List<Color> darkCardGradient = [
    Color(0xFF1C1917),
    Color(0xFF292524),
  ];

  /// Chat bubble mine gradient (dark mode)
  static const List<Color> darkBubbleMineGradient = [
    Color(0xFF292524),
    Color(0xFF1C1917),
  ];

  /// Chat bubble mine gradient (light mode) — warm brand orange.
  static const List<Color> lightBubbleMineGradient = [
    Color(0xFFD97706),
    Color(0xFFB45309),
  ];

  /// Alias for legacy compatibility
  static const List<Color> chatBubbleMineGradient = darkBubbleMineGradient;

  /// Premium shimmer
  static const List<Color> shimmerGradient = [
    Color(0xFFFAF8F5),
    Color(0xFFF5F2EE),
    Color(0xFFFAF8F5),
  ];

  // ════════════════════════════════════════════════════════════════
  //  ALIASES — Legacy compatibility
  // ════════════════════════════════════════════════════════════════
  static const Color primaryOrange = primaryAmber;
  static const Color primaryOrangeLight = primaryAmberLight;
  static const Color primaryOrangeDark = primaryAmberDark;
  static const Color accentRed = error;
  static const Color accentRedLight = errorLight;
  static const Color accentBrown = textPrimary;
  static const Color accentBrownLight = textSecondary;
  static const Color neutralBlack = textPrimary;
  static const Color neutralGray900 = textPrimary;
  static const Color neutralGray800 = Color(0xFF292524);
  static const Color neutralGray700 = textSecondary;
  static const Color neutralGray500 = textTertiary;
  static const Color neutralGray400 = textTertiary;
  static const Color neutralGray300 = borderStrong;
  static const Color neutralGray200 = borderDefault;
  static const Color neutralGray100 = creamSurface;
  static final Color neutralGray50 = creamElevated;
  static final Color neutralWhite = creamWhite;
  static final Color backgroundWhite = creamWhite;
  static final Color backgroundGray = cream;
  static final Color textHint = textPlaceholder;
  static final Color textBlue = info;
  static final Color borderGray = borderDefault;
  static final Color sidebarDark = darkSurface;
  static final Color sidebarLight = creamWhite;
  static final Color callRed = error;
  static final Color callGreen = success;
  static final Color callBackground = darkBackground;
  static final Color whiteOpacity = Colors.white24;
  static final Color primaryBlue = primaryAmber;
  static final Color lightBlue = primaryAmberLight;
  static final Color darkBlue = textPrimary;
  static final Color creamBackground = cream;
  static final Color darkDivider = darkBorder;
  static final List<Color> brandGradient = [
    Color(0xFF1C1917),
    Color(0xFF292524),
  ];
  static final List<Color> appBarGradient = [
    creamWhite,
    cream,
  ];

  // ════════════════════════════════════════════════════════════════
  //  HELPER METHODS
  // ════════════════════════════════════════════════════════════════
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : cream;

  static Color getSurface(bool isDark) =>
      isDark ? darkSurface : creamWhite;

  static Color getCard(bool isDark) => isDark ? darkCard : creamWhite;

  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : textPrimary;

  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : textSecondary;

  static Color getDivider(bool isDark) => isDark ? darkBorder : divider;

  /// Avatar color based on name (hash for consistent colors)
  static Color avatarColorFor(String name) {
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

  // ════════════════════════════════════════════════════════════════
  //  DARK PREMIUM — Extended dark mode tokens
  // ════════════════════════════════════════════════════════════════
  static const Color darkPremiumVoid = Color(0xFF000000);
  static const Color darkPremiumBackground = Color(0xFF0C0A09);
  static const Color darkPremiumSurface = Color(0xFF1C1917);
  static const Color darkPremiumElevated = Color(0xFF292524);
  static const Color darkPremiumBorder = Color(0xFF292524);
  static const Color darkPremiumDivider = Color(0xFF1C1917);
  static const Color darkPremiumHover = Color(0xFF292524);
  static const Color darkPremiumSelected = Color(0xFF1C1917);
  static const Color darkPremiumTextPrimary = Color(0xFFFAF8F5);
  static const Color darkPremiumTextBody = Color(0xFFE7E5E4);
  static const Color darkPremiumTextSecondary = Color(0xFFA8A29E);
  static const Color darkPremiumTextHint = Color(0xFF78716C);
  static const Color neonRoyal = Color(0xFFD97706);
  static const Color neonRoyalGlow = Color(0xFFD97706);
  static const Color neonPink = Color(0xFFEA580C);
  static const Color neonOrange = Color(0xFFD97706);
  static const Color neonOnline = Color(0xFF16A34A);
  static const Color neonYellow = Color(0xFFD97706);
  static const Color neonPurple = Color(0xFF7C3AED);
  static const Color neonRed = Color(0xFFDC2626);
  static const Color neonRoyalShadow = Color(0x40D97706);
  static const Color darkPremiumBubbleTheirs = Color(0xFF1C1917);
  static const Color darkPremiumBubbleTheirsBorder = Color(0xFF292524);
  static const Color darkPremiumPinnedLabel = Color(0xFFD97706);

  static const List<Color> darkPremiumHeaderGradient = [
    Color(0xFF0C0A09),
    Color(0xFF1C1917),
  ];

  static const List<Color> darkChatSurfaceGradient = [
    Color(0xFF0C0A09),
    Color(0xFF1C1917),
  ];

  static const List<Color> darkSlimSidebarItemActive = [
    Color(0xFFD97706),
    Color(0xFFB45309),
  ];

  static const List<Color> neonButtonGradient = [
    Color(0xFFD97706),
    Color(0xFFB45309),
  ];

  static const List<Color> neonPinkGradient = [
    Color(0xFFEA580C),
    Color(0xFFDC2626),
  ];

  static const List<Color> neonOrangeGradient = [
    Color(0xFFD97706),
    Color(0xFFB45309),
  ];

  static const List<Color> darkPremiumAvatarPalette = [
    Color(0xFFFAF8F5),
    Color(0xFFE7E5E4),
    Color(0xFFA8A29E),
    Color(0xFF78716C),
    Color(0xFF57534E),
    Color(0xFF292524),
  ];

  /// Build dark premium theme
  static ThemeData buildDarkPremiumTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkPremiumBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        onPrimary: textWhite,
        surface: darkPremiumSurface,
        onSurface: darkPremiumTextPrimary,
        secondary: primaryAmber,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: darkPremiumTextPrimary,
        displayColor: darkPremiumTextPrimary,
      ),
      dividerColor: darkPremiumDivider,
    );
  }
}
