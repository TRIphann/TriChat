import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

/// ════════════════════════════════════════════════════════════════
/// SIGN UP VIEW — Tạo tài khoản trực tiếp (đã bỏ qua bước OTP)
/// ════════════════════════════════════════════════════════════════

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  DateTime? _dateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _agreeTerms = false;
  String? _errorMessage;
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  late AnimationController _mainController;
  late AnimationController _shakeCtrl;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );
    _mainController.forward();

    _firstNameController.addListener(_updateButtonState);
    _lastNameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(() {
      _evaluatePasswordStrength();
      _updateButtonState();
    });
    _confirmPasswordController.addListener(_updateButtonState);
    _updateButtonState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _shakeCtrl.dispose();
    _mainController.dispose();
    super.dispose();
  }

  void _evaluatePasswordStrength() {
    final p = _passwordController.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
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
        case 4:
          _passwordStrengthLabel = score == 4 ? 'Rất mạnh' : 'Mạnh';
          _passwordStrengthColor = AppColors.success;
          break;
      }
    });
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    return emailRegex.hasMatch(value.trim());
  }

  void _updateButtonState() {
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final isEmailValid = _isValidEmail(email);
    final isPasswordValid =
        password.length >= 8 &&
            RegExp(r'[a-z]').hasMatch(password) &&
            RegExp(r'[A-Z]').hasMatch(password) &&
            RegExp(r'[0-9]').hasMatch(password);
    final isConfirmValid = confirm.isNotEmpty && confirm == password;
    final isDobValid = _dateOfBirth != null &&
        _dateOfBirth!.isBefore(DateTime.now());

    setState(() {
      _isButtonEnabled = email.isNotEmpty &&
          firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          isEmailValid &&
          isPasswordValid &&
          isConfirmValid &&
          isDobValid &&
          _agreeTerms;
      if (_errorMessage != null) _errorMessage = null;
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryOrange,
                  onPrimary: Colors.white,
                  surface: isDark ? AppColors.darkCard : AppColors.creamWhite,
                  onSurface: isDark ? Colors.white : AppColors.accentBrown,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _dateOfBirth = picked);
    _updateButtonState();
  }

  void _onAgreeTermsChanged(bool? value) {
    setState(() => _agreeTerms = value ?? false);
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
      final password = _passwordController.text;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final dob = _dateOfBirth!;

      await AuthService.register(
        RegisterRequest(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth:
              '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        ),
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      final rawMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = _mapRegisterError(rawMessage);
      });
      _shakeCtrl.forward(from: 0);
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
    if (lower.contains('password') &&
        (lower.contains('8') ||
            lower.contains('least') ||
            lower.contains('minimum') ||
            lower.contains('characters') ||
            lower.contains('ký tự'))) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    return message;
  }

  void _showSuccessDialog() {
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
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tạo tài khoản thành công!',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tài khoản của bạn đã được tạo.\nHãy đăng nhập để bắt đầu.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Đăng nhập ngay',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() => _isLoading = false);
                    context.go('/login');
                  },
                ),
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
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
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryButton(
                      'Tiếp tục',
                      () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDangerButton(
                      'Hủy đăng ký',
                      () => Navigator.pop(ctx, true),
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

  Widget _buildSecondaryButton(String label, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.creamSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
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
                        SizedBox(height: size.height * 0.03),
                        _buildHeader(theme, isDark),
                        SizedBox(height: size.height * 0.025),
                        _buildForm(theme, isDark),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
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
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _onBackPressed,
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
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
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
              'TẠO TÀI KHOẢN',
              style: AppTypography.eyebrow.copyWith(
                color: AppColors.primaryAmber,
              ),
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
          'Điền thông tin để tạo tài khoản TriChat mới.',
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          _buildErrorBanner(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Họ + Tên
        Row(
          children: [
            Expanded(
              child: TriTextField(
                controller: _firstNameController,
                focusNode: _firstNameFocusNode,
                keyboardType: TextInputType.name,
                hintText: 'Họ',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primaryAmber),
                textInputAction: TextInputAction.next,
                onSubmitted: () => _lastNameFocusNode.requestFocus(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập họ';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TriTextField(
                controller: _lastNameController,
                focusNode: _lastNameFocusNode,
                keyboardType: TextInputType.name,
                hintText: 'Tên',
                textInputAction: TextInputAction.next,
                onSubmitted: () => _emailFocusNode.requestFocus(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập tên';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Email
        TriTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          hintText: 'Nhập email của bạn',
          prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.primaryAmber),
          textInputAction: TextInputAction.next,
          onSubmitted: () => _passwordFocusNode.requestFocus(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!_isValidEmail(value)) {
              return 'Địa chỉ email không hợp lệ';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Ngày sinh
        _buildDobField(isDark),
        const SizedBox(height: AppSpacing.md),
        // Mật khẩu
        TriTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          hintText: 'Mật khẩu',
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primaryAmber),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: () => _confirmFocusNode.requestFocus(),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
            if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
            if (!RegExp(r'[a-z]').hasMatch(value)) {
              return 'Phải có ít nhất 1 chữ thường';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Phải có ít nhất 1 chữ hoa';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Phải có ít nhất 1 chữ số';
            }
            return null;
          },
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildPasswordStrengthBar(),
        ],
        const SizedBox(height: AppSpacing.md),
        // Xác nhận mật khẩu
        TriTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmFocusNode,
          obscureText: _obscureConfirm,
          hintText: 'Xác nhận mật khẩu',
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primaryAmber),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: _handleRegister,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
            if (value != _passwordController.text) return 'Mật khẩu không khớp';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildCheckbox(
          value: _agreeTerms,
          onChanged: _onAgreeTermsChanged,
          label: 'Tôi đồng ý với',
          link: 'Điều khoản sử dụng & Chính sách bảo mật',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDobField(bool isDark) {
    final dobText = _dateOfBirth == null
        ? null
        : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}';

    return InkWell(
      onTap: _pickDateOfBirth,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 4,
          vertical: AppSpacing.md + 6,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.creamWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.neutralGray200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 20, color: AppColors.primaryAmber),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                dobText ?? 'Ngày sinh (yyyy-MM-dd)',
                style: TextStyle(
                  fontSize: 15,
                  color: dobText == null
                      ? (isDark
                          ? AppColors.darkPremiumTextHint
                          : AppColors.textHint)
                      : (isDark ? Colors.white : AppColors.accentBrown),
                ),
              ),
            ),
            if (_dateOfBirth != null)
              GestureDetector(
                onTap: () {
                  setState(() => _dateOfBirth = null);
                  _updateButtonState();
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkPremiumTextSecondary
                      : AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            minHeight: 4,
            backgroundColor: Colors.black12,
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.errorLight,
              AppColors.errorLight.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
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
              child: Icon(
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, animValue, child) {
                return Transform.scale(
                  scale: animValue,
                  child: child,
                );
              },
              child: AnimatedContainer(
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
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAmber.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.textWhite,
                        size: 16,
                      )
                    : null,
              ),
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

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
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
          GestureDetector(
            onTap: _isButtonEnabled && !_isLoading ? _handleRegister : null,
            child: AnimatedContainer(
              duration: AppCurves.durationNormal,
              height: 56,
              decoration: BoxDecoration(
                gradient: _isButtonEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.primaryGradient,
                      )
                    : null,
                color: _isButtonEnabled
                    ? null
                    : (isDark ? AppColors.darkBorder : AppColors.borderDefault),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: _isButtonEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAmber.withValues(alpha: 0.35),
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
                              color: _isButtonEnabled
                                  ? AppColors.textWhite
                                  : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _isButtonEnabled
                                ? AppColors.textWhite
                                : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đã có tài khoản? ',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'Đăng nhập ngay',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
