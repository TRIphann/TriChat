import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/component/widgets.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/services/friend_service.dart';

/// Callback khi chọn một người dùng.
typedef OnUserSelected = void Function({
  required String userId,
  required String name,
  required String? avatar,
});

/// Màn hình tìm kiếm overlay.
///
/// Hiển thị danh sách liên hệ gần đây (avatar + tên) ở dạng cuộn ngang.
/// Khi gõ, danh sách kết quả tìm kiếm xổ xuống bên dưới sau debounce 0.5s.
/// Nút quay lại gọi [onBack], cho phép parent quyết định hành động
/// (ví dụ: Navigator.pop hoặc chuyển tab).
class SearchOverlayScreen extends StatefulWidget {
  /// Callback khi nhấn nút quay lại.
  final VoidCallback onBack;

  /// Callback khi chọn một người dùng từ kết quả tìm kiếm.
  final OnUserSelected? onSearchResultTap;

  /// Danh sách liên hệ gần đây (avatar + tên).
  final List<Map<String, dynamic>> recentContacts;

  /// Callback khi chọn một liên hệ gần đây.
  final void Function(Map<String, dynamic> contact)? onRecentContactTap;

  const SearchOverlayScreen({
    super.key,
    required this.onBack,
    this.onSearchResultTap,
    this.recentContacts = const [],
    this.onRecentContactTap,
  });

  @override
  State<SearchOverlayScreen> createState() => _SearchOverlayScreenState();
}

class _SearchOverlayScreenState extends State<SearchOverlayScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<UserSearchModel> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _debounce?.cancel();
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
        _hasError = false;
      });
      return;
    }

    setState(() {});

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await FriendService.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _hasError = true;
          _hasSearched = true;
        });
      }
    }
  }

  void _onRecentContactTap(Map<String, dynamic> contact) {
    widget.onRecentContactTap?.call(contact);
  }

  void _onSearchResultTap(UserSearchModel user) {
    widget.onSearchResultTap?.call(
      userId: user.id,
      name: user.fullName.isNotEmpty ? user.fullName : user.email,
      avatar: user.avatar.isNotEmpty ? user.avatar : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.darkPremiumBackground,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(child: _buildBody(isDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonRoyalGlow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.darkPremiumTextPrimary,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkPremiumElevated,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.darkPremiumBorder,
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.md),
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.neonRoyal,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.darkPremiumTextPrimary,
                      ),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm tin nhắn, người trong TriChat',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.darkPremiumTextHint,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (_, value, _) {
                      if (value.text.isEmpty) {
                        return const SizedBox(width: AppSpacing.md);
                      }
                      return GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _isLoading = false;
                            _hasSearched = false;
                            _hasError = false;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            Icons.cancel_rounded,
                            color: AppColors.darkPremiumTextHint,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onBack,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    if (hasQuery) return _buildSearchResults(isDark);
    return _buildRecentContacts(isDark);
  }

  Widget _buildRecentContacts(bool isDark) {
    if (widget.recentContacts.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: 'Chưa có liên hệ gần đây',
        subtitle: 'Bắt đầu trò chuyện để thấy danh sách ở đây',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SectionHeader(
            title: 'Tin nhắn trực tiếp',
            isDark: isDark,
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            itemCount: widget.recentContacts.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final contact = widget.recentContacts[index];
              return _RecentContactChip(
                contact: contact,
                isDark: isDark,
                onTap: () => _onRecentContactTap(contact),
              );
            },
          ),
        ),
        const Divider(height: AppSpacing.lg),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Tìm kiếm người trong danh bạ TriChat',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isLoading) {
      return const LoadingView(
        message: 'Đang tìm kiếm...',
      );
    }

    if (_hasError) {
      return ErrorStateView(
        icon: Icons.wifi_off_rounded,
        title: 'Không thể kết nối',
        message: 'Vui lòng kiểm tra mạng và thử lại',
        onRetry: () => _performSearch(_searchController.text),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy người dùng',
        subtitle: 'Thử tìm với từ khóa khác',
      );
    }

    if (_results.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: AppColors.getDivider(isDark)),
      itemBuilder: (context, index) {
        final user = _results[index];
        return _SearchResultTile(
          user: user,
          isDark: isDark,
          onTap: () => _onSearchResultTap(user),
        );
      },
    );
  }
}

/// Chip liên hệ gần đây: avatar tròn + tên bên dưới.
class _RecentContactChip extends StatelessWidget {
  final Map<String, dynamic> contact;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentContactChip({
    required this.contact,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = contact['name'] ?? '';
    final avatar = contact['avatar'];
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              TriAvatar(
                imageUrl: avatar is String ? avatar : '',
                name: name,
                size: 56,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.creamWhite,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.getTextPrimary(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng kết quả tìm kiếm.
class _SearchResultTile extends StatelessWidget {
  final UserSearchModel user;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.creamWhite,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              TriAvatar(
                imageUrl: user.avatar,
                name: user.fullName.isNotEmpty ? user.fullName : user.email,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.email,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.getTextPrimary(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email.isNotEmpty && user.fullName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (user.status) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}