import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/app_spacing.dart';
import '../../config/app_typography.dart';
import '../../config/tri_chat_logo.dart';

/// Màn hình splash — phong cách Glassmorphism:
/// - Nền kem (cream) với gradient nhẹ
/// - Logo TriChat lớn
/// - Hiệu ứng glow xung quanh
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
  late final AnimationController _pulseCtrl;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.creamBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.8, curve: Curves.elasticOut),
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

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _logoCtrl.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted || _navigated) return;
    _navigated = true;
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    user != null ? context.go('/chat-list') : context.go('/');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.creamBackgroundGradient,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Decorative glow — cam san hô
                  Positioned(
                    top: -120,
                    right: -100,
                    child: _PulseGlow(
                      animation: _pulseCtrl,
                      size: 360,
                      color: AppColors.primaryOrangeLight,
                    ),
                  ),
                  Positioned(
                    bottom: -140,
                    left: -110,
                    child: _PulseGlow(
                      animation: _pulseCtrl,
                      size: 400,
                      color: AppColors.accentBrownLight,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: const TriChatLogoLarge(size: 130),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Opacity(
                          opacity: _titleFade.value,
                          child: ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [
                                AppColors.accentBrown,
                                AppColors.primaryOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(rect),
                            child: const Text(
                              'TriChat',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Opacity(
                          opacity: _taglineFade.value,
                          child: Text(
                            'Trò chuyện. Kết nối. Trên mọi thiết bị.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutralGray700,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.huge),
                        Opacity(
                          opacity: _taglineFade.value,
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primaryOrange.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulseGlow extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;

  const _PulseGlow({
    required this.animation,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.18 * (0.6 + animation.value * 0.4)),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}