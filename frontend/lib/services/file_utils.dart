// File utilities with conditional imports
import 'file_io.dart' if (dart.library.io) 'dart:io' as io;

class FileUtils {
  /// Creates a File instance - returns null on web
  static dynamic createFile(String path) {
    return io.File(path);
  }

  /// Check if file exists - always returns false on web
  static Future<bool> fileExists(dynamic file) async {
    if (file == null) return false;
    return await io.File(file.path).exists();
  }

  /// Delete file - no-op on web
  static Future<void> deleteFile(dynamic file) async {
    if (file == null) return;
    try {
      await io.File(file.path).delete();
    } catch (_) {}
  }

  /// Get temp directory - returns empty on web
  static Future<String> getTempDirectory() async {
    try {
      // This will fail on web but we handle it
      return await _getTempDir();
    } catch (_) {
      return '';
    }
  }
}

// Conditional import for temp directory
String _getTempDir() => throw UnimplementedError();

String getTempDirectory_io() => throw UnimplementedError();
