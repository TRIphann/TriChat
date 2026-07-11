import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/screens/add_friend_screen.dart';
import 'package:frontend/features/friends/screens/friend_list_screen.dart';
import 'package:frontend/features/friends/screens/friend_requests_screen.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';

/// Màn hình Danh bạ - Contacts View
/// Giao diện nhỏ (mobile): hiển thị tabs Bạn bè / Nhóm
/// Giao diện lớn (wide): hiển thị sidebar menu + content panel
class ContactsView extends StatefulWidget {
  final bool isWideScreen;

  const ContactsView({super.key, this.isWideScreen = false});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, locale, child) {
            final t = AppLocalizations(locale);
            if (widget.isWideScreen) {
              return _buildWideLayout(t, isDark);
            }
            return _buildMobileLayout(t, isDark);
          },
        );
      },
    );
  }

  // ============================================
  // MOBILE LAYOUT
  // ============================================
  Widget _buildMobileLayout(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        _buildMobileHeader(t, isDark),
        _buildMobileTabs(t, isDark),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendListMobile(t, isDark),
              _buildGroupListMobile(t, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.appBarGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TriSearchField(
                hintText: t.get('searchPlaceholder'),
                readOnly: true,
                onTap: () => _openSearchOverlay(context),
                background: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildHeaderIcon(
              icon: Icons.group_add_rounded,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tạo nhóm - đang phát triển')),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildHeaderIcon(
              icon: Icons.person_add_alt_1_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddFriendScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildMobileTabs(AppLocalizations t, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          bottom: BorderSide(
            color: AppColors.getDivider(isDark),
            width: 0.6,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: AppColors.getTextSecondary(isDark),
        indicatorColor: AppColors.primaryOrange,
        indicatorWeight: 2.5,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        tabs: [
          Tab(text: t.get('friends')),
          Tab(text: t.get('groups')),
        ],
      ),
    );
  }

  Widget _buildFriendListMobile(AppLocalizations t, bool isDark) {
    // Sử dụng FriendListScreen thật thay vì mock data
    return const FriendListScreen();
  }

  Widget _buildGroupListMobile(AppLocalizations t, bool isDark) {
    return Container(
      color: AppColors.creamBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: 0.15),
                      AppColors.accentBrown.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_outlined,
                  size: 42,
                  color: AppColors.primaryOrange.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chưa có nhóm nào',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tạo nhóm để trò chuyện cùng nhiều bạn bè cùng lúc.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
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

  // ============================================
  // WIDE LAYOUT (Desktop)
  // ============================================
  Widget _buildWideLayout(AppLocalizations t, bool isDark) {
    return Row(
      children: [
        // Left sidebar menu
        _buildWideSidebar(t, isDark),
        // Right content panel
        Expanded(child: _buildWideContent(t, isDark)),
      ],
    );
  }

  Widget _buildWideSidebar(AppLocalizations t, bool isDark) {
    final menuItems = [
      {'icon': Icons.people_outline, 'label': t.get('friendList')},
      {'icon': Icons.groups_outlined, 'label': t.get('groupAndCommunity')},
      {'icon': Icons.person_add_alt_outlined, 'label': t.get('friendRequest')},
      {'icon': Icons.group_add_outlined, 'label': t.get('groupInvitation')},
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.creamWhite,
        border: Border(
          right: BorderSide(color: AppColors.getDivider(isDark), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: TriSearchField(
              hintText: t.get('searchPlaceholder'),
              readOnly: true,
              onTap: () => _openSearchOverlay(context),
              filledBackground: AppColors.getBackground(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedMenuIndex == index;
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrangePale.withValues(alpha: isDark ? 0.18 : 1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedMenuIndex = index),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected
                              ? AppColors.primaryOrange
                              : AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : AppColors.getTextPrimary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWideContent(AppLocalizations t, bool isDark) {
    return Container(
      color: AppColors.creamBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.creamWhite,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.getDivider(isDark),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrangePale.withValues(
                      alpha: isDark ? 0.2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _getContentIcon(),
                    size: 18,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _getContentTitle(t),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContentByMenu(t, isDark)),
        ],
      ),
    );
  }

  IconData _getContentIcon() {
    switch (_selectedMenuIndex) {
      case 0:
        return Icons.people_outline;
      case 1:
        return Icons.groups_outlined;
      case 2:
        return Icons.person_add_alt_outlined;
      case 3:
        return Icons.group_add_outlined;
      default:
        return Icons.people_outline;
    }
  }

  String _getContentTitle(AppLocalizations t) {
    switch (_selectedMenuIndex) {
      case 0:
        return t.get('friendList');
      case 1:
        return t.get('groupAndCommunity');
      case 2:
        return t.get('friendRequest');
      case 3:
        return t.get('groupInvitation');
      default:
        return t.get('friendList');
    }
  }

  Widget _buildContentByMenu(AppLocalizations t, bool isDark) {
    switch (_selectedMenuIndex) {
      case 0:
        // Danh sách bạn bè thật từ API
        return const FriendListScreen();
      case 1:
        return _buildWideGroupList(t, isDark);
      case 2:
        // Lời mời kết bạn thật từ API
        return const FriendRequestsScreen();
      case 3:
        return _buildWideGroupInvitations(t, isDark);
      default:
        return const FriendListScreen();
    }
  }

  Widget _buildWideGroupList(AppLocalizations t, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.15),
                    AppColors.accentBrown.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 46,
                color: AppColors.primaryOrange.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có nhóm nào',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tạo nhóm để trò chuyện cùng nhiều bạn bè cùng lúc — nhóm giúp mọi người trao đổi dễ dàng hơn.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutralGray700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideGroupInvitations(AppLocalizations t, bool isDark) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: t.get('noGroupInvitation'),
      subtitle: 'Lời mời vào nhóm sẽ xuất hiện tại đây',
    );
  }

  // ============================================
  // SEARCH OVERLAY
  // ============================================
  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, childAnimation) => SearchOverlayScreen(
          onBack: () => Navigator.of(context).pop(),
          onSearchResultTap: ({required userId, required name, avatar}) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã chọn: $name'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          recentContacts: const [],
        ),
        transitionsBuilder: (_, animation, childAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
