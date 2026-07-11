import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/calling/screens/call_screen.dart';
import 'package:frontend/features/calling/screens/incoming_call_screen.dart';
import 'package:frontend/features/feedback/screens/feedback_screen.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/contact_main_screen.dart';
import 'package:frontend/features/newfeed/screens/newfeed_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/models/call_model.dart';
import 'package:frontend/models/chat/conversation.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/services/call_notification_service.dart';
import 'package:frontend/services/flutter_callkeep.dart';
import 'package:frontend/services/message_notification_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:frontend/views/chat/chat_screen.dart';
import 'package:frontend/views/chat/new_conversation_screen.dart';
import 'package:frontend/views/chat/ultra_dark_chat_layout.dart';
import 'package:frontend/views/contacts/contacts_view.dart';
import 'package:provider/provider.dart';

/// ════════════════════════════════════════════════════════════════
/// ChatListView — TriChat
///
/// Bố cục 3 cột chuẩn cho Desktop / Wide Screen:
///   ┌─Sidebar─┬────List────┬─────Main Chat─────┐
///   │ Avatar  │  Header    │                   │
///   │ Menu    │  Filter    │   ChatScreen /    │
///   │ Settings│  List      │   Empty Panel     │
///   └─────────┴────────────┴───────────────────┘
///
/// Trên mobile (width < 900): dùng IndexedStack + bottom nav.
/// ════════════════════════════════════════════════════════════════
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => ChatListViewState();
}

class ChatListViewState extends State<ChatListView> {
  String _filterMode = 'all';
  int _selectedNavIndex = 0;
  Conversation? _selectedConversation;
  bool _coldStartCallHandled = false;
  bool _callScreenOpened = false;
  late CallProvider _callProvider;

  void switchTab(int index) {
    setState(() => _selectedNavIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const hasPendingFeedbackEvaluation = true;
      if (hasPendingFeedbackEvaluation) {
        _showFeedbackFlow(context);
      }
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    Future.microtask(() {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final provider = context.read<FriendProvider>();
      if (uid.isNotEmpty) {
        provider.setCurrentUid(uid);
      } else {
        provider.loadAll();
      }
      provider.startRealtime();

      if (uid.isNotEmpty) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.setContext(context);
        chatProvider.init(uid);
      }

      if (mounted) CallNotificationService.checkPendingCall(_handleFcmCall);
      if (!kIsWeb) _pollActiveCalls();
      MessageNotificationService.onNotificationTap = _openConversationById;
      MessageNotificationService.checkInitialMessage();
    });

    _callProvider = context.read<CallProvider>();
    _callProvider.addListener(_onCallStateChanged);
    CallNotificationService.acceptedCall.addListener(_onCallAcceptedNotifier);
    CallNotificationService.declinedCall.addListener(_onCallDeclinedNotifier);
    if (CallNotificationService.acceptedCall.value != null) {
      Future.microtask(_onCallAcceptedNotifier);
    }
  }

  @override
  void dispose() {
    MessageNotificationService.onNotificationTap = null;
    _callProvider.removeListener(_onCallStateChanged);
    CallNotificationService.acceptedCall.removeListener(_onCallAcceptedNotifier);
    CallNotificationService.declinedCall.removeListener(_onCallDeclinedNotifier);
    super.dispose();
  }

  Future<void> _openConversationById(String conversationId) async {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    Conversation? conv = chatProvider.conversations
        .where((c) => c.id == conversationId)
        .firstOrNull;
    conv ??= await chatProvider.fetchConversation(conversationId);
    if (conv == null || !mounted) return;
    await chatProvider.openConversation(conv);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv!)),
    );
  }

  void _onCallStateChanged() {
    final call = context.read<CallProvider>().currentCall;
    if (call != null && call.isIncoming && call.status == CallStatus.ringing) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(call: call),
          fullscreenDialog: true,
        ),
      );
    }
  }

  Future<void> _pollActiveCalls() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted || _coldStartCallHandled) return;
      try {
        final activeCalls = await CallKeep.instance.activeCalls();
        if (activeCalls.isNotEmpty) {
          _coldStartCallHandled = true;
          final event = activeCalls.first;
          await CallKeep.instance.endAllCalls();
          if (mounted) _handleCallAccepted(event);
          return;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _onCallAcceptedNotifier() {
    final event = CallNotificationService.acceptedCall.value;
    if (event == null || !mounted) return;
    CallNotificationService.acceptedCall.value = null;
    _handleCallAccepted(event);
  }

  void _onCallDeclinedNotifier() {
    final event = CallNotificationService.declinedCall.value;
    if (event == null || !mounted) return;
    CallNotificationService.declinedCall.value = null;
    _handleCallDeclined(event);
  }

  void _handleCallAccepted(CallEvent event) {
    if (!mounted || _callScreenOpened) return;
    _callScreenOpened = true;
    _coldStartCallHandled = true;
    final extra = event.extra ?? {};
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final call = CallModel(
      conversationId: extra['conversation_id'] ?? '',
      callerId: extra['caller_id'] ?? '',
      calleeId: currentUid,
      remoteName: extra['caller_name'] ?? event.callerName ?? '',
      remoteAvatar: extra['caller_avatar'] ?? '',
      isVideo: extra['call_type'] == 'video',
      isIncoming: true,
      status: CallStatus.active,
    );

    context.read<CallProvider>().acceptCall();
    context.read<ChatProvider>().acceptCall(call.conversationId, call.callerId);

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => CallScreen(call: call),
          ),
        )
        .then((_) {
          _callScreenOpened = false;
          _coldStartCallHandled = false;
        });
  }

  void _handleCallDeclined(CallEvent event) {
    if (!mounted) return;
    final extra = event.extra ?? {};
    final chat = context.read<ChatProvider>();
    chat.rejectCall(
      extra['conversation_id'] ?? '',
      extra['caller_id'] ?? '',
      reason: 'rejected',
    );
    context.read<CallProvider>().rejectCall();
  }

  void _handleFcmCall(Map<String, String> data) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final callModel = CallModel(
      conversationId: data['conversation_id'] ?? '',
      callerId: data['caller_id'] ?? '',
      calleeId: currentUid,
      remoteName: data['caller_name'] ?? '',
      remoteAvatar: data['caller_avatar'] ?? '',
      isVideo: data['call_type'] == 'video',
      isIncoming: true,
      status: CallStatus.ringing,
    );

    context.read<CallProvider>().receiveIncomingCall(callModel);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(call: callModel),
        fullscreenDialog: true,
      ),
    );
  }

  void _onConversationTap(Conversation conversation) {
    context.read<ChatProvider>().openConversation(conversation);
    final isWideScreen = MediaQuery.of(context).size.width >= 900;
    if (isWideScreen) {
      setState(() => _selectedConversation = conversation);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    }
  }

  void _showFeedbackFlow(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FeedbackFlowModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            final t = AppLocalizations(locale);
            final screenWidth = MediaQuery.of(context).size.width;
            final isWideScreen = screenWidth >= 900;
            final isVeryWideScreen = screenWidth >= 1200;

            return Scaffold(
              backgroundColor: AppColors.getBackground(isDark),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (isWideScreen) {
                      return _buildWideLayout(
                        t,
                        isDark,
                        isVeryWideScreen,
                      );
                    }

                    return _buildMobileView(t, isDark);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── WIDE LAYOUT ─────────────────────────────────────────────
  // Khi người dùng đang ở tab Chat (index 0), dùng Ultra-Dark 4-column
  // dashboard (Slim Sidebar + Message List + Chat + Details). Các tab
  // khác giữ nguyên layout cũ 3-column cream.
  Widget _buildWideLayout(
    AppLocalizations t,
    bool isDark,
    bool isVeryWideScreen,
  ) {
    // Tab chat → Ultra Dark 4-column
    if (_selectedNavIndex == 0) {
      return UltraDarkChatLayout(t: t);
    }

    return Container(
      color: AppColors.creamBackground,
      child: Row(
        children: [
          // Cột 1: Navigation Sidebar (Glassmorphism nâu)
          _buildSidebar(isDark),
          // Cột 2 + 3: list + main
          Expanded(
            child: Row(
              children: [
                if (_selectedNavIndex == 1)
                  const Expanded(child: ContactsView(isWideScreen: true))
                else if (_selectedNavIndex == 2)
                  const Expanded(child: NewfeedScreen())
                else if (_selectedNavIndex == 3)
                  const Expanded(child: ProfileScreen())
                else if (_selectedNavIndex == 4)
                  const Expanded(child: _SettingsPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE LAYOUT (bottom nav) ──────────────────────────────
  Widget _buildMobileView(AppLocalizations t, bool isDark) {
    return Container(
      color: AppColors.creamBackground,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedNavIndex,
              children: [
                _buildChatListPanel(t, isDark),
                const ContactsMainScreen(),
                const NewfeedScreen(),
                const ProfileScreen(),
                const SettingsTab(),
              ],
            ),
          ),
          _buildBottomNavigation(isDark),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 1 — SIDEBAR (Glassmorphism nâu socola)
  // ════════════════════════════════════════════════════════════════
  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.sidebarBrownGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildUserAvatar(),
          const SizedBox(height: AppSpacing.xl),
          _buildSidebarItem(
            Icons.chat_bubble_rounded,
            Icons.chat_bubble_outline_rounded,
            0,
            isDark,
            tooltip: 'Tin nhắn',
          ),
          _buildSidebarItem(
            Icons.contacts_rounded,
            Icons.contacts_outlined,
            1,
            isDark,
            tooltip: 'Bạn bè',
          ),
          _buildSidebarItem(
            Icons.auto_stories_rounded,
            Icons.auto_stories_outlined,
            2,
            isDark,
            tooltip: 'Bảng tin',
          ),
          _buildSidebarItem(
            Icons.person_rounded,
            Icons.person_outline_rounded,
            3,
            isDark,
            tooltip: 'Cá nhân',
          ),
          const Spacer(),
          _buildSidebarItem(
            Icons.settings_rounded,
            Icons.settings_outlined,
            4,
            isDark,
            tooltip: 'Cài đặt',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final avatarUrl = firebaseUser?.photoURL ?? '';
    final displayName = firebaseUser?.displayName ?? 'U';
    return Tooltip(
      message: displayName,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TriAvatar(
          imageUrl: avatarUrl,
          name: displayName,
          size: 48,
          elevated: true,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
    bool isDark, {
    String? tooltip,
  }) {
    final isSelected = _selectedNavIndex == index;
    final tooltipStr = tooltip ?? '';
    return Tooltip(
      message: tooltipStr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 6,
                  bottom: 6,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedNavIndex = index;
                    _selectedConversation = null;
                  });
                },
                icon: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected
                      ? AppColors.primaryOrange
                      : Colors.white.withValues(alpha: 0.75),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 2 — LIST (Cream/White)
  // ════════════════════════════════════════════════════════════════
  Widget _buildChatListPanel(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        _buildSearchHeader(t, isDark, isMobile: true),
        Expanded(child: _buildConversationList(t, isDark)),
      ],
    );
  }

  Widget _buildChatListPanelWide(
    AppLocalizations t,
    bool isDark,
    bool isVeryWideScreen,
  ) {
    return Container(
      width: isVeryWideScreen ? 380 : 340,
      decoration: const BoxDecoration(
        color: AppColors.creamWhite,
        border: Border(
          right: BorderSide(
            color: AppColors.neutralGray300,
            width: 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSearchHeader(t, isDark, isMobile: false),
          _buildFilterTabs(t, isDark),
          Expanded(child: _buildConversationList(t, isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(
    AppLocalizations t,
    bool isDark, {
    bool isMobile = false,
  }) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.creamWhite,
          border: Border(
            bottom: BorderSide(
              color: AppColors.neutralGray300,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  TriAvatar(
                    imageUrl:
                        FirebaseAuth.instance.currentUser?.photoURL ?? '',
                    name:
                        FirebaseAuth.instance.currentUser?.displayName ?? 'U',
                    size: 40,
                    elevated: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      t.get('messages'),
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.neutralBlack,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  _buildHeaderIconButton(
                    Icons.search_rounded,
                    () => _openSearchOverlay(context),
                  ),
                  _buildHeaderIconButton(
                    Icons.qr_code_scanner_rounded,
                    () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TriSearchField(
                hintText: t.get('searchPlaceholder'),
                readOnly: true,
                onTap: () => _openSearchOverlay(context),
              ),
            ],
          ),
        ),
      );
    }

    // Wide layout (Cột 2)
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.creamWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralGray300,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề "ĐOẠN CHAT" viết hoa
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.md,
              ),
              child: Text(
                t.get('messages').toString().toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.neutralBlack,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ),
            TriSearchField(
              hintText: t.get('searchPlaceholder'),
              readOnly: true,
              onTap: () => _openSearchOverlay(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderIconButton(
                  Icons.person_add_alt_1_rounded,
                  () {},
                  tooltip: 'Thêm bạn',
                ),
                _buildHeaderIconButton(
                  Icons.group_add_rounded,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const NewConversationScreen(type: 'group'),
                    ),
                  ),
                  tooltip: 'Tạo nhóm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
    String? tooltip,
  }) {
    final btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.neutralGray100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.accentBrown,
            size: 20,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FriendSearchPage()),
    );
  }

  Widget _buildFilterTabs(AppLocalizations t, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.creamWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralGray300,
            width: 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 46,
      child: Row(
        children: [
          _buildFilterTab(t.get('all'), 'all', isDark),
          _buildFilterTab(t.get('unread'), 'unread', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, bool isDark) {
    final isSelected = _filterMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterMode = value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? AppColors.primaryOrange
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.neutralGray700,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(AppLocalizations t, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        if (chat.conversationsState == ChatLoadingState.loading) {
          return const LoadingView();
        }
        if (chat.conversationsState == ChatLoadingState.error) {
          return _buildErrorState(chat.errorMessage, () => chat.loadConversations());
        }

        final list = _filterMode == 'unread'
            ? chat.conversations.where((c) => c.unreadCount > 0).toList()
            : chat.conversations;

        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.12),
                          AppColors.accentRed.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      _filterMode == 'unread'
                          ? Icons.mark_chat_read_rounded
                          : Icons.forum_rounded,
                      size: 42,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _filterMode == 'unread'
                        ? 'Không có tin nhắn chưa đọc'
                        : 'Chưa có cuộc trò chuyện nào',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _filterMode == 'unread'
                        ? 'Mọi tin nhắn của bạn đã được đọc.'
                        : 'Hãy kết bạn để bắt đầu nhắn tin — cuộc trò chuyện sẽ xuất hiện ở đây.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutralGray700,
                      height: 1.5,
                    ),
                  ),
                  if (_filterMode != 'unread') ...[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => _openSearchOverlay(context),
                      icon: const Icon(
                        Icons.person_search_rounded,
                        size: 18,
                      ),
                      label: const Text('Tìm bạn bè ngay'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm + 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () => chat.loadConversations(),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final conversation = list[index];
              return _buildConversationTile(conversation, t, isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String? error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.12),
                    AppColors.accentRed.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 42,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có cuộc trò chuyện nào',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kết bạn để bắt đầu nhắn tin — mọi cuộc trò chuyện sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutralGray700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _openSearchOverlay(context),
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Tìm bạn bè ngay'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Thử lại',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.neutralGray700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    Conversation conversation,
    AppLocalizations t,
    bool isDark,
  ) {
    final name = conversation.displayName;
    final lastMessage = conversation.lastMessage?.content ?? '';
    final unreadCount = conversation.unreadCount;
    final isGroup = conversation.type == 'group';
    final memberCount = conversation.participants.length;
    final isSelected = _selectedConversation?.id == conversation.id;
    final otherUserId = conversation.otherUserId;

    return InkWell(
      onTap: () => _onConversationTap(conversation),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.neutralGray300.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: conversation.displayAvatar.isEmpty
                        ? const LinearGradient(
                            colors: AppColors.chatBubbleMineGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        conversation.displayAvatar.isNotEmpty
                            ? NetworkImage(conversation.displayAvatar)
                            : null,
                    backgroundColor: Colors.transparent,
                    child: conversation.displayAvatar.isEmpty
                        ? Text(
                            _getInitials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
                if (isGroup)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.chatBubbleMineGradient,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          '$memberCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isGroup && otherUserId != null)
                  Selector<ChatProvider, bool>(
                    selector: (_, p) => p.isUserOnline(otherUserId),
                    builder: (_, isOnline, __) => isOnline
                        ? Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.creamWhite,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatConversationTime(conversation.updatedAt, t),
                        style: AppTypography.timestamp.copyWith(
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: unreadCount > 0
                              ? AppColors.primaryOrange
                              : AppColors.neutralGray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty
                              ? 'Chưa có tin nhắn nào'
                              : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: unreadCount > 0
                                ? AppColors.neutralBlack
                                : AppColors.neutralGray700,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        UnreadBadge(count: unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatConversationTime(DateTime updatedAt, AppLocalizations t) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${updatedAt.day}/${updatedAt.month}';
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 3 — MAIN CHAT (Glassmorphism trắng)
  // ════════════════════════════════════════════════════════════════
  Widget _buildWelcomePanel(AppLocalizations t, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.creamBackground,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: 0.18),
                      AppColors.accentRed.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  size: 56,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tin nhắn',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.neutralBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Chọn một cuộc trò chuyện để bắt đầu nhắn tin',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutralGray700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION (Mobile)
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamWhite,
        border: const Border(
          top: BorderSide(
            color: AppColors.neutralGray300,
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBrown.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildBottomNavItem(
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded,
                0,
                'Tin nhắn',
                isDark,
              ),
              _buildBottomNavItem(
                Icons.contacts_rounded,
                Icons.contacts_outlined,
                1,
                'Bạn bè',
                isDark,
              ),
              _buildBottomNavItem(
                Icons.auto_stories_rounded,
                Icons.auto_stories_outlined,
                2,
                'Bảng tin',
                isDark,
              ),
              _buildBottomNavItem(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                3,
                'Cá nhân',
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
    String label,
    bool isDark,
  ) {
    final isSelected = _selectedNavIndex == index;
    final activeColor = AppColors.primaryOrange;
    final inactiveColor = AppColors.neutralGray700;
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedNavIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrange.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Panel Cài đặt — hiển thị ở cột 2/3 của layout rộng khi người dùng
/// nhấn vào biểu tượng bánh răng ở sidebar trái.
class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.creamBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.creamWhite,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.neutralGray300,
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D7B4F35),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.appBarGradient,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'CÀI ĐẶT',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutralBlack,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: SettingsTab()),
        ],
      ),
    );
  }
}