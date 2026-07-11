import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/screens/add_friend_screen.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:provider/provider.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Consumer<FriendProvider>(
          builder: (context, provider, _) {
            final friends = provider.friends;

            return Container(
              color: AppColors.darkPremiumBackground,
              child: Column(
                children: [
                  _FriendHeader(count: friends.length, isDark: isDark),
                  Expanded(
                    child: friends.isEmpty
                        ? _FriendEmptyState()
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: friends.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 70,
                              endIndent: AppSpacing.lg,
                              color: AppColors.darkPremiumBorder,
                            ),
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              return _FriendRowItem(
                                friend: friend,
                                isDark: isDark,
                                onRowTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                        targetUserId: friend.friendId,
                                      ),
                                    ),
                                  );
                                },
                                onMessageTap: () async {
                                  if (friend.friendId.isEmpty) return;
                                  final currentUid =
                                      FirebaseAuth.instance.currentUser?.uid ?? '';
                                  if (currentUid.isEmpty) return;
                                  final conversation =
                                      await ChatService().createConversation(
                                    type: 'private',
                                    participantIds: [friend.friendId],
                                  );
                                  if (!context.mounted) return;
                                  await context
                                      .read<ChatProvider>()
                                      .openConversation(conversation);
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(conversation: conversation),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FriendHeader extends StatelessWidget {
  final int count;
  final bool isDark;

  const _FriendHeader({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.darkBubbleMineGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonRoyal.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$count',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            'Bạn bè',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.darkPremiumTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRowItem extends StatelessWidget {
  final FriendSummaryModel friend;
  final bool isDark;
  final VoidCallback onRowTap;
  final VoidCallback onMessageTap;

  const _FriendRowItem({
    required this.friend,
    required this.isDark,
    required this.onRowTap,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');

    return Material(
      color: AppColors.darkPremiumSurface,
      child: InkWell(
        onTap: onRowTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              TriAvatar(
                imageUrl: friend.avatar,
                name: displayName,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.darkPremiumTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bạn bè từ ${_formatFriendsSince(friend.friendsSince)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.darkPremiumTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconCircleButton(
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: onMessageTap,
                gradient: const LinearGradient(
                  colors: AppColors.darkBubbleMineGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                size: 38,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatFriendsSince(DateTime since) {
    final now = DateTime.now();
    final diff = now.difference(since);
    if (diff.inDays < 1) return 'hôm nay';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}

class _FriendEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkPremiumBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonRoyal.withValues(alpha: 0.18),
                      AppColors.neonPink.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonRoyal.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonRoyal.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 50,
                  color: AppColors.neonRoyal,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chưa có bạn bè nào',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPremiumTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hãy kết bạn để bắt đầu trò chuyện',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.darkPremiumTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.darkBubbleMineGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonRoyal.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddFriendScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tìm bạn bè ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
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