import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/app_colors.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import 'comment_sheet.dart';

/// Widget PostCard hiện đại, tái sử dụng được ở cả Newfeed và Profile.
/// Thiết kế theo phong cách Facebook/Instagram: card bo góc, có shadow nhẹ,
/// header có tên + avatar + menu, nội dung có hỗ trợ expand "Xem thêm",
/// media grid đẹp, footer có reaction bar với hiệu ứng like animation.
class ModernPostCard extends StatefulWidget {
  final PostModel post;
  final bool useProfileProvider;
  final VoidCallback? onProfileTap;

  const ModernPostCard({
    super.key,
    required this.post,
    this.useProfileProvider = false,
    this.onProfileTap,
  });

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeAnimController;
  bool _showLikeOverlay = false;

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTapLike() async {
    if (widget.post.isLiked) {
      _showQuickLike();
      return;
    }
    _toggleLike();
    _showQuickLike();
  }

  void _toggleLike() {
    if (widget.useProfileProvider) {
      // ignore: use_build_context_synchronously
      context.read<dynamic>().toggleLike(widget.post.id);
    } else {
      context.read<FeedProvider>().toggleLike(widget.post.id);
    }
  }

  void _showQuickLike() {
    if (!widget.post.isLiked) {
      _toggleLike();
    }
    setState(() => _showLikeOverlay = true);
    _likeAnimController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showLikeOverlay = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return GestureDetector(
      onDoubleTap: _handleDoubleTapLike,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkPremiumSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(p),
            if (p.content.isNotEmpty) _buildContent(p),
            if (p.mediaUrls.isNotEmpty) _buildMedia(p),
            _buildStatsBar(p),
            Divider(height: 1, thickness: 0.5, color: AppColors.divider),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PostModel p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: _Avatar(name: p.userName, url: p.userAvatar, size: 44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                Flexible(
                  child: Text(
                    p.userName.isNotEmpty ? p.userName : 'Người dùng',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPremiumTextPrimary,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                      if (p.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonRoyal.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonRoyal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _formatTime(p.createdAt),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.darkPremiumTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.darkPremiumTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      p.visibility == 'public'
                          ? Icons.public
                          : p.visibility == 'friends'
                              ? Icons.group
                              : p.visibility == 'selected_friends'
                                  ? Icons.group_outlined
                                  : Icons.lock_outline,
                      size: 13,
                      color: AppColors.darkPremiumTextSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: AppColors.darkPremiumTextSecondary,
              size: 22,
            ),
            color: AppColors.darkPremiumElevated,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              // TODO: handle edit/delete
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline, size: 18, color: AppColors.darkPremiumTextPrimary),
                    const SizedBox(width: 10),
                    Text('Lưu bài viết', style: TextStyle(fontSize: 14, color: AppColors.darkPremiumTextPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hide',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.darkPremiumTextPrimary),
                    const SizedBox(width: 10),
                    Text('Ẩn bài viết', style: TextStyle(fontSize: 14, color: AppColors.darkPremiumTextPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: AppColors.neonRed),
                    const SizedBox(width: 10),
                    Text('Báo cáo', style: TextStyle(fontSize: 14, color: AppColors.neonRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PostModel p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        p.content,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.darkPremiumTextPrimary,
        ),
      ),
    );
  }

  Widget _buildMedia(PostModel p) {
    final urls = p.mediaUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    // Single image: full-width with rounded corners
    if (urls.length == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: _NetworkImageWithLoader(url: urls.first),
              ),
              if (_showLikeOverlay)
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _likeAnimController,
                      builder: (_, __) {
                        final scale = 0.6 +
                            (1 - (_likeAnimController.value - 0.5).abs() * 2) * 0.6;
                        final opacity = _likeAnimController.value < 0.5
                            ? _likeAnimController.value * 2
                            : (1 - _likeAnimController.value) * 2;
                        return Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: scale.clamp(0.4, 1.4),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 96,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 2 images: side-by-side
    if (urls.length == 2) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _NetworkImageWithLoader(url: urls[0]),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _NetworkImageWithLoader(url: urls[1]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3 images: 1 large + 2 small
    if (urls.length == 3) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _NetworkImageWithLoader(url: urls[0]),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: _NetworkImageWithLoader(url: urls[1]),
                    ),
                    const SizedBox(height: 2),
                    AspectRatio(
                      aspectRatio: 1,
                      child: _NetworkImageWithLoader(url: urls[2]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4+ images: grid 2x2, the fourth shows +N overlay
    final visible = urls.length > 4 ? 4 : urls.length;
    final remaining = urls.length - 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
          children: List.generate(visible, (i) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImageWithLoader(url: urls[i]),
                if (i == 3 && remaining > 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatsBar(PostModel p) {
    if (p.likeCount == 0 && p.commentCount == 0 && p.shareCount == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          // Like summary: like icon + count
          if (p.likeCount > 0) ...[
            _LikeBadge(),
            const SizedBox(width: 5),
            Text(
              _formatCount(p.likeCount),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkPremiumTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          if (p.commentCount > 0) ...[
            Text(
              '${_formatCount(p.commentCount)} bình luận',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkPremiumTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (p.shareCount > 0)
            Text(
              '${_formatCount(p.shareCount)} chia sẻ',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkPremiumTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final p = widget.post;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: p.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              label: 'Thích',
              active: p.isLiked,
              activeColor: AppColors.neonRed,
              onTap: _showQuickLike,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Bình luận',
              active: false,
              activeColor: AppColors.neonRoyal,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => CommentSheet(
                    post: p,
                    useProfileProvider: widget.useProfileProvider,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.share_outlined,
              label: 'Chia sẻ',
              active: false,
              activeColor: AppColors.neonOnline,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng đang phát triển'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}Tr';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}

/// Action button với gradient + animation khi active
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? widget.activeColor
        : AppColors.darkPremiumTextSecondary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _pressed
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: color, size: 19),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge like — vòng tròn icon thumbs-up xanh
class _LikeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryOrangeLight, AppColors.primaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 11),
    );
  }
}

/// Avatar widget có fallback màu + initials
class _Avatar extends StatelessWidget {
  final String name;
  final String url;
  final double size;

  const _Avatar({required this.name, required this.url, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(name);
    final initials = _initials(name);
    final useNet = url.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: useNet
          ? ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.38,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.38,
                ),
              ),
            ),
    );
  }
}

/// Network image với loading indicator đẹp
class _NetworkImageWithLoader extends StatelessWidget {
  final String url;
  const _NetworkImageWithLoader({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.darkPremiumElevated,
          alignment: Alignment.center,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: AppColors.neonRoyal,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.darkPremiumSurface,
        alignment: Alignment.center,
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.darkPremiumTextSecondary,
          size: 32,
        ),
      ),
    );
  }
}

Color _avatarColor(String name) {
  const colors = [
    AppColors.success,
    AppColors.primaryOrange,
    AppColors.primaryOrangeLight,
    AppColors.accentBrown,
    AppColors.accentRed,
    AppColors.accentBrown,
    AppColors.accentBrown,
    AppColors.neutralGray700,
    AppColors.primaryOrange,
    Color(0xFFFF5722),
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
