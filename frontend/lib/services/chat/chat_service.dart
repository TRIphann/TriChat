// Conditional export for ChatService
// Web uses chat_service_web.dart (Uint8List for uploads)
// Native uses chat_service_io.dart (dart:io File for uploads)
export 'chat_service_web.dart'
    if (dart.library.io) 'chat_service_io.dart';
