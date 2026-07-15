import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/widgets/emoji_picker_widget.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../providers/feed_provider.dart';

class CommentSheet extends StatefulWidget {
  final PostModel post;
  final bool useProfileProvider;

  const CommentSheet({
    super.key,
    required this.post,
    this.useProfileProvider = false,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  XFile? _selectedImage;
  bool _isSending = false;
  bool _showEmojiKeyboard = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.useProfileProvider) {
        context.read<ProfileProvider>().fetchComments(widget.post.id);
      } else {
        context.read<FeedProvider>().fetchComments(widget.post.id);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() {
      _isSending = true;
    });

    final comment = widget.useProfileProvider
        ? await context.read<ProfileProvider>().addComment(
            widget.post.id,
            text,
            _selectedImage,
          )
        : await context.read<FeedProvider>().addComment(
            widget.post.id,
            text,
            _selectedImage,
          );

    setState(() {
      _isSending = false;
    });

    if (comment != null) {
      _commentController.clear();
      _removeSelectedImage();
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi bình luận, vui lòng thử lại')),
      );
    }
  }

  void _insertEmoji(String emoji) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      final newPosition = selection.start + emoji.length;
      
      _commentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPosition),
      );
    } else {
      _commentController.text += emoji;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78 + keyboardHeight,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle với title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.1),
                        AppColors.primaryBlue.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.forum_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bình luận',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: widget.useProfileProvider
                ? Consumer<ProfileProvider>(
                    builder: (context, provider, _) {
                      final comments = provider.getCommentsForPost(widget.post.id);

                      if (provider.isLoading && comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đang tải bình luận...',
                                style: TextStyle(
                                  color: AppColors.neutralGray700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (comments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryBlue.withValues(alpha: 0.1),
                                        AppColors.primaryBlue.withValues(alpha: 0.04),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 42,
                                    color: AppColors.primaryBlue.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có bình luận nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutralBlack,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Hãy là người đầu tiên chia sẻ cảm nghĩ!',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _CommentItem(
                            comment: comment,
                            onLikeTap: () {
                              provider.toggleCommentLike(
                                widget.post.id,
                                comment.id,
                              );
                            },
                          );
                        },
                      );
                    },
                  )
                : Consumer<FeedProvider>(
                    builder: (context, provider, _) {
                      final comments = provider.getCommentsForPost(widget.post.id);

                      if (provider.isLoadingComments && comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đang tải bình luận...',
                                style: TextStyle(
                                  color: AppColors.neutralGray700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (comments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryBlue.withValues(alpha: 0.1),
                                        AppColors.primaryBlue.withValues(alpha: 0.04),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 42,
                                    color: AppColors.primaryBlue.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có bình luận nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutralBlack,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Hãy là người đầu tiên chia sẻ cảm nghĩ!',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _CommentItem(
                            comment: comment,
                            onLikeTap: () {
                              provider.toggleCommentLike(
                                widget.post.id,
                                comment.id,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          // Selected image preview if any
          if (_selectedImage != null) _buildImagePreview(),
          // Input bar
          _buildInputBar(),
          if (_showEmojiKeyboard)
            EmojiPickerWidget(
              onEmojiSelected: _insertEmoji,
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.04),
            AppColors.primaryBlue.withValues(alpha: 0.02),
          ],
        ),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _selectedImage!.path,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _removeSelectedImage,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentRed, AppColors.accentRed],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ảnh đính kèm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutralBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sẵn sàng gửi cùng bình luận',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showEmojiKeyboard = !_showEmojiKeyboard;
                  if (_showEmojiKeyboard) FocusScope.of(context).unfocus();
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _showEmojiKeyboard
                      ? AppColors.primaryBlue.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sentiment_satisfied_alt_rounded,
                  color: _showEmojiKeyboard
                      ? AppColors.primaryBlue
                      : Colors.grey.shade700,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _showEmojiKeyboard
                      ? AppColors.primaryBlue.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 15),
                onTap: () {
                  setState(() => _showEmojiKeyboard = false);
                },
                decoration: const InputDecoration(
                  hintText: 'Viết bình luận...',
                  hintStyle: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14.5,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedImage != null
                      ? AppColors.primaryBlue.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_rounded,
                  color: _selectedImage != null
                      ? AppColors.primaryBlue
                      : Colors.grey.shade700,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _isSending
              ? Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitComment,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryOrange, AppColors.accentBrown],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLikeTap;

  const _CommentItem({
    required this.comment,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(comment.userName);
    final avatarColor = _avatarColor(comment.userName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar với gradient
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  avatarColor,
                  avatarColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: comment.userAvatar.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        comment.userAvatar,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Comment box content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.backgroundGray,
                        AppColors.backgroundGray.withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName.isNotEmpty
                            ? comment.userName
                            : 'Người dùng',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (comment.content.isNotEmpty)
                        Text(
                          comment.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.neutralBlack,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
                if (comment.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 200,
                        maxHeight: 200,
                      ),
                      child: Image.network(
                        comment.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (comment.likeCount > 0) ...[
                      const SizedBox(width: 14),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentRed, AppColors.accentRed],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${comment.likeCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Heart like button
          GestureDetector(
            onTap: () {
              onLikeTap();
              // Simple scale animation feedback
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: comment.isLiked
                      ? AppColors.accentRed.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: comment.isLiked ? AppColors.accentRed : Colors.grey.shade500,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String name) {
    final colors = [
      AppColors.primaryOrange,
      AppColors.primaryOrangeLight,
      AppColors.success,
      AppColors.primaryOrangeLight,
      AppColors.accentBrown,
      AppColors.accentRed,
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
