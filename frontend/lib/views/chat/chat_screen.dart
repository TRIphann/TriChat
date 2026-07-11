import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/geolocator.dart';
import 'package:frontend/services/permission_handler.dart';
import 'package:frontend/services/record.dart';
import 'package:frontend/services/file_helper.dart';
import '../../features/calling/screens/call_screen.dart';
import '../../models/call_model.dart';
import '../../models/chat/conversation.dart';
import '../../providers/call_provider.dart';
import '../../models/chat/message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/emoji_picker_widget.dart';
import 'group_info_screen.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';

// Re-export file_helper types for convenience
export 'package:frontend/services/file_helper.dart' show FileHelper;

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late ChatProvider _chatProvider;

  List<Message> _messages = [];
  bool _isLoading = true;
  final bool _showEmojiKeyboard = false;

  // Typing indicator
  bool _isTyping = false;
  String? _typingUserId;
  Timer? _typingTimer;

  // Reply
  Message? _replyToMessage;

  // Track IDs đã load từ history — không animate
  final Set<String> _historyIds = {};
  bool _historyLoaded = false;

  // Recording
  bool _isRecording = false;
  bool _isRecordingActionInProgress = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  late final AudioRecorder _audioRecorder;

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _historyIds.clear();
      _historyLoaded = false;
      _scrolledToUnread = false;
      _initialUnreadCount = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ChatProvider>().setConversationVisible(true);
        }
      });
    }
  }

  // Scroll tracking
  int _prevMessageCount = 0;
  bool _initialScrollDone = false;
  bool _showScrollToBottom = false;

  // Jump-to-reply: GlobalKey per message + highlight
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;

  // Unread tracking
  int _initialUnreadCount = 0;
  bool _scrolledToUnread = false;
  final GlobalKey _firstUnreadKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _setupScrollListener();
    _setupSignalR();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatProvider>().setConversationVisible(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final provider = context.read<ChatProvider>();
    if (state == AppLifecycleState.resumed) {
      provider.setConversationVisible(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      provider.setConversationVisible(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatProvider.setConversationVisible(false);
    Future.microtask(() => _chatProvider.closeConversation());
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final atBottom = _scrollController.offset <= 80;
      if (atBottom && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      } else if (!atBottom && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      }
    });
  }

  void _setupSignalR() {
    // ChatProvider handles all SignalR events
  }

  Future<void> _loadMessages() async {
    _scrollToBottom();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    final replyId = _replyToMessage?.id;
    setState(() => _replyToMessage = null);

    await context.read<ChatProvider>().sendMessage(
      content: content,
      replyToMessageId: replyId,
    );
    _scrollToBottom();
  }

  void _onTyping() {
    context.read<ChatProvider>().sendTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      context.read<ChatProvider>().sendTyping(false);
    });
  }

  Future<void> _jumpToMessage(String messageId) async {
    final key = _messageKeys[messageId];
    if (key?.currentContext == null) return;

    await Scrollable.ensureVisible(
      key!.currentContext!,
      alignment: 0.3,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    if (!mounted) return;
    setState(() => _highlightedMessageId = messageId);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _highlightedMessageId = null);
  }

  void _scrollToBottom({bool instant = false}) {
    if (!_scrollController.hasClients) return;
    if (instant) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      final newPosition = selection.start + emoji.length;

      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPosition),
      );
    } else {
      _messageController.text += emoji;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    _messages = chat.messages;
    _isTyping = chat.isOtherTyping;
    _typingUserId = chat.typingUserId;
    _isLoading = chat.messagesState == ChatLoadingState.loading;

    if (!_historyLoaded && chat.messagesState == ChatLoadingState.success) {
      _historyIds.addAll(_messages.map((m) => m.id));
      _initialUnreadCount = chat.openedWithUnreadCount;
      _historyLoaded = true;
    }

    if (_historyLoaded && !_scrolledToUnread && _messages.isNotEmpty) {
      _scrolledToUnread = true;
      if (_initialUnreadCount > 0 && _initialUnreadCount < _messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_firstUnreadKey.currentContext != null) {
            Scrollable.ensureVisible(
              _firstUnreadKey.currentContext!,
              alignment: 0.2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    final currentCount = _messages.length;
    if (currentCount > 0 &&
        (!_initialScrollDone || currentCount > _prevMessageCount)) {
      _prevMessageCount = currentCount;
      if (!_initialScrollDone) _initialScrollDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    if (_isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<ChatProvider>().setConversationVisible(false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.creamBackground,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            if ((chat.activeConversation ?? widget.conversation)
                    .pinnedMessageId !=
                null)
              _buildPinnedMessage(
                chat.activeConversation ?? widget.conversation,
              ),
            Expanded(
              child: Stack(
                children: [
                  _isLoading
                      ? const LoadingView()
                      : _buildMessageList(),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    right: 16,
                    bottom: _showScrollToBottom ? 12 : -56,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _showScrollToBottom ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x29000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryOrange,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_replyToMessage != null) _buildReplyPreview(),
            _buildInputArea(),
            if (_showEmojiKeyboard)
              EmojiPickerWidget(onEmojiSelected: _insertEmoji),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return TriAppBar(
      gradientColors: AppColors.appBarGradient,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        splashRadius: 22,
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleWidget: InkWell(
        onTap: _openConversationInfo,
        child: Selector<ChatProvider, bool>(
          selector: (_, p) =>
              widget.conversation.type == 'private' &&
              widget.conversation.otherUserId != null &&
              p.isUserOnline(widget.conversation.otherUserId!),
          builder: (_, isOnline, __) => Row(
            children: [
              TriAvatar(
                imageUrl: widget.conversation.displayAvatar,
                name: widget.conversation.displayName,
                size: 40,
                online: isOnline,
                elevated: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.displayName,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isOnline ? 'Đang hoạt động' : widget.conversation.displayStatus,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, color: Colors.white, size: 21),
          splashRadius: 22,
          onPressed: _startVoiceCall,
        ),
        IconButton(
          icon: const Icon(
            Icons.videocam_rounded,
            color: Colors.white,
            size: 23,
          ),
          splashRadius: 22,
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
          splashRadius: 22,
          onPressed: _openConversationInfo,
        ),
      ],
    );
  }

  Widget _buildPinnedMessage(Conversation conv) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhiteSoft,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.chatBubbleMineGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(
            Icons.push_pin_rounded,
            size: 14,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tin nhắn đã ghim',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conv.pinnedMessageContent ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutralBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _unpinMessage,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.neutralGray500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isTyping) {
      return EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chưa có tin nhắn nào',
        message: 'Gửi tin nhắn để bắt đầu cuộc trò chuyện',
      );
    }

    final totalItems = _messages.length + (_isTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (_isTyping && index == 0) {
          return const TypingIndicator(key: ValueKey('typing'));
        }

        final msgIndex = _messages.length - 1 - (_isTyping ? index - 1 : index);
        if (msgIndex < 0 || msgIndex >= _messages.length) {
          return const SizedBox.shrink();
        }

        final message = _messages[msgIndex];
        final prev = msgIndex > 0 ? _messages[msgIndex - 1] : null;
        final next = msgIndex < _messages.length - 1
            ? _messages[msgIndex + 1]
            : null;

        final sameAsPrev =
            prev != null &&
            prev.senderId == message.senderId &&
            message.createdAt.difference(prev.createdAt).inMinutes < 3;
        final sameAsNext =
            next != null &&
            next.senderId == message.senderId &&
            next.createdAt.difference(message.createdAt).inMinutes < 3;

        final isLastInGroup = !sameAsNext;
        final isFirstInGroup = !sameAsPrev;

        final showDateSeparator =
            prev == null ||
            prev.createdAt.day != message.createdAt.day ||
            prev.createdAt.month != message.createdAt.month ||
            prev.createdAt.year != message.createdAt.year;

        final msgKey = _messageKeys.putIfAbsent(message.id, () => GlobalKey());

        final replyToIsMine =
            message.replyToMessageId != null &&
            _messages.any((m) => m.id == message.replyToMessageId && m.isMine);

        final bubble = MessageBubble(
          key: msgKey,
          message: message,
          showAvatar: !message.isMine && isLastInGroup,
          showSenderName:
              !message.isMine &&
              isFirstInGroup &&
              widget.conversation.type == 'group',
          showMeta: isLastInGroup,
          isGroupTop: isFirstInGroup && sameAsNext,
          isGroupMiddle: sameAsPrev && sameAsNext,
          isGroupBottom: sameAsPrev && isLastInGroup,
          highlighted: _highlightedMessageId == message.id,
          replyToIsMine: replyToIsMine,
          onReplyPreviewTap: message.replyToMessageId != null
              ? () => _jumpToMessage(message.replyToMessageId!)
              : null,
          onReact: (emoji) => _reactToMessage(message.id, emoji),
          onPin: () async {
            try {
              await context.read<ChatProvider>().pinMessage(
                message.id,
                message.content,
              );
            } catch (_) {
              if (mounted) _showError('Không thể ghim tin nhắn');
            }
          },
          onReply: () => setState(() => _replyToMessage = message),
          onForward: () => _forwardMessage(message),
          onCopy: () => _copyMessage(message),
          onEdit: () => _editMessage(message),
          onDelete: () => _deleteMessage(message),
          onHideForMe: () =>
              context.read<ChatProvider>().hideMessageForMe(message.id),
          onInfo: () => _showMessageInfo(message),
          onRetry: () =>
              context.read<ChatProvider>().retrySendMessage(message.id),
        );

        final isNew = !_historyIds.contains(message.id);
        final bubbleWidget = isNew
            ? _AnimatedBubble(isMine: message.isMine, child: bubble)
            : bubble;

        final isFirstUnread =
            _initialUnreadCount > 0 &&
            msgIndex == _messages.length - _initialUnreadCount;

        return Column(
          key: isFirstUnread ? _firstUnreadKey : ValueKey(message.id),
          children: [
            if (showDateSeparator) _buildDateSeparator(message.createdAt),
            if (isFirstUnread) _buildUnreadDivider(_initialUnreadCount),
            _SwipeToReplyWrapper(
              isMine: message.isMine,
              onReply: () => setState(() => _replyToMessage = message),
              child: bubbleWidget,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnreadDivider(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.red.shade300, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$count tin nhắn chưa đọc',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.red.shade300, thickness: 0.8)),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            _formatDate(date),
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhiteSoft,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.chatBubbleMineGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trả lời ${_replyToMessage!.senderName}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _replyToMessage!.content,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutralGray700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyToMessage = null),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.neutralGray500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    if (_isRecording) {
      return _buildRecordingInputArea();
    }
    final hasText = _messageController.text.trim().isNotEmpty;
    final iconColor = AppColors.neutralGray700;

    Widget iconBtn(IconData icon, VoidCallback onTap, {double size = 22}) =>
        IconCircleButton(
          icon: icon,
          onPressed: onTap,
          color: iconColor,
          size: 38,
          iconSize: size,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        border: Border(
          top: BorderSide(
            color: AppColors.neutralGray300.withValues(alpha: 0.6),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBrown.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              iconBtn(
                Icons.add_circle_outline_rounded,
                _showAttachmentOptions,
                size: 26,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 42,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.creamWhite,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: AppColors.neutralGray300.withValues(alpha: 0.7),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          onChanged: (_) {
                            _onTyping();
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Aa',
                            hintStyle: TextStyle(
                              color: AppColors.neutralGray500,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            isDense: true,
                          ),
                          style: AppTypography.messageBody,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 4),
                        child: InkWell(
                          onTap: _showEmojiPicker,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.emoji_emotions_outlined,
                              color: AppColors.neutralGray500,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (hasText)
                _SendButton(onPressed: _sendMessage)
              else ...[
                iconBtn(Icons.image_outlined, _pickImageFromGallery, size: 23),
                iconBtn(Icons.mic_none_rounded, _recordAudio, size: 23),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hôm nay';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  color: Colors.purple,
                  onTap: _pickImageFromGallery,
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: _pickImageFromCamera,
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.orange,
                  onTap: _pickVideo,
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Tệp',
                  color: Colors.blue,
                  onTap: _pickFile,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.mic,
                  label: 'Ghi âm',
                  color: Colors.green,
                  onTap: _recordAudio,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Vị trí',
                  color: Colors.teal,
                  onTap: _shareLocation,
                ),
                _buildAttachmentOption(
                  icon: Icons.person,
                  label: 'Danh bạ',
                  color: Colors.indigo,
                  onTap: _shareContact,
                ),
                _buildAttachmentOption(
                  icon: Icons.emoji_emotions,
                  label: 'Sticker',
                  color: Colors.amber,
                  onTap: _showStickerPicker,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  void _openConversationInfo() {
    if (widget.conversation.type == 'group') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupInfoScreen(conversation: widget.conversation),
        ),
      );
    }
  }

  void _startVideoCall() => _startCall(isVideo: true);
  void _startVoiceCall() => _startCall(isVideo: false);

  Future<void> _startCall({required bool isVideo}) async {
    final conv = widget.conversation;
    final otherUserId = conv.otherUserId;
    if (otherUserId == null) return;

    final chatProvider = context.read<ChatProvider>();
    final callProvider = context.read<CallProvider>();
    final myUid = chatProvider.currentUid ?? '';

    final call = CallModel(
      conversationId: conv.id,
      callerId: myUid,
      calleeId: otherUserId,
      remoteName: conv.displayName,
      remoteAvatar: conv.displayAvatar,
      isVideo: isVideo,
      isIncoming: false,
      status: CallStatus.dialing,
    );

    final me = conv.participants.where((p) => p.userId == myUid).firstOrNull;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final myName = [
      me?.displayName,
      chatProvider.cachedSenderName,
      firebaseUser?.displayName,
      firebaseUser?.email?.split('@').first,
      myUid,
    ].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => myUid)!;
    final myAvatar = me?.avatar ?? chatProvider.cachedSenderAvatar ?? '';

    await chatProvider.initiateCall(
      conversationId: conv.id,
      calleeId: otherUserId,
      callType: isVideo ? 'video' : 'voice',
      callerName: myName,
      callerAvatar: myAvatar,
    );

    callProvider.startOutgoingCall(call);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CallScreen(call: call),
      ),
    );
  }

  void _unpinMessage() {
    context.read<ChatProvider>().unpinMessage().catchError((error) {
      if (mounted) _showError('Không thể bỏ ghim tin nhắn');
    });
  }

  void _reactToMessage(String messageId, String emoji) {
    context.read<ChatProvider>().reactToMessage(messageId, emoji);
  }

  void _forwardMessage(Message message) {
    _showInfo('Tính năng chuyển tiếp đang được phát triển');
  }

  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    _showInfo('Đã sao chép');
  }

  void _editMessage(Message message) {
    _messageController.text = message.content;
    _focusNode.requestFocus();
  }

  void _deleteMessage(Message message) {
    context.read<ChatProvider>().deleteMessage(message.id);
  }

  void _showMessageInfo(Message message) {
    _showInfo('Tính năng đánh dấu tin nhắn đang được phát triển');
  }

  void _showEmojiPicker() {
    _showInfo('Tính năng emoji picker đang được phát triển');
  }

  void _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      if (kIsWeb) {
        // Read bytes directly for web
        final bytes = await image.readAsBytes();
        if (mounted) {
          _sendImageWithBytes(image.name, bytes);
        }
      } else {
        final file = FileHelper.createFile(image.path);
        final bytes = await file.readAsBytes();
        _sendImageWithBytes(image.name, bytes);
      }
    }
  }

  void _pickImageFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      if (kIsWeb) {
        if (mounted) {
          _showInfo('Chụp ảnh từ web chưa hỗ trợ — vui lòng chọn từ thư viện');
        }
      } else {
        final file = FileHelper.createFile(image.path);
        final bytes = await file.readAsBytes();
        _sendImageWithBytes(image.name, bytes);
      }
    }
  }

  void _sendImageWithBytes(String fileName, List<int> bytes) {
    _showInfo('Đang gửi hình ảnh...');
    context
        .read<ChatProvider>()
        .sendImageMessage(fileName, bytes, fileName)
        .then((_) {
          _scrollToBottom();
        })
        .catchError((error) {
          if (mounted) _showError('Không thể gửi hình ảnh');
        });
  }

  void _sendImage(dynamic imageFile) {
    // Legacy method - redirect to bytes version
  }

  void _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      if (kIsWeb) {
        _showInfo('Video từ web đang được phát triển');
      } else {
        _showInfo('Đang gửi video...');
      }
    }
  }

  void _pickFile() async {
    _showInfo('Tính năng chọn tệp đang được phát triển');
  }

  Widget _buildRecordingInputArea() {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 26,
                ),
                onPressed: _cancelRecording,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.creamWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.neutralGray300.withValues(alpha: 0.7),
                      width: 0.6,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const _FlashingRedDot(),
                      const SizedBox(width: 8),
                      Text(
                        'Đang ghi âm...',
                        style: TextStyle(
                          color: AppColors.neutralGray700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _stopAndSendRecording,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_isRecordingActionInProgress) return;
    _isRecordingActionInProgress = true;
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showError(
          'Ứng dụng cần quyền sử dụng microphone để ghi âm tin nhắn thoại.',
        );
        return;
      }

      String? path;
      if (!kIsWeb) {
        final tempDir = await FileHelper.getTempDirectory();
        path = '$tempDir/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      if (await _audioRecorder.hasPermission()) {
        final effectivePath = kIsWeb
            ? 'audio_${DateTime.now().millisecondsSinceEpoch}.webm'
            : path!;
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: effectivePath,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration++;
            });
            if (_recordingDuration >= 300) {
              _stopAndSendRecording();
            }
          }
        });
      } else {
        throw Exception('Thiếu quyền truy cập microphone trên thiết bị.');
      }
    } catch (_) {
      _showError('Không thể khởi động ghi âm');
    } finally {
      _isRecordingActionInProgress = false;
    }
  }

  Future<void> _cancelRecording() async {
    if (_isRecordingActionInProgress) return;
    _isRecordingActionInProgress = true;
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();
      if (path != null && !kIsWeb) {
        await FileHelper.deleteFile(path);
      }
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });
      _showInfo('Đã hủy ghi âm.');
    } catch (_) {
      _showInfo('Đã hủy ghi âm.');
    } finally {
      _isRecordingActionInProgress = false;
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (_isRecordingActionInProgress) return;
    _isRecordingActionInProgress = true;
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();

      final finalDuration = _recordingDuration;
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });

      if (path != null && finalDuration > 0) {
        if (kIsWeb) {
          if (mounted) {
            _showInfo('Gửi tin nhắn thoại từ web đang được phát triển');
          }
        } else {
          final file = FileHelper.createFile(path);
          if (file != null) {
            if (!mounted) return;
            final bytes = await file.readAsBytes();
            final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
            await context.read<ChatProvider>().sendAudioMessage(
              path,
              bytes,
              finalDuration,
              fileName: fileName,
            );
            _scrollToBottom();
          }
        }
      }
    } catch (_) {
      _showError('Lỗi khi lưu hoặc gửi file ghi âm');
    } finally {
      _isRecordingActionInProgress = false;
    }
  }

  void _recordAudio() {
    if (_isRecordingActionInProgress) return;
    if (_isRecording) {
      _stopAndSendRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _shareLocation() async {
    if (kIsWeb) {
      _showInfo('Chia sẻ vị trí từ web đang được phát triển');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showError('Bạn chưa cấp quyền vị trí');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        _showError(
          'Quyền vị trí bị từ chối vĩnh viễn. Vào cài đặt để bật lại.',
        );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Đang lấy vị trí...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      Navigator.pop(context);

      await context.read<ChatProvider>().sendMessage(
        content: 'Đã chia sẻ vị trí',
        type: 'location',
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError('Không thể lấy vị trí: $e');
    }
  }

  void _shareContact() {
    _showInfo('Tính năng chia sẻ danh bạ đang được phát triển');
  }

  void _showStickerPicker() {
    _showInfo('Tính năng sticker đang được phát triển');
  }

  void _showError(String message) {
    showTriSnack(
      context,
      message,
      type: TriSnackType.error,
      icon: Icons.error_outline_rounded,
    );
  }

  void _showSuccess(String message) {
    showTriSnack(
      context,
      message,
      type: TriSnackType.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  void _showInfo(String message) {
    showTriSnack(
      context,
      message,
      type: TriSnackType.info,
      icon: Icons.info_outline_rounded,
      duration: const Duration(seconds: 2),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.chatBubbleMineGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool isMine;
  final VoidCallback? onReply;

  const _SwipeToReplyWrapper({
    required this.child,
    required this.isMine,
    this.onReply,
  });

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  double _offset = 0;
  bool _triggered = false;
  late final AnimationController _ctrl;
  Animation<double>? _returnAnim;

  static const double _threshold = 56;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ctrl.addListener(() {
      if (mounted && _returnAnim != null) {
        setState(() => _offset = _returnAnim!.value);
      }
    });
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _offset = 0;
          _triggered = false;
          _returnAnim = null;
        });
        _ctrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_ctrl.isAnimating) return;
    final dx = d.delta.dx;
    if (widget.isMine && dx > 0) return;
    if (!widget.isMine && dx < 0) return;

    setState(() {
      _offset += dx;
      final max = _threshold * 1.3;
      _offset = widget.isMine ? _offset.clamp(-max, 0) : _offset.clamp(0, max);
    });

    if (_offset.abs() >= _threshold && !_triggered) {
      _triggered = true;
      HapticFeedback.mediumImpact();
      widget.onReply?.call();
    }
  }

  void _onEnd(DragEndDetails _) {
    _returnAnim = Tween<double>(
      begin: _offset,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_offset.abs() / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: widget.isMine ? null : 10,
            right: widget.isMine ? 10 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + 0.5 * progress,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_offset, 0), child: widget.child),
        ],
      ),
    );
  }
}

class _AnimatedBubble extends StatefulWidget {
  final Widget child;
  final bool isMine;

  const _AnimatedBubble({required this.child, required this.isMine});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _slide = Tween<Offset>(
      begin: Offset(widget.isMine ? 0.25 : -0.25, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

class _FlashingRedDot extends StatefulWidget {
  const _FlashingRedDot();

  @override
  State<_FlashingRedDot> createState() => _FlashingRedDotState();
}

class _FlashingRedDotState extends State<_FlashingRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
