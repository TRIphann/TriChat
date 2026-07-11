import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';

/// Dialog loading — overlay mờ + spinner cam, căn giữa.
/// Thay thế cho `LoadingDialog` cũ (dùng màu xanh cứng).
class LoadingDialog {
  static void show(BuildContext context, {String message = "Đang xử lý..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (BuildContext context) {
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
                  color: AppColors.accentBrown.withValues(alpha: 0.22),
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
                if (message.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}