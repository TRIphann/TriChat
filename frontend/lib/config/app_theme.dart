import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END THEME — Premium Visual Design
/// ════════════════════════════════════════════════════════════════
///
/// Design Language:
/// - Premium Editorial Luxury with warm cream tones
/// - Soft Structuralism with diffused ambient shadows
/// - Double-Bezel nested architecture for cards
/// - Large squircle radii (24-32px) for expensive feel
/// - Fluid spring animations
/// - Generous macro-whitespace

class AppTheme {
  AppTheme._();

  /// Light theme — warm cream background
  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  /// Dark theme — premium dark charcoal
  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  // ════════════════════════════════════════════════════════════════
  //  THEME BUILDER
  // ════════════════════════════════════════════════════════════════
  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    // Color scheme
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryAmber,
      brightness: brightness,
      primary: AppColors.primaryAmber,
      onPrimary: AppColors.textWhite,
      secondary: AppColors.accentWarm,
      onSecondary: AppColors.textWhite,
      surface: isDark ? AppColors.darkSurface : AppColors.creamWhite,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textWhite,
    );

    // Base colors
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.cream;
    final cardBg = isDark ? AppColors.darkCard : AppColors.creamWhite;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.borderDefault;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: scheme,
      primaryColor: AppColors.primaryAmber,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scaffoldBg,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scaffoldBg,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 24),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: textPrimary),
        toolbarHeight: 64,
        titleSpacing: AppSpacing.md,
      ),

      // ── Buttons ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAmber,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor:
              isDark ? AppColors.darkBorder : AppColors.borderDefault,
          disabledForegroundColor: textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: dividerColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAmber,
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

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAmber,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Inputs ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkElevated : AppColors.creamElevated,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPlaceholder,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
        helperStyle: AppTypography.bodySmall.copyWith(color: textSecondary),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: dividerColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.primaryAmber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
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
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: dividerColor, width: 1),
        ),
      ),

      // ── Dialogs ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      // ── Bottom sheets ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        elevation: 0,
        modalBackgroundColor: cardBg,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: dividerColor,
        dragHandleSize: const Size(40, 4),
      ),

      // ── Lists ────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: AppTypography.titleMedium.copyWith(color: textPrimary),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),

      // ── Dividers & progress ──────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryAmber,
        circularTrackColor: dividerColor,
        linearTrackColor: dividerColor,
      ),

      // ── Snackbar ─────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // ── Chips ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.creamSurface,
        selectedColor: AppColors.primaryAmber,
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textWhite,
        ),
        side: BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Floating action button ───────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAmber,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      // ── Switches / checkboxes / radios ───────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textWhite;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAmber;
          }
          return isDark ? AppColors.darkBorder : AppColors.borderStrong;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAmber;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.textWhite),
        side: BorderSide(color: dividerColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAmber;
          }
          return textSecondary;
        }),
      ),

      // ── Tab bar ──────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryAmber,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.primaryAmber,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        dividerColor: dividerColor,
        dividerHeight: 0,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primaryAmber, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      // ── Tooltip ─────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── Text ─────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: textPrimary),
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
