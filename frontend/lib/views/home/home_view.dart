import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/tri_chat_logo.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Trang chào mừng — phong cách Glassmorphism:
/// - Nền kem với hiệu ứng kính mờ
/// - Card kính trắng cho nội dung chính
/// - Logo TriChat lớn ở giữa
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  String _selectedLanguage =
      AppLocalizations(localeNotifier.value).displayName;

  late final AnimationController _contentCtrl;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.55, 1, curve: Curves.easeOut),
      ),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
      ),
    );

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onLanguageChanged(String lang) {
    setState(() {
      _selectedLanguage = lang;
      localeNotifier.value = AppLocalizations.localeFromDisplayName(lang);
    });
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.creamWhite,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chọn ngôn ngữ',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...AppLocalizations.supportedLanguages.map((lang) {
                  final isSelected = lang == _selectedLanguage;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _onLanguageChanged(lang);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lang,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.neutralBlack,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryOrange,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final t = AppLocalizations(locale);
        return AnimatedBuilder(
          animation: _contentCtrl,
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
                  child: Column(
                    children: [
                      _buildLanguageSelector(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpacing.huge),
                              _buildHero(t),
                              const SizedBox(height: AppSpacing.huge),
                              _buildGlassCard(t),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildButtons(t),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return FadeTransition(
      opacity: _logoFade,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          right: AppSpacing.lg,
          left: AppSpacing.lg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _showLanguageSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.neutralGray300.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBrown.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: AppColors.accentBrown,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedLanguage,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutralBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.accentBrown,
                      size: 18,
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

  Widget _buildHero(AppLocalizations t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _logoFade,
          child: SlideTransition(
            position: _logoSlide,
            child: const TriChatLogoLarge(size: 120),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeTransition(
          opacity: _titleFade,
          child: SlideTransition(
            position: _titleSlide,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [
                      AppColors.accentBrown,
                      AppColors.primaryOrange,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(rect),
                  child: Text(
                    'TriChat',
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 56,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.get('appName'),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.neutralGray700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(AppLocalizations t) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureChip(
                    Icons.chat_bubble_rounded,
                    'Chat',
                    AppColors.primaryOrange,
                  ),
                  _buildFeatureChip(
                    Icons.people_alt_rounded,
                    'Bạn bè',
                    AppColors.accentBrown,
                  ),
                  _buildFeatureChip(
                    Icons.auto_stories_rounded,
                    'Bản tin',
                    AppColors.primaryOrangeLight,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Trò chuyện. Kết nối. Mọi lúc mọi nơi.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutralGray700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.neutralBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(AppLocalizations t) {
    return FadeTransition(
      opacity: _buttonsFade,
      child: SlideTransition(
        position: _buttonsSlide,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryButtonGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/login'),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              t.get('login'),
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.neutralGray300.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/sign-up'),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppColors.accentBrown,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              t.get('createAccount'),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accentBrown,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}