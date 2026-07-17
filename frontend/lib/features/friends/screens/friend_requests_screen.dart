import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:provider/provider.dart';

import '../providers/friend_provider.dart';
import '../services/friend_service.dart';
import '../widgets/friend_action_button.dart';
import '../widgets/friend_avatar.dart';

/// Màn hình Lời mời kết bạn — hiển thị 2 tab:
/// • Đã nhận: chấp nhận / từ chối
/// • Đã gửi: huỷ lời mời
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ChangeNotifierProvider(
          create: (_) {
            final provider = FriendProvider();
            provider.loadRequests();
            provider.startRealtime();
            provider.onRealtimeNotify = (msg, {isSuccess = false}) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: isSuccess
                      ? AppColors.success
                      : AppColors.primaryOrange,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              );
            };
            return provider;
          },
          child: Consumer<FriendProvider>(
            builder: (ctx, provider, _) =>
                _buildScaffold(ctx, isDark, provider),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext ctx,
    bool isDark,
    FriendProvider provider,
  ) {
    return Scaffold(
      backgroundColor: AppColors.darkPremiumBackground,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.darkPremiumHeaderGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.darkPremiumTextPrimary, size: 22),
          onPressed: () => Navigator.pop(ctx),
        ),
        title: Text(
          'Lời mời kết bạn',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.darkPremiumTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.darkPremiumBorder, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.neonRoyal,
              unselectedLabelColor: AppColors.darkPremiumTextSecondary,
              indicatorColor: AppColors.neonRoyal,
              indicatorWeight: 2.5,
              labelStyle: AppTypography.labelLarge,
              unselectedLabelStyle: AppTypography.labelMedium,
              tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Đã nhận'),
                    if (provider.pendingReceivedCount > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _buildBadge(
                        '${provider.pendingReceivedCount}',
                        AppColors.neonRed,
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Đã gửi'),
                    if (provider.pendingSent.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _buildBadge(
                        '${provider.pendingSent.length}',
                        AppColors.darkPremiumTextSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: AppColors.darkPremiumBackground,
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildReceivedTab(isDark, provider),
            _buildSentTab(isDark, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── TAB: ĐÃ NHẬN ─────────────────────────────────────────────
  Widget _buildReceivedTab(bool isDark, FriendProvider provider) {
    if (provider.requestsState == LoadingState.loading) {
      return Container(
        color: AppColors.darkPremiumBackground,
        child: const LoadingView(),
      );
    }

    if (provider.pendingReceived.isEmpty) {
      return Container(
        color: AppColors.darkPremiumBackground,
        child: EmptyState(
          icon: Icons.mark_email_read_outlined,
          title: 'Không có lời mời kết bạn',
          subtitle: 'Khi ai đó gửi lời mời, bạn sẽ thấy ở đây',
        ),
      );
    }

    return Container(
      color: AppColors.darkPremiumBackground,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: provider.pendingReceived.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.darkPremiumBorder),
        itemBuilder: (_, i) =>
            _buildReceivedTile(provider.pendingReceived[i], isDark, provider),
      ),
    );
  }

  Widget _buildReceivedTile(
    FriendshipModel f,
    bool isDark,
    FriendProvider provider,
  ) {
    final isLoading = provider.isActionLoading(f.senderId);
    final displayName = (f.senderName?.isNotEmpty == true)
        ? f.senderName!
        : f.senderId;

    return Container(
      color: AppColors.darkPremiumSurface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FriendAvatar(
            name: f.addresseeName.isNotEmpty ? f.addresseeName : f.addresseeId,
            radius: 26,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.darkPremiumTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(f.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.darkPremiumTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildSourceBadge(f.sourceType, isDark),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FriendActionButton(
                        label: 'Từ chối',
                        style: FriendActionStyle.ghost,
                        isLoading: isLoading,
                        height: 36,
                        onTap: () =>
                            provider.declineFriendRequest(f.senderId),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FriendActionButton(
                        label: 'Chấp nhận',
                        style: FriendActionStyle.primary,
                        isLoading: isLoading,
                        height: 36,
                        onTap: () =>
                            provider.acceptFriendRequest(f.senderId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String sourceType, bool isDark) {
    String label;
    switch (sourceType) {
      case 'phone_contact':
        label = '📱 Từ danh bạ';
        break;
      case 'group':
        label = '👥 Từ nhóm';
        break;
      case 'qr_code':
        label = '📷 Quét QR';
        break;
      default:
        label = '🔍 Tìm kiếm';
    }

    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.darkPremiumTextSecondary,
      ),
    );
  }

  // ── TAB: ĐÃ GỬI ──────────────────────────────────────────────
  Widget _buildSentTab(bool isDark, FriendProvider provider) {
    if (provider.requestsState == LoadingState.loading) {
      return Container(
        color: AppColors.darkPremiumBackground,
        child: const LoadingView(),
      );
    }

    if (provider.pendingSent.isEmpty) {
      return Container(
        color: AppColors.darkPremiumBackground,
        child: EmptyState(
          icon: Icons.send_outlined,
          title: 'Chưa gửi lời mời nào',
          subtitle: 'Tìm bạn bè và gửi lời mời kết bạn',
        ),
      );
    }

    return Container(
      color: AppColors.darkPremiumBackground,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: provider.pendingSent.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.darkPremiumBorder),
        itemBuilder: (_, i) =>
            _buildSentTile(provider.pendingSent[i], isDark, provider),
      ),
    );
  }

  Widget _buildSentTile(
    FriendshipModel f,
    bool isDark,
    FriendProvider provider,
  ) {
    final isLoading = provider.isActionLoading(f.addresseeId);

    return Container(
      color: AppColors.darkPremiumSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          FriendAvatar(name: f.addresseeId, radius: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f.addresseeId,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.darkPremiumTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đang chờ chấp nhận • ${_formatTime(f.createdAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkPremiumTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          FriendActionButton(
            label: 'Huỷ lời mời',
            style: FriendActionStyle.ghost,
            isLoading: isLoading,
            onTap: () => provider.cancelFriendRequest(f.addresseeId),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}