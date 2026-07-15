import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Màn hình đăng nhập — phong cách Minimalist:
/// - Nền trắng, không gradient, không glass
/// - Form tối giản, border hairline
/// - CTA đen đặc
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _debugError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_debugError != null) {
      setState(() => _debugError = null);
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _debugError = null;
    });

    try {
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        try {
          final friendProvider = context.read<FriendProvider>();
          final firebaseUid = FirebaseAuth.instance.currentUser!.uid;
          await friendProvider.setCurrentUid(firebaseUid);
          await friendProvider.loadAll();
          friendProvider.startRealtime();
          if (!mounted) return;
          context.go('/chat-list');
        } catch (e) {
          if (!mounted) return;
          showTriSnack(
            context,
            'Lỗi khởi tạo dữ liệu: $e',
            type: TriSnackType.error,
          );
          setState(() => _isLoading = false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _debugError =
              result.errorMessage ?? result.errorCode ?? 'Unknown error';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _debugError = 'Exception: $e';
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackButton(theme),
                const SizedBox(height: AppSpacing.md),
                _buildHeader(theme),
                const SizedBox(height: AppSpacing.huge),
                _buildForm(theme),
                const SizedBox(height: AppSpacing.xl),
                _buildSignupHint(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: theme.brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.neutralGray100,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => context.go('/'),
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

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào mừng trở lại',
          style: AppTypography.headlineLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Đăng nhập để tiếp tục trò chuyện cùng bạn bè.',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_debugError != null) ...[
          _buildErrorBanner(theme),
          const SizedBox(height: AppSpacing.lg),
        ],
        TriTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          hintText: 'Số điện thoại / Email',
          prefixIcon: const Icon(
            Icons.alternate_email_rounded,
            size: 18,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập email';
            }
            final email = value.trim();
            final emailRegex = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            );
            if (!emailRegex.hasMatch(email)) {
              return 'Email không đúng định dạng';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TriTextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleLogin,
          hintText: 'Mật khẩu',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
          suffixIcon: IconButton(
            splashRadius: 18,
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: () => setState(
              () => _isPasswordVisible = !_isPasswordVisible,
            ),
          ),
          validator: (value) => Validator.password(value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextLinkButton(
            label: 'Quên mật khẩu?',
            onPressed: () {
              showTriSnack(
                context,
                'Liên hệ hỗ trợ để khôi phục mật khẩu',
                type: TriSnackType.info,
                icon: Icons.info_outline_rounded,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Đăng nhập',
          loading: _isLoading,
          icon: Icons.login_rounded,
          onPressed: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
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
              _debugError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupHint(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.hintColor,
          ),
        ),
        TextLinkButton(
          label: 'Đăng ký ngay',
          fontWeight: FontWeight.w700,
          onPressed: () => context.go('/sign-up'),
        ),
      ],
    );
  }
}
