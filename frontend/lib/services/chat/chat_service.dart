// ChatService - works on both web and native platforms
// Uses Uint8List for file uploads (works on all platforms)
import 'package:dio/dio.dart';
import 'package:frontend/services/dio_client.dart';
import '../../models/chat/conversation.dart';
import '../../models/chat/message.dart';

class ChatService {
  final Dio _dio = DioClient.instance;

  ChatService();

  Future<List<Conversation>> getConversations() async {
    final response = await _dio.get('/api/chat/conversations');
    final body = response.data;
    if (body is! Map || body['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: body is Map ? body['message']?.toString() : 'API error',
      );
    }
    final result = body['result'];
    if (result is! List) return [];
    return result
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> getConversation(String conversationId) async {
    final response = await _dio.get('/api/chat/conversations/$conversationId');
    return Conversation.fromJson(response.data['result']);
  }

  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      },
    );
    final data = response.data['result'] as List;
    return data.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String type,
    required String content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    bool isForwarded = false,
  }) async {
    // Backend expects PascalCase field names (SendMessageRequest)
    final response = await _dio.post(
      '/api/chat/messages',
      data: {
        'ConversationId': conversationId,
        'Type': type,
        'Content': content,
        'IsForwarded': isForwarded,
        if (mediaUrl != null) 'MediaUrl': mediaUrl,
        if (thumbnailUrl != null) 'ThumbnailUrl': thumbnailUrl,
        if (fileName != null) 'FileName': fileName,
        if (fileSize != null) 'FileSize': fileSize,
        if (replyToMessageId != null) 'ReplyToMessageId': replyToMessageId,
      },
    );
    return Message.fromJson(response.data['result']);
  }

  /// Upload ảnh/video cho tin nhắn chat lên Cloudinary (qua backend).
  /// Trả về { media_url, media_type, file_name, file_size }.
  /// Uses bytes instead of File for cross-platform compatibility.
  Future<Map<String, dynamic>> uploadMedia({
    required String conversationId,
    required String fileName,
    required int fileSize,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    final formData = FormData.fromMap({
      'ConversationId': conversationId,  // PascalCase
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _dio.post('/api/chat/upload', data: formData);
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Conversation> createConversation({
    required String type,
    required List<String> participantIds,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    // Backend expects PascalCase field names (CreateConversationRequest)
    final response = await _dio.post(
      '/api/chat/conversations',
      data: {
        'Type': type,
        'ParticipantIds': participantIds,
        if (groupName != null) 'GroupName': groupName,
        if (groupAvatarUrl != null) 'GroupAvatarUrl': groupAvatarUrl,
        if (groupDescription != null) 'GroupDescription': groupDescription,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Message> updateMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.put(
      '/api/chat/messages',
      data: {
        'ConversationId': conversationId,
        'MessageId': messageId,
        'NewContent': newContent,
      },
    );
    return Message.fromJson(response.data['result']);
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/messages/$messageId',
    );
  }

  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    // Backend expects PascalCase field names
    await _dio.post(
      '/api/chat/messages/react',
      data: {
        'ConversationId': conversationId,
        'MessageId': messageId,
        'Emoji': emoji,
      },
    );
  }

  Future<void> markAsRead(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/read',
    );
  }

  Future<void> markAsDelivered(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/delivered',
    );
  }

  Future<Conversation> updateGroup({
    required String conversationId,
    String? groupName,
    String? groupAvatarUrl,
    String? groupDescription,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.put(
      '/api/chat/conversations/group',
      data: {
        'ConversationId': conversationId,
        if (groupName != null) 'GroupName': groupName,
        if (groupAvatarUrl != null) 'GroupAvatarUrl': groupAvatarUrl,
        if (groupDescription != null) 'GroupDescription': groupDescription,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Conversation> addParticipants({
    required String conversationId,
    required List<String> userIds,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.post(
      '/api/chat/conversations/participants',
      data: {
        'ConversationId': conversationId,
        'UserIds': userIds,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/participants/$userId',
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete('/api/chat/conversations/$conversationId');
  }

  Future<void> hideMessageForMe(String conversationId, String messageId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/messages/$messageId/hide',
    );
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _dio.get('/api/user/$userId');
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<void> saveFcmToken(String token) async {
    // Backend expects PascalCase field name
    await _dio.post('/api/user/fcm-token', data: {'Token': token});
  }

  Future<Conversation> pinMessage(String conversationId, String messageId) async {
    final response = await _dio.post(
      '/api/chat/conversations/$conversationId/pin/$messageId',
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Conversation> unpinMessage(String conversationId) async {
    final response = await _dio.delete(
      '/api/chat/conversations/$conversationId/pin',
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Map<String, dynamic>> getConversationSettings(String conversationId) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/settings',
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateConversationSettings(
    String conversationId, {
    bool? isNotificationEnabled,
    String? theme,
    String? backgroundUrl,
    String? emojiSet,
    bool? autoDownloadMedia,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/settings',
      data: {
        if (isNotificationEnabled != null) 'IsNotificationEnabled': isNotificationEnabled,
        if (theme != null) 'Theme': theme,
        if (backgroundUrl != null) 'BackgroundUrl': backgroundUrl,
        if (emojiSet != null) 'EmojiSet': emojiSet,
        if (autoDownloadMedia != null) 'AutoDownloadMedia': autoDownloadMedia,
      },
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setDisappearingDuration(
    String conversationId, {
    required int durationSeconds,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/settings/disappearing',
      data: {'DurationSeconds': durationSeconds},
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setNickname(
    String conversationId,
    String userId, {
    String? nickname,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/members/$userId/nickname',
      data: {'Nickname': nickname},
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<Conversation> updateGroupSettings(
    String conversationId, {
    bool? onlyAdminCanSend,
    bool? onlyAdminCanEditInfo,
    bool? approvalRequiredToJoin,
  }) async {
    // Backend expects PascalCase field names
    final response = await _dio.put(
      '/api/chat/conversations/$conversationId/group-settings',
      data: {
        if (onlyAdminCanSend != null) 'OnlyAdminCanSend': onlyAdminCanSend,
        if (onlyAdminCanEditInfo != null) 'OnlyAdminCanEditInfo': onlyAdminCanEditInfo,
        if (approvalRequiredToJoin != null) 'ApprovalRequiredToJoin': approvalRequiredToJoin,
      },
    );
    return Conversation.fromJson(response.data['result']);
  }

  Future<Map<String, dynamic>> createJoinRequest(String conversationId) async {
    final response = await _dio.post(
      '/api/chat/conversations/$conversationId/join-requests',
    );
    return response.data['result'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getJoinRequests(String conversationId) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/join-requests',
    );
    return (response.data['result'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> approveJoinRequest(String conversationId, String userId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/join-requests/$userId/approve',
    );
  }

  Future<void> rejectJoinRequest(String conversationId, String userId) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/join-requests/$userId/reject',
    );
  }
}
