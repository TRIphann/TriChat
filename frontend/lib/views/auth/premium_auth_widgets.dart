import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/tri_chat_logo.dart';
import 'package:go_router/go_router.dart';

/// ════════════════════════════════════════════════════════════════
/// PREMIUM AUTH WRAPPER — Shared Authentication Layout
/// ════════════════════════════════════════════════════════════════

class PremiumAuthWrapper extends StatefulWidget {
  final Widget child;
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool showBackButton;

  const PremiumAuthWrapper({
    super.key,
    required this.child,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.showBackButton = true,
  });

  @override
  State<PremiumAuthWrapper> createState() => _PremiumAuthWrapperState();
}

class _PremiumAuthWrapperState extends State<PremiumAuthWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.04),
                      if (widget.showBackButton) ...[
                        _buildBackButton(context, isDark),
                        SizedBox(height: size.height * 0.04),
                      ],
                      _buildHeader(theme, isDark),
                      SizedBox(height: size.height * 0.06),
                      widget.child,
                      SizedBox(height: size.height * 0.04),
                      SizedBox(height: AppSpacing.xxl),
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

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
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
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
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
            widget.eyebrow.toUpperCase(),
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.primaryAmber,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.title,
          style: AppTypography.displaySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.subtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// PREMIUM CARD — Consistent Card Style for Auth Screens
/// ════════════════════════════════════════════════════════════════

class PremiumAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const PremiumAuthCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
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
        padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// PREMIUM LOGO — Animated Logo for Auth
/// ════════════════════════════════════════════════════════════════

class AnimatedAuthLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const AnimatedAuthLogo({
    super.key,
    this.size = 80,
    this.animate = true,
  });

  @override
  State<AnimatedAuthLogo> createState() => _AnimatedAuthLogoState();
}

class _AnimatedAuthLogoState extends State<AnimatedAuthLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAmber.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.chat_rounded,
          color: AppColors.textWhite,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// OTP INPUT ENHANCED — Better OTP with Animations
/// ════════════════════════════════════════════════════════════════

class PremiumOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onResend;
  final int countdownSeconds;

  const PremiumOtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.onResend,
    this.countdownSeconds = 60,
  });

  @override
  State<PremiumOtpInput> createState() => _PremiumOtpInputState();
}

class _PremiumOtpInputState extends State<PremiumOtpInput>
    with SingleTickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdown = widget.countdownSeconds;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canResend = true;
          _pulseController.repeat(reverse: true);
        }
      });
      return _countdown > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _handleChange(int index, String value) {
    if (value.length > 1) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < clean.length && index + i < widget.length; i++) {
        _controllers[index + i].text = clean[i];
      }
      _focusNodes[(index + clean.length - 1).clamp(0, widget.length - 1)]
          .requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      widget.onChanged?.call(_controllers.map((c) => c.text).join());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: _buildOtpBox(index, isDark),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildResendRow(isDark),
      ],
    );
  }

  Widget _buildOtpBox(int index, bool isDark) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) => _handleKey(index, event),
      child: AnimatedContainer(
        duration: AppCurves.durationNormal,
        width: 52,
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _focusNodes[index].hasFocus
                ? AppColors.primaryAmber
                : (isDark ? AppColors.darkBorder : AppColors.borderDefault),
            width: _focusNodes[index].hasFocus ? 2 : 1.5,
          ),
          boxShadow: _focusNodes[index].hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primaryAmber.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            filled: false,
            counterText: '',
          ),
          onChanged: (v) => _handleChange(index, v),
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

  void _onResend() {
    _pulseController.stop();
    _pulseController.reset();
    _startCountdown();
    widget.onResend?.call();
  }
}
