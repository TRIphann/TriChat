import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END SIGN UP VIEW — Premium Registration Screen
/// ════════════════════════════════════════════════════════════════

class SignUpView extends StatefulWidget {
  final String? initialEmail;
  const SignUpView({super.key, this.initialEmail});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  bool _agreeTerms = false;
  bool _agreeSocialPolicy = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }

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

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-0.02, 0),
          end: const Offset(0.02, 0),
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _emailController.addListener(_updateButtonState);
    _updateButtonState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _shakeCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final t = AppLocalizations(localeNotifier.value);
    final isEmailValid = Validator.email(
      _emailController.text,
      requiredMessage: t.get('validatorRequired'),
      invalidMessage: t.get('validatorEmail'),
    ) ==
        null;

    setState(() {
      _isButtonEnabled = isEmailValid && _agreeTerms && _agreeSocialPolicy;
      if (_errorMessage != null) _errorMessage = null;
    });
  }

  void _onAgreeTermsChanged(bool? value) {
    setState(() => _agreeTerms = value ?? false);
    _updateButtonState();
  }

  void _onAgreeSocialPolicyChanged(bool? value) {
    setState(() => _agreeSocialPolicy = value ?? false);
    _updateButtonState();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      await AuthService.sendOtp(email);
      if (!mounted) return;
      _showConfirmSheet();
    } catch (e) {
      if (!mounted) return;
      final rawMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = _mapRegisterError(rawMessage));
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapRegisterError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already') ||
        lower.contains('exists') ||
        lower.contains('tồn tại') ||
        lower.contains('đã đăng ký') ||
        lower.contains('đã được')) {
      return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
    }
    if (lower.contains('invalid') && lower.contains('email')) {
      return 'Địa chỉ email không hợp lệ.';
    }
    if (lower.contains('gửi') || lower.contains('send')) {
      return 'Không thể gửi OTP. Vui lòng thử lại sau.';
    }
    return message;
  }

  void _showConfirmSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.creamWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryAmberLight.withValues(alpha: 0.5),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.primaryAmber,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Xác nhận email',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mã xác thực sẽ được gửi đến\n${_emailController.text}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Hủy',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Tiếp tục',
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/otp', extra: _emailController.text.trim());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onBackPressed() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.creamWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warningLight,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Hủy đăng ký?',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Toàn bộ dữ liệu đã nhập sẽ bị xóa.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Tiếp tục',
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: const Text('Hủy đăng ký'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (shouldExit == true && mounted) {
      context.go('/');
    }
  }

  void _clearEmail() {
    _emailController.clear();
    _updateButtonState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final t = AppLocalizations(locale);
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _shakeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildBackButton(theme, isDark),
                              SizedBox(height: size.height * 0.04),
                              _buildHeader(theme, isDark, t),
                              SizedBox(height: size.height * 0.04),
                              _buildForm(theme, isDark, t),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomBar(theme, isDark, t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
          onTap: _onBackPressed,
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

  Widget _buildHeader(ThemeData theme, bool isDark, AppLocalizations t) {
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
            'TẠO TÀI KHOẢN',
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.primaryAmber,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Bắt đầu hành trình\ncủa bạn',
          style: AppTypography.displaySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nhập email để tạo tài khoản TriChat mới.',
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          _buildErrorBanner(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        TriTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          hintText: 'Nhập email của bạn',
          prefixIcon: const Icon(Icons.email_outlined, size: 20),
          suffixIcon: _emailController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel_rounded, size: 20),
                  onPressed: _clearEmail,
                )
              : null,
          validator: (value) {
            final t = AppLocalizations(localeNotifier.value);
            return Validator.email(
              value,
              requiredMessage: t.get('validatorRequired'),
              invalidMessage: t.get('validatorEmail'),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildCheckbox(
          value: _agreeTerms,
          onChanged: _onAgreeTermsChanged,
          label: t.get('agreeTerms'),
          link: t.get('agreeTermsLink'),
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildCheckbox(
          value: _agreeSocialPolicy,
          onChanged: _onAgreeSocialPolicyChanged,
          label: t.get('agreePolicy'),
          link: t.get('agreePolicyLink'),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String label,
    required String link,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppCurves.durationFast,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryAmber : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: value
                      ? AppColors.primaryAmber
                      : (isDark ? AppColors.darkBorder : AppColors.borderStrong),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$label $link',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.cream,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Tiếp tục',
            icon: Icons.arrow_forward_rounded,
            loading: _isLoading,
            onPressed: _isButtonEnabled ? _handleRegister : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${t.get('noAccount')} ',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              TextLinkButton(
                label: t.get('loginNow'),
                fontWeight: FontWeight.w700,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
