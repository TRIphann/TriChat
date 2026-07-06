import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised API endpoint resolution.
///
/// Priority (highest first):
///   1. `--dart-define=API_BASE_URL=...`               (used by Docker/CI/build)
///   2. `API_BASE_URL` from `.env`                     (mobile dev only)
///   3. `window.location.origin`  when `kIsWeb`        (same-host deploy — Firebase Hosting → /api/* rewrite)
///   4. `http://10.0.2.2:5244` for Android emulator    (dev machine localhost)
///   5. `http://localhost:5244`  otherwise             (iOS simulator / desktop / older web default)
class ApiConfig {
  static String get baseUrl {
    const dartDefine = String.fromEnvironment('API_BASE_URL');
    if (dartDefine.isNotEmpty) return dartDefine;

    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      // On web, "localhost" is the user's browser. The SPA is usually deployed
      // behind the same origin as the backend (e.g. Firebase Hosting rewrites
      // /api/* and /hubs/* to the ASP.NET Core service), so default to the
      // current origin which will work out-of-the-box.
      try {
        // ignore: avoid_web_libraries_in_flutter
        return _webOrigin();
      } catch (_) {
        return 'http://localhost:5244';
      }
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:5244';
    return 'http://localhost:5244';
  }

  static String _webOrigin() {
    // We cannot import dart:html on non-web platforms. Guarded by kIsWeb at
    // the call site, so this body is only reached in the browser.
    // Keep the helper tiny and defensive.
    // ignore: avoid_web_libraries_in_flutter
    return Uri.base.origin;
  }
}
