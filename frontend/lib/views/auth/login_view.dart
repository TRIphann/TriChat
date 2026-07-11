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

/// Màn hình đăng nhập — phong cách Glassmorphism:
/// - Nền kem với gradient nhẹ
/// - Card kính trắng chứa form
/// - Hiệu ứng glow xung quanh
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
                  _buildBackButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.huge),
                  _buildGlassForm(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSignupHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: () => context.go('/'),
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

  Widget _buildHeader() {
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
            Icons.login_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Chào mừng trở lại',
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.neutralBlack,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Đăng nhập để tiếp tục trò chuyện cùng bạn bè.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutralGray700,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassForm() {
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
          if (_debugError != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
          TriTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hintText: 'Số điện thoại / Email',
            prefixIcon: const Icon(
              Icons.alternate_email_rounded,
              size: 20,
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
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                key: ValueKey(_isPasswordVisible),
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
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 0.8,
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

  Widget _buildSignupHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutralGray700,
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