import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'platform.dart' if (dart.library.io) 'dart:io' as io;

/// Centralised API endpoint resolution.
///
/// Priority (highest first):
///   1. `--dart-define=API_BASE_URL=...`   (used by Netlify/CI/build)
///   2. `API_BASE_URL` from `.env`           (mobile/desktop dev)
///   3. `window.location.origin`  when web    (same-host SPA deploy)
///   4. `http://10.0.2.2:5244` Android emulator
///   5. `http://localhost:5244`  otherwise
class ApiConfig {
  static String get baseUrl {
    // 1. Dart define (always available — set at build time)
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;

    // 2. .env — guard against NotInitializedError on web
    final envUrl = _tryGetDotenv('API_BASE_URL');
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // 3. Web: use same origin as the browser
    if (kIsWeb) {
      return _webOrigin();
    }

    // 4. Mobile / desktop defaults
    if (!kIsWeb && io.Platform.isAndroid) return 'http://10.0.2.2:5244';
    if (!kIsWeb) return 'http://localhost:5244';
    return 'http://localhost:5244';
  }

  /// SignalR hub base URL — same as baseUrl but without the trailing path.
  /// For web, SignalR must use the same WebSocket scheme (wss:// if https).
  static String get hubUrl => baseUrl;

  /// Web origin helper — reads window.location.origin safely.
  static String _webOrigin() {
    try {
      return Uri.base.origin;
    } catch (_) {
      return 'http://localhost:5244';
    }
  }

  /// Read a dotenv key safely. Returns null if dotenv is not loaded yet
  /// (which happens on web because we skip dotenv.load() there).
  static String? _tryGetDotenv(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }
}
