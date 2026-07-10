import 'package:flutter/foundation.dart';

/// Web stub for call notification service
/// CallKeep và native call UI không khả dụng trên web

class CallNotificationService {
  static final ValueNotifier<dynamic> acceptedCall = ValueNotifier(null);
  static final ValueNotifier<dynamic> declinedCall = ValueNotifier(null);
  static final ValueNotifier<dynamic> incomingCall = ValueNotifier(null);

  static Future<void> showIncomingCall(Map<String, dynamic> data) async {}

  static Future<void> initialize() async {}

  static Future<void> saveTokenToServer() async {}

  static Future<void> checkPendingCall(
      Function(Map<String, String>) onIncomingCall) async {}
}
