import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/utils/app_localizations.dart';

class ConfirmPhoneSheet extends StatelessWidget {
  final String phone;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const ConfirmPhoneSheet({
    super.key,
    required this.phone,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(localeNotifier.value);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 600;

    final dialogWidth = isWideScreen
        ? (screenWidth * 0.35).clamp(340.0, 420.0)
        : (screenWidth * 0.82).clamp(280.0, 360.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxHeight: screenHeight * 0.45),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(AppRadius.xl),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.get('confirmPhoneTitle')}\n$phone',
                      style: AppTypography.titleLarge.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.get('confirmPhoneDesc'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutralGray700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.neutralGray300),
              _SheetButton(
                label: t.get('continue_'),
                color: AppColors.primaryOrange,
                onTap: onContinue,
              ),
              Divider(height: 1, color: AppColors.neutralGray300),
              _SheetButton(
                label: t.get('changeNumber'),
                color: AppColors.neutralBlack,
                onTap: onCancel,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _SheetButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isLast
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          )
        : BorderRadius.zero;
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}