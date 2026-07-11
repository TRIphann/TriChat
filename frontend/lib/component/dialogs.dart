import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// DIALOGS — Chuẩn hoá các dialog thường gặp
/// ════════════════════════════════════════════════════════════════

/// Dialog xác nhận (OK / Cancel) — thiết kế mới, gradient cam, sạch sẽ.
Future<bool> showTriConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmText = 'Xác nhận',
  String cancelText = 'Hủy',
  bool danger = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final accent = danger ? AppColors.error : AppColors.primaryOrange;
      return Dialog(
        backgroundColor: AppColors.creamWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
            color: AppColors.neutralGray300.withValues(alpha: 0.7),
            width: 0.6,
          ),
        ),
        elevation: 8,
        shadowColor: AppColors.accentBrown.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.15),
                      accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  icon ?? Icons.help_outline_rounded,
                  color: accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(ctx).hintColor,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(cancelText),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(confirmText),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Dialog loading overlay đẹp hơn loading_dialog.dart cũ.
class TriLoadingDialog extends StatelessWidget {
  final String? message;
  const TriLoadingDialog({super.key, this.message});

  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => TriLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.creamWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.neutralGray300.withValues(alpha: 0.7),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBrown.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: AppTypography.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Phân loại snack bar.
enum TriSnackType { info, success, error, warning }

/// Snackbar wrapper với style đẹp — kế thừa theme nhưng cho phép tuỳ biến.
void showTriSnack(
  BuildContext context,
  String message, {
  TriSnackType type = TriSnackType.info,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  Color bg;
  Color fg = Colors.white;
  IconData defaultIcon;
  switch (type) {
    case TriSnackType.success:
      bg = AppColors.success;
      defaultIcon = Icons.check_circle_outline_rounded;
      break;
    case TriSnackType.error:
      bg = AppColors.error;
      defaultIcon = Icons.error_outline_rounded;
      break;
    case TriSnackType.warning:
      bg = AppColors.primaryOrange;
      defaultIcon = Icons.warning_amber_rounded;
      break;
    case TriSnackType.info:
      bg = AppColors.neutralGray800;
      defaultIcon = Icons.info_outline_rounded;
      break;
  }
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: fg),
            ),
          ),
        ],
      ),
      backgroundColor: bg,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
    ),
  );
}