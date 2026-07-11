import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// THEME — Light & Dark cho TriChat (Glassmorphism)
/// ════════════════════════════════════════════════════════════════
///
/// Phong cách mới:
/// - Nền cream / be cực nhạt
/// - Hiệu ứng kính mờ (glass) cho sidebar, header, modal
/// - Accent: cam san hô + nâu socola sữa
/// - Material 3 + glass tokens
class AppTheme {
  AppTheme._();

  /// Theme cho chế độ sáng — primary mặc định.
  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  /// Theme cho chế độ tối.
  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  // ════════════════════════════════════════════════════════════════
  //  BUILDER
  // ════════════════════════════════════════════════════════════════
  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryOrange,
      brightness: brightness,
      primary: AppColors.primaryOrange,
      onPrimary: Colors.white,
      secondary: AppColors.accentBrown,
      onSecondary: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.creamWhite,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.neutralBlack,
      error: AppColors.error,
      onError: Colors.white,
    );

    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.creamBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.creamWhite;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.neutralBlack;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.neutralGray700;
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.neutralGray300;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: scheme,
      primaryColor: AppColors.primaryOrange,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scaffoldBg,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 22),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: Colors.white),
        toolbarHeight: 56,
        shape: const Border(),
      ),

      // ── Buttons ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? AppColors.neutralGray700.withValues(alpha: 0.5)
              : AppColors.neutralGray300,
          disabledForegroundColor:
              isDark ? AppColors.neutralGray500 : AppColors.neutralGray700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md + 2,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: dividerColor, width: 1.2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md + 2,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          textStyle: AppTypography.labelMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // ── Inputs ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkCard
            : Colors.white.withValues(alpha: 0.7),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutralGray500,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
        helperStyle: AppTypography.bodySmall.copyWith(color: textSecondary),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ── Cards ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: dividerColor.withValues(alpha: 0.5)),
        ),
      ),

      // ── Dialogs ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      // ── Bottom sheets ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        elevation: 12,
        modalBackgroundColor: cardBg,
        modalElevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: dividerColor,
      ),

      // ── Lists ────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: AppTypography.titleSmall.copyWith(color: textPrimary),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Dividers & progress ──────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        space: 1,
        thickness: 0.6,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryOrange,
        circularTrackColor: AppColors.primaryOrange.withValues(alpha: 0.18),
        linearTrackColor: AppColors.primaryOrange.withValues(alpha: 0.18),
      ),

      // ── Snackbar ─────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutralBlack,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // ── Chips ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkCard
            : Colors.white.withValues(alpha: 0.6),
        selectedColor: AppColors.primaryOrangePale,
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        side: BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Floating action button ───────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      // ── Switches / checkboxes / radios ───────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return isDark ? AppColors.darkDivider : AppColors.neutralGray300;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: dividerColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return textSecondary;
        }),
      ),

      // ── Tab bar ──────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.primaryOrange,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        dividerColor: dividerColor,
      ),

      // ── Tooltip ──────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.neutralBlack.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── Text ─────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: textPrimary,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: textPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: textPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: textPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: textPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: textSecondary),
        labelLarge: AppTypography.labelLarge.copyWith(color: textPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: textPrimary),
        labelSmall: AppTypography.labelSmall.copyWith(color: textSecondary),
      ),
    );
  }
}