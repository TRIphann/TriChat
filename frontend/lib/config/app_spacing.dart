import 'package:flutter/widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END SPACING & RADIUS SYSTEM
/// ════════════════════════════════════════════════════════════════
///
/// Premium spacing with generous macro-whitespace
/// Large squircle radii for expensive feel
/// Soft diffused shadows for depth

class AppSpacing {
  AppSpacing._();

  /// 4 — micro spacing (icon margins)
  static const double micro = 4;
  /// 8 — tight spacing (within components)
  static const double xs = 8;
  /// 12 — compact spacing (input fields)
  static const double sm = 12;
  /// 16 — standard spacing (card padding)
  static const double md = 16;
  /// 20 — comfortable spacing (section padding)
  static const double lg = 20;
  /// 24 — relaxed spacing (screen padding)
  static const double xl = 24;
  /// 32 — spacious (major section gaps)
  static const double xxl = 32;
  /// 48 — generous (hero spacing)
  static const double xxxl = 48;
  /// 64 — luxurious (splash/landing)
  static const double huge = 64;
  /// 96 — cinematic (hero sections)
  static const double gigantic = 96;

  /// Backward compatibility aliases
  static const double xxs = micro;
}

/// ════════════════════════════════════════════════════════════════
/// PREMIUM RADIUS TOKENS — Large Squircle for Expensive Feel
/// ════════════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();

  /// 4 — subtle rounding (small elements)
  static const double xs = 4;
  /// 8 — light rounding (inputs, chips)
  static const double sm = 8;
  /// 12 — medium rounding (buttons, cards)
  static const double md = 12;
  /// 16 — premium rounding (large cards)
  static const double lg = 16;
  /// 20 — luxurious (modal, sheets)
  static const double xl = 20;
  /// 24 — ultra premium (hero cards, avatars)
  static const double xxl = 24;
  /// 32 — cinematic (floating elements)
  static const double xxxl = 32;
  /// 999 — pill (avatars, badges)
  static const double pill = 999;
  /// full — perfect circle
  static const double full = 999;

  /// Backward compatibility
  static const double xxlAlias = xxxl;
  static const double fullAlias = full;

  /// Pre-defined BorderRadius for convenience
  static BorderRadius get radiusXs => BorderRadius.circular(xs);
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get radiusXxxl => BorderRadius.circular(xxxl);
  static BorderRadius get radiusPill => BorderRadius.circular(pill);
}

/// ════════════════════════════════════════════════════════════════
/// SOFT SHADOW SYSTEM — Highly Diffused for Premium Depth
/// ════════════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  /// Ultra subtle — hairline elevation
  static List<BoxShadow> get xs => [
    BoxShadow(
      color: const Color(0x0A000000),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Subtle — card resting state
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: const Color(0x0F000000),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0x05000000),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Medium — elevated cards, modals
  static List<BoxShadow> get md => [
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0x0A000000),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Large — floating elements, dropdowns
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: const Color(0x19000000),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0x0F000000),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  /// Premium glow — CTA buttons
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: const Color(0x20D97706),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Premium glow large
  static List<BoxShadow> get glowLg => [
    BoxShadow(
      color: const Color(0x30D97706),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Inner subtle — inset elements
  static List<BoxShadow> get innerSm => [
    BoxShadow(
      color: const Color(0x08000000),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Backward compatibility
  static List<BoxShadow> get card => sm;
  static List<BoxShadow> get primaryGlow => glow;
}

/// ════════════════════════════════════════════════════════════════
/// ANIMATION CURVES — Premium Spring Physics
/// ════════════════════════════════════════════════════════════════
class AppCurves {
  AppCurves._();

  /// Primary ease — smooth deceleration
  static const Curve primary = Curves.easeOutCubic;

  /// Secondary ease — gentle
  static const Curve secondary = Curves.easeInOutCubic;

  /// Snappy — for micro-interactions
  static const Curve snappy = Curves.easeOutQuart;

  /// Bouncy — for playful elements
  static const Curve bouncy = Curves.elasticOut;

  /// Smooth slide — for panels
  static const Curve slide = Curves.easeOutExpo;

  /// Spring simulation parameters
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 700);
}
