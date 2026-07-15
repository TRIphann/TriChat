import 'package:flutter/widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// SPACING TOKENS — Khoảng cách chuẩn 4pt grid cho TriChat
/// ════════════════════════════════════════════════════════════════
///
/// Sử dụng thay vì hardcode EdgeInsets/padding để giữ nhịp thị giác
/// thống nhất toàn app.
class AppSpacing {
  AppSpacing._();

  /// 2 — khoảng rất nhỏ (icon sát text)
  static const double xxs = 2;
  /// 4 — nhỏ (giữa 2 dòng meta)
  static const double xs = 4;
  /// 8 — chuẩn nhỏ (padding trong input)
  static const double sm = 8;
  /// 12 — chuẩn vừa (padding card)
  static const double md = 12;
  /// 16 — chuẩn (padding section)
  static const double lg = 16;
  /// 20 — lớn (padding screen)
  static const double xl = 20;
  /// 24 — rất lớn (padding section quan trọng)
  static const double xxl = 24;
  /// 32 — giant (giữa section lớn)
  static const double xxxl = 32;
  /// 48 — section lớn (hero spacing)
  static const double huge = 48;
  /// 64 — cực lớn (splash)
  static const double gigantic = 64;
}

/// ════════════════════════════════════════════════════════════════
/// RADIUS TOKENS — Bo góc chuẩn (minimalist: nhỏ, sắc nét)
/// ════════════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();

  /// 2 — góc vuông gần như sắc (chip nhỏ)
  static const double xs = 2;
  /// 4 — input field (minimalist)
  static const double sm = 4;
  /// 6 — card, button nhỏ
  static const double md = 6;
  /// 8 — modal, sheet
  static const double lg = 8;
  /// 10 — button lớn, message bubble
  static const double xl = 10;
  /// 999 — pill (chỉ dùng cho avatar / tag tròn)
  static const double pill = 999;
  /// 12 — card lớn
  static const double xxl = 12;
  /// full — tròn (avatar, dot)
  static const double full = 999;
}

/// ════════════════════════════════════════════════════════════════
/// SHADOWS — Hairline elevation (gần như không có)
/// ════════════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  /// Shadow siêu nhẹ — border subtle separation
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Shadow nhỏ — input focus
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Shadow vừa — modal
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Shadow card — equivalent to md (alias)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Shadow lớn — popup/floating
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Shadow primary — dùng cho button chính (đen)
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFF0F0F0F).withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
