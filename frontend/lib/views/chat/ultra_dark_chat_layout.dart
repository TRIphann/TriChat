import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/models/chat/participant.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/views/chat/chat_screen.dart';

/// Layout 4 cột minimalist black & white — dùng cho màn hình chat khi user
/// chọn tab "Tin nhắn" ở sidebar trên màn hình rộng.
///
/// Cấu trúc cột (trái → phải):
///   1. Slim Sidebar (60-72px, avatar cá nhân, icon nav)
///   2. Message List (search + filter pills + conversation list)
///   3. Main Chat (Expanded, header + bubbles + input bar)
///   4. Chat Details (Members, File types — info panel)
class UltraDarkChatLayout extends StatefulWidget {
  final AppLocalizations t;
  final ValueChanged<int>? onNavTap;
  final int currentNavIndex;

  const UltraDarkChatLayout({
    super.key,
    required this.t,
    this.onNavTap,
    this.currentNavIndex = 0,
  });

  @override
  State<UltraDarkChatLayout> createState() => _UltraDarkChatLayoutState();
}

class _UltraDarkChatLayoutState extends State<UltraDarkChatLayout> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _filterMode = 'all';
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isVeryWide = w >= 1400;
            final isWide = w >= 1100;

            final listWidth = isVeryWide ? 340.0 : (isWide ? 320.0 : 280.0);
            final detailsWidth = isVeryWide ? 340.0 : 320.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSlimSidebar(isDark),
                _buildMessageListColumn(width: listWidth),
                Expanded(child: _buildMainChatColumn()),
                if (isWide) _buildDetailsColumn(width: detailsWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 1 — SLIM SIDEBAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildSlimSidebar(bool isDark) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.neutralBlack,
        border: Border(
          right: BorderSide(
            color:
                isDark ? AppColors.darkDivider : AppColors.neutralGray800,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildSlimAvatar(),
          const SizedBox(height: AppSpacing.xl),
          _buildSlimIcon(
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum_rounded,
            active: widget.currentNavIndex == 0,
            onTap: () => widget.onNavTap?.call(0),
            tooltip: 'Tin nhắn',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSlimIcon(
            icon: Icons.contacts_outlined,
            activeIcon: Icons.contacts_rounded,
            active: widget.currentNavIndex == 1,
            onTap: () => widget.onNavTap?.call(1),
            tooltip: 'Bạn bè',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSlimIcon(
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories_rounded,
            active: widget.currentNavIndex == 2,
            onTap: () => widget.onNavTap?.call(2),
            tooltip: 'Bảng tin',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSlimIcon(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            active: widget.currentNavIndex == 3,
            onTap: () => widget.onNavTap?.call(3),
            tooltip: 'Cá nhân',
          ),
          const Spacer(),
          _buildSlimIcon(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            active: widget.currentNavIndex == 4,
            size: 46,
            onTap: () => widget.onNavTap?.call(4),
            tooltip: 'Cài đặt',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSlimAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'U';
    final photo = user?.photoURL ?? '';
    return TriAvatar(imageUrl: photo, name: name, size: 44);
  }

  Widget _buildSlimIcon({
    required IconData icon,
    required IconData activeIcon,
    required bool active,
    double size = 46,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    final color =
        active ? AppColors.neutralWhite : AppColors.neutralGray400;
    final iconWidget = Icon(
      active ? activeIcon : icon,
      color: color,
      size: 22,
    );
    final Widget tap = GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.neutralGray800 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: iconWidget,
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: tap) : tap;
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 2 — MESSAGE LIST
  // ════════════════════════════════════════════════════════════════
  Widget _buildMessageListColumn({required double width}) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final conversations = chat.conversations;
        final loading = chat.conversationsState == ChatLoadingState.loading &&
            conversations.isEmpty;
        final errorState = chat.conversationsState == ChatLoadingState.error &&
            conversations.isEmpty;

        final filtered = _searchQuery.isEmpty
            ? conversations
            : conversations
                .where((c) =>
                    c.displayName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    (c.lastMessage?.content ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();

        final unread = filtered.where((c) => c.unreadCount > 0).toList();
        final pinned =
            filtered.where((c) => c.isPinned == true).toList();
        final rest = filtered
            .where((c) => c.unreadCount == 0 && c.isPinned != true)
            .toList();

        final theme = Theme.of(context);
        return Container(
          width: width,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              right: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListHeader(chat),
              _buildSearchBar(),
              _buildFilterTabs(unread.length),
              Expanded(
                child: loading
                    ? const _ListLoading()
                    : errorState
                        ? _ListErrorState(
                            onRetry: () => chat.loadConversations(),
                          )
                        : filtered.isEmpty
                            ? _buildEmptyState(_filterMode == 'unread')
                            : _buildConversationsBody(
                                pinned: pinned,
                                unread: unread,
                                rest: rest,
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListHeader(ChatProvider chat) {
    final theme = Theme.of(context);
    final unreadCount = chat.conversations
        .where((c) => c.unreadCount > 0)
        .fold<int>(0, (s, c) => s + c.unreadCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tin nhắn',
            style: AppTypography.headlineMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            UnreadBadge(count: unreadCount),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.neutralGray100,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.search_rounded,
              color: theme.hintColor,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Tìm kiếm cuộc trò chuyện...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                onPressed: () => _searchController.clear(),
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.hintColor,
                  size: 16,
                ),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(int unreadCount) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _buildFilterPill(
            label: 'Tất cả',
            active: _filterMode == 'all',
            onTap: () => setState(() => _filterMode = 'all'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterPill(
            label: unreadCount > 0 ? 'Chưa đọc ($unreadCount)' : 'Chưa đọc',
            active: _filterMode == 'unread',
            onTap: () => setState(() => _filterMode = 'unread'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.onSurface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(
              color: active ? theme.colorScheme.onSurface : theme.dividerColor,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: active
                  ? theme.colorScheme.surface
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool unreadMode) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkCard
                    : AppColors.neutralGray100,
              ),
              child: Icon(
                unreadMode
                    ? Icons.mark_chat_read_outlined
                    : Icons.chat_bubble_outline_rounded,
                size: 36,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              unreadMode
                  ? 'Không có tin nhắn chưa đọc'
                  : 'Chưa có cuộc trò chuyện nào',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              unreadMode
                  ? 'Mọi tin nhắn của bạn đã được đọc.'
                  : 'Hãy kết bạn để bắt đầu nhắn tin — cuộc trò chuyện sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsBody({
    required List<Conversation> pinned,
    required List<Conversation> unread,
    required List<Conversation> rest,
  }) {
    List<Conversation> visible;
    switch (_filterMode) {
      case 'unread':
        visible = unread;
        break;
      default:
        visible = [...pinned, ...rest];
    }

    if (visible.isEmpty) {
      if (_filterMode == 'unread') {
        return _buildEmptyState(true);
      }
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      children: [
        if (_filterMode != 'unread' && pinned.isNotEmpty) ...[
          const _LabelRow(text: '# PINNED'),
          ...pinned.map((c) => _buildConversationTile(c)),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_filterMode != 'unread' && rest.isNotEmpty) ...[
          const _LabelRow(text: '# ALL MESSAGE'),
          ...rest.map((c) => _buildConversationTile(c)),
        ],
        if (_filterMode == 'unread')
          ...visible.map((c) => _buildConversationTile(c)),
      ],
    );
  }

  Widget _buildConversationTile(Conversation c) {
    final isSelected = _selectedConversation?.id == c.id;
    final lastMsg = c.lastMessage?.content ?? '';
    final lastTime = _formatTime(c.lastMessage?.createdAt);
    final isOnline = c.type == 'group'
        ? false
        : Provider.of<ChatProvider>(context, listen: false)
            .isUserOnline(c.otherUserId ?? '');

    final theme = Theme.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              TriAvatar(
                imageUrl: c.displayAvatar,
                name: c.displayName,
                size: 44,
                overlayCount: c.type == 'group' ? c.participants.length : null,
              ),
              if (isOnline && c.type != 'group')
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
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
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: c.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      lastTime,
                      style: AppTypography.timestamp.copyWith(
                        color: c.unreadCount > 0
                            ? theme.colorScheme.onSurface
                            : theme.hintColor,
                        fontWeight: c.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.type == 'group'
                            ? '${c.participants.length} thành viên'
                            : lastMsg.isEmpty
                                ? 'Bắt đầu cuộc trò chuyện...'
                                : lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: c.unreadCount > 0
                              ? theme.colorScheme.onSurface
                              : theme.hintColor,
                          fontWeight: c.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (c.unreadCount > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      UnreadBadge(count: c.unreadCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final onTap = () {
      setState(() => _selectedConversation = c);
      context.read<ChatProvider>().openConversation(c);
    };

    final inner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: tile,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? (theme.brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.neutralGray100)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: inner,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts.last.isNotEmpty) {
      return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
    }
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final localDt = dt.toLocal();
    if (now.year == localDt.year &&
        now.month == localDt.month &&
        now.day == localDt.day) {
      return '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
    }
    final diff = now.difference(localDt).inDays;
    if (diff < 1) {
      return '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
    }
    if (diff < 7) {
      const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return weekdays[localDt.weekday % 7];
    }
    return '${localDt.day}/${localDt.month}';
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 3 — MAIN CHAT
  // ════════════════════════════════════════════════════════════════
  Widget _buildMainChatColumn() {
    if (_selectedConversation == null) {
      return _buildWelcomeDark();
    }
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ChatScreen(conversation: _selectedConversation!),
    );
  }

  Widget _buildWelcomeDark() {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.huge,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.brightness == Brightness.dark
                      ? AppColors.darkCard
                      : AppColors.neutralGray100,
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.forum_outlined,
                  size: 44,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Chọn một cuộc trò chuyện',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Trò chuyện với bạn bè ngay bây giờ — chọn một hội thoại ở danh sách bên trái để bắt đầu.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.hintColor,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 4 — CHAT DETAILS
  // ════════════════════════════════════════════════════════════════
  Widget _buildDetailsColumn({required double width}) {
    final conv = _selectedConversation;
    final members = conv?.participants ?? <Participant>[];
    final memberCount = members.length;
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: conv == null
          ? _DetailsIdleState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsHeader(conv),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailsBigAvatar(conv),
                        const SizedBox(height: AppSpacing.lg),
                        _buildMembersSection(members, memberCount),
                        const SizedBox(height: AppSpacing.xl),
                        _buildFileTypeSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailsHeader(Conversation conv) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            'Chi tiết',
            style: AppTypography.titleLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBigAvatar(Conversation conv) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          TriAvatar(
            imageUrl: conv.displayAvatar,
            name: conv.displayName,
            size: 80,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            conv.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkCard
                  : AppColors.neutralGray100,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              conv.type == 'group'
                  ? 'Nhóm · ${conv.participants.length} thành viên'
                  : 'Tin nhắn trực tiếp',
              style: AppTypography.labelSmall.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
      List<Participant> members, int memberCount) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'THÀNH VIÊN',
                style: AppTypography.labelSmall.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '($memberCount)',
                style: AppTypography.labelSmall.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...members.take(8).map((m) => _buildMemberRow(m)),
        if (members.length > 8) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '+ ${members.length - 8} thành viên khác',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberRow(Participant m) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          TriAvatar(imageUrl: m.avatar, name: m.displayName, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (m.role.isNotEmpty)
                  Text(
                    m.role == 'admin'
                        ? 'Quản trị viên'
                        : m.role == 'owner'
                            ? 'Trưởng nhóm'
                            : 'Thành viên',
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.call_outlined,
            color: theme.hintColor,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildFileTypeSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'LOẠI FILE',
            style: AppTypography.labelSmall.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _FileTypeTile(
              icon: Icons.description_outlined,
              label: 'Tài liệu',
              count: 6,
              theme: theme,
            ),
            const SizedBox(width: AppSpacing.sm),
            _FileTypeTile(
              icon: Icons.photo_outlined,
              label: 'Ảnh',
              count: 28,
              theme: theme,
            ),
            const SizedBox(width: AppSpacing.sm),
            _FileTypeTile(
              icon: Icons.movie_outlined,
              label: 'Video',
              count: 4,
              theme: theme,
            ),
            const SizedBox(width: AppSpacing.sm),
            _FileTypeTile(
              icon: Icons.audio_file_outlined,
              label: 'Âm thanh',
              count: 12,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }
}

/// Nhãn phân nhóm minimalist (ví dụ "# PINNED", "# ALL MESSAGE")
class _LabelRow extends StatelessWidget {
  final String text;
  const _LabelRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: theme.hintColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FileTypeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final ThemeData theme;
  const _FileTypeTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.neutralGray100,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 18),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$count',
              style: AppTypography.titleSmall.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Đang tải cuộc trò chuyện...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ListErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.errorLight,
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chưa thể tải cuộc trò chuyện',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kết nối mạng có vấn đề, bạn có thể thử lại hoặc kết bạn để tạo cuộc trò chuyện mới.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: theme.hintColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Thử lại',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _DetailsIdleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.hintColor,
              size: 36,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn một cuộc trò chuyện để xem thông tin chi tiết.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}