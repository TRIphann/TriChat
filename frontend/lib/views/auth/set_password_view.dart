import 'package:flutter/material.dart';
import 'package:frontend/component/buttons.dart';
import 'package:frontend/component/dialogs.dart';
import 'package:frontend/component/inputs.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

/// ════════════════════════════════════════════════════════════════
/// SET PASSWORD VIEW — After OTP verification, create account
/// ════════════════════════════════════════════════════════════════

class ResetPasswordView extends StatefulWidget {
  final String? email;
  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = false;
  bool _obscureConfirm = false;
  bool _isFormValid = false;
  bool _isLoading = false;
  String? _errorMessage;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onInputChanged);
    _confirmCtrl.addListener(_onInputChanged);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _evaluatePasswordStrength();
    _validateForm();
  }

  void _validateForm() {
    final p = _passwordCtrl.text;
    final c = _confirmCtrl.text;
    final isValid = p.length >= 8 && c.isNotEmpty && p == c;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  void _evaluatePasswordStrength() {
    final p = _passwordCtrl.text;
    if (p.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
        _passwordStrengthColor = Colors.transparent;
      });
      return;
    }
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
    setState(() {
      _passwordStrength = score / 4;
      switch (score) {
        case 0:
        case 1:
          _passwordStrengthLabel = 'Yếu';
          _passwordStrengthColor = AppColors.error;
          break;
        case 2:
          _passwordStrengthLabel = 'Trung bình';
          _passwordStrengthColor = AppColors.warning;
          break;
        case 3:
          _passwordStrengthLabel = 'Mạnh';
          _passwordStrengthColor = AppColors.success;
          break;
        case 4:
          _passwordStrengthLabel = 'Rất mạnh';
          _passwordStrengthColor = AppColors.success;
          break;
      }
    });
  }

  String _mapError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('weak-password')) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    if (lower.contains('email-already')) {
      return 'Email này đã được đăng ký. Vui lòng dùng email khác.';
    }
    if (lower.contains('invalid-email')) {
      return 'Địa chỉ email không hợp lệ.';
    }
    if (lower.contains('invalid-credential')) {
      return 'Thông tin đăng nhập không hợp lệ.';
    }
    if (lower.contains('network')) {
      return 'Lỗi kết nối mạng. Vui lòng thử lại.';
    }
    return msg;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    if (widget.email == null || widget.email!.isEmpty) {
      setState(() => _errorMessage = 'Email không hợp lệ. Vui lòng quay lại bước trước.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.register(
        RegisterRequest(
          email: widget.email!,
          password: _passwordCtrl.text.trim(),
          firstName: '',
          lastName: '',
        ),
      );

      if (!mounted) return;
      _showSuccessAndNavigate();
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = _mapError(raw);
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  void _showSuccessAndNavigate() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.creamWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
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
                  gradient: LinearGradient(colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.8),
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.textWhite, size: 36),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tài khoản đã được tạo!',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hoàn tất thông tin cá nhân để bắt đầu trò chuyện.',
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
                    context.pushReplacement('/enter-name', extra: {
                      'email': widget.email,
                      'password': _passwordCtrl.text.trim(),
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
      body: SafeArea(
        child: SlideTransition(
          position: _shakeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildBackButton(theme, isDark),
                const SizedBox(height: AppSpacing.xl),
                _buildHeader(theme, isDark),
                const SizedBox(height: AppSpacing.xxl),
                _buildCard(theme, isDark),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return Container(
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
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.micro),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primaryAmber.withValues(alpha: 0.2),
              AppColors.primaryAmber.withValues(alpha: 0.1),
            ]),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            'THIẾT LẬP MẬT KHẨU',
            style: AppTypography.eyebrow.copyWith(color: AppColors.primaryAmber),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tạo mật khẩu\ncho tài khoản',
          style: AppTypography.displaySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ hoa, chữ thường và số.',
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(ThemeData theme, bool isDark) {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorBanner(isDark),
              const SizedBox(height: AppSpacing.lg),
            ],
            _buildPasswordField(theme, isDark),
            if (_passwordCtrl.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildStrengthBar(theme),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildConfirmField(theme, isDark),
            const SizedBox(height: AppSpacing.xl),
            _buildSubmitButton(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mật khẩu',
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TriTextField(
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          obscureText: !_obscurePassword,
          hintText: 'Nhập mật khẩu mới',
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primaryAmber),
          suffixIcon: IconButton(
            splashRadius: 20,
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
            if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
            if (!RegExp(r'[a-z]').hasMatch(v)) return 'Phải có ít nhất 1 chữ thường';
            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Phải có ít nhất 1 chữ hoa';
            if (!RegExp(r'[0-9]').hasMatch(v)) return 'Phải có ít nhất 1 chữ số';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác nhận mật khẩu',
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TriTextField(
          controller: _confirmCtrl,
          focusNode: _confirmFocus,
          obscureText: !_obscureConfirm,
          hintText: 'Nhập lại mật khẩu',
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primaryAmber),
          suffixIcon: IconButton(
            splashRadius: 20,
            icon: Icon(
              _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
            if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStrengthBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            minHeight: 4,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Độ mạnh: $_passwordStrengthLabel',
          style: AppTypography.bodySmall.copyWith(
            color: _passwordStrengthColor,
            fontWeight: FontWeight.w600,
          ),
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
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
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
            child: Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
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

  Widget _buildSubmitButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _isFormValid && !_isLoading ? _handleSubmit : null,
      child: AnimatedContainer(
        duration: AppCurves.durationNormal,
        height: 56,
        decoration: BoxDecoration(
          gradient: _isFormValid && !_isLoading
              ? LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: _isFormValid && !_isLoading
              ? null
              : (isDark ? AppColors.darkBorder : AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: _isFormValid && !_isLoading
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
                    color: AppColors.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tạo tài khoản',
                      style: AppTypography.labelLarge.copyWith(
                        color: _isFormValid
                            ? AppColors.textWhite
                            : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _isFormValid
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
}
