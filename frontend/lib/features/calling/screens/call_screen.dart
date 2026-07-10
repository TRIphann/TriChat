// Conditional export for CallScreen
// Web uses call_screen_web.dart (no flutter_webrtc)
// Native uses call_screen_native.dart (full flutter_webrtc implementation)
export 'call_screen_web.dart'
    if (dart.library.io) 'call_screen_native.dart';
