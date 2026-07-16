import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/dio_client.dart';
import '../models/story_model.dart';

class StoryService {
  static final Dio _dio = DioClient.instance;

  static Future<List<UserStory>> getStories() async {
    try {
      final response = await _dio.get('/api/feed/stories');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>?;
        if (result == null) return [];

        final List<StoryModel> flatStories = result
            .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Group stories by userId
        final Map<String, List<StoryModel>> grouped = {};
        for (final story in flatStories) {
          grouped.putIfAbsent(story.userId, () => []).add(story);
        }

        // Get current user to determine ownership
        final currentUser = FirebaseAuth.instance.currentUser;
        final currentUserId = currentUser?.uid ?? '';

        // Convert to List<UserStory>
        final List<UserStory> userStories = [];
        grouped.forEach((userId, stories) {
          if (stories.isNotEmpty) {
            final first = stories.first;
            final isOwner = userId == currentUserId;
            userStories.add(UserStory(
              oderId: userId,
              userName: first.userName,
              userAvatar: first.userAvatar,
              stories: stories,
              isOwner: isOwner,
            ));
          }
        });

        // Sort: Owner first, then others by latest story creation date
        userStories.sort((a, b) {
          if (a.isOwner) return -1;
          if (b.isOwner) return 1;
          if (a.stories.isEmpty) return 1;
          if (b.stories.isEmpty) return -1;
          return b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
        });

        return userStories;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<StoryModel> createStory({
    required XFile imageFile,
  }) async {
    try {
      // Clean filename to prevent ASP.NET Core from discarding it due to slashes (common in Web Blobs/camera captures)
      String safeFilename = imageFile.name;
      if (safeFilename.isEmpty || 
          safeFilename.contains('/') || 
          safeFilename.contains('\\') || 
          !safeFilename.contains('.')) {
        safeFilename = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      final bytes = await imageFile.readAsBytes();
      final formData = FormData.fromMap({
        'Type': 'story',
        'Privacy': 'public',
        'Content.Caption': '',
        'Content.Text': '',
        'files': MultipartFile.fromBytes(bytes, filename: safeFilename),
      });

      final response = await _dio.post('/api/feed', data: formData);

      // Accept both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Handle nested 'result' field
        dynamic result = data is Map ? data['result'] ?? data : data;
        if (result == null) throw Exception('Invalid response from server');
        return StoryModel.fromJson(result is Map ? result.cast<String, dynamic>() : {});
      }
      throw Exception('Failed to create story: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Lỗi tạo story: $e');
    }
  }

  static Future<void> viewStory(String storyId) async {
    try {
      await _dio.post('/api/feed/$storyId/view');
    } on DioException catch (_) {}
  }

  static Future<void> deleteStory(String storyId) async {
    try {
      await _dio.delete('/api/feed/$storyId');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static String _handleError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Chưa đăng nhập hoặc token hết hạn';
    if (status == 404) return 'Không tìm thấy tin';
    if (status != null) return 'Lỗi server $status';
    return 'Lỗi kết nối: ${e.message}';
  }
}
