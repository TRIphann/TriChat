import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';

class SuccessDialog extends StatefulWidget {
  final VoidCallback onRedirect;

  const SuccessDialog({super.key, required this.onRedirect});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();

  static void show(BuildContext context, VoidCallback onRedirect) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SuccessDialog(onRedirect: onRedirect),
    ).then((_) => onRedirect());
  }
}

class _SuccessDialogState extends State<SuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.creamWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: AppColors.neutralGray300.withValues(alpha: 0.7),
          width: 0.6,
        ),
      ),
      elevation: 10,
      shadowColor: AppColors.accentBrown.withValues(alpha: 0.18),
      child: InkWell(
        onTap: () {
          _timer?.cancel();
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withValues(alpha: 0.18),
                      AppColors.success.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tạo tài khoản mới thành công',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Đang chuyển hướng...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutralGray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}