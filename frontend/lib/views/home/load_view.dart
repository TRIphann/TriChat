import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/app_spacing.dart';
import '../../config/app_typography.dart';
import '../../config/tri_chat_logo.dart';

/// Màn hình splash — phong cách Minimalist:
/// - Nền trắng / đen
/// - Logo TriChat lớn, không glow, không gradient
/// - Tự động điều hướng sau khi load xong
class LoadView extends StatefulWidget {
  const LoadView({super.key});

  @override
  State<LoadView> createState() => _LoadViewState();
}

class _LoadViewState extends State<LoadView> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _taglineFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? AppColors.darkBackground : AppColors.creamBackground,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _logoCtrl.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _navigated) return;
    _navigated = true;
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    user != null ? context.go('/chat-list') : context.go('/');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _logoCtrl,
          builder: (context, _) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: const TriChatLogoLarge(size: 120),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Opacity(
                    opacity: _titleFade.value,
                    child: Text(
                      'TriChat',
                      style: AppTypography.displayLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 44,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Opacity(
                    opacity: _taglineFade.value,
                    child: Text(
                      'Trò chuyện. Kết nối. Trên mọi thiết bị.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  Opacity(
                    opacity: _taglineFade.value,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
