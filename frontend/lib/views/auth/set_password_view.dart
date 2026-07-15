import 'package:flutter/material.dart';
import 'package:frontend/component/buttons.dart';
import 'package:frontend/component/inputs.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordView extends StatefulWidget {
  final String? email;
  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();

  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isFormValid = false;
  String? _errorMessage;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onInputChanged);
    _confirmPasswordCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _evaluatePasswordStrength();
    _validateFormStatus();
  }

  void _validateFormStatus() {
    final password = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    bool isValid = password.length >= 8 &&
        confirm.isNotEmpty &&
        password == confirm;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _evaluatePasswordStrength() {
    final p = _passwordCtrl.text;
    if (p.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
      });
      return;
    }

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

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      LoadingDialog.show(context, message: "Đang tải...");
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      LoadingDialog.hide(context);
      context.pushReplacement('/enter-name', extra: {
        'email': widget.email,
        'password': _passwordCtrl.text.trim()
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackRow(theme),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Cài đặt mật khẩu',
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Mật khẩu mới phải từ 8 ký tự và bao gồm tối thiểu 1 chữ hoa, 1 chữ số, có thể chứa ký tự đặc biệt.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.hintColor,
                    height: 1.5,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                TriTextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  hintText: 'Nhập mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => Validator.password(v),
                  onSubmitted: () => _confirmFocus.requestFocus(),
                ),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildPasswordStrengthBar(theme),
                ],
                const SizedBox(height: AppSpacing.lg),
                TriTextField(
                  controller: _confirmPasswordCtrl,
                  focusNode: _confirmFocus,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  hintText: 'Nhập lại mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) =>
                      Validator.confirmPassword(v, _passwordCtrl.text),
                  onSubmitted: _isFormValid ? () => _handleSubmit() : null,
                ),
                const SizedBox(height: AppSpacing.huge),
                PrimaryButton(
                  label: 'Tiếp tục',
                  onPressed: _isFormValid ? _handleSubmit : null,
                ),
              ],
            ),
          ),
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
}
