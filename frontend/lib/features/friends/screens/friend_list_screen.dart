import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:provider/provider.dart';

enum FriendDirectoryTab { friends, groups, requests }

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen>
    with SingleTickerProviderStateMixin {
  FriendDirectoryTab _tab = FriendDirectoryTab.friends;
  bool _isGrid = true;

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
                  _buildCategoryTabs(),
                  Expanded(
                    child: _buildBody(provider, friends, isDark),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.darkPremiumBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          _CategoryTab(
            label: 'Danh sách bạn bè',
            selected: _tab == FriendDirectoryTab.friends,
            onTap: () => setState(() => _tab = FriendDirectoryTab.friends),
          ),
          _CategoryTab(
            label: 'Danh sách nhóm',
            selected: _tab == FriendDirectoryTab.groups,
            onTap: () => setState(() => _tab = FriendDirectoryTab.groups),
          ),
          _CategoryTab(
            label: 'Lời mời kết bạn',
            selected: _tab == FriendDirectoryTab.requests,
            onTap: () => setState(() => _tab = FriendDirectoryTab.requests),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _isGrid = !_isGrid),
            icon: Icon(
              _isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
              color: AppColors.darkPremiumTextSecondary,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      FriendProvider provider, List<FriendSummaryModel> friends, bool isDark) {
    switch (_tab) {
      case FriendDirectoryTab.friends:
        if (friends.isEmpty) {
          return _buildPremiumEmpty(
            icon: Icons.people_outline_rounded,
            title: 'Chưa có bạn bè nào',
            subtitle:
                'Hãy thêm bạn bè để bắt đầu trò chuyện và chia sẻ khoảnh khắc.',
          );
        }
        return _buildFriendGridOrList(friends);
      case FriendDirectoryTab.groups:
        return _buildPremiumEmpty(
          icon: Icons.groups_outlined,
          title: 'Chưa có nhóm nào',
          subtitle:
              'Tạo nhóm để trò chuyện cùng nhiều bạn bè cùng lúc.',
        );
      case FriendDirectoryTab.requests:
        final requests = provider.pendingReceived;
        if (requests.isEmpty) {
          return _buildPremiumEmpty(
            icon: Icons.person_add_alt_outlined,
            title: 'Không có lời mời kết bạn',
            subtitle: 'Lời mời mới sẽ xuất hiện ở đây.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: requests.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 0.5,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: AppColors.darkPremiumBorder,
          ),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _RequestRow(request: request);
          },
        );
    }
  }

  Widget _buildFriendGridOrList(List<FriendSummaryModel> friends) {
    if (_isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return _FriendGridCard(friend: friend);
        },
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: friends.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 72,
        endIndent: AppSpacing.lg,
        color: AppColors.darkPremiumBorder,
      ),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _FriendListRow(friend: friend);
      },
    );
  }

  Widget _buildPremiumEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonRoyal.withValues(alpha: 0.18),
                    AppColors.neonPink.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.neonRoyal.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonRoyal.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Icon(icon, size: 44, color: AppColors.neonRoyal),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkPremiumTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkPremiumTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
                  blurRadius: 12,
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

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? AppColors.neonRoyal
                    : AppColors.darkPremiumBorder,
                width: selected ? 2.5 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? AppColors.neonRoyal
                  : AppColors.darkPremiumTextSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _FriendGridCard extends StatelessWidget {
  final FriendSummaryModel friend;
  const _FriendGridCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');
    final online = friend.friendId.codeUnitAt(0).isOdd;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPremiumBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonRoyal.withValues(alpha: 0.35),
                              AppColors.neonPink.withValues(alpha: 0.20),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.neonRoyal.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _avatarText(displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      if (online)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.neonOnline,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.darkPremiumSurface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPremiumTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Bạn bè từ ...',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.darkPremiumTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: _NeonOutlineButton(
                    label: 'Nhắn tin',
                    color: AppColors.neonRoyal,
                    onTap: () => _openChat(context, friend.friendId),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _NeonOutlineButton(
                    label: 'Gọi điện',
                    color: AppColors.darkPremiumTextSecondary,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _avatarText(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _FriendListRow extends StatelessWidget {
  final FriendSummaryModel friend;
  const _FriendListRow({required this.friend});

  @override
  Widget build(BuildContext context) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');

    return Container(
      color: AppColors.darkPremiumSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonRoyal.withValues(alpha: 0.35),
                      AppColors.neonPink.withValues(alpha: 0.20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.neonRoyal.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _avatarText(displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (friend.friendId.codeUnitAt(0).isOdd)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.neonOnline,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.darkPremiumSurface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkPremiumTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Bạn bè từ ...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkPremiumTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _NeonOutlineButton(
            label: 'Nhắn tin',
            color: AppColors.neonRoyal,
            onTap: () => _openChat(context, friend.friendId),
          ),
          const SizedBox(width: 6),
          _NeonOutlineButton(
            label: 'Gọi điện',
            color: AppColors.darkPremiumTextSecondary,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  String _avatarText(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _NeonOutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NeonOutlineButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final FriendshipModel request;
  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final senderName = request.senderName ?? 'Người dùng';

    return Container(
      color: AppColors.darkPremiumSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.neonRoyal.withValues(alpha: 0.35),
                  AppColors.neonPink.withValues(alpha: 0.20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.neonRoyal.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkPremiumTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Muốn kết bạn với bạn',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkPremiumTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _NeonOutlineButton(
                label: 'Từ chối',
                color: AppColors.neonRed,
                onTap: () {},
              ),
              const SizedBox(width: 6),
              _NeonOutlineButton(
                label: 'Đồng ý',
                color: AppColors.neonOnline,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openChat(BuildContext context, String friendId) async {
  if (friendId.isEmpty) return;
  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (currentUid.isEmpty) return;
  final conversation = await ChatService().createConversation(
    type: 'private',
    participantIds: [friendId],
  );
  if (!context.mounted) return;
  await context.read<ChatProvider>().openConversation(conversation);
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
  );
}
