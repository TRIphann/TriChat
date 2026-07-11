import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/widgets/demo_bio.dart';
import 'package:frontend/features/friends/widgets/my_profile.dart';
import 'package:go_router/go_router.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isInputNotEmpty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(
        () => _isInputNotEmpty = _phoneController.text.trim().isNotEmpty,
      );
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _findUser() async {
    if (_isLoading) return;

    final email = _phoneController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<FriendProvider>();
      final user = await provider.findUserByEmail(email);

      if (!mounted) return;

      if (user == null) {
        showTriSnack(
          context,
          'Người dùng chưa đăng kí tài khoản hoặc không cho phép tìm kiếm',
        );
        return;
      }

      context.push('/demo-profile', extra: user);
    } catch (e) {
      if (!mounted) return;
      showTriSnack(context, 'Lỗi: $e', type: TriSnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.creamBackground,
          appBar: AppBar(
            backgroundColor: AppColors.creamWhite,
            elevation: 0.5,
            shadowColor: AppColors.accentBrown.withValues(alpha: 0.08),
            leading: const BackButton(color: AppColors.primaryOrange),
            titleSpacing: AppSpacing.sm,
            title: Text(
              'Thêm bạn',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.neutralBlack,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: false,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(child: _buildQRCard(isDark)),
              const SizedBox(height: AppSpacing.lg),
              _buildPhoneInput(),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Divider(
                  height: 0.5,
                  color: AppColors.neutralGray300,
                ),
              ),
              _buildOptionItem(
                Icons.qr_code_scanner_rounded,
                'Quét mã QR',
                isDark,
              ),
              _buildOptionItem(
                Icons.contacts_outlined,
                'Danh bạ máy',
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRCard(bool isDark) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.creamWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.neutralGray300.withValues(alpha: 0.7),
          width: 0.6,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Mã QR của tôi',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Chạm để hiển thị',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Container(
          color: AppColors.creamWhite,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập email để tìm bạn',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _findUser(),
                ),
              ),
              TextLinkButton(
                label: _isLoading ? '...' : 'Tìm',
                onPressed:
                    (_isInputNotEmpty && !_isLoading) ? _findUser : null,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(IconData icon, String title, bool isDark) {
    return Material(
      color: AppColors.creamWhite,
      child: InkWell(
        onTap: () {
          if (title == 'Quét mã QR') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyProfileScreen(),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(
                  user: UserSearchModel(
                    id: '',
                    fullName: 'Demo',
                    email: '',
                    avatar: '',
                    status: false,
                  ),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrangePale.withValues(
                    alpha: isDark ? 0.2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.getTextSecondary(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}