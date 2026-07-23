import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/models/chat/message.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/widgets/chat/message_bubble.dart';
import 'package:frontend/widgets/chat/typing_indicator.dart';
import 'package:frontend/component/avatars.dart';

/// ════════════════════════════════════════════════════════════════
/// CHAT CONTENT PANEL — Message View for 3-Column Layout
/// ════════════════════════════════════════════════════════════════

class ChatContentPanel extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback? onOpenChatScreen;

  const ChatContentPanel({
    super.key,
    required this.conversation,
    this.onOpenChatScreen,
  });

  @override
  State<ChatContentPanel> createState() => _ChatContentPanelState();
}

class _ChatContentPanelState extends State<ChatContentPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkChatSurfaceGradient.first,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final conv = widget.conversation;
    final isGroup = conv.type == 'group';
    final otherUserId = conv.otherUserId;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
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
          TriAvatar(
            imageUrl: conv.displayAvatar,
            name: conv.displayName,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conv.displayName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.darkPremiumTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (!isGroup && otherUserId != null)
                  Selector<ChatProvider, bool>(
                    selector: (_, p) => p.isUserOnline(otherUserId),
                    builder: (_, isOnline, __) => Text(
                      isOnline ? 'Đang hoạt động' : conv.displayStatus,
                      style: AppTypography.labelSmall.copyWith(
                        color: isOnline
                            ? AppColors.success
                            : AppColors.darkPremiumTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Text(
                    isGroup
                        ? '${conv.participants.length} thành viên'
                        : conv.displayStatus,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.darkPremiumTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.open_in_full_rounded,
              color: AppColors.darkPremiumTextSecondary,
              size: 20,
            ),
            onPressed: widget.onOpenChatScreen,
            tooltip: 'Mở đầy đủ',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final messages = chat.messages;
        final isTyping = chat.isOtherTyping;

        if (messages.isEmpty && !isTyping) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Chưa có tin nhắn nào',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: messages.length + (isTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (isTyping && index == messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: TypingIndicator(),
              );
            }

            final message = messages[index];
            final prev = index > 0 ? messages[index - 1] : null;
            final next = index < messages.length - 1 ? messages[index + 1] : null;

            final sameAsPrev = prev != null &&
                prev.senderId == message.senderId &&
                message.createdAt.difference(prev.createdAt).inMinutes < 3;
            final sameAsNext = next != null &&
                next.senderId == message.senderId &&
                next.createdAt.difference(message.createdAt).inMinutes < 3;

            return MessageBubble(
              message: message,
              showAvatar: !message.isMine && sameAsNext,
              showSenderName: !message.isMine && widget.conversation.type == 'group',
              showMeta: true,
              isGroupTop: false,
              isGroupMiddle: sameAsPrev && sameAsNext,
              isGroupBottom: sameAsPrev,
              highlighted: false,
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.darkPremiumTextSecondary,
              size: 24,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.darkPremiumElevated,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.darkPremiumBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Aa',
                  hintStyle: TextStyle(
                    color: AppColors.darkPremiumTextHint,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                style: TextStyle(
                  color: AppColors.darkPremiumTextPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.neonRoyal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonRoyal.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// CONVERSATION DETAIL PANEL — Profile & Details Tabs
/// ════════════════════════════════════════════════════════════════

class ConversationDetailPanel extends StatefulWidget {
  final Conversation conversation;

  const ConversationDetailPanel({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationDetailPanel> createState() => _ConversationDetailPanelState();
}

class _ConversationDetailPanelState extends State<ConversationDetailPanel>
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
    return Container(
      color: AppColors.darkPremiumSurface,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProfileTab(conversation: widget.conversation),
                _DetailsTab(conversation: widget.conversation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final conv = widget.conversation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          TriAvatar(
            imageUrl: conv.displayAvatar,
            name: conv.displayName,
            size: 80,
            elevated: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            conv.displayName,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.darkPremiumTextPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            conv.type == 'group'
                ? '${conv.participants.length} thành viên'
                : conv.displayStatus,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.darkPremiumTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.neonRoyal,
        labelColor: AppColors.neonRoyal,
        unselectedLabelColor: AppColors.darkPremiumTextSecondary,
        labelStyle: AppTypography.labelMedium,
        tabs: const [
          Tab(text: 'Trang cá nhân'),
          Tab(text: 'Chi tiết'),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// PROFILE TAB — Show partner/group info
/// ════════════════════════════════════════════════════════════════

class _ProfileTab extends StatelessWidget {
  final Conversation conversation;

  const _ProfileTab({required this.conversation});

  @override
  Widget build(BuildContext context) {
    if (conversation.type == 'group') {
      return _buildGroupProfile();
    }
    return _buildUserProfile();
  }

  Widget _buildUserProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.person_outline_rounded,
            label: 'Tên',
            value: conversation.displayName,
          ),
          if (conversation.otherUserId != null)
            _buildInfoItem(
              icon: Icons.fingerprint_rounded,
              label: 'ID',
              value: conversation.otherUserId!,
            ),
          _buildInfoItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Trạng thái',
            value: conversation.displayStatus,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGroupProfile() {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final participants = conversation.participants;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thành viên (${participants.length})',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.darkPremiumTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...participants.map((p) => _buildParticipantItem(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantItem(Participant p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          TriAvatar(
            imageUrl: p.avatar ?? '',
            name: p.displayName ?? 'U',
            size: 36,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName ?? 'Người dùng',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.darkPremiumTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (p.role == 'admin')
                  Text(
                    'Quản trị viên',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryAmber,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.darkPremiumElevated,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: AppColors.darkPremiumTextSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.darkPremiumTextSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.darkPremiumTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.call_outlined,
          label: 'Gọi điện',
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActionButton(
          icon: Icons.videocam_outlined,
          label: 'Gọi video',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkPremiumElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.darkPremiumTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// DETAILS TAB — Media, Links, Files
/// ════════════════════════════════════════════════════════════════

class _DetailsTab extends StatelessWidget {
  final Conversation conversation;

  const _DetailsTab({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final messages = chat.messages;

        // Filter media (images)
        final mediaMessages = messages
            .where((m) => m.type == 'image' && m.mediaUrl != null)
            .toList();

        // Filter links
        final linkRegex = RegExp(
          r'https?://[^\s]+',
          caseSensitive: false,
        );
        final linkMessages = messages
            .where((m) => m.type == 'text' && linkRegex.hasMatch(m.content))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Hình ảnh',
                count: mediaMessages.length,
                icon: Icons.image_outlined,
                child: mediaMessages.isEmpty
                    ? _buildEmptyState('Chưa có hình ảnh nào')
                    : _buildMediaGrid(mediaMessages),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSection(
                title: 'Liên kết',
                count: linkMessages.length,
                icon: Icons.link_rounded,
                child: linkMessages.isEmpty
                    ? _buildEmptyState('Chưa có liên kết nào')
                    : _buildLinkList(linkMessages),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSection(
                title: 'Tệp đính kèm',
                count: messages.where((m) => m.type == 'file').length,
                icon: Icons.attach_file_rounded,
                child: _buildEmptyState('Chưa có tệp nào'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.darkPremiumTextSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.darkPremiumTextSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkPremiumElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.darkPremiumTextHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.darkPremiumTextHint,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<Message> messages) {
    // Show max 9 images in 3x3 grid
    final displayMessages = messages.take(9).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: displayMessages.length,
      itemBuilder: (context, index) {
        final message = displayMessages[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.network(
            message.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.darkPremiumElevated,
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.darkPremiumTextHint,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinkList(List<Message> messages) {
    return Column(
      children: messages.take(10).map((m) {
        final uri = Uri.tryParse(m.content);
        final displayUrl = uri?.host ?? m.content;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.darkPremiumElevated,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: AppColors.neonRoyal,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    displayUrl,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neonRoyal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
