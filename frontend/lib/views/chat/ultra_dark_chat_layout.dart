import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/component/dark_chat_widgets.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/models/chat/participant.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/views/chat/chat_screen.dart';

/// Ultra-Dark "Premium Glass" 4-column dashboard layout — chuyên dùng cho
/// màn hình chat khi user chọn tab "Tin nhắn" ở sidebar.
///
/// Cấu trúc cột (trái → phải):
///   1. Slim Sidebar       (60-72px, 3 chấm Mac, avatar cá nhân, icon nav)
///   2. Message List       (300-360px, title + search + #PINNED + #ALL MSG)
///   3. Main Chat          (Expanded, header + bubbles + input bar)
///   4. Chat Details       (300-360px, header + Files/Links + Members + Media
///      + File types)
class UltraDarkChatLayout extends StatefulWidget {
  final AppLocalizations t;

  const UltraDarkChatLayout({super.key, required this.t});

  @override
  State<UltraDarkChatLayout> createState() => _UltraDarkChatLayoutState();
}

class _UltraDarkChatLayoutState extends State<UltraDarkChatLayout> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _filterMode = 'all'; // 'all' | 'unread' | 'pinned'
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
    return Container(
      color: AppColors.darkPremiumBackground,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isVeryWide = w >= 1400;
            final isWide = w >= 1100;

            final slimWidth = 72.0;
            final listWidth = isVeryWide ? 340.0 : (isWide ? 320.0 : 280.0);
            final detailsWidth = isVeryWide ? 340.0 : 320.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSlimSidebar(),
                _buildMessageListColumn(width: listWidth),
                Expanded(
                  child: _buildMainChatColumn(),
                ),
                if (isWide) _buildDetailsColumn(width: detailsWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 1 — SLIM SIDEBAR (60-72px)
  // ════════════════════════════════════════════════════════════════
  Widget _buildSlimSidebar() {
    final currentRoute = _selectedConversation == null ? 'chat-list' : 'chat';

    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumVoid,
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          // 3 chấm Mac
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                _MacDot(color: Color(0xFFFF5F57)),
                SizedBox(width: 6),
                _MacDot(color: Color(0xFFFEBB2E)),
                SizedBox(width: 6),
                _MacDot(color: Color(0xFF28C840)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Avatar cá nhân
          _buildSlimAvatar(),
          const SizedBox(height: 28),
          _buildSlimIcon(
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum_rounded,
            active: currentRoute == 'chat-list' || currentRoute == 'chat',
          ),
          const SizedBox(height: 14),
          _buildSlimIcon(
            icon: Icons.contacts_outlined,
            activeIcon: Icons.contacts_rounded,
            active: false,
          ),
          const SizedBox(height: 14),
          _buildSlimIcon(
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories_rounded,
            active: false,
          ),
          const SizedBox(height: 14),
          _buildSlimIcon(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            active: false,
          ),
          const Spacer(),
          _buildSlimIcon(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            active: false,
            size: 42,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildSlimAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'U';
    final photo = user?.photoURL ?? '';
    final colorIdx =
        name.isEmpty ? 0 : name.codeUnitAt(0) % AppColors.darkPremiumAvatarPalette.length;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.darkPremiumAvatarPalette[colorIdx].withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: photo.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.darkPremiumAvatarPalette[colorIdx],
                      Color.lerp(
                            AppColors.darkPremiumAvatarPalette[colorIdx],
                            Colors.black,
                            0.4,
                          ) ??
                          AppColors.darkPremiumAvatarPalette[colorIdx],
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.darkPremiumAvatarPalette[colorIdx],
                        Color.lerp(
                              AppColors.darkPremiumAvatarPalette[colorIdx],
                              Colors.black,
                              0.4,
                            ) ??
                          AppColors.darkPremiumAvatarPalette[colorIdx],
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSlimIcon({
    required IconData icon,
    required IconData activeIcon,
    required bool active,
    double size = 46,
  }) {
    if (active) {
      return NeonActiveCircle(
        size: size,
        glowColor: AppColors.neonRoyal,
        child: Icon(activeIcon, color: AppColors.neonRoyal, size: 22),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onHover: (v) {},
          onTap: () {},
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: AppColors.darkPremiumTextSecondary,
            ),
          ),
        ),
      ),
    );
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

        // Filter chính
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

        final unread =
            filtered.where((c) => c.unreadCount > 0).toList();
        final pinned =
            filtered.where((c) => c.isPinned == true).toList();
        final rest = filtered
            .where((c) => c.unreadCount == 0 && c.isPinned != true)
            .toList();

        return Container(
          width: width,
          decoration: const BoxDecoration(
            color: AppColors.darkPremiumBackground,
            border: Border(
              right: BorderSide(
                color: AppColors.darkPremiumBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListHeader(chat),
              const SizedBox(height: 4),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildFilterTabs(unread.length),
              const SizedBox(height: 4),
              Expanded(
                child: loading
                    ? const _ListLoading()
                    : errorState
                        ? _ListErrorState(
                            onRetry: () => chat.loadConversations(),
                          )
                        : filtered.isEmpty
                            ? const DarkEmptyState(
                                icon: Icons.forum_outlined,
                                accentColor: AppColors.neonRoyal,
                                title: 'Chưa có cuộc trò chuyện nào',
                                subtitle:
                                    'Hãy kết bạn để bắt đầu nhắn tin —\nmọi cuộc trò chuyện sẽ xuất hiện ở đây.',
                              )
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
    final unreadCount = chat.conversations
        .where((c) => c.unreadCount > 0)
        .fold<int>(0, (s, c) => s + c.unreadCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Message',
            style: TextStyle(
              color: AppColors.darkPremiumTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '($unreadCount)',
                style: const TextStyle(
                  color: AppColors.neonRoyal,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          const Spacer(),
          Icon(
            Icons.tune_rounded,
            color: AppColors.darkPremiumTextSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.darkPremiumSurface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              color: AppColors.darkPremiumTextSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.darkPremiumTextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Tìm kiếm cuộc trò chuyện...',
                  hintStyle: const TextStyle(
                    color: AppColors.darkPremiumTextHint,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.darkPremiumTextSecondary,
                  size: 16,
                ),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(int unreadCount) {
    final allActive = _filterMode == 'all';
    final unreadActive = _filterMode == 'unread';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Row(
        children: [
          _buildFilterPill(
            label: 'Tất cả',
            active: allActive,
            onTap: () => setState(() => _filterMode = 'all'),
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            label: unreadCount > 0 ? 'Chưa đọc ($unreadCount)' : 'Chưa đọc',
            active: unreadActive,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? AppColors.neonRoyal.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.neonRoyal.withValues(alpha: 0.5)
                  : AppColors.darkPremiumBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? AppColors.neonRoyal
                  : AppColors.darkPremiumTextSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
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
        return const DarkEmptyState(
          icon: Icons.mark_chat_read_rounded,
          accentColor: AppColors.neonOnline,
          title: 'Không có tin nhắn chưa đọc',
          subtitle: 'Mọi tin nhắn của bạn đã được đọc.',
        );
      }
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        if (_filterMode != 'unread' && pinned.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: NeonLabelChip(text: '# PINNED'),
          ),
          ...pinned.map(
            (c) => _buildConversationTile(c),
          ),
          const SizedBox(height: 12),
        ],
        if (_filterMode != 'unread' && rest.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: NeonLabelChip(text: '# ALL MESSAGE'),
          ),
          ...rest.map(
            (c) => _buildConversationTile(c),
          ),
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

    final tile = Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildTileAvatar(c),
              if (isOnline && c.type != 'group')
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: const NeonOnlineDot(size: 11),
                ),
            ],
          ),
          const SizedBox(width: 12),
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
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.darkPremiumTextPrimary
                              : AppColors.darkPremiumTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lastTime,
                      style: TextStyle(
                        color: c.unreadCount > 0
                            ? AppColors.neonRoyal
                            : AppColors.darkPremiumTextHint,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
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
                        style: TextStyle(
                          color: c.unreadCount > 0
                              ? AppColors.darkPremiumTextBody
                              : AppColors.darkPremiumTextSecondary,
                          fontSize: 12.5,
                          fontWeight: c.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (c.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonRoyal,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.neonRoyal.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Text(
                          c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
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
        borderRadius: BorderRadius.circular(16),
        child: tile,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: isSelected
          ? DarkActiveConversationTile(child: inner)
          : inner,
    );
  }

  Widget _buildTileAvatar(Conversation c) {
    final name = c.displayName;
    final url = c.displayAvatar;
    final colorIdx = name.isEmpty
        ? 0
        : name.codeUnitAt(0) % AppColors.darkPremiumAvatarPalette.length;
    final color = c.type == 'group'
        ? AppColors.neonPurple
        : AppColors.darkPremiumAvatarPalette[colorIdx];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: url.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      Color.lerp(color, Colors.black, 0.4) ?? color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.4) ?? color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
      ),
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
      color: AppColors.darkPremiumBackground,
      child: ChatScreen(conversation: _selectedConversation!),
    );
  }

  Widget _buildWelcomeDark() {
    return Container(
      color: AppColors.darkPremiumBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonOutlineIcon(
                icon: Icons.forum_outlined,
                accent: AppColors.neonRoyal,
                size: 110,
                iconSize: 44,
                glowStrength: 0.55,
              ),
              const SizedBox(height: 28),
              const Text(
                'Chọn một cuộc trò chuyện',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkPremiumTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trò chuyện với bạn bè ngay bây giờ — chọn một hội thoại ở danh sách bên trái để bắt đầu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkPremiumTextSecondary,
                  fontSize: 14,
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

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          left: BorderSide(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
      ),
      child: conv == null
          ? const _DetailsIdleState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsHeader(conv),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailsBigAvatar(conv),
                        const SizedBox(height: 18),
                        _buildDetailsStats(conv),
                        const SizedBox(height: 24),
                        _buildMembersSection(members, memberCount),
                        const SizedBox(height: 24),
                        _buildMediaSection(),
                        const SizedBox(height: 24),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
      child: Row(
        children: [
          const Text(
            'Chat Details',
            style: TextStyle(
              color: AppColors.darkPremiumTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.close_rounded,
            color: AppColors.darkPremiumTextSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBigAvatar(Conversation conv) {
    final name = conv.displayName;
    final url = conv.displayAvatar;
    final colorIdx = name.isEmpty
        ? 0
        : name.codeUnitAt(0) % AppColors.darkPremiumAvatarPalette.length;
    final color = conv.type == 'group'
        ? AppColors.neonPurple
        : AppColors.darkPremiumAvatarPalette[colorIdx];

    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: url.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            Color.lerp(color, Colors.black, 0.4) ?? color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              Color.lerp(color, Colors.black, 0.4) ?? color,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkPremiumTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkPremiumElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkPremiumBorder),
            ),
            child: Text(
              conv.type == 'group'
                  ? 'Group · ${conv.participants.length} members'
                  : 'Direct message',
              style: const TextStyle(
                color: AppColors.darkPremiumTextSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStats(Conversation conv) {
    // Các số liệu Files/Links hiện chưa có trong API Response — sử dụng
    // các con số "dự kiến" để giữ bố cục dashboard nhất quán. Backend
    // sẽ bổ sung trường này sau; lúc đó chỉ cần thay bằng dữ liệu thật.
    return Row(
      children: [
        Expanded(
          child: DarkStatTile(
            icon: Icons.folder_outlined,
            accentColor: AppColors.neonPink,
            label: 'Files',
            count: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DarkStatTile(
            icon: Icons.link_rounded,
            accentColor: AppColors.neonYellow,
            label: 'Links',
            count: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(
      List<Participant> members, int memberCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text(
                'MEMBERS',
                style: TextStyle(
                  color: AppColors.darkPremiumTextSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($memberCount)',
                style: const TextStyle(
                  color: AppColors.darkPremiumTextHint,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...members.take(8).map((m) => _buildMemberRow(m)),
        if (members.length > 8) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '+ ${members.length - 8} thành viên khác',
              style: const TextStyle(
                color: AppColors.neonRoyal,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberRow(Participant m) {
    final colorIdx = (m.userId.codeUnitAt(0)) %
        AppColors.darkPremiumAvatarPalette.length;
    final color = AppColors.darkPremiumAvatarPalette[colorIdx];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: m.avatar.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            Color.lerp(color, Colors.black, 0.4) ?? color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(m.displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Image.network(
                      m.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              Color.lerp(color, Colors.black, 0.4) ??
                                  color,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(m.displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkPremiumTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (m.role.isNotEmpty)
                  Text(
                    m.role == 'admin'
                        ? 'Quản trị viên'
                        : m.role == 'owner'
                            ? 'Trưởng nhóm'
                            : 'Thành viên',
                    style: const TextStyle(
                      color: AppColors.darkPremiumTextHint,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call_outlined,
              color: AppColors.darkPremiumTextSecondary,
              size: 18,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    // Số lượng media hiển thị demo; backend sẽ cập nhật sau. Hiện tại dùng
    // con số trình diễn để giữ cảm giác dashboard hoàn chỉnh.
    const shownCount = 298;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text(
                'MEDIA',
                style: TextStyle(
                  color: AppColors.darkPremiumTextSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '$shownCount items',
                style: const TextStyle(
                  color: AppColors.darkPremiumTextHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...List.generate(8, (i) => _buildMediaTile(i)),
            DarkMediaTile(
              badge: '+$shownCount',
              child: Container(
                color: AppColors.darkPremiumElevated,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaTile(int i) {
    final palette = AppColors.darkPremiumAvatarPalette;
    final color = palette[i % palette.length];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.55),
            Color.lerp(color, Colors.black, 0.4) ?? color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        i.isEven ? Icons.image_outlined : Icons.play_circle_outline_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildFileTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'FILE TYPE',
            style: TextStyle(
              color: AppColors.darkPremiumTextSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DarkFileTypeTile(
                icon: Icons.description_outlined,
                accentColor: AppColors.neonRoyal,
                label: 'Documents',
                count: 6,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DarkFileTypeTile(
                icon: Icons.photo_outlined,
                accentColor: AppColors.neonRed,
                label: 'Photos',
                count: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DarkFileTypeTile(
                icon: Icons.movie_outlined,
                accentColor: AppColors.neonOnline,
                label: 'Movies',
                count: 4,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DarkFileTypeTile(
                icon: Icons.audio_file_outlined,
                accentColor: AppColors.neonPurple,
                label: 'Audios',
                count: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 3 chấm điều khiển của Mac — dùng ở đầu slim sidebar
class _MacDot extends StatelessWidget {
  final Color color;
  const _MacDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.neonRoyal,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Đang tải cuộc trò chuyện...',
            style: TextStyle(
              color: AppColors.darkPremiumTextSecondary,
              fontSize: 12.5,
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
    return DarkEmptyState(
      icon: Icons.cloud_off_outlined,
      accentColor: AppColors.neonRed,
      title: 'Chưa thể tải cuộc trò chuyện',
      subtitle:
          'Kết nối mạng có vấn đề, bạn vẫn có thể thử lại hoặc kết bạn để tạo cuộc trò chuyện mới.',
      actionLabel: 'Thử lại',
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
      actionGradient: AppColors.neonButtonGradient,
    );
  }
}

class _DetailsIdleState extends StatelessWidget {
  const _DetailsIdleState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.darkPremiumTextHint,
              size: 36,
            ),
            SizedBox(height: 12),
            Text(
              'Chọn một cuộc trò chuyện để xem thông tin chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkPremiumTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
