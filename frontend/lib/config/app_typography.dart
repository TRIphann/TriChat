import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END TYPOGRAPHY SYSTEM
/// ════════════════════════════════════════════════════════════════
///
/// Premium type scale with wide geometric Grotesk aesthetic
/// High contrast for cinematic hierarchy
/// Generous tracking for spacious headlines

class AppTypography {
  AppTypography._();

  // Font family — geometric sans-serif
  // Flutter uses system fonts: SF Pro on iOS, Roboto on Android
  // We use system font with geometric characteristics
  static const String fontFamily = 'Roboto';

  // ════════════════════════════════════════════════════════════════
  //  DISPLAY — Massive typography for hero sections
  // ════════════════════════════════════════════════════════════════
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -1.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  // ════════════════════════════════════════════════════════════════
  //  HEADLINE — Section titles with hierarchy
  // ════════════════════════════════════════════════════════════════
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.8,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // ════════════════════════════════════════════════════════════════
  //  TITLE — Component titles, card headings
  // ════════════════════════════════════════════════════════════════
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  // ════════════════════════════════════════════════════════════════
  //  BODY — Content text
  // ════════════════════════════════════════════════════════════════
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.1,
  );

  // ════════════════════════════════════════════════════════════════
  //  LABEL — Buttons, chips, captions
  // ════════════════════════════════════════════════════════════════
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // ════════════════════════════════════════════════════════════════
  //  CHAT-SPECIFIC — Optimized for messaging
  // ════════════════════════════════════════════════════════════════
  static const TextStyle messageBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static const TextStyle messageMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.2,
  );

  static const TextStyle timestamp = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.2,
  );

  // ════════════════════════════════════════════════════════════════
  //  SPECIAL — Eyebrow tags, badges
  // ════════════════════════════════════════════════════════════════
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.5,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
  );
}
