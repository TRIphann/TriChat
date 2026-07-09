import 'package:flutter_dotenv/flutter_dotenv.dart';

String? _dotenv(String key) {
  try {
    return dotenv.env[key];
  } catch (_) {
    return null;
  }
}

class AgoraConfig {
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

  static String generateToken(String channelName) => '';
}
