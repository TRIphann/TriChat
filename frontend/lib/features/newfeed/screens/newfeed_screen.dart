import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/component/avatars.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';
import '../providers/feed_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/story_list.dart';
import 'create_post_screen.dart';
import '../widgets/modern_post_card.dart';

class NewfeedScreen extends StatefulWidget {
  const NewfeedScreen({super.key});

  @override
  State<NewfeedScreen> createState() => _NewfeedScreenState();
}

class _NewfeedScreenState extends State<NewfeedScreen>
    with WidgetsBindingObserver {
  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserAvatar = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mỗi lần tab này được focus lại (khi user chuyển tab trong IndexedStack),
    // thử reload feed để hiển thị bài mới nhất
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _refreshIfStale();
    }
  }

  DateTime? _lastRefreshed;

  Future<void> _refreshIfStale() async {
    // Tránh gọi liên tục: chỉ reload nếu đã quá 5 giây từ lần cuối
    final now = DateTime.now();
    if (_lastRefreshed != null &&
        now.difference(_lastRefreshed!).inSeconds < 5) {
      return;
    }
    _lastRefreshed = now;
    try {
      if (!mounted) return;
      await context.read<FeedProvider>().refreshFeed();
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadCurrentUser();
    }
  }

  Future<void> _reloadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (!mounted) return;
    _loadCurrentUser();
    setState(() {});
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : user.email?.split('@').firstOrNull ?? 'User';
      _currentUserAvatar = user.photoURL ?? '';
    }
  }

  void _loadData() {
    Future.microtask(() {
      final feed = context.read<FeedProvider>();
      // Only load if we don't already have cached data
      if (feed.allPosts.isEmpty) {
        feed.loadFeed();
      }
      final stories = context.read<StoryProvider>();
      if (stories.allUserStories.isEmpty) {
        stories.loadStories();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      context.read<FeedProvider>().loadMore();
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchOverlayScreen(
          onBack: () => Navigator.of(context).pop(),
          onSearchResultTap: ({required userId, required name, avatar}) {
            Navigator.of(context).pop();
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _showCreatePost() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkPremiumSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: CreatePostScreen(
            currentUserName: _currentUserName,
            currentUserAvatar: _currentUserAvatar,
          ),
        ),
      ),
    );

    // CreatePostScreen already inserts the new post into FeedProvider via
    // createPost(). We still want to refresh so we pick up any backend-side
    // changes (e.g. comment_count, like state for older posts) and ensure
    // the new entry is in sync with the server.
    if (!mounted) return;
    if (result == true) {
      try {
        await context.read<FeedProvider>().refreshFeed();
      } catch (_) {}
    }
  }

  Color get _avatarColor {
    final colors = [
      AppColors.primaryOrange,
      AppColors.primaryOrangeLight,
      AppColors.success,
      AppColors.primaryOrangeLight,
      AppColors.accentBrown,
      AppColors.accentRed,
    ];
    if (_currentUserName.isEmpty) return colors[0];
    return colors[_currentUserName.codeUnitAt(0) % colors.length];
  }

  String get _userInitials {
    if (_currentUserName.isEmpty) return '?';
    final parts = _currentUserName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return _currentUserName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPremiumBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.neonRoyal,
          onRefresh: () async {
            await _reloadCurrentUser();
            await context.read<FeedProvider>().refreshFeed();
            await context.read<StoryProvider>().loadStories();
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildComposeCard()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              SliverToBoxAdapter(child: _buildStorySection()),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              _buildPostList(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.darkBubbleMineGradient,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonRoyal.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showCreatePost,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.edit_rounded, size: 20),
          label: const Text(
            'Đăng',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
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
          // Logo phía trái
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.darkBubbleMineGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonRoyal.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TriChat',
                style: TextStyle(
                  color: AppColors.darkPremiumTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Search bar expandable
          Expanded(
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkPremiumElevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.darkPremiumBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.darkPremiumTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tìm kiếm bạn bè, bài viết...',
                      style: TextStyle(
                        color: AppColors.darkPremiumTextHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.notifications_none_rounded,
            badge: 1,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thông báo - đang phát triển')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkPremiumElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkPremiumBorder,
                  width: 1,
                ),
              ),
              child: Icon(icon, color: AppColors.darkPremiumTextPrimary, size: 22),
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkPremiumSurface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPremiumBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          TriAvatar(
            imageUrl: _currentUserAvatar,
            name: FirebaseAuth.instance.currentUser?.displayName ?? 'U',
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showCreatePost,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.darkPremiumElevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.darkPremiumBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  _currentUserName.isNotEmpty
                      ? '${_currentUserName.split(' ').last}, bạn đang nghĩ gì?'
                      : 'Bạn đang nghĩ gì?',
                  style: const TextStyle(
                    color: AppColors.darkPremiumTextSecondary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPremiumBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildAction(
            icon: Icons.image_outlined,
            label: 'Ảnh/Video',
            color: AppColors.neonOnline,
            onTap: _showCreatePost,
          ),
          _verticalDivider(),
          _buildAction(
            icon: Icons.mood_outlined,
            label: 'Cảm xúc',
            color: AppColors.neonYellow,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bày tỏ cảm xúc - đang phát triển')),
              );
            },
          ),
          _verticalDivider(),
          _buildAction(
            icon: Icons.videocam_outlined,
            label: 'Video trực tiếp',
            color: AppColors.neonRed,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live - đang phát triển')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.darkPremiumBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPremiumTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorySection() {
    return StoryList(
      currentUserId: _currentUserId,
      currentUserName: _currentUserName,
      currentUserAvatar: _currentUserAvatar,
    );
  }

  List<Widget> _buildMockPostsFeed() {
    final mockPosts = [
      _MockPostData(
        userName: 'Minh Anh',
        userEmoji: '🌸',
        timeAgo: '2 giờ trước',
        content: 'Hôm nay trời đẹp quá! Ai đi chơi không nào? ☀️',
        imageUrl: null,
        likes: 24,
        comments: 5,
        isLiked: false,
      ),
      _MockPostData(
        userName: 'Văn Hùng',
        userEmoji: '🚀',
        timeAgo: '4 giờ trước',
        content: 'Vừa hoàn thành dự án mới! Cảm ơn team đã hỗ trợ 💪',
        imageUrl: null,
        likes: 56,
        comments: 12,
        isLiked: true,
      ),
      _MockPostData(
        userName: 'Thị Hà',
        userEmoji: '🎨',
        timeAgo: '6 giờ trước',
        content: 'Mình vừa thử một quán cafe mới, không gian rất xinh! ☕✨',
        imageUrl: null,
        likes: 89,
        comments: 18,
        isLiked: false,
      ),
      _MockPostData(
        userName: 'Quang Vinh',
        userEmoji: '📸',
        timeAgo: '1 ngày trước',
        content: 'Chuyến đi Đà Lạt tuần rồi thật tuyệt vời! 🌄',
        imageUrl: null,
        likes: 142,
        comments: 23,
        isLiked: true,
      ),
    ];

    return mockPosts.map((post) => _buildMockPostCard(post)).toList();
  }

  Widget _buildMockPostCard(_MockPostData post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPremiumBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.neonRoyal.withValues(alpha: 0.4),
                        AppColors.neonPink.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.neonRoyal.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(post.userEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          color: AppColors.darkPremiumTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          color: AppColors.darkPremiumTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.darkPremiumTextSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(
              post.content,
              style: TextStyle(
                color: AppColors.darkPremiumTextPrimary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonRoyal.withValues(alpha: 0.2),
                  AppColors.neonPink.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonRoyal.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_rounded,
                    color: AppColors.neonRoyal.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hình ảnh',
                    style: TextStyle(
                      color: AppColors.darkPremiumTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _PostActionButton(
                  icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  label: '${post.likes}',
                  color: post.isLiked ? AppColors.neonRed : AppColors.darkPremiumTextSecondary,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _PostActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments}',
                  color: AppColors.darkPremiumTextSecondary,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _PostActionButton(
                  icon: Icons.share_outlined,
                  label: 'Chia sẻ',
                  color: AppColors.darkPremiumTextSecondary,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return Consumer<FeedProvider>(
      builder: (context, provider, _) {
        if (provider.state == FeedLoadingState.loading &&
            provider.posts.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.neonRoyal,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Đang tải bài viết...',
                    style: TextStyle(
                      color: AppColors.darkPremiumTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.state == FeedLoadingState.error &&
            provider.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 52, color: AppColors.darkPremiumTextSecondary),
                  const SizedBox(height: 14),
                  Text(
                    'Không thể tải bài viết',
                    style: TextStyle(
                      color: AppColors.darkPremiumTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.refreshFeed(),
                    child: Text(
                      'Thử lại',
                      style: TextStyle(color: AppColors.neonRoyal),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonOrange.withValues(alpha: 0.18),
                            AppColors.neonPink.withValues(alpha: 0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.neonOrange.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonOrange.withValues(alpha: 0.30),
                            blurRadius: 24,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 52,
                        color: AppColors.neonOrange,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Chưa có bài viết nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPremiumTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hãy là người đầu tiên chia sẻ khoảnh khắc đáng nhớ của bạn với cộng đồng TriChat!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkPremiumTextSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.darkBubbleMineGradient,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonRoyal.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: _showCreatePost,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Đăng bài đầu tiên',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == provider.posts.length) {
              // Bottom loading indicator when there are more posts to load
              if (provider.hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.neonRoyal,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox(height: 32);
            }
            final post = provider.posts[index];
            return ModernPostCard(
              post: post,
              onProfileTap: post.userId != _currentUserId
                  ? () => context.push('/profile', extra: post.userId)
                  : null,
            );
          }, childCount: provider.posts.length + (provider.hasMore ? 1 : 0)),
        );
      },
    );
  }
}

class _MockPostData {
  final String userName;
  final String userEmoji;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final bool isLiked;

  const _MockPostData({
    required this.userName,
    required this.userEmoji,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.isLiked,
  });
}

class _PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PostActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
