import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/component/avatars.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  // Friends pagination
  static const int _initialShow = 6;
  static const int _pageSize = 20;
  int _shownCount = _initialShow;

  // Search state
  List<UserSearchModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Reset shown friends count when query changes
    setState(() => _shownCount = _initialShow);
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
        _hasError = false;
        _shownCount = _initialShow;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(value));
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // For queries >= 3 chars, search API (matches friends by name or strangers by full email)
    // For < 3 chars, we only show filtered friends locally
    if (trimmed.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = true;
      });
      return;
    }

    try {
      final results = await FriendService.searchUsers(trimmed);

      if (!mounted) return;

      // Filter out only current user (friends still show with "Nhắn tin" button)
      final filtered = results
          .where((u) => u.id != FirebaseAuth.instance.currentUser?.uid)
          .toList();

      setState(() {
        _searchResults = filtered;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = true;
        _hasError = true;
      });
    }
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearched = false;
      _hasError = false;
      _shownCount = _initialShow;
    });
  }

  // ================= BASE TILE =================

  Widget _buildUserTile({
    required String name,
    required String avatar,
    required Widget trailing,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.darkPremiumBorder)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              TriAvatar(
                imageUrl: avatar,
                name: name,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkPremiumTextPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.darkPremiumTextSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FRIEND TILE =================

  Widget _friendTile(FriendSummaryModel f) {
    return _buildUserTile(
      name: f.fullName,
      avatar: f.avatar,
      subtitle: 'Bạn bè',
      onTap: () async {
        // Open chat conversation directly
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.openChatWithUser(f.friendId);
        // Pop back to chat list (only one route above us)
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.neonRoyal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          onPressed: () async {
            final chatProvider = context.read<ChatProvider>();
            await chatProvider.openChatWithUser(f.friendId);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Nhắn tin',
        ),
      ),
    );
  }

  // ================= SEARCH TILE =================

  Widget _searchTile(UserSearchModel user) {
    final provider = context.watch<FriendProvider>();
    final sent = provider.pendingSent.any((f) => f.addresseeId == user.id);
    final received = provider.getReceivedRequest(user.id);
    final isFriend = provider.isFriend(user.id);
    final isLoading = provider.isActionLoading(user.id);

    Widget action;

      if (isLoading) {
      action = SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonRoyal),
          ),
        ),
      );
    } else if (isFriend) {
      action = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.neonRoyal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          onPressed: () async {
            final chatProvider = context.read<ChatProvider>();
            await chatProvider.openChatWithUser(user.id);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Nhắn tin',
        ),
      );
    } else if (received != null) {
      action = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => provider.declineFriendRequest(user.id),
            icon: Icon(Icons.close, color: AppColors.darkPremiumTextSecondary, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Từ chối',
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.neonRoyal,
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              onPressed: () => provider.acceptFriendRequest(user.id),
              icon: Icon(Icons.check, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Xác nhận',
            ),
          ),
        ],
      );
    } else if (sent) {
      action = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          onPressed: () => provider.cancelFriendRequest(user.id),
          icon: Icon(Icons.close, color: AppColors.darkPremiumTextSecondary, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Thu hồi',
        ),
      );
    } else {
      action = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.neonRoyal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IconButton(
          onPressed: () => provider.sendFriendRequest(user.id),
          icon: Icon(Icons.person_add, color: Colors.white, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Kết bạn',
        ),
      );
    }

    return _buildUserTile(
      name: user.fullName.isNotEmpty ? user.fullName : user.email,
      avatar: user.avatar,
      subtitle: user.email,
      onTap: () async {
        // Open chat conversation directly with this user
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.openChatWithUser(user.id);
        // Pop back to chat list to see the conversation
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      trailing: action,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    final allFriends = provider.friends;
    final shownFriends = allFriends.take(_shownCount).toList();
    final hasMoreFriends = _shownCount < allFriends.length;
    final query = _controller.text.trim();

    // Determine if we should show friends list (empty query)
    final showFriendsList = query.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.darkPremiumSurface,
      appBar: AppBar(
        backgroundColor: AppColors.darkPremiumSurface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkPremiumTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.darkPremiumElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: AppColors.darkPremiumTextPrimary),
            cursorColor: AppColors.neonRoyal,
            decoration: InputDecoration(
              hintText: 'Tìm bạn bè, email...',
              hintStyle: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: AppColors.darkPremiumTextSecondary, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clear,
                      icon: Icon(Icons.close, size: 14, color: AppColors.darkPremiumTextSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    )
                  : null,
            ),
            onChanged: _onTextChanged,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isSearching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Load more friends when scrolled to bottom
                if (!notification.metrics.atEdge) return false;
                if (notification.metrics.pixels < notification.metrics.maxScrollExtent - 100) return false;
                if (!hasMoreFriends) return false;

                setState(() {
                  _shownCount += _pageSize;
                });
                return false;
              },
              child: ListView(
                children: [
                  // ===== SECTION: FRIENDS (only when search is empty) =====
                  if (showFriendsList && shownFriends.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bạn bè (${allFriends.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkPremiumTextSecondary,
                            ),
                          ),
                          if (hasMoreFriends)
                            GestureDetector(
                              onTap: () => setState(() => _shownCount = allFriends.length),
                              child: Text(
                                'Xem thêm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.neonRoyal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...shownFriends.map(_friendTile),
                    if (hasMoreFriends)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => setState(() => _shownCount = allFriends.length),
                            child: Text(
                              'Tải thêm bạn bè',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // ===== SECTION: EMPTY STATE (no search, no friends) =====
                  if (showFriendsList && allFriends.isEmpty && !_isSearching) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_add_alt_1, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có bạn bè nào',
                            style: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tìm kiếm để kết bạn',
                            style: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ===== SECTION: SEARCH RESULTS (only when searching) =====
                  if (!showFriendsList) ...[
                    if (_searchResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(
                          'Kết quả tìm kiếm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkPremiumTextSecondary,
                          ),
                        ),
                      ),
                      ..._searchResults.map(_searchTile),
                    ] else if (_hasSearched && !_isSearching && !_hasError) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: AppColors.darkPremiumTextSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy kết quả',
                              style: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // ===== SECTION: ERROR STATE =====
                  if (_hasError) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppColors.accentRed),
                          const SizedBox(height: 12),
                          Text(
                            'Có lỗi xảy ra khi tìm kiếm',
                            style: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
