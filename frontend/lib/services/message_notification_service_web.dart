/// Web stub cho message notification service

class MessageNotificationService {
  static String? activeConversationId;
  static void Function(String conversationId)? onNotificationTap;

  static Future<void> initialize() async {}

  static Future<void> checkInitialMessage() async {}

  static Future<void> showLocal(String title, String body, String convId) async {}
}
