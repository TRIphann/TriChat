import 'package:flutter/material.dart';
import 'package:frontend/component/friend_search_page.dart';
import 'package:frontend/component/inputs.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/features/friends/screens/add_friend_screen.dart';
import 'package:frontend/features/friends/screens/friend_tab_content.dart';
import 'package:frontend/features/friends/screens/group_tab_content.dart';

class ContactsMainScreen extends StatefulWidget {
  const ContactsMainScreen({super.key});

  @override
  State<ContactsMainScreen> createState() => _ContactsMainScreenState();
}

class _ContactsMainScreenState extends State<ContactsMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: AppColors.darkPremiumBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppColors.darkPremiumSurface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TriSearchField(
                      hintText: 'Tìm kiếm',
                      readOnly: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FriendSearchPage()),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.person_add_alt_1_outlined,
                      color: AppColors.darkPremiumTextPrimary,
                      size: 22,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.darkPremiumSurface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.neonRoyal,
              unselectedLabelColor: AppColors.darkPremiumTextSecondary,
              indicatorColor: AppColors.neonRoyal,
              indicatorWeight: 2,
              labelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTypography.labelLarge,
              tabs: const [
                Tab(text: 'Bạn bè'),
                Tab(text: 'Nhóm'),
              ],
            ),
          ),
          Divider(color: AppColors.darkPremiumBorder, height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const FriendTabView(),
                const GroupTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
