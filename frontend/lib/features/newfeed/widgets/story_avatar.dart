import 'package:flutter/material.dart';
import '../models/story_model.dart';
import 'story_ring.dart';
import 'package:frontend/config/app_colors.dart';

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
    final bgUrl = latestStory?.imageUrl ??
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=800';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 152,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: NetworkImage(bgUrl),
            fit: BoxFit.cover,
          ),
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
                  child: userStory.userAvatar.isNotEmpty
                      ? Image.network(
                          userStory.userAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitials(),
                        )
                      : _buildInitials(),
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

  Widget _buildInitials() {
    final name = userStory.userName.isNotEmpty ? userStory.userName : '?';
    return Container(
      color: AppColors.primaryOrange,
      alignment: Alignment.center,
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
