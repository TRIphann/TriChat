import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/app_colors.dart';
import '../providers/story_provider.dart';
import 'story_avatar.dart';

class StoryList extends StatelessWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const StoryList({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPremiumBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          final stories = provider.userStories;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    Text(
                      'Khoảnh khắc',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkPremiumTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonOrange.withValues(alpha: 0.18),
                            AppColors.neonPink.withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.neonPink.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) =>
                                LinearGradient(
                              colors: [
                                AppColors.neonOrange,
                                AppColors.neonPink,
                                AppColors.neonPurple,
                              ],
                            ).createShader(rect),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Mới',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stories.length + (provider.hasMore ? 2 : 1),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddStory(context);
                    }
                    if (index <= stories.length) {
                      final userStory = stories[index - 1];
                      return StoryAvatar(
                        userStory: userStory,
                        onTap: () => _openStoryViewer(context, index - 1),
                      );
                    }
                    return _buildSeeMoreButton(context, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeeMoreButton(BuildContext context, StoryProvider provider) {
    return GestureDetector(
      onTap: () => provider.loadMore(),
      child: Container(
        width: 104,
        height: 152,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.darkPremiumElevated,
          border: Border.all(color: AppColors.darkPremiumBorder, width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.darkPremiumTextSecondary,
              size: 18,
            ),
            SizedBox(height: 6),
            Text(
              'Xem thêm',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkPremiumTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStory(BuildContext context) {
    final hasAvatar = currentUserAvatar.isNotEmpty;
    return GestureDetector(
      onTap: () => context.push('/create-story'),
      child: Container(
        width: 104,
        height: 152,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF1E1E1E),
          image: hasAvatar
              ? DecorationImage(
                  image: NetworkImage(currentUserAvatar),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.2),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Gradient ring ở avatar vùng dưới
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.neonOrange,
                        AppColors.neonPink,
                        AppColors.neonPurple,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkPremiumSurface,
                    ),
                    child: ClipOval(
                      child: hasAvatar
                          ? Image.network(
                              currentUserAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitialsBig(),
                            )
                          : _buildInitialsBig(),
                    ),
                  ),
                ),
              ),
            ),
            // Text "Tạo mới" ở dưới
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: const Text(
                'Tạo story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            // Nút + ở giữa dưới
            Positioned(
              bottom: 26,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.neonOrange, AppColors.neonPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.darkPremiumSurface, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonOrange.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsBig() {
    final name = currentUserName.isNotEmpty ? currentUserName : '?';
    return Container(
      color: AppColors.neonOrange,
      alignment: Alignment.center,
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, int startIndex) {
    context.push('/story-viewer', extra: startIndex);
  }
}
