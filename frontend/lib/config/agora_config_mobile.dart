import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agora_token_generator/agora_token_generator.dart';

/// Reads a value from dotenv (.env file on mobile/desktop, skipped on web).
/// Accessing a non-existent key throws DotEnvNotInitialized — we catch that.
String? _dotenv(String key) {
  try {
    return dotenv.env[key];
  } catch (_) {
    return null;
  }
}

class AgoraConfig {
  // NOTE: on web builds, --dart-define=AGORA_APP_ID=... is baked in at compile
  // time.  On mobile/desktop .env is loaded before this class is accessed, so
  // dotenv.env[key] works.  Both paths go through the _dotenv() helper above.

  static String get appId =>
      _dotenv('AGORA_APP_ID') ??
      const String.fromEnvironment('AGORA_APP_ID', defaultValue: '');

  static String get appCertificate =>
      _dotenv('AGORA_APP_CERTIFICATE') ??
      const String.fromEnvironment('AGORA_APP_CERTIFICATE', defaultValue: '');

  static String generateChannelName(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static String generateToken(String channelName) {
    final id = appId;
    final cert = appCertificate;
    if (id.isEmpty || cert.isEmpty) return '';
    return RtcTokenBuilder.buildTokenWithUid(
      appId: id,
      appCertificate: cert,
      channelName: channelName,
      uid: 0,
      tokenExpireSeconds: 3600,
    );
  }
}
