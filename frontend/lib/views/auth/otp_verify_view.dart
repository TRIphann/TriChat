import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Màn hình nhập mã OTP — phong cách Glassmorphism
class OtpVerifyView extends StatefulWidget {
  final String email;

  const OtpVerifyView({super.key, required this.email});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String _otp = '';

  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _startCountdown();
    AuthService.sendOtp(widget.email).catchError((_) {});
  }

  void _startCountdown() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _onContinue(String otp) async {
    if (otp.length != 6 || _isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      bool isValid = await AuthService.verifyOtp(widget.email, otp);
      if (!mounted) return;
      if (isValid) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Mã xác thực không chính xác');
        setState(() {
          _otp = '';
          _isButtonEnabled = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      setState(() {
        _otp = '';
        _isButtonEnabled = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResend() async {
    if (!_canResend || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.sendOtp(widget.email);
      _startCountdown();
      setState(() {
        _otp = '';
        _isButtonEnabled = false;
      });
      if (!mounted) return;
      showTriSnack(
        context,
        'Mã OTP mới đã được gửi',
        type: TriSnackType.success,
        icon: Icons.mark_email_read_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      showTriSnack(
        context,
        'Không thể gửi lại mã. Vui lòng thử lại.',
        type: TriSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final t = AppLocalizations(localeNotifier.value);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBrown.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
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
              Text(t.get('otpSuccess'), style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushReplacement('/set-password', extra: widget.email);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(t.get('continue_')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBrown.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 52,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Mã xác thực không đúng',
                style: AppTypography.titleLarge,
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutralGray700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: const Text('Thử lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.creamBackgroundGradient,
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: localeNotifier,
            builder: (context, locale, _) {
              final t = AppLocalizations(locale);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBackRow(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHero(t),
                    const SizedBox(height: AppSpacing.huge),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBrown.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TriOtpInput(
                            length: 6,
                            onChanged: (otp) {
                              setState(() {
                                _otp = otp;
                                _isButtonEnabled = otp.length == 6;
                              });
                            },
                            onCompleted: _onContinue,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PrimaryButton(
                            label: t.get('continue_'),
                            loading: _isLoading,
                            onPressed: _isButtonEnabled
                                ? () => _onContinue(_otp)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildResendRow(t),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => context.pop(),
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.7),
              border: Border.all(
                color: AppColors.neutralGray300.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.accentBrown,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: AppColors.primaryButtonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          t.get('otpTitle'),
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.neutralBlack,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutralGray700,
              height: 1.5,
            ),
            children: [
              TextSpan(text: '${t.get('otpDesc')} '),
              TextSpan(
                text: widget.email,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResendRow(AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.get('otpNotReceived'),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutralGray700,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _canResend ? _onResend : null,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTypography.labelMedium.copyWith(
              color: _canResend
                  ? AppColors.primaryOrange
                  : AppColors.neutralGray500,
              fontWeight: FontWeight.w700,
            ),
            child: Text(
              _canResend
                  ? t.get('otpResend')
                  : '${t.get('otpResend')} (${_countdown}s)',
            ),
          ),
        ),
      ],
    );
  }
}