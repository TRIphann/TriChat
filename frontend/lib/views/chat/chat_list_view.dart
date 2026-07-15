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
/// ChatListView — TriChat (Minimalist Black & White)
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
    final extra = event.extra!;
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
    final extra = event.extra!;
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (isWideScreen) {
                      return _buildWideLayout(t, isDark, isVeryWideScreen);
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

  Widget _buildWideLayout(
    AppLocalizations t,
    bool isDark,
    bool isVeryWideScreen,
  ) {
    if (_selectedNavIndex == 0) {
      return UltraDarkChatLayout(
        t: t,
        currentNavIndex: _selectedNavIndex,
        onNavTap: (i) => setState(() => _selectedNavIndex = i),
      );
    }

    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          _buildSidebar(theme),
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

  Widget _buildMobileView(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
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
          _buildBottomNavigation(theme),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 1 — SIDEBAR (Minimalist — đơn sắc đen)
  // ════════════════════════════════════════════════════════════════
  Widget _buildSidebar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.neutralBlack;
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.neutralGray800,
            width: 1,
          ),
        ),
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
            theme,
            tooltip: 'Tin nhắn',
          ),
          _buildSidebarItem(
            Icons.people_rounded,
            Icons.people_outline_rounded,
            1,
            theme,
            tooltip: 'Bạn bè',
          ),
          _buildSidebarItem(
            Icons.auto_stories_rounded,
            Icons.auto_stories_outlined,
            2,
            theme,
            tooltip: 'Bảng tin',
          ),
          _buildSidebarItem(
            Icons.person_rounded,
            Icons.person_outline_rounded,
            3,
            theme,
            tooltip: 'Cá nhân',
          ),
          const Spacer(),
          _buildSidebarItem(
            Icons.settings_rounded,
            Icons.settings_outlined,
            4,
            theme,
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
    return TriAvatar(
      imageUrl: avatarUrl,
      name: displayName,
      size: 44,
    );
  }

  Widget _buildSidebarItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
    ThemeData theme, {
    String? tooltip,
  }) {
    final isSelected = _selectedNavIndex == index;
    final Widget item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neutralGray800 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: AppColors.neutralWhite,
                    borderRadius: BorderRadius.circular(1),
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
                    ? AppColors.neutralWhite
                    : AppColors.neutralGray400,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip, child: item) : item;
  }

  // ════════════════════════════════════════════════════════════════
  // CỘT 2 — LIST
  // ════════════════════════════════════════════════════════════════
  Widget _buildChatListPanel(AppLocalizations t, bool isDark) {
    return Column(
      children: [
        _buildSearchHeader(t, isDark, isMobile: true),
        Expanded(child: _buildConversationList(t, isDark)),
      ],
    );
  }

  Widget _buildSearchHeader(
    AppLocalizations t,
    bool isDark, {
    bool isMobile = false,
  }) {
    final theme = Theme.of(context);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 1),
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
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      t.get('messages'),
                      style: AppTypography.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  _buildHeaderIconButton(
                    Icons.search_rounded,
                    () => _openSearchOverlay(context),
                    theme,
                  ),
                  _buildHeaderIconButton(
                    Icons.qr_code_scanner_rounded,
                    () {},
                    theme,
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.md,
              ),
              child: Text(
                t.get('messages').toString().toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 12,
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
                  Icons.person_add_alt_1_outlined,
                  () {},
                  theme,
                  tooltip: 'Thêm bạn',
                ),
                _buildHeaderIconButton(
                  Icons.group_add_outlined,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const NewConversationScreen(type: 'group'),
                    ),
                  ),
                  theme,
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
    VoidCallback onTap,
    ThemeData theme, {
    Color? iconColor,
    String? tooltip,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onSurface,
            size: 18,
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

  Widget _buildFilterTabs(AppLocalizations t, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 44,
      child: Row(
        children: [
          _buildFilterTab(t.get('all'), 'all', theme),
          _buildFilterTab(t.get('unread'), 'unread', theme),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, ThemeData theme) {
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
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.hintColor,
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
          return _buildErrorState(
              chat.errorMessage, () => chat.loadConversations(), t);
        }

        final list = _filterMode == 'unread'
            ? chat.conversations.where((c) => c.unreadCount > 0).toList()
            : chat.conversations;

        if (list.isEmpty) {
          return _buildEmptyState(t);
        }

        return RefreshIndicator(
          color: AppColors.neutralBlack,
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

  Widget _buildEmptyState(AppLocalizations t) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                _filterMode == 'unread'
                    ? Icons.mark_chat_read_outlined
                    : Icons.chat_bubble_outline_rounded,
                size: 36,
                color: theme.colorScheme.onSurface,
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _filterMode == 'unread'
                  ? 'Mọi tin nhắn của bạn đã được đọc.'
                  : 'Hãy kết bạn để bắt đầu nhắn tin — cuộc trò chuyện sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
            if (_filterMode != 'unread') ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 44,
                child: PrimaryButton(
                  label: 'Tìm bạn bè ngay',
                  icon: Icons.person_search_rounded,
                  onPressed: () => _openSearchOverlay(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      String? error, VoidCallback onRetry, AppLocalizations t) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorLight,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Bắt đầu cuộc trò chuyện mới',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kết bạn để bắt đầu nhắn tin — mọi cuộc trò chuyện sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 44,
              child: PrimaryButton(
                label: 'Tìm bạn bè ngay',
                icon: Icons.person_search_rounded,
                onPressed: () => _openSearchOverlay(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Thử lại',
                style: AppTypography.labelMedium.copyWith(
                  color: theme.hintColor,
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
    final theme = Theme.of(context);
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
              ? (isDark ? AppColors.darkCard : AppColors.neutralGray100)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
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
                TriAvatar(
                  imageUrl: conversation.displayAvatar,
                  name: name,
                  size: 48,
                  overlayCount: isGroup ? memberCount : null,
                ),
                if (!isGroup && otherUserId != null)
                  Selector<ChatProvider, bool>(
                    selector: (_, p) => p.isUserOnline(otherUserId),
                    builder: (_, isOnline, __) => isOnline
                        ? Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
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
                            color: theme.colorScheme.onSurface,
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
                              ? theme.colorScheme.onSurface
                              : theme.hintColor,
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
                                ? theme.colorScheme.onSurface
                                : theme.hintColor,
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

  Widget _buildWelcomePanel(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
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
                  color: theme.brightness == Brightness.dark
                      ? AppColors.darkCard
                      : AppColors.neutralGray100,
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tin nhắn',
                style: AppTypography.headlineMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Chọn một cuộc trò chuyện để bắt đầu nhắn tin',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.hintColor,
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
  // BOTTOM NAVIGATION (Mobile) — Minimalist
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
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
                theme,
              ),
              _buildBottomNavItem(
                Icons.people_rounded,
                Icons.people_outline_rounded,
                1,
                'Bạn bè',
                theme,
              ),
              _buildBottomNavItem(
                Icons.auto_stories_rounded,
                Icons.auto_stories_outlined,
                2,
                'Bảng tin',
                theme,
              ),
              _buildBottomNavItem(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                3,
                'Cá nhân',
                theme,
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
    ThemeData theme,
  ) {
    final isSelected = _selectedNavIndex == index;
    final activeColor = AppColors.neutralBlack;
    final inactiveColor = theme.hintColor;
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedNavIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

/// Panel Cài đặt — hiển thị ở cột 2/3 của layout rộng.
class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.neutralBlack,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'CÀI ĐẶT',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
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
