import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// ════════════════════════════════════════════════════════════════
/// PREMIUM LOGIN VIEW — High-End Authentication Screen
/// ════════════════════════════════════════════════════════════════

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _debugError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
          showTriSnack(context, 'Lỗi khởi tạo dữ liệu: $e', type: TriSnackType.error);
          setState(() => _isLoading = false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _debugError = result.errorMessage ?? result.errorCode ?? 'Unknown error';
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
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.06),
                      _buildBackButton(theme, isDark),
                      SizedBox(height: size.height * 0.06),
                      _buildHeader(theme, isDark),
                      SizedBox(height: size.height * 0.06),
                      _buildCard(theme, isDark),
                      SizedBox(height: size.height * 0.04),
                      _buildSignupHint(theme, isDark),
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

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/'),
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
        ),
        child: Icon(Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, size: 22),
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
          child: Text('CHÀO MỪNG TRỞ LẠI',
              style: AppTypography.eyebrow.copyWith(color: AppColors.primaryAmber)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Đăng nhập\nđể tiếp tục',
            style: AppTypography.displaySmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.1,
            )),
        const SizedBox(height: AppSpacing.sm),
        Text('Kết nối với bạn bè và gia đình một cách dễ dàng.',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            )),
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
            if (_debugError != null) ...[
              _buildErrorBanner(theme, isDark),
              const SizedBox(height: AppSpacing.lg),
            ],
            _buildEmailField(theme, isDark),
            const SizedBox(height: AppSpacing.md),
            _buildPasswordField(theme, isDark),
            const SizedBox(height: AppSpacing.sm),
            _buildForgotPassword(theme, isDark),
            const SizedBox(height: AppSpacing.xl),
            _buildLoginButton(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            )),
        const SizedBox(height: AppSpacing.sm),
        TriTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          hintText: 'Nhập email của bạn',
          prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.primaryAmber),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Vui lòng nhập email';
            final email = value.trim();
            final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
            if (!emailRegex.hasMatch(email)) return 'Email không đúng định dạng';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mật khẩu',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            )),
        const SizedBox(height: AppSpacing.sm),
        TriTextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleLogin,
          hintText: 'Nhập mật khẩu',
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primaryAmber),
          suffixIcon: IconButton(
            splashRadius: 20,
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          validator: (value) => Validator.password(value),
        ),
      ],
    );
  }

  Widget _buildForgotPassword(ThemeData theme, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          showTriSnack(context, 'Liên hệ hỗ trợ để khôi phục mật khẩu',
              type: TriSnackType.info, icon: Icons.info_outline_rounded);
        },
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryAmber),
        child: Text('Quên mật khẩu?',
            style: AppTypography.labelMedium.copyWith(color: AppColors.primaryAmber, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _isLoading ? null : LinearGradient(colors: AppColors.primaryGradient),
          color: _isLoading ? (isDark ? AppColors.darkBorder : AppColors.borderDefault) : null,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: _isLoading ? null : [
            BoxShadow(
              color: AppColors.primaryAmber.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.primaryAmber,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đăng nhập',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.textWhite, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.errorLight, AppColors.errorLight.withValues(alpha: 0.5)]),
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
            child: Text(_debugError!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupHint(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Chưa có tài khoản? ',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            )),
        GestureDetector(
          onTap: () => context.go('/sign-up'),
          child: Text('Đăng ký ngay',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primaryAmber, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
