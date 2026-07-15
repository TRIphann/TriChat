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

/// Màn hình nhập mã OTP — phong cách Minimalist.
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successLight,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.get('otpSuccess'),
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: t.get('continue_'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushReplacement('/set-password',
                        extra: widget.email);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorLight,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Mã xác thực không đúng',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Thử lại',
                  onPressed: () => Navigator.pop(ctx),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            final t = AppLocalizations(locale);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBackRow(theme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHero(t, theme),
                  const SizedBox(height: AppSpacing.huge),
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
                    onPressed:
                        _isButtonEnabled ? () => _onContinue(_otp) : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildResendRow(t, theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackRow(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: theme.brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.neutralGray100,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => context.pop(),
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations t, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.get('otpTitle'),
          style: AppTypography.headlineLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium.copyWith(
              color: theme.hintColor,
              height: 1.5,
            ),
            children: [
              TextSpan(text: '${t.get('otpDesc')} '),
              TextSpan(
                text: widget.email,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResendRow(AppLocalizations t, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.get('otpNotReceived'),
          style: AppTypography.bodyMedium.copyWith(
            color: theme.hintColor,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _canResend ? _onResend : null,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTypography.labelMedium.copyWith(
              color: _canResend
                  ? AppColors.neutralBlack
                  : AppColors.neutralGray500,
              fontWeight: FontWeight.w700,
              decoration: _canResend
                  ? TextDecoration.underline
                  : TextDecoration.none,
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
