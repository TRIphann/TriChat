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
/// RADIUS TOKENS — Bo góc chuẩn
/// ════════════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();

  /// 4 — góc vuông vừa (chip nhỏ)
  static const double xs = 4;
  /// 8 — input field
  static const double sm = 8;
  /// 12 — card, button nhỏ
  static const double md = 12;
  /// 16 — modal, sheet
  static const double lg = 16;
  /// 20 — button lớn, message bubble
  static const double xl = 20;
  /// 25 — pill button (default Zalo-style)
  static const double pill = 25;
  /// 28 — card lớn
  static const double xxl = 28;
  /// full — tròn (avatar, dot)
  static const double full = 999;
}

/// ════════════════════════════════════════════════════════════════
/// SHADOWS — Soft elevation chuẩn
/// ════════════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  /// Shadow siêu nhẹ cho border/subtle separation
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Shadow nhỏ cho card/input
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Shadow vừa cho modal/button hover
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Shadow vừa cho card — equivalent to md (alias)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Shadow lớn cho popup/floating
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Shadow cam — dùng cho button primary nổi bật
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFFE25822).withValues(alpha: 0.30),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}