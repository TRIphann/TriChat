// File helper for cross-platform file operations
// Uses conditional imports to support both web and mobile

import 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper_io.dart' as platform;

class FileHelper {
  static Future<String> getTempDirectory() => platform.getTempDirectory();
  static dynamic createFile(String path) => platform.createFile(path);
  static Future<bool> exists(dynamic file) => platform.exists(file);
  static Future<void> deleteFile(dynamic file) => platform.deleteFile(file);
}
