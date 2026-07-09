import 'package:flutter/foundation.dart';

/// Web stub for call notification service
/// CallKeep và native call UI không khả dụng trên web

class CallNotificationService {
  static final ValueNotifier<dynamic> acceptedCall = ValueNotifier(null);
  static final ValueNotifier<dynamic> declinedCall = ValueNotifier(null);
  static final ValueNotifier<dynamic> incomingCall = ValueNotifier(null);

  static Future<void> showIncomingCall(Map<String, dynamic> data) async {
    debugPrint('[CallNotificationService Web] showIncomingCall called');
  }

  static Future<void> initialize() async {
    debugPrint('[CallNotificationService Web] initialized (stub)');
  }

  static Future<void> saveTokenToServer() async {
    debugPrint('[CallNotificationService Web] saveTokenToServer called');
  }

  static Future<void> checkPendingCall(
      Function(Map<String, String>) onIncomingCall) async {
    debugPrint('[CallNotificationService Web] checkPendingCall called');
  }
}
