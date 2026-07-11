import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// TRIẾT LÝ THIẾT KẾ — Typography scale cho TriChat
/// ════════════════════════════════════════════════════════════════
///
/// Hệ thống type 8pt dựa trên Material 3 nhưng tinh chỉnh cho tiếng
/// Việt: letterSpacing âm cho display/title để chữ đậm-nét,
/// lineHeight vừa phải để dễ đọc nhiều dòng.
class AppTypography {
  AppTypography._();

  // Font family mặc định của toàn app
  static const String fontFamily = 'Roboto';

  // ════════════════════════════════════════════════════════════════
  //  DISPLAY — Tiêu đề lớn (splash, hero text)
  // ════════════════════════════════════════════════════════════════
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.0,
  );

  // ════════════════════════════════════════════════════════════════
  //  HEADLINE — Tiêu đề màn hình / section
  // ════════════════════════════════════════════════════════════════
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // ════════════════════════════════════════════════════════════════
  //  TITLE — Tiêu đề phụ / card / dialog
  // ════════════════════════════════════════════════════════════════
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ════════════════════════════════════════════════════════════════
  //  BODY — Nội dung chính
  // ════════════════════════════════════════════════════════════════
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ════════════════════════════════════════════════════════════════
  //  LABEL — Button, chip, tab, caption
  // ════════════════════════════════════════════════════════════════
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // ════════════════════════════════════════════════════════════════
  //  CHAT-SPECIFIC
  // ════════════════════════════════════════════════════════════════
  static const TextStyle messageBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.05,
  );

  static const TextStyle messageMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  static const TextStyle timestamp = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );
}