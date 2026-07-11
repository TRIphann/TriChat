import 'package:flutter/material.dart';
import 'package:frontend/widgets/location_message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/chat/message.dart';
import '../../providers/chat_provider.dart';
import 'fullscreen_image_viewer.dart';
import 'audio_message_player.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool showSenderName;
  final bool showMeta;
  final bool isGroupTop;
  final bool isGroupMiddle;
  final bool isGroupBottom;
  final bool highlighted;
  final bool replyToIsMine; // true → hiện "Tôi" thay vì tên gửi
  final VoidCallback? onReplyPreviewTap;
  final Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final Future<void> Function()? onPin;
  final VoidCallback? onDelete; // Gỡ tin cho tất cả (sender only)
  final VoidCallback? onHideForMe; // Xóa ở phía mình (bất kỳ ai)
  final VoidCallback? onInfo;
  final VoidCallback? onRetry; // Gửi lại tin nhắn lỗi (status == 'failed')

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showSenderName = false,
    this.showMeta = true,
    this.isGroupTop = false,
    this.isGroupMiddle = false,
    this.isGroupBottom = false,
    this.highlighted = false,
    this.replyToIsMine = false,
    this.onReplyPreviewTap,
    this.onReact,
    this.onReply,
    this.onForward,
    this.onCopy,
    this.onEdit,
    this.onPin,
    this.onDelete,
    this.onHideForMe,
    this.onInfo,
    this.onRetry,
  });

  static const _zaloBlue = AppColors.primaryOrange;
  static const _receivedBg = AppColors.chatBubbleTheirs;
  static const _receivedBorder = AppColors.chatBubbleBorder;

  @override
  Widget build(BuildContext context) {
    // Spacing dày hơn khi bắt đầu nhóm mới, mỏng khi cùng nhóm
    final topPad = (isGroupBottom || isGroupMiddle) ? 1.0 : 6.0;
    final bottomPad = showMeta ? 1.0 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryOrange.withValues(alpha: 0.10)
            : Colors.transparent,
      ),
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md - 2,
            topPad,
            AppSpacing.md - 2,
            bottomPad,
          ),
          child: Row(
            mainAxisAlignment: message.isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isMine) ...[
                // Avatar chỉ hiện ở tin CUỐI nhóm
                showAvatar ? _buildAvatar() : const SizedBox(width: 30),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: message.isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!message.isMine && showSenderName)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 6,
                          bottom: 3,
                        ),
                        child: Text(
                          message.senderName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.neutralGray700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    _buildBubble(),
                    if (showMeta) ...[
                      const SizedBox(height: 3),
                      _buildMetaRow(),
                    ],
                    if (message.reactions != null &&
                        message.reactions!.isNotEmpty)
                      _buildReactions(),
                  ],
                ),
              ),
              if (message.isMine) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFCCCCCC),
      backgroundImage: message.senderAvatar.isNotEmpty
          ? NetworkImage(message.senderAvatar)
          : null,
      child: message.senderAvatar.isEmpty
          ? Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildBubble() {
    final isMine = message.isMine;

    const r = Radius.circular(AppRadius.xl);
    const rTail = Radius.circular(4);
    const rMid = Radius.circular(6);
    // Zalo: góc nhọn hơn ở cạnh "đuôi" (gần avatar), góc tròn ở cạnh xa
    final radius = isMine
        ? BorderRadius.only(
            topLeft: r,
            topRight: (isGroupBottom || isGroupMiddle) ? rMid : r,
            bottomLeft: r,
            bottomRight: (isGroupTop || isGroupMiddle) ? rMid : rTail,
          )
        : BorderRadius.only(
            topLeft: (isGroupBottom || isGroupMiddle) ? rMid : r,
            topRight: r,
            bottomLeft: (isGroupTop || isGroupMiddle) ? rMid : rTail,
            bottomRight: r,
          );

    if (message.isDeleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.neutralGray100,
          borderRadius: radius,
          border: Border.all(color: AppColors.neutralGray300, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_circle_outline_rounded,
              size: 14,
              color: AppColors.neutralGray500,
            ),
            const SizedBox(width: 5),
            Text(
              'Tin nhắn đã được thu hồi',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutralGray700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (message.type == 'location') {
      return Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyToMessageId != null) _buildReplyPreview(),
          LocationMessageBubble(
            latitude: message.latitude ?? 0,
            longitude: message.longitude ?? 0,
            address: message.address,
            isMine: isMine,
            senderName: isMine ? 'Bạn' : message.senderName,
          ),
        ],
      );
    }

    final isMediaOrSticker = message.type == 'image' ||
        message.type == 'video' ||
        message.type == 'sticker';

    final mineGradient = const LinearGradient(
      colors: AppColors.chatBubbleMineGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        color: isMediaOrSticker
            ? Colors.transparent
            : (isMine ? null : _receivedBg),
        gradient: isMediaOrSticker || !isMine ? null : mineGradient,
        borderRadius: radius,
        border: isMediaOrSticker
            ? null
            : (isMine
                ? null
                : Border.all(color: _receivedBorder, width: 0.5)),
        boxShadow: isMediaOrSticker
            ? null
            : [
                if (isMine)
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyToMessageId != null) _buildReplyPreview(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case 'image':
        return _buildImageContent();
      case 'video':
        return _buildVideoContent();
      case 'audio':
        return _buildAudioContent();
      case 'file':
        return _buildFileContent();
      case 'sticker':
        return _buildStickerContent();
      case 'call':
        return _buildCallContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.content,
        style: AppTypography.messageBody.copyWith(
          color: message.isMine ? Colors.white : AppColors.neutralBlack,
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final hasRemote = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
    final hasLocal = message.localFilePath != null;

    Widget image;
    if (hasRemote) {
      image = Image.network(
        message.mediaUrl!,
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 180,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else if (hasLocal) {
      // Đang upload/gửi — hiện ảnh local ngay, chưa cần URL từ Cloudinary
      // On web, localFilePath is a blob URL or data URL
      image = Stack(
        children: [
          Image.network(
            message.localFilePath!,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 220,
              height: 180,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          if (message.status == 'sending')
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      image = Container(
        width: 220,
        height: 180,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return Builder(
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: !hasRemote
              ? null
              : () {
                  final chatProvider = context.read<ChatProvider>();
                  final imageMessages = chatProvider.messages
                      .where((m) =>
                          m.type == 'image' &&
                          m.mediaUrl != null &&
                          m.mediaUrl!.isNotEmpty)
                      .toList();

                  final imageUrls = imageMessages.map((m) => m.mediaUrl!).toList();
                  int initialIndex = imageMessages.indexWhere((m) => m.id == message.id);
                  if (initialIndex == -1) {
                    imageUrls.insert(0, message.mediaUrl!);
                    initialIndex = 0;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => FullscreenImageViewer(
                        imageUrls: imageUrls,
                        initialIndex: initialIndex,
                      ),
                    ),
                  );
                },
          child: image,
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 220,
            height: 180,
            color: Colors.grey[300],
            child: message.thumbnailUrl != null
                ? Image.network(message.thumbnailUrl!, fit: BoxFit.cover)
                : const Icon(Icons.videocam, size: 48, color: Colors.grey),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildAudioContent() {
    final hasRemote = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
    final hasLocal = message.localFilePath != null;

    if (hasRemote) {
      return AudioMessagePlayer(
        audioUrl: message.mediaUrl!,
        durationSeconds: message.duration,
        isMine: message.isMine,
      );
    } else if (hasLocal && message.status == 'sending') {
      final iconColor = message.isMine ? Colors.white : _zaloBlue;
      final textColor = message.isMine ? Colors.white : Colors.black87;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Đang gửi ghi âm...',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      final iconColor = message.isMine ? Colors.white : _zaloBlue;
      final textColor = message.isMine ? Colors.white : Colors.black87;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(
              'Ghi âm không khả dụng',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFileContent() {
    final iconBg = message.isMine
        ? Colors.white.withValues(alpha: 0.2)
        : _zaloBlue.withValues(alpha: 0.1);
    final iconColor = message.isMine ? Colors.white : _zaloBlue;
    final textColor = message.isMine ? Colors.white : Colors.black87;
    final subColor = message.isMine ? Colors.white70 : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Tệp đính kèm',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(
                    _formatFileSize(message.fileSize!),
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    final isMissed =
        message.content.contains('nhỡ') || message.content.contains('từ chối');
    final isVideo = message.content.contains('video');

    // Sender (nền xanh): trắng cho tất cả — đỏ không đọc được trên nền xanh
    // Receiver (nền xám): đỏ cho nhỡ/từ chối, xanh cho bình thường
    final Color iconColor;
    final Color textColor;
    if (message.isMine) {
      iconColor = Colors.white;
      textColor = Colors.white;
    } else {
      iconColor = isMissed ? Colors.red.shade400 : _zaloBlue;
      textColor = isMissed ? Colors.red.shade400 : AppColors.neutralBlack;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerContent() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Image.network(
        message.mediaUrl ?? '',
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 100, height: 100),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return GestureDetector(
      onTap: onReplyPreviewTap,
      child: _buildReplyPreviewContent(),
    );
  }

  Widget _buildReplyPreviewContent() {
    // Sender (xanh): preview nền trắng mờ, viền trắng
    // Receiver (xám): preview nền trắng nhạt, viền xanh
    final bgColor = message.isMine
        ? Colors.white.withValues(alpha: 0.22)
        : AppColors.primaryOrangePale;
    final borderColor = message.isMine ? Colors.white60 : _zaloBlue;
    final nameColor = message.isMine ? Colors.white : _zaloBlue;
    final bodyColor = message.isMine ? Colors.white70 : AppColors.neutralGray700;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToIsMine ? 'Tôi' : (message.replyToSenderName ?? ''),
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            style: AppTypography.bodySmall.copyWith(color: bodyColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Padding(
      padding: EdgeInsets.only(
        left: message.isMine ? 0 : 4,
        right: message.isMine ? 4 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(message.createdAt),
            style: AppTypography.messageMeta.copyWith(
              color: AppColors.neutralGray500,
            ),
          ),
          if (message.isMine) ...[
            const SizedBox(width: 3),
            _buildStatusIcon(),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '• đã sửa',
              style: AppTypography.messageMeta.copyWith(
                color: AppColors.neutralGray500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case 'read':
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: _zaloBlue,
        );
      case 'delivered':
        return Icon(
          Icons.done_all_rounded,
          size: 13,
          color: AppColors.neutralGray500,
        );
      case 'sending':
        return Icon(
          Icons.access_time_rounded,
          size: 12,
          color: AppColors.neutralGray500,
        );
      case 'failed':
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(
            Icons.error_outline_rounded,
            size: 13,
            color: AppColors.error,
          ),
        );
      default:
        return Icon(
          Icons.done_rounded,
          size: 13,
          color: AppColors.neutralGray500,
        );
    }
  }

  Widget _buildReactions() {
    return Container(
      margin: EdgeInsets.only(
        top: 4,
        left: message.isMine ? 0 : 4,
        right: message.isMine ? 4 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.neutralGray300.withValues(alpha: 0.6),
          width: 0.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: message.reactions!.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(e.key, style: const TextStyle(fontSize: 13)),
                if (e.value.length > 1)
                  Text(
                    ' ${e.value.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        decoration: BoxDecoration(
          color: AppColors.creamWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.neutralGray300.withValues(alpha: 0.7),
              width: 0.6,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBrown.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.neutralGray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick reactions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '😂', '😮', '😢', '😡'].map((e) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReact?.call(e);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutralGray100,
                      ),
                      child: Center(
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _actionTile(Icons.reply_rounded, 'Trả lời', () {
              Navigator.pop(context);
              onReply?.call();
            }),
            _actionTile(Icons.push_pin_outlined, 'Ghim tin nhắn', () async {
              Navigator.pop(context);
              await onPin?.call();
            }),
            _actionTile(Icons.copy_rounded, 'Sao chép', () {
              Navigator.pop(context);
              onCopy?.call();
            }),
            _actionTile(Icons.shortcut_rounded, 'Chuyển tiếp', () {
              Navigator.pop(context);
              onForward?.call();
            }),
            if (message.isMine && message.type == 'text')
              _actionTile(Icons.edit_rounded, 'Chỉnh sửa', () {
                Navigator.pop(context);
                onEdit?.call();
              }),
            _actionTile(Icons.info_outline_rounded, 'Thông tin', () {
              Navigator.pop(context);
              onInfo?.call();
            }),
            Divider(height: 1, color: Colors.grey[200]),
            _actionTile(Icons.delete_outline_rounded, 'Xóa ở phía bạn', () {
              Navigator.pop(context);
              onHideForMe?.call();
            }, color: Colors.red),
            if (message.isMine && !message.isDeleted)
              _actionTile(
                Icons.remove_circle_outline_rounded,
                'Thu hồi tin nhắn',
                () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
                color: Colors.red,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? AppColors.neutralBlack;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: AppSpacing.lg),
            Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
