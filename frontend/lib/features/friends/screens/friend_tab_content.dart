import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/friend_birthday.dart';
import 'package:frontend/features/friends/screens/friend_request_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class FriendTabView extends StatefulWidget {
  const FriendTabView({super.key});

  @override
  State<FriendTabView> createState() => _FriendTabViewState();
}

class _FriendTabViewState extends State<FriendTabView> {
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<FriendProvider>();
      await provider.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildActionTile(
          context,
          Icons.people_alt,
          AppColors.darkPremiumTextPrimary,
          'Lời mời kết bạn',
          trailing: '${provider.pendingReceived.length + provider.pendingSent.length}',
        ),
        _buildActionTile(
          context,
          Icons.cake,
          AppColors.darkPremiumTextPrimary,
          'Sinh nhật',
        ),
        Divider(thickness: 8, color: AppColors.darkPremiumBorder),

        // Khu vực Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('Tất cả ${provider.friends.length}', 0),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Divider(thickness: 1, color: AppColors.divider, height: 1),
        if (_selectedFilterIndex == 0) ...[
          if (provider.friendsState == LoadingState.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Chưa có bạn bè')),
            )
          else ...[
            ...provider.friends.map((friend) => _buildContactItem(friend)),
          ],
        ],
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    Color color,
    String title, {
    String? trailing,
  }) {
    return Material(
      color: AppColors.darkPremiumSurface,
      child: InkWell(
        onTap: () {
          if (title == 'Lời mời kết bạn') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendRequestScreen()),
            );
          }
          if (title == 'Sinh nhật') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendBirthdayScreen()),
            );
          }
        },
        highlightColor: Colors.black.withValues(alpha: 0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonRoyal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.neonRoyal, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkPremiumTextPrimary,
            ),
          ),
          trailing: trailing != null
              ? Text(
                  '($trailing)',
                  style: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 14),
                )
              : Icon(Icons.chevron_right, color: AppColors.darkPremiumTextSecondary),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonRoyal : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkPremiumTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(FriendSummaryModel friend) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');

    return Material(
      color: AppColors.darkPremiumSurface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(targetUserId: friend.friendId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.neonRoyal.withValues(alpha: 0.3),
                backgroundImage: friend.avatar.isNotEmpty ? NetworkImage(friend.avatar) : null,
                child: friend.avatar.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(color: AppColors.neonRoyal),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkPremiumTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (friend.friendId.isEmpty || currentUid.isEmpty) return;
                  final conversation = await ChatService().createConversation(
                    type: 'private',
                    participantIds: [currentUid, friend.friendId],
                  );
                  if (!context.mounted) return;
                  await context.read<ChatProvider>().openConversation(conversation);
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.neonRoyal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.white,
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
