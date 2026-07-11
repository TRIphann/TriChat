import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/component/confirm_phone_sheet.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';

/// Màn hình đăng ký bước 1 — phong cách Glassmorphism
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

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

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
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmPhoneSheet(
        phone: _emailController.text,
        onContinue: () {
          Navigator.pop(context);
          context.push('/otp', extra: _emailController.text.trim());
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _onBackPressed() async {
    final shouldExit = await showTriConfirm(
      context,
      title: 'Hủy đăng ký?',
      message:
          'Bạn có chắc chắn muốn hủy đăng ký không? Toàn bộ dữ liệu đã nhập sẽ bị xóa.',
      confirmText: 'Hủy đăng ký',
      cancelText: 'Tiếp tục',
      danger: true,
      icon: Icons.warning_amber_rounded,
    );
    if (shouldExit && mounted) {
      context.go('/');
    }
  }

  void _clearEmail() {
    _emailController.clear();
    _updateButtonState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final t = AppLocalizations(locale);
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
              child: SlideTransition(
                position: _shakeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.md,
                            AppSpacing.xl,
                            AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildBackRow(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildHero(t),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildEmailCard(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildCheckbox(
                                value: _agreeTerms,
                                onChanged: _onAgreeTermsChanged,
                                label: t.get('agreeTerms'),
                                link: t.get('agreeTermsLink'),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildCheckbox(
                                value: _agreeSocialPolicy,
                                onChanged: _onAgreeSocialPolicyChanged,
                                label: t.get('agreePolicy'),
                                link: t.get('agreePolicyLink'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            PrimaryButton(
                              label: t.get('continue_'),
                              loading: _isLoading,
                              onPressed:
                                  _isButtonEnabled ? _handleRegister : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLoginLink(t),
                          ],
                        ),
                      ),
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

  Widget _buildBackRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _onBackPressed,
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
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.get('enterEmail'),
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.neutralBlack,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Nhập email để bắt đầu đăng ký tài khoản TriChat.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutralGray700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Container(
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
          TriTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            hintText: AppLocalizations(localeNotifier.value).get('emailHint'),
            prefixIcon: const Icon(
              Icons.alternate_email_rounded,
              size: 20,
            ),
            suffixIcon: _emailController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                    ),
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
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildErrorBanner(),
          ],
        ],
      ),
    );
  }

  // Email hint fallback (no global)

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
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
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutralBlack,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (link.isNotEmpty)
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          ' $link',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.get('noAccount'),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutralGray700,
          ),
        ),
        const SizedBox(width: 4),
        TextLinkButton(
          label: t.get('loginNow'),
          fontWeight: FontWeight.w700,
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }
}