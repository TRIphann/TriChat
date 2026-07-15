import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END OTP VERIFY VIEW — Premium Verification Screen
/// ════════════════════════════════════════════════════════════════

class OtpVerifyView extends StatefulWidget {
  final String email;

  const OtpVerifyView({super.key, required this.email});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView>
    with SingleTickerProviderStateMixin {
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String _otp = '';

  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

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
    setState(() => _isLoading = true);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.creamWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.successLight,
                      Color(0xFFDCFCE7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Xác thực thành công!',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mã OTP đã được xác thực.\nTiếp tục thiết lập mật khẩu.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Tiếp tục',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushReplacement('/set-password', extra: widget.email);
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
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.creamWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.errorLight,
                      Color(0xFFFEE2E2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Mã xác thực không đúng',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.06),
                  _buildBackButton(theme, isDark),
                  SizedBox(height: size.height * 0.04),
                  _buildHeader(theme, isDark),
                  SizedBox(height: size.height * 0.08),
                  _buildOtpCard(theme, isDark),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.creamWhite,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => context.pop(),
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.micro,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryAmberLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            'XÁC THỰC',
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.primaryAmber,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nhập mã\nxác thực',
          style: AppTypography.displaySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: 'Mã xác thực đã được gửi đến '),
              TextSpan(
                text: widget.email,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primaryAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.creamWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
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
            label: 'Xác thực',
            icon: Icons.verified_rounded,
            loading: _isLoading,
            onPressed: _isButtonEnabled ? () => _onContinue(_otp) : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildResendRow(isDark),
        ],
      ),
    );
  }

  Widget _buildResendRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Không nhận được mã? ',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: _canResend ? _onResend : null,
          child: AnimatedDefaultTextStyle(
            duration: AppCurves.durationFast,
            style: AppTypography.labelMedium.copyWith(
              color: _canResend
                  ? AppColors.primaryAmber
                  : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
              fontWeight: FontWeight.w700,
              decoration: _canResend ? TextDecoration.underline : TextDecoration.none,
            ),
            child: Text(
              _canResend
                  ? 'Gửi lại mã'
                  : 'Gửi lại (${_countdown}s)',
            ),
          ),
        ),
      ],
    );
  }
}
