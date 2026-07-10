import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:uuid/uuid.dart';

/// Background handler — app bị kill, FCM đến → hiện native call UI
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.data['type'] == 'incoming_call') {
    await CallNotificationService.showIncomingCall(message.data);
  }
}

class CallNotificationService {
  static final _fcm = FirebaseMessaging.instance;

  static final ValueNotifier<CallEvent?> acceptedCall  = ValueNotifier(null);
  static final ValueNotifier<CallEvent?> declinedCall  = ValueNotifier(null);
  static final ValueNotifier<CallEvent?> incomingCall  = ValueNotifier(null);

  static Future<void> showIncomingCall(Map<String, dynamic> data) async {
    final uuid = const Uuid().v4();
    final callEvent = CallEvent(
      uuid:       uuid,
      callerName: data['caller_name'] ?? 'Cuộc gọi đến',
      handle:     data['caller_id'] ?? '',
      hasVideo:   data['call_type'] == 'video',
      duration:   30000,
      extra: {
        'conversation_id': data['conversation_id'] ?? '',
        'caller_id':       data['caller_id'] ?? '',
        'caller_name':     data['caller_name'] ?? '',
        'caller_avatar':   data['caller_avatar'] ?? '',
        'call_type':       data['call_type'] ?? 'voice',
      },
    );
    await CallKeep.instance.displayIncomingCall(callEvent);
  }

  static Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    CallKeep.instance.configure(CallKeepConfig(
      appName: 'TriChat',
      acceptText: 'Chấp nhận',
      declineText: 'Từ chối',
      missedCallText: 'Cuộc gọi nhỡ',
      callBackText: 'Gọi lại',
      android: CallKeepAndroidConfig(
        logo: 'ic_launcher',
        accentColor: '#0068FF',
        showCallBackAction: false,
        showMissedCallNotification: true,
        incomingCallNotificationChannelName: 'Cuộc gọi đến',
        missedCallNotificationChannelName: 'Cuộc gọi nhỡ',
      ),
      ios: CallKeepIosConfig(
        handleType: CallKitHandleType.generic,
        isVideoSupported: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionActive: true,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        supportsDTMF: false,
      ),
    ));

    CallKeep.instance.handler = CallEventHandler(
      onCallIncoming: (event) {
        incomingCall.value = event;
      },
      onCallAccepted: (event) {
        acceptedCall.value = event;
      },
      onCallDeclined: (event) {
        declinedCall.value = event;
      },
      onCallEnded: (_) {
        acceptedCall.value = null;
      },
    );
  }

  static Future<void> saveTokenToServer() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await ChatService().saveFcmToken(token);
      _fcm.onTokenRefresh.listen((t) => ChatService().saveFcmToken(t));
    } catch (_) {}
  }

  static Future<void> checkPendingCall(
      Function(Map<String, String>) onIncomingCall) async {
    final initial = await _fcm.getInitialMessage();
    if (initial != null && initial.data['type'] == 'incoming_call') {
      onIncomingCall(Map<String, String>.from(initial.data));
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'incoming_call') {
        onIncomingCall(Map<String, String>.from(message.data));
      }
    });
  }
}
