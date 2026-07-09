// Stub for web - flutter_callkeep not available
import 'package:flutter/foundation.dart';

class CallEvent {
  final String uuid;
  final String callerName;
  final String handle;
  final bool hasVideo;
  final int duration;
  final Map<String, dynamic> extra;

  CallEvent({
    required this.uuid,
    required this.callerName,
    required this.handle,
    required this.hasVideo,
    required this.duration,
    required this.extra,
  });
}

class CallKeep {
  static CallKeep get instance => _instance;
  static final _instance = CallKeep._();

  CallKeep._();

  CallEventHandler? handler;

  Future<void> configure(CallKeepConfig config) async {
    debugPrint('[CallKeep Stub] configure called');
  }

  Future<void> displayIncomingCall(CallEvent event) async {
    debugPrint('[CallKeep Stub] displayIncomingCall: ${event.callerName}');
  }

  Future<List<CallEvent>> activeCalls() async {
    debugPrint('[CallKeep Stub] activeCalls called');
    return [];
  }

  Future<void> endAllCalls() async {
    debugPrint('[CallKeep Stub] endAllCalls called');
  }
}

class CallKeepConfig {
  final String appName;
  final String acceptText;
  final String declineText;
  final String missedCallText;
  final String callBackText;
  final CallKeepAndroidConfig? android;
  final CallKeepIosConfig? ios;

  CallKeepConfig({
    required this.appName,
    required this.acceptText,
    required this.declineText,
    required this.missedCallText,
    required this.callBackText,
    this.android,
    this.ios,
  });
}

class CallKeepAndroidConfig {
  final String? logo;
  final String? accentColor;
  final bool? showCallBackAction;
  final bool? showMissedCallNotification;
  final String? incomingCallNotificationChannelName;
  final String? missedCallNotificationChannelName;

  CallKeepAndroidConfig({
    this.logo,
    this.accentColor,
    this.showCallBackAction,
    this.showMissedCallNotification,
    this.incomingCallNotificationChannelName,
    this.missedCallNotificationChannelName,
  });
}

class CallKeepIosConfig {
  final dynamic handleType;
  final bool isVideoSupported;
  final int maximumCallGroups;
  final int maximumCallsPerCallGroup;
  final bool audioSessionActive;
  final bool supportsHolding;
  final bool supportsGrouping;
  final bool supportsUngrouping;
  final bool supportsDTMF;

  CallKeepIosConfig({
    this.handleType,
    required this.isVideoSupported,
    required this.maximumCallGroups,
    required this.maximumCallsPerCallGroup,
    required this.audioSessionActive,
    required this.supportsHolding,
    required this.supportsGrouping,
    required this.supportsUngrouping,
    required this.supportsDTMF,
  });
}

enum CallKitHandleType { generic }

class CallEventHandler {
  final void Function(CallEvent)? onCallIncoming;
  final void Function(CallEvent)? onCallAccepted;
  final void Function(CallEvent)? onCallDeclined;
  final void Function(CallEvent)? onCallEnded;

  CallEventHandler({
    this.onCallIncoming,
    this.onCallAccepted,
    this.onCallDeclined,
    this.onCallEnded,
  });
}
