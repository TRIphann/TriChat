import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import '../models/story_model.dart';
import 'story_ring.dart';
import 'package:frontend/component/avatars.dart';

class StoryAvatar extends StatelessWidget {
  final UserStory userStory;
  final VoidCallback onTap;

  const StoryAvatar({
    super.key,
    required this.userStory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final latestStory = userStory.stories.isNotEmpty ? userStory.stories.first : null;
    // Use the user's avatar as the story background fallback, falling back to
    // a solid dark gradient if neither is available — never an external default
    // photo, which looks like a placeholder bug.
    final bgUrl = latestStory?.imageUrl ?? userStory.userAvatar;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 152,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: bgUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(bgUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : const BoxDecoration(),
          gradient: bgUrl.isEmpty
              ? LinearGradient(
                  colors: [
                    AppColors.darkPremiumSurface,
                    AppColors.darkPremiumElevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.35, 0.55, 1.0],
                ),
              ),
            ),
            // Avatar with ring at top
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: StoryRing(
                  hasUnseen: userStory.hasUnseenStories,
                  isOwner: userStory.isOwner,
                  size: 48,
                  child: TriAvatar(
                    imageUrl: userStory.userAvatar,
                    name: userStory.userName,
                    size: 44,
                  ),
                ),
              ),
            ),
            // User Name at the bottom
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: Text(
                userStory.userName.isNotEmpty ? userStory.userName : '...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
