// Stub for web - no platform-specific initialization needed
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> initPlatform() async {
  // Web doesn't need SystemChrome or image picker tuning
  if (kIsWeb) {
    // Skip platform-specific setup on web
  }
}

void initBackgroundHandler() {
  // No background handler on web
}
