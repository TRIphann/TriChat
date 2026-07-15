import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/component/buttons.dart';
import 'package:frontend/component/dialogs.dart';
import 'package:frontend/component/inputs.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  DateTime? _selectedDob;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

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
            begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _passwordCtrl.addListener(_evaluatePasswordStrength);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _passwordCtrl,
      _confirmPasswordCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _firstNameFocus,
      _lastNameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  void _evaluatePasswordStrength() {
    final p = _passwordCtrl.text;
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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: maxDate,
      helpText: 'Chọn ngày sinh',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.neutralBlack,
            onPrimary: Colors.white,
            onSurface: AppColors.neutralBlack,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dobStr = _selectedDob != null
          ? '${_selectedDob!.year.toString().padLeft(4, '0')}-'
              '${_selectedDob!.month.toString().padLeft(2, '0')}-'
              '${_selectedDob!.day.toString().padLeft(2, '0')}'
          : null;

      await AuthService.register(
        RegisterRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          dateOfBirth: dobStr,
        ),
      );

      if (!mounted) return;
      _showSuccessAndNavigate();
    } catch (e) {
      if (!mounted) return;
      final rawMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = _mapBackendError(rawMessage);
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  String _mapBackendError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('password') &&
        (lower.contains('8') ||
            lower.contains('least') ||
            lower.contains('minimum') ||
            lower.contains('characters') ||
            lower.contains('ký tự'))) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    if (lower.contains('password') &&
        (lower.contains('uppercase') ||
            lower.contains('upper case') ||
            lower.contains('capital') ||
            lower.contains('chữ hoa'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa (A-Z).';
    }
    if (lower.contains('password') &&
        (lower.contains('lowercase') ||
            lower.contains('lower case') ||
            lower.contains('letter') ||
            lower.contains('chữ thường'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường (a-z).';
    }
    if (lower.contains('email') && lower.contains('exist')) {
      return 'Email này đã được sử dụng. Vui lòng dùng email khác.';
    }
    if (lower.contains('invalid') && lower.contains('email')) {
      return 'Địa chỉ email không hợp lệ.';
    }
    return message;
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                decoration: const BoxDecoration(
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
                'Đăng ký thành công!',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tài khoản của bạn đã được tạo. Hãy đăng nhập để tiếp tục.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Đăng nhập ngay',
                  onPressed: () {
                    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: SlideTransition(
                      position: _shakeAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _buildSubtitle(theme),
                            const SizedBox(height: AppSpacing.xxl),
                            _buildNameRow(),
                            const SizedBox(height: AppSpacing.md),
                            _buildEmailField(),
                            const SizedBox(height: AppSpacing.md),
                            _buildDobField(),
                            const SizedBox(height: AppSpacing.md),
                            _buildPasswordField(),
                            if (_passwordCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _buildPasswordStrengthBar(theme),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            _buildConfirmPasswordField(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _buildErrorBanner(),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                            _buildRegisterButton(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildLoginRow(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/login'),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              'TriChat',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tạo tài khoản',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Điền thông tin để bắt đầu kết nối',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.hintColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            controller: _firstNameCtrl,
            focusNode: _firstNameFocus,
            nextFocus: _lastNameFocus,
            label: 'Họ',
            hint: 'Nguyễn',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập họ';
              return null;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildField(
            controller: _lastNameCtrl,
            focusNode: _lastNameFocus,
            nextFocus: _emailFocus,
            label: 'Tên',
            hint: 'Văn A',
            icon: null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập tên';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildField(
      controller: _emailCtrl,
      focusNode: _emailFocus,
      nextFocus: _passwordFocus,
      label: 'Email',
      hint: 'example@email.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
        final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
        if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildDobField() {
    final dobText = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}'
        : null;

    return GestureDetector(
      onTap: _pickDob,
      child: AbsorbPointer(
        child: TriTextField(
          hintText: 'Ngày sinh',
          controller: dobText != null
              ? TextEditingController(text: dobText)
              : null,
          prefixIcon: const Icon(Icons.cake_outlined, size: 18),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TriTextField(
      controller: _passwordCtrl,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      onSubmitted: () => _confirmFocus.requestFocus(),
      hintText: 'Mật khẩu',
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
        ),
        onPressed: () =>
            setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
        if (!RegExp(r'[a-z]').hasMatch(v)) {
          return 'Mật khẩu phải có ít nhất 1 chữ thường';
        }
        if (!RegExp(r'[A-Z]').hasMatch(v)) {
          return 'Mật khẩu phải có ít nhất 1 chữ hoa';
        }
        if (!RegExp(r'[0-9]').hasMatch(v)) {
          return 'Mật khẩu phải có ít nhất 1 chữ số (0-9)';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordStrengthBar(ThemeData theme) {
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

  Widget _buildConfirmPasswordField() {
    return TriTextField(
      controller: _confirmPasswordCtrl,
      focusNode: _confirmFocus,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onSubmitted: () => _handleRegister(),
      hintText: 'Xác nhận mật khẩu',
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirm
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
        if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
        return null;
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return PrimaryButton(
      label: 'Đăng ký',
      loading: _isLoading,
      onPressed: _isLoading ? null : _handleRegister,
    );
  }

  Widget _buildLoginRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.hintColor,
          ),
        ),
        TextLinkButton(
          label: 'Đăng nhập',
          fontWeight: FontWeight.w700,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TriTextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: nextFocus != null ? () => nextFocus.requestFocus() : null,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      validator: validator,
    );
  }
}
