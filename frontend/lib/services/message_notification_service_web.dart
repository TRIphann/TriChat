import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Web stub cho message notification service
/// Sử dụng Web Notification API thay vì flutter_local_notifications

class MessageNotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static String? activeConversationId;
  static void Function(String conversationId)? onNotificationTap;

  static Future<void> initialize() async {
    debugPrint('[MessageNotificationService Web] initialized (stub)');
    // Web không cần local notifications plugin
  }

  static Future<void> checkInitialMessage() async {
    debugPrint('[MessageNotificationService Web] checkInitialMessage called');
  }

  static Future<void> showLocal(String title, String body, String convId) async {
    debugPrint('[MessageNotificationService Web] showLocal: $title - $body');
  }
}
