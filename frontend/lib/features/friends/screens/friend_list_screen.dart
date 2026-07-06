import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/widgets/friend_avatar.dart';
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

            if (friends.isEmpty) {
              return _EmptyState(isDark: isDark);
            }

            return Column(
              children: [
                _FriendHeader(count: friends.length, isDark: isDark),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 70,
                      endIndent: 16,
                      color: AppColors.getDivider(isDark),
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
                              builder: (_) =>
                                  ProfileScreen(targetUserId: friend.friendId),
                            ),
                          );
                        },
                        onMessageTap: () async {
                          if (friend.friendId.isEmpty) return;
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid ?? '';
                          if (currentUid.isEmpty) return;
                          final conversation = await ChatService()
                              .createConversation(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          bottom: BorderSide(color: AppColors.getDivider(isDark), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryOrange, AppColors.accentRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Bạn bè',
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.15),
                  AppColors.accentRed.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Chưa có bạn bè nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy kết bạn để bắt đầu trò chuyện',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onRowTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FriendAvatar(
                    name: displayName,
                    avatarUrl: friend.avatar.isNotEmpty ? friend.avatar : null,
                    radius: 24,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Bạn bè từ ${_FriendRowItem._formatFriendsSince(friend.friendsSince)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMessageTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange,
                          AppColors.primaryOrangeLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Colors.white,
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

  static String _formatFriendsSince(DateTime since) {
    final now = DateTime.now();
    final diff = now.difference(since);
    if (diff.inDays < 1) return 'hôm nay';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}
