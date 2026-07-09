// Stub for web - path_provider not available
import 'dart:typed_data';

class PathProvider {
  static Future<String> getTemporaryDirectory() async {
    return '/tmp';
  }
}
