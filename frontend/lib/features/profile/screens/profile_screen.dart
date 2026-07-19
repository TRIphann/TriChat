import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';
import 'package:frontend/features/profile/services/profile_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/features/newfeed/models/post_model.dart';
import 'package:frontend/features/newfeed/screens/create_post_screen.dart';
import 'package:frontend/features/newfeed/widgets/modern_post_card.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/views/chat/chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late String _currentUserId;
  late String _currentUserName;
  late String _currentUserAvatar;

  String? _targetUserId;
  bool _isOwnProfile = true;
  String _targetUserName = '';
  String _targetUserAvatar = '';
  String? _targetUserEmail;

  bool _isLoadingRelationship = false;
  String _relationshipStatus = '';
  String? _friendshipId;
  String? _relationshipSenderId;

  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedAvatarBytes;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _setupTargetUser();
    _tabController = TabController(
      length: _isOwnProfile ? 4 : 3,
      vsync: this,
      initialIndex: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialProfile();
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetUserId != widget.targetUserId) {
      _setupTargetUser();
      final newLength = _isOwnProfile ? 4 : 3;
      if (_tabController.length != newLength) {
        _tabController.dispose();
        _tabController = TabController(
          length: newLength,
          vsync: this,
          initialIndex: 0,
        );
      }
      if (mounted) {
        setState(() {});
        _loadInitialProfile();
      }
    }
  }

  DateTime? _lastReloadedAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mỗi lần tab profile được focus lại (sau khi switch tab trong IndexedStack
    // hoặc quay lại từ route khác) → reload 1 lần để cập nhật thay đổi mới nhất
    // (bài viết, thông tin cá nhân, ảnh, bạn bè, ...).
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _reloadIfStale();
    }
  }

  Future<void> _reloadIfStale() async {
    // Tránh gọi liên tục khi rebuild nhiều lần: chỉ reload nếu đã quá 3 giây
    final now = DateTime.now();
    if (_lastReloadedAt != null &&
        now.difference(_lastReloadedAt!).inSeconds < 3) {
      return;
    }
    _lastReloadedAt = now;
    _loadInitialProfile();
  }

  void _loadInitialProfile() {
    if (_isOwnProfile) {
      _reloadOwnProfile();
    } else {
      _loadOtherUserProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : user.email?.split('@').firstOrNull ?? 'User';
      _currentUserAvatar = user.photoURL ?? '';
    } else {
      _currentUserId = '';
      _currentUserName = '';
      _currentUserAvatar = '';
    }
  }

  void _setupTargetUser() {
    _targetUserId = widget.targetUserId;
    final wasOwnProfile = _isOwnProfile;
    _isOwnProfile =
        _targetUserId == null || _targetUserId == _currentUserId;

    if (_isOwnProfile) {
      _targetUserId = _currentUserId;
      _targetUserName = _currentUserName;
      _targetUserAvatar = _currentUserAvatar;
      if (!wasOwnProfile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ProfileProvider>().clearExternalUserProfile();
        });
      }
    }
  }

  Future<void> _reloadOwnProfile() async {
    if (_targetUserId == null) return;
    if (!mounted) return;
    await context.read<ProfileProvider>().loadProfile(_targetUserId!);
  }

  Future<void> _loadOtherUserProfile() async {
    if (_targetUserId == null) return;

    setState(() => _isLoadingRelationship = true);

    try {
      final provider = context.read<ProfileProvider>();
      final results = await Future.wait([
        ProfileService.getUserById(_targetUserId!),
        ProfileService.getUserPosts(_targetUserId!),
        FriendService.getRelationshipStatus(_targetUserId!),
        FriendService.getFriendsByUserId(_targetUserId!),
      ]);

      final userProfile = results[0] as UserProfileModel;
      final posts = results[1] as List<PostModel>;
      final relationship = results[2] as FriendshipModel?;
      final externalFriends = results[3] as List<FriendSummaryModel>;

      provider.setExternalUserProfile(userProfile);
      provider.setExternalPosts(posts);
      provider.setExternalFriends(externalFriends);

      if (!mounted) return;
      setState(() {
        _targetUserName = userProfile.fullName;
        _targetUserAvatar = userProfile.avatar;
        _relationshipStatus = relationship?.status ?? '';
        _friendshipId = relationship?.id;
        _relationshipSenderId = relationship?.senderId;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelationship = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    final currentTabIndex = _tabController.index;

    if (_isOwnProfile) {
      await context.read<ProfileProvider>().loadProfile(_targetUserId!);
    } else {
      await _loadOtherUserProfile();
    }

    if (!mounted) return;

    if (_tabController.index != currentTabIndex &&
        currentTabIndex >= 0 &&
        currentTabIndex < _tabController.length) {
      _tabController.animateTo(currentTabIndex);
    }
  }

  Future<void> _pickAvatarAndPost() async {
    if (!_isOwnProfile) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    final currentUser = FirebaseAuth.instance.currentUser;

    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AvatarChoiceSheet(
        imageBytes: bytes,
        onAvatarOnly: () async {
          Navigator.pop(ctx);
          await _updateAvatarOnly(image, bytes);
        },
        onPostOnly: () {
          Navigator.pop(ctx);
          _openCreatePost(
            currentUserName: currentUser?.displayName ?? 'User',
            currentUserAvatar: currentUser?.photoURL ?? '',
            imageBytes: bytes,
            imagePath: image.path,
          );
        },
        onBoth: () {
          Navigator.pop(ctx);
          _openCreatePost(
            currentUserName: currentUser?.displayName ?? 'User',
            currentUserAvatar: currentUser?.photoURL ?? '',
            imageBytes: bytes,
            imagePath: image.path,
            shouldUpdateAvatarOnSubmit: true,
            avatarImagePath: image.path,
          );
        },
      ),
    );
  }

  void _openCreatePost({
    required String currentUserName,
    required String currentUserAvatar,
    Uint8List? imageBytes,
    String? imagePath,
    bool shouldUpdateAvatarOnSubmit = false,
    String? avatarImagePath,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: CreatePostScreen(
            currentUserName: currentUserName,
            currentUserAvatar: currentUserAvatar,
            preSelectedBytes: imageBytes,
            preSelectedPath: imagePath,
            shouldUpdateAvatarOnSubmit: shouldUpdateAvatarOnSubmit,
            avatarImagePath: avatarImagePath,
          ),
        ),
      ),
    );

    // After the create-post sheet closes, if a post was created, force a fresh
    // refresh so the new entry shows up immediately on the profile (and other
    // tabs that observe the same ProfileProvider).
    if (!mounted) return;
    if (result == true) {
      // Throttle: don't refetch more than once every 2s
      final now = DateTime.now();
      if (_lastReloadedAt == null ||
          now.difference(_lastReloadedAt!) > const Duration(seconds: 2)) {
        _lastReloadedAt = now;
        if (_isOwnProfile) {
          await _reloadOwnProfile();
        } else if (_targetUserId != null) {
          await context.read<ProfileProvider>().refreshProfile(_targetUserId!);
        }
      }
    }
  }

  Future<void> _updateAvatarOnly(XFile image, Uint8List bytes) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryOrange,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Đang cập nhật ảnh đại diện...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final newAvatarUrl = await AuthService.updateAvatar(image);
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _currentUserAvatar = newAvatarUrl);
      await FirebaseAuth.instance.currentUser?.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đổi ảnh đại diện thành công!'),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đổi avatar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_targetUserId == null) return;
    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.sendRequest(addresseeId: _targetUserId!);
      if (!mounted) return;
      await context.read<FriendProvider>().loadFriends();
      if (!mounted) return;
      setState(() {
        _relationshipStatus = 'pending';
        _relationshipSenderId = _currentUserId;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRelationship = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _cancelRequest() async {
    if (_friendshipId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi lời mời'),
        content: Text('Thu hồi lời mời kết bạn đã gửi đến $_targetUserName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirmed != true || _friendshipId == null) return;
    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.cancelRequest(_friendshipId!);
      if (!mounted) return;
      setState(() {
        _relationshipStatus = '';
        _friendshipId = null;
        _relationshipSenderId = null;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelationship = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _unfriend() async {
    if (_friendshipId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Hủy kết bạn với $_targetUserName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy kết bạn'),
          ),
        ],
      ),
    );
    if (confirmed != true || _friendshipId == null) return;
    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.unfriend(_friendshipId!);
      if (!mounted) return;
      setState(() {
        _relationshipStatus = '';
        _friendshipId = null;
        _relationshipSenderId = null;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelationship = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _respondToFriendRequest(bool accept) async {
    if (_friendshipId == null) return;
    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.respondRequest(
        friendshipId: _friendshipId!,
        accept: accept,
      );
      if (!mounted) return;
      if (accept) {
        await context.read<FriendProvider>().loadFriends();
        if (!mounted) return;
        setState(() {
          _relationshipStatus = 'accepted';
          _relationshipSenderId = null;
          _isLoadingRelationship = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chấp nhận lời mời kết bạn từ $_targetUserName'),
              backgroundColor: AppColors.primaryBlue,
            ),
          );
        }
      } else {
        setState(() {
          _relationshipStatus = '';
          _friendshipId = null;
          _relationshipSenderId = null;
          _isLoadingRelationship = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã từ chối lời mời kết bạn')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelationship = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _showRespondDialog() async {
    final action = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Lời mời kết bạn từ $_targetUserName'),
        content: const Text('Bạn muốn chấp nhận hay từ chối lời mời này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
    if (action == null) return;
    await _respondToFriendRequest(action);
  }

  Future<void> _showRespondDialogForFriend(String senderId) async {
    final senderName = _resolveFriendDisplayName(senderId);
    if (!mounted) return;
    final action = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Lời mời kết bạn từ $senderName'),
        content: const Text('Bạn muốn chấp nhận hay từ chối lời mời này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
    if (action == null) return;
    if (!mounted) return;
    if (action) {
      await context.read<FriendProvider>().acceptFriendRequest(senderId);
    } else {
      await context.read<FriendProvider>().declineFriendRequest(senderId);
    }
  }

  String _resolveFriendDisplayName(String friendId) {
    final prov = context.read<ProfileProvider>();
    final external =
        prov.externalFriends.where((f) => f.friendId == friendId).toList();
    if (external.isNotEmpty) {
      final f = external.first;
      return f.fullName.isNotEmpty ? f.fullName : 'Người dùng';
    }
    final friendProv = context.read<FriendProvider>();
    final received = friendProv.getReceivedRequest(friendId);
    if (received != null && received.senderName != null) {
      return received.senderName!;
    }
    return 'Người dùng';
  }

  Future<void> _openChat() async {
    if (_targetUserId == null || _targetUserId!.isEmpty) return;
    try {
      final conversation = await ChatService().createConversation(
        type: 'private',
        participantIds: [_targetUserId!],
      );
      if (!mounted) return;
      await context.read<ChatProvider>().openConversation(conversation);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPremiumBackground,
      // Dùng SliverAppBar chuẩn để:
      //  - Tránh "vạch vàng đen" do NestedScrollView + custom SliverToBoxAdapter
      //  - Back button tự động chỉ hiện khi Navigator có thể pop (own profile -> ẩn)
      //  - Không cần RefreshIndicator bọc ngoài
      body: DefaultTabController(
        length: _isOwnProfile ? 4 : 3,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: AppColors.darkPremiumSurface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: true,
                snap: false,
                floating: false,
                iconTheme: const IconThemeData(
                  color: AppColors.darkPremiumTextPrimary,
                ),
                automaticallyImplyLeading: !_isOwnProfile,
                leading: _isOwnProfile
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.darkPremiumTextPrimary,
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/newfeed');
                          }
                        },
                      ),
                actions: const [
                  SizedBox(width: 4),
                ],
              ),
              _buildProfileHeader(),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  isOwnProfile: _isOwnProfile,
                ),
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.neonRoyal,
            child: TabBarView(
              controller: _tabController,
              children: _isOwnProfile
                  ? [
                      _PostsTab(targetUserId: _targetUserId ?? ''),
                      _InfoTab(isOwnProfile: true),
                      _ImagesTab(),
                    ]
                  : [
                      _PostsTab(targetUserId: _targetUserId ?? ''),
                      _InfoTab(
                          isOwnProfile: false, targetUserId: _targetUserId),
                      _ImagesTab(),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  // Backward compat: giữ method này để các chỗ gọi cũ không lỗi
  // (không dùng nữa nhưng xóa sẽ vỡ override ở nơi khác nếu có)
  // ignore: unused_element
  Widget _buildLegacyAppBar() {
    // Trả về SliverAppBar đơn giản thay vì tham chiếu _buildAppBar đã xóa
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: !_isOwnProfile,
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          final profile = _isOwnProfile
              ? provider.userProfile
              : provider.externalUserProfile;
          final displayName = _isOwnProfile
              ? (profile?.fullName.isNotEmpty == true
                  ? profile!.fullName
                  : _currentUserName)
              : _targetUserName;
          final bio = profile?.bio.trim() ?? '';
          final coverColor = _avatarColor(displayName);

          return Column(
            children: [
              // ==== COVER PHOTO với gradient ====
              _buildCover(coverColor),
              // ==== Thông tin user ====
              Container(
                color: AppColors.darkPremiumBackground,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 0),
                    // Tên + verified badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName.isNotEmpty ? displayName : 'Người dùng',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkPremiumTextPrimary,
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.neonRoyal,
                          size: 20,
                        ),
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          bio,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkPremiumTextSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else if (!_isOwnProfile && _targetUserEmail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _targetUserEmail!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkPremiumTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Stats: Posts | Followers | Following
                    _buildStatRow(),
                    const SizedBox(height: 16),
                    if (_isOwnProfile)
                      _buildOwnProfileActions()
                    else
                      _buildOtherProfileActions(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCover(Color accentColor) {
    // Bố cục: cover gradient tối (xám → xanh dương sâu) + avatar nhô lên vào phần info
    return Column(
      children: [
        Container(
          height: 130,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1B23),
                Color(0xFF16171D),
                Color(0xFF0E1726),
                Color(0xFF101D3A),
              ],
              stops: [0.0, 0.45, 0.75, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle highlight Neon ở góc trên phải (rất mờ)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonRoyal.withValues(alpha: 0.18),
                        AppColors.neonRoyal.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Avatar đẩy lên vào phần info
              Positioned(
                left: 0,
                right: 0,
                bottom: -50,
                child: Center(child: _buildAvatar(size: 100)),
              ),
            ],
          ),
        ),
        // Đệm cho phần avatar nhô lên
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildAvatar({double size = 112}) {
    final name = _isOwnProfile ? _currentUserName : _targetUserName;
    final avatarColor = _avatarColor(name);
    final avatarUrl = _isOwnProfile ? _currentUserAvatar : _targetUserAvatar;
    final initials = _getInitials(name);

    Widget avatar = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [avatarColor, avatarColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipOval(
          child: _selectedAvatarBytes != null
              ? Image.memory(
                  _selectedAvatarBytes!,
                  width: size - 8,
                  height: size - 8,
                  fit: BoxFit.cover,
                )
              : avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      width: size - 8,
                      height: size - 8,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: size * 0.38,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: size * 0.38,
                        ),
                      ),
                    ),
        ),
      ),
    );

    if (_isOwnProfile) {
      return GestureDetector(
        onTap: _pickAvatarAndPost,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.successLight, AppColors.success],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successLight.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return avatar;
  }

  Widget _buildStatRow() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoading;
        final photoCount = provider.photoCount;
        final friendCount = _isOwnProfile
            ? provider.friendCount
            : provider.externalFriendCount;
        final postCount = _isOwnProfile
            ? provider.postCount
            : provider.posts.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.darkPremiumSurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.darkPremiumBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: isLoading ? '...' : '$postCount',
                  label: 'Bài viết',
                  onTap: isLoading ? null : () => _tabController.animateTo(0),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.darkPremiumBorder.withValues(alpha: 0.0),
                      AppColors.darkPremiumBorder,
                      AppColors.darkPremiumBorder.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: AppColors.darkPremiumBorder, width: 0.5),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: isLoading ? '...' : '$photoCount',
                  label: 'Ảnh',
                  onTap: isLoading || photoCount <= 0
                      ? null
                      : () => _tabController.animateTo(_isOwnProfile ? 2 : 2),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.darkPremiumBorder.withValues(alpha: 0.0),
                      AppColors.darkPremiumBorder,
                      AppColors.darkPremiumBorder.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: AppColors.darkPremiumBorder, width: 0.5),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: isLoading ? '...' : '$friendCount',
                  label: 'Bạn bè',
                  onTap: isLoading || friendCount <= 0
                      ? null
                      : () {
                          if (_isOwnProfile) {
                            _tabController.animateTo(1);
                          } else {
                            _showFriendCountSheet(context, friendCount);
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.darkPremiumTextPrimary,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.darkPremiumTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnProfileActions() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildGradientButton(
            icon: Icons.edit_rounded,
            label: 'Chỉnh sửa trang cá nhân',
            gradient: const [
              AppColors.neonRoyal,
              AppColors.neonRoyalGlow,
            ],
            onTap: () {
              // Chuyển sang tab Giới thiệu (index 1) để chỉnh sửa thông tin
              _tabController.animateTo(1);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildOutlinedButton(
            icon: Icons.share_rounded,
            label: 'Chia sẻ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết trang cá nhân')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOtherProfileActions() {
    if (_isLoadingRelationship) {
      return SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    final isPending = _relationshipStatus == 'pending';
    final isPendingSentByMe =
        isPending && _relationshipSenderId == _currentUserId;
    final isPendingReceivedByMe =
        isPending && _relationshipSenderId != _currentUserId;
    final isNotFriend = _relationshipStatus.isEmpty;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: isNotFriend
              ? _buildGradientButton(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Kết bạn',
                  gradient: [AppColors.primaryOrange, AppColors.accentBrown],
                  onTap: _sendFriendRequest,
                )
              : isPendingSentByMe
                  ? _buildOutlinedButton(
                      icon: Icons.undo_rounded,
                      label: 'Thu hồi lời mời',
                      onTap: _cancelRequest,
                    )
                  : isPendingReceivedByMe
                      ? _buildGradientButton(
                          icon: Icons.check_rounded,
                          label: 'Phản hồi',
                          gradient: [AppColors.primaryOrange, AppColors.accentBrown],
                          onTap: _showRespondDialog,
                        )
                      : _buildGradientButton(
                          icon: Icons.check_rounded,
                          label: 'Bạn bè',
                          gradient: const [AppColors.successLight, AppColors.success],
                          onTap: _unfriend,
                        ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildOutlinedButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Nhắn tin',
            onTap: _openChat,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.darkPremiumSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.darkPremiumBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.darkPremiumTextPrimary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkPremiumTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendCountSheet(BuildContext context, int count) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          _targetUserName.isNotEmpty
                              ? 'Bạn bè của $_targetUserName ($count)'
                              : 'Bạn bè ($count)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Consumer<ProfileProvider>(
                      builder: (context, prov, _) {
                        if (prov.isLoadingExternalFriends) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 3),
                          );
                        }
                        final friends = prov.externalFriends;
                        if (friends.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 56,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Chưa có bạn bè',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralGray700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: friends.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            return _FriendRowItem(
                              friend: friend,
                              currentUid: currentUid,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                      targetUserId: friend.friendId,
                                    ),
                                  ),
                                );
                              },
                              onRespondFriend: _showRespondDialogForFriend,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// FRIEND ROW ITEM
// ============================================================
class _FriendRowItem extends StatelessWidget {
  final FriendSummaryModel friend;
  final String currentUid;
  final VoidCallback onTap;
  final ValueChanged<String> onRespondFriend;

  const _FriendRowItem({
    required this.friend,
    required this.currentUid,
    required this.onTap,
    required this.onRespondFriend,
  });

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

  @override
  Widget build(BuildContext context) {
    final displayName = friend.fullName.isNotEmpty
        ? friend.fullName
        : (friend.firstName.isNotEmpty || friend.lastName.isNotEmpty
            ? '${friend.firstName} ${friend.lastName}'.trim()
            : 'Người dùng');
    final avatarColor = _avatarColor(displayName);
    final initials = _initials(displayName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.neutralGray100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
                child: ClipOval(
                  child: friend.avatar.isNotEmpty
                      ? Image.network(
                          friend.avatar,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<FriendProvider>(
                builder: (context, friendProvider, _) {
                  if (friend.friendId == currentUid) {
                    return const SizedBox.shrink();
                  }
                  final isFriend = friendProvider.isFriend(friend.friendId);
                  final sentRequest =
                      friendProvider.getSentRequest(friend.friendId);
                  final receivedRequest =
                      friendProvider.getReceivedRequest(friend.friendId);
                  final isLoading =
                      friendProvider.isActionLoading(friend.friendId);
                  if (isLoading) {
                    return const SizedBox(
                      width: 38,
                      height: 38,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  if (receivedRequest != null) {
                    return _buildFriendRowAction(
                      icon: Icons.reply_rounded,
                      gradient: [AppColors.primaryOrange, AppColors.accentBrown],
                      onTap: () => onRespondFriend(friend.friendId),
                    );
                  }
                  if (sentRequest != null) {
                    return _buildFriendRowAction(
                      icon: Icons.undo_rounded,
                      gradient: const [AppColors.primaryOrangeLight, AppColors.primaryOrange],
                      onTap: () async {
                        await friendProvider.cancelFriendRequest(
                          friend.friendId,
                        );
                      },
                    );
                  }
                  if (isFriend) {
                    return _buildFriendRowAction(
                      icon: Icons.chat_bubble_rounded,
                      gradient: const [AppColors.successLight, AppColors.success],
                      onTap: () async {
                        final conversation =
                            await ChatService().createConversation(
                          type: 'private',
                          participantIds: [currentUid, friend.friendId],
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(conversation: conversation),
                          ),
                        );
                      },
                    );
                  }
                  return _buildFriendRowAction(
                    icon: Icons.person_add_alt_1_rounded,
                    gradient: [AppColors.primaryOrange, AppColors.accentBrown],
                    onTap: () async {
                      await friendProvider.sendFriendRequest(friend.friendId);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRowAction({
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ============================================================
// TAB BAR DELEGATE
// ============================================================
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isOwnProfile;

  _TabBarDelegate({required this.tabController, required this.isOwnProfile});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumSurface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            color: AppColors.darkPremiumBorder,
          ),
          TabBar(
            controller: tabController,
            labelColor: AppColors.darkPremiumTextPrimary,
            unselectedLabelColor: AppColors.darkPremiumTextSecondary,
            indicatorColor: AppColors.neonRoyal,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            tabs: isOwnProfile
                ? const [
                    Tab(icon: Icon(Icons.grid_on_rounded, size: 16), text: 'BÀI VIẾT', height: 56),
                    Tab(icon: Icon(Icons.person_outline_rounded, size: 16), text: 'GIỚI THIỆU', height: 56),
                    Tab(icon: Icon(Icons.image_outlined, size: 16), text: 'ẢNH', height: 56),
                  ]
                : const [
                    Tab(icon: Icon(Icons.grid_on_rounded, size: 16), text: 'BÀI VIẾT', height: 56),
                    Tab(icon: Icon(Icons.person_outline_rounded, size: 16), text: 'GIỚI THIỆU', height: 56),
                    Tab(icon: Icon(Icons.image_outlined, size: 16), text: 'ẢNH', height: 56),
                  ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 58;

  @override
  double get minExtent => 58;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController ||
      oldDelegate.isOwnProfile != isOwnProfile;
}

// ============================================================
// TAB 0: POSTS
// ============================================================
class _PostsTab extends StatefulWidget {
  final String targetUserId;
  const _PostsTab({required this.targetUserId});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  int _displayedPostCount = 6;
  bool _hasLoadedOnce = false;

  late final List<_MockPostTile> _mockTiles;

  @override
  void initState() {
    super.initState();
    _mockTiles = _buildMockTiles();
  }

  List<_MockPostTile> _buildMockTiles() {
    const colors = <List<Color>>[
      [Color(0xFF6A8BFF), Color(0xFF3A5CFF)],
      [Color(0xFFFF7AB6), Color(0xFFFF4F8A)],
      [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
      [Color(0xFFFFA552), Color(0xFFFF7A1A)],
      [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      [Color(0xFF34D399), Color(0xFF059669)],
      [Color(0xFFE879F9), Color(0xFFA21CAF)],
      [Color(0xFFFACC15), Color(0xFFEA580C)],
      [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
      [Color(0xFFFB923C), Color(0xFFB91C1C)],
      [Color(0xFF67E8F9), Color(0xFF0E7490)],
      [Color(0xFFC084FC), Color(0xFF6B21A8)],
    ];
    return List.generate(12, (i) {
      final c = colors[i % colors.length];
      return _MockPostTile(
        gradient: [c[0], c[1]],
        emoji: _emojiFor(i),
      );
    });
  }

  String _emojiFor(int i) {
    const e = ['🌅', '🍜', '✈️', '🎨', '🐶', '🏖️', '🎵', '☕', '🚀', '🌸', '🎮', '📸'];
    return e[i % e.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.posts.isEmpty && !_hasLoadedOnce) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.neonRoyal,
              ),
            ),
          );
        }

        // Nếu có data thật → dùng data thật
        final realPosts = provider.posts;
        if (realPosts.isNotEmpty) {
          final displayed = realPosts.take(_displayedPostCount).toList();
          final hasMore = _displayedPostCount < realPosts.length;
          _hasLoadedOnce = true;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ModernPostCard(
                      post: realPosts[index],
                      useProfileProvider: true,
                    ),
                    childCount: displayed.length,
                  ),
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _displayedPostCount += 6);
                        },
                        icon: const Icon(Icons.expand_more_rounded, size: 20),
                        label: const Text(
                          'Xem thêm bài viết',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.neonRoyal,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        // Nếu KHÔNG có data → hiển thị empty state
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có bài viết nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMockGrid() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final t = _mockTiles[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bài viết #${index + 1}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: t.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: t.gradient.first.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Subtle inner glow
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: RadialGradient(
                                  center: const Alignment(0.7, -0.6),
                                  radius: 1.1,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              t.emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                          // Tag góc dưới phải
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '#${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: _mockTiles.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockPostTile {
  final List<Color> gradient;
  final String emoji;
  _MockPostTile({required this.gradient, required this.emoji});
}

// ============================================================
// TAB 1: INFO (Editable)
// ============================================================
class _InfoTab extends StatelessWidget {
  final bool isOwnProfile;
  final String? targetUserId;
  const _InfoTab({required this.isOwnProfile, this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final profile = isOwnProfile
            ? provider.userProfile
            : provider.externalUserProfile;
        final email = profile?.email ??
            (isOwnProfile
                ? FirebaseAuth.instance.currentUser?.email ?? ''
                : '');
        final fullName = profile?.fullName ??
            (isOwnProfile ? provider.userName ?? '' : '');
        final bio = profile?.bio ?? '';
        final birthday = profile?.dateOfBirth != null
            ? '${profile!.dateOfBirth!.year}-${profile.dateOfBirth!.month.toString().padLeft(2, '0')}-${profile.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : (isOwnProfile ? (provider.birthday ?? '') : '');

        if (!isOwnProfile &&
            profile == null &&
            !provider.isLoadingExternalFriends) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Không có thông tin',
                  style: TextStyle(
                    color: AppColors.neutralGray700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _InfoCard(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primaryOrange,
                    label: 'Họ và tên',
                    value: fullName.isEmpty ? 'Chưa cập nhật' : fullName,
                    isOwnProfile: isOwnProfile,
                    onTap: isOwnProfile
                        ? () =>
                            _showNameDialog(context, provider, fullName)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.accentRed,
                    label: 'Email',
                    value: email.isEmpty ? 'Chưa cập nhật' : email,
                    isOwnProfile: false,
                    onTap: null,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.cake_outlined,
                    iconColor: AppColors.primaryOrangeLight,
                    label: 'Ngày sinh',
                    value: birthday.isEmpty ? 'Chưa cập nhật' : birthday,
                    isOwnProfile: isOwnProfile,
                    onTap: isOwnProfile
                        ? () =>
                            _showDateDialog(context, provider, birthday)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.successLight,
                    label: 'Giới thiệu',
                    value: bio.isEmpty ? 'Chưa cập nhật' : bio,
                    isOwnProfile: isOwnProfile,
                    onTap: isOwnProfile
                        ? () => _showBioDialog(context, provider, bio)
                        : null,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNameDialog(BuildContext context, ProfileProvider provider,
      String currentName) async {
    final parts = currentName.trim().split(' ');
    final firstNameController =
        TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    final lastNameController = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chỉnh sửa tên'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'Họ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Họ không được trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Tên không được trống' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    try {
      await AuthService.updateUserInfo(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: provider.birthday,
        bio: provider.userProfile?.bio,
      );
      if (!context.mounted) return;
      final updated = provider.userProfile;
      if (updated != null) {
        provider.updateUserProfile(UserProfileModel(
          id: updated.id,
          fullName: '$firstName $lastName',
          email: updated.email,
          avatar: updated.avatar,
          dateOfBirth: updated.dateOfBirth,
          bio: updated.bio,
        ));
      } else {
        await provider.loadProfile(
          FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật tên thành công!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showDateDialog(BuildContext context, ProfileProvider provider,
      String currentBirthday) async {
    DateTime? selected;
    if (currentBirthday.isNotEmpty) {
      try {
        final parts = currentBirthday.split('-');
        selected = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } catch (_) {}
    }
    selected ??= DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    final dateStr =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      await AuthService.updateUserInfo(
        firstName: provider.userProfile?.firstName ?? '',
        lastName: provider.userProfile?.lastName ?? '',
        dateOfBirth: dateStr,
        bio: provider.userProfile?.bio,
      );
      if (!context.mounted) return;
      await provider.loadProfile(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật ngày sinh thành công!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showBioDialog(BuildContext context, ProfileProvider provider,
      String currentBio) async {
    final bioController = TextEditingController(text: currentBio);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chỉnh sửa giới thiệu'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: bioController,
            decoration: InputDecoration(
              labelText: 'Giới thiệu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: 'Viết gì đó về bản thân...',
            ),
            maxLines: 3,
            maxLength: 200,
            validator: (v) =>
                v != null && v.length > 200 ? 'Tối đa 200 ký tự' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != true) return;
    try {
      await AuthService.updateUserInfo(
        firstName: provider.userProfile?.firstName ?? '',
        lastName: provider.userProfile?.lastName ?? '',
        dateOfBirth: provider.birthday,
        bio: bioController.text.trim(),
      );
      if (!context.mounted) return;
      await provider.loadProfile(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật giới thiệu thành công!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isOwnProfile;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isOwnProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = isOwnProfile && onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canEdit ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkPremiumSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.darkPremiumBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkPremiumTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.isEmpty ? 'Chưa cập nhật' : value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: value.isEmpty
                            ? AppColors.darkPremiumTextSecondary
                            : AppColors.darkPremiumTextPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                const Icon(
                  Icons.edit_rounded,
                  color: AppColors.neonRoyal,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TAB 2: IMAGES
// ============================================================
class _ImagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final posts = provider.posts;
        final imagePosts =
            posts.where((p) => p.mediaUrls.isNotEmpty).toList();
        if (imagePosts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
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
                      Icons.photo_library_rounded,
                      size: 36,
                      color: AppColors.primaryBlue.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Chưa có ảnh nào',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hãy đăng ảnh để hiển thị trong album',
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
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = imagePosts[index];
                    final firstImage = post.mediaUrls.first;
                    return GestureDetector(
                      onTap: () => _showImagePostSheet(context, post),
                      child: Hero(
                        tag: 'img_$firstImage',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            firstImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: imagePosts.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImagePostSheet(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImagePostSheet(post: post),
    );
  }
}

class _ImagePostSheet extends StatelessWidget {
  final PostModel post;

  const _ImagePostSheet({required this.post});

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
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(post.userName);
    final initials = _initials(post.userName);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    const Text(
                      'Bài viết có ảnh',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipOval(
                              child: post.userAvatar.isNotEmpty
                                  ? Image.network(
                                      post.userAvatar,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      post.userName,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (post.isOwner) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Bạn',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatTime(post.createdAt),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(
                          post.content,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: post.mediaUrls.length == 1
                              ? 1
                              : post.mediaUrls.length == 2
                                  ? 2
                                  : 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 1,
                          children: post.mediaUrls.map((url) {
                            return Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey.shade400),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// TAB 3: SETTINGS
// ============================================================
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  int _selectedSettingsIndex = 0;
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGray,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: _buildSettingsContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    switch (_selectedSettingsIndex) {
      case 0:
        return Column(
          children: [
            _buildSettingsGroup(
              title: 'Tài khoản',
              items: [
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.primaryOrange,
                  title: 'Mật khẩu & bảo mật',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.accentRed,
                  title: 'Thông báo',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.successLight,
                  title: 'Quyền riêng tư',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSettingsGroup(
              title: 'Hỗ trợ',
              items: [
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.primaryOrangeLight,
                  title: 'Trợ giúp & phản hồi',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.accentBrown,
                  title: 'Về TriChat',
                  subtitle: 'Phiên bản 1.0.0',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TriChat v1.0.0')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildLogoutTile(),
          ],
        );
      case 1:
        return _buildAppearanceSettings();
      case 2:
        return _buildLanguageSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 60),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.accentRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final friendProvider = context.read<FriendProvider>();
    await friendProvider.disposeRealtime();
    friendProvider.clear();
    if (!mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Widget _buildAppearanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'GIAO DIỆN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.neutralGray700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildThemeOption('Chế độ sáng', false, Icons.light_mode_rounded, [AppColors.primaryOrangeLight, AppColors.primaryOrange]),
              const SizedBox(height: 6),
              _buildThemeOption('Chế độ tối', true, Icons.dark_mode_rounded, [AppColors.accentBrown, AppColors.accentBrown]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    String title,
    bool isDarkOption,
    IconData icon,
    List<Color> colors,
  ) {
    final isSelected = _isDark == isDarkOption;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isDark = isDarkOption),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.06),
                      AppColors.primaryBlue.withValues(alpha: 0.02),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.neutralBlack,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'NGÔN NGỮ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.neutralGray700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildLanguageOption('Tiếng Việt', 'vi', true,
                  Icons.flag_rounded, [AppColors.accentRed, AppColors.accentRed]),
              const SizedBox(height: 6),
              _buildLanguageOption('English', 'en', false,
                  Icons.flag_outlined, [AppColors.primaryOrange, AppColors.accentBrown]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    String title,
    String code,
    bool isSelected,
    IconData icon,
    List<Color> colors,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã chọn: $title')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.neutralBlack,
                  ),
                ),
              ),
              Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AVATAR CHOICE SHEET
// ============================================================
class _AvatarChoiceSheet extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onAvatarOnly;
  final VoidCallback onPostOnly;
  final VoidCallback onBoth;

  const _AvatarChoiceSheet({
    required this.imageBytes,
    required this.onAvatarOnly,
    required this.onPostOnly,
    required this.onBoth,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              imageBytes,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Bạn muốn làm gì với ảnh này?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralBlack,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _buildChoiceTile(
            context,
            icon: Icons.camera_alt_rounded,
            iconColor: AppColors.primaryBlue,
            gradient: const [AppColors.primaryOrange, AppColors.accentBrown],
            title: 'Đổi ảnh đại diện',
            subtitle: 'Cập nhật avatar trên trang cá nhân',
            onTap: onAvatarOnly,
          ),
          _buildChoiceTile(
            context,
            icon: Icons.article_outlined,
            iconColor: AppColors.successLight,
            gradient: const [AppColors.successLight, AppColors.success],
            title: 'Đăng bài viết mới',
            subtitle: 'Chia sẻ ảnh lên trang cá nhân',
            onTap: onPostOnly,
          ),
          _buildChoiceTile(
            context,
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.primaryOrangeLight,
            gradient: const [AppColors.primaryOrangeLight, AppColors.primaryOrange],
            title: 'Cả hai',
            subtitle: 'Đổi avatar và đăng bài viết',
            onTap: onBoth,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralGray700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
