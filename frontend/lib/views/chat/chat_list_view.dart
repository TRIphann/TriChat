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
/// HIGH-END CHAT LIST VIEW — Premium Messaging Screen
/// ════════════════════════════════════════════════════════════════
///
/// Design Language:
/// - Premium Editorial with warm cream tones
/// - Double-Bezel card architecture
/// - Soft diffused shadows
/// - Amber accent for CTAs
/// - Large squircle radii (24px+)

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => ChatListViewState();
}

class ChatListViewState extends State<ChatListView>
    with TickerProviderStateMixin {
  String _filterMode = 'all';
  int _selectedNavIndex = 0;
  Conversation? _selectedConversation;
  bool _coldStartCallHandled = false;
  bool _callScreenOpened = false;
  late CallProvider _callProvider;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  void switchTab(int index) {
    setState(() => _selectedNavIndex = index);
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      const hasPendingFeedbackEvaluation = true;
      if (hasPendingFeedbackEvaluation) {
        _showFeedbackFlow(context);
      }
    });

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
    _fadeController.dispose();
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
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
              body: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isWideScreen) {
                        return _buildWideLayout(t, isDark, isVeryWideScreen);
                      }
                      return _buildMobileView(t, isDark);
                    },
                  ),
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

    return Container(
      color: AppColors.darkPremiumBackground,
      child: Row(
        children: [
          _buildSidebar(ThemeData.dark()),
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
    return Container(
      color: AppColors.darkPremiumBackground,
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
  // PREMIUM SIDEBAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 86,
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          right: BorderSide(
            color: AppColors.darkPremiumBorder,
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
            0,
            Icons.forum_rounded,
            Icons.forum_outlined,
            tooltip: 'Tin nhắn',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSidebarItem(
            1,
            Icons.contacts_rounded,
            Icons.contacts_outlined,
            tooltip: 'Bạn bè',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSidebarItem(
            2,
            Icons.auto_stories_rounded,
            Icons.auto_stories_outlined,
            tooltip: 'Bảng tin',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSidebarItem(
            3,
            Icons.person_rounded,
            Icons.person_outline_rounded,
            tooltip: 'Cá nhân',
          ),
          const Spacer(),
          _buildSidebarItem(
            4,
            Icons.settings_rounded,
            Icons.settings_outlined,
            tooltip: 'Cài đặt',
            size: 46,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = firebaseUser?.displayName ?? 'U';
    final photo = firebaseUser?.photoURL ?? '';
    return TriAvatar(imageUrl: photo, name: name, size: 44);
  }

  Widget _buildSidebarItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon, {
    String? tooltip,
    double size = 46,
  }) {
    final isSelected = _selectedNavIndex == index;
    final color = isSelected
        ? AppColors.neonRoyal
        : AppColors.darkPremiumTextSecondary;
    final bg = isSelected
        ? AppColors.neonRoyal.withValues(alpha: 0.18)
        : Colors.transparent;
    final iconWidget = Icon(
      isSelected ? activeIcon : inactiveIcon,
      color: color,
      size: 22,
    );
    final Widget tap = GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
          _selectedConversation = null;
        });
      },
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: iconWidget,
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: tap) : tap;
  }

  // ════════════════════════════════════════════════════════════════
  // PREMIUM CHAT LIST PANEL
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
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        color: AppColors.darkPremiumSurface,
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      t.get('messages'),
                      style: AppTypography.headlineMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _buildHeaderIconButton(
                    Icons.search_rounded,
                    () => _openSearchOverlay(context),
                    theme,
                    isDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildHeaderIconButton(
                    Icons.qr_code_scanner_rounded,
                    () {},
                    theme,
                    isDark,
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
        color: isDark ? AppColors.darkCard : AppColors.creamWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
            width: 1,
          ),
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
                style: AppTypography.eyebrow.copyWith(
                  color: AppColors.primaryAmber,
                  letterSpacing: 1.5,
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
                  isDark,
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
                  isDark,
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
    ThemeData theme,
    bool isDark, {
    String? tooltip,
  }) {
    final btn = Material(
      color: isDark ? AppColors.darkElevated : AppColors.creamSurface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
          return _buildEmptyState(t, isDark);
        }

        return RefreshIndicator(
          color: AppColors.primaryAmber,
          onRefresh: () => chat.loadConversations(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

  Widget _buildEmptyState(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.darkElevated, AppColors.darkSurface]
                      : [AppColors.creamWhite, AppColors.creamSurface],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _filterMode == 'unread'
                    ? Icons.mark_chat_read_outlined
                    : Icons.chat_bubble_outline_rounded,
                size: 44,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _filterMode == 'unread'
                  ? 'Không có tin nhắn chưa đọc'
                  : 'Chưa có cuộc trò chuyện nào',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _filterMode == 'unread'
                  ? 'Mọi tin nhắn của bạn đã được đọc.'
                  : 'Hãy kết bạn để bắt đầu nhắn tin.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (_filterMode != 'unread') ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Tìm bạn bè ngay',
                icon: Icons.person_search_rounded,
                onPressed: () => _openSearchOverlay(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      String? error, VoidCallback onRetry, AppLocalizations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ErrorStateView(
      error: error,
      onRetry: onRetry,
      title: 'Lỗi tải cuộc trò chuyện',
      message: 'Vui lòng thử lại.',
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: AnimatedContainer(
        duration: AppCurves.durationNormal,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrangeLight.withValues(alpha: 0.45)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            onTap: () => _onConversationTap(conversation),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TriAvatar(
                        imageUrl: conversation.displayAvatar,
                        name: name,
                        size: 52,
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
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.success.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
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
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _formatConversationTime(conversation.updatedAt, t),
                              style: AppTypography.timestamp.copyWith(
                                color: unreadCount > 0
                                    ? AppColors.primaryAmber
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
                                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
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
          ),
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
  // PREMIUM BOTTOM NAVIGATION
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkPremiumBorder, width: 1),
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
              ),
              _buildBottomNavItem(
                Icons.people_rounded,
                Icons.people_outline_rounded,
                1,
                'Bạn bè',
              ),
              _buildBottomNavItem(
                Icons.auto_stories_rounded,
                Icons.auto_stories_outlined,
                2,
                'Bảng tin',
              ),
              _buildBottomNavItem(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                3,
                'Cá nhân',
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
  ) {
    final isSelected = _selectedNavIndex == index;
    final activeColor = AppColors.neonRoyal;
    final inactiveColor = AppColors.darkPremiumTextSecondary;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedNavIndex = index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppCurves.durationNormal,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? AppSpacing.md : 0,
                  vertical: isSelected ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.neonRoyal.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: color,
                  size: 24,
                ),
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

/// Premium Settings Panel
class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.cream,
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
              color: isDark ? AppColors.darkCard : AppColors.creamWhite,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryAmber, AppColors.accentWarm],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAmber.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.primaryAmber,
                    letterSpacing: 1.5,
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
