import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

/// ════════════════════════════════════════════════════════════════
/// PREMIUM OTP VERIFY VIEW — High-End Verification Screen
/// ════════════════════════════════════════════════════════════════

class OtpVerifyView extends StatefulWidget {
  final String email;

  const OtpVerifyView({super.key, required this.email});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _otp = '';
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isSuccess = false;
  String? _errorMessage;

  // OTP input controllers — one per digit
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  late AnimationController _mainController;
  late AnimationController _successController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successScaleAnimation;

  bool _otpSent = false;
  String? _otpError;

  @override
  void initState() {
    super.initState();

    // OTP controllers & focus nodes
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.easeOutBack,
      ),
    );

    _mainController.forward();
    _pulseController.repeat(reverse: true);

    _startCountdown();
    _sendOtpSilently();
  }

  Future<void> _sendOtpSilently() async {
    try {
      await AuthService.sendOtp(widget.email);
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  /// Called whenever any OTP digit changes — rebuilds _otp string and enables button when complete.
  void _onOtpChanged(String value, int index) {
    final fullOtp = _controllers.map((c) => c.text).join();
    setState(() {
      _otp = fullOtp;
      _errorMessage = null;
    });

    // Auto-advance focus
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are entered
    if (fullOtp.length == 6) {
      FocusScope.of(context).unfocus();
      _onVerify(fullOtp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _onOtpChanged('', index - 1);
    }
  }

  Future<void> _onResend() async {
    if (!_canResend || _isLoading) return;

    // Clear all inputs
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();

    setState(() {
      _otp = '';
      _isLoading = true;
      _errorMessage = null;
      _otpError = null;
    });

    try {
      await AuthService.sendOtp(widget.email);
      _startCountdown();
      if (!mounted) return;
      showTriSnack(
        context,
        'Mã OTP mới đã được gửi đến ${widget.email}',
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

  Future<void> _onVerify(String otp) async {
    if (_otp.length != 6 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.verifyOtp(widget.email, otp);
      if (!mounted) return;

      if (success) {
        setState(() => _isSuccess = true);
        _successController.forward();
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        _showErrorDialog('Mã xác thực không chính xác');
        _clearOtp();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showErrorDialog(msg);
      _clearOtp();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _otp = '';
      _errorMessage = null;
    });
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
              ScaleTransition(
                scale: _successScaleAnimation,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.textWhite,
                    size: 44,
                  ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.error,
                      AppColors.error.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.textWhite,
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
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _mainController.dispose();
    _successController.dispose();
    _pulseController.dispose();
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
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
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
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return Transform.scale(
      scale: 1.0,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkCard : AppColors.creamWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => context.pop(),
            customBorder: const CircleBorder(),
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
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAmber.withValues(alpha: 0.2),
                AppColors.primaryAmber.withValues(alpha: 0.1),
              ],
            ),
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
          _buildOtpInputs(isDark),
          if (_otpError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _otpError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_otpSent && _otpError == null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryAmber,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Đang gửi mã OTP...',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildVerifyButton(theme, isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildResendRow(isDark),
        ],
      ),
    );
  }

  Widget _buildOtpInputs(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _buildOtpBox(index, isDark);
      }),
    );
  }

  Widget _buildOtpBox(int index, bool isDark) {
    final hasFocus = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: AppCurves.durationNormal,
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasFocus
              ? AppColors.primaryAmber
              : (isDark ? AppColors.darkBorder : AppColors.borderDefault),
          width: hasFocus ? 2 : 1.5,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primaryAmber.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _onKeyEvent(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: AppTypography.headlineMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: false,
            hintText: hasValue ? '' : '•',
            hintStyle: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onChanged: (value) => _onOtpChanged(value, index),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(ThemeData theme, bool isDark) {
    final canVerify = _otp.length == 6 && !_isLoading;

    return GestureDetector(
      onTap: canVerify ? () => _onVerify(_otp) : null,
      child: AnimatedContainer(
        duration: AppCurves.durationNormal,
        height: 56,
        decoration: BoxDecoration(
          gradient: canVerify
              ? LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: canVerify
              ? null
              : (isDark ? AppColors.darkBorder : AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: canVerify
              ? [
                  BoxShadow(
                    color: AppColors.primaryAmber.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xác thực',
                      style: AppTypography.labelLarge.copyWith(
                        color: canVerify
                            ? AppColors.textWhite
                            : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.verified_rounded,
                      color: canVerify
                          ? AppColors.textWhite
                          : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                      size: 20,
                    ),
                  ],
                ),
        ),
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
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _canResend ? 1.0 + (_pulseController.value * 0.05) : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
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
        ),
      ],
    );
  }
}
