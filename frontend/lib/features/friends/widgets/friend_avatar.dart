import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/component/avatars.dart';

/// Avatar tròn có badge online, dùng chung khắp màn hình bạn bè.
/// Sử dụng TriAvatar cho fallback đồng nhất.
class FriendAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final bool? isOnline;
  final Color? backgroundColor;

  const FriendAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 22,
    this.isOnline,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return TriAvatar(
      imageUrl: avatarUrl ?? '',
      name: name,
      size: radius * 2,
      online: isOnline ?? false,
    );
  }
}
