import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_colors.dart';
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
      _currentUserName = user.displayName ?? 'User';
      _currentUserAvatar = user.photoURL ?? '';
    }
  }

  void _loadData() {
    Future.microtask(() {
      context.read<FeedProvider>().loadFeed();
      context.read<StoryProvider>().loadStories();
    });
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

  void _showCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
  }

  Color get _avatarColor {
    const colors = [
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
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            await _reloadCurrentUser();
            await context.read<FeedProvider>().refreshFeed();
            await context.read<StoryProvider>().loadStories();
          },
          child: CustomScrollView(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePost,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text(
          'Đăng',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TriChat',
                style: TextStyle(
                  color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tìm kiếm bạn bè, bài viết...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
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
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryOrange, width: 1.5),
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
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_avatarColor, _avatarColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _avatarColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _currentUserAvatar.isNotEmpty
                      ? Image.network(
                          _currentUserAvatar,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _userInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _userInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
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
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      _currentUserName.isNotEmpty
                          ? '${_currentUserName.split(' ').last}, bạn đang nghĩ gì?'
                          : 'Bạn đang nghĩ gì?',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAction(
            icon: Icons.photo_library_rounded,
            label: 'Ảnh/Video',
            gradient: const [AppColors.successLight, Color(0xFF30B94E)],
            onTap: _showCreatePost,
          ),
          _verticalDivider(),
          _buildAction(
            icon: Icons.emoji_emotions_outlined,
            label: 'Cảm xúc',
            gradient: const [AppColors.primaryOrangeLight, AppColors.primaryOrange],
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bày tỏ cảm xúc - đang phát triển')),
              );
            },
          ),
          _verticalDivider(),
          _buildAction(
            icon: Icons.live_tv_rounded,
            label: 'Video trực tiếp',
            gradient: const [AppColors.accentRed, AppColors.accentRed],
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

  Widget _buildAction({
    required IconData icon,
    required String label,
    required List<Color> gradient,
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralBlack,
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

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.borderGray,
    );
  }

  Widget _buildStorySection() {
    return StoryList(
      currentUserId: _currentUserId,
      currentUserName: _currentUserName,
      currentUserAvatar: _currentUserAvatar,
    );
  }

  Widget _buildPostList() {
    return Consumer<FeedProvider>(
      builder: (context, provider, _) {
        if (provider.state == FeedLoadingState.loading &&
            provider.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
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
                  const SizedBox(height: 14),
                  Text(
                    'Đang tải bài viết...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Không thể tải bài viết',
                    style: TextStyle(
                      color: AppColors.neutralBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hãy kiểm tra kết nối mạng và thử lại',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadFeed(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Thử lại',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                      width: 80,
                      height: 80,
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
                        Icons.feed_rounded,
                        size: 40,
                        color: AppColors.primaryBlue.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Bảng tin trống',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hãy là người đầu tiên chia sẻ khoảnh khắc của bạn!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13.5,
                        height: 1.4,
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
            final post = provider.posts[index];
            return ModernPostCard(
              post: post,
              onProfileTap: post.userId != _currentUserId
                  ? () => context.push('/profile', extra: post.userId)
                  : null,
            );
          }, childCount: provider.posts.length),
        );
      },
    );
  }
}
