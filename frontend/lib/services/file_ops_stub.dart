// Web stub - web uses Uint8List directly from file picker, not file paths
import 'dart:typed_data';

Future<Uint8List> readFileBytes(String path) async {
  // On web, this should not be called with file paths
  // Web should use bytes directly from file picker
  throw UnsupportedError('readFileBytes not supported on web');
}

Future<int> getFileSize(String path) async {
  throw UnsupportedError('getFileSize not supported on web');
}

Future<bool> fileExists(String path) async {
  throw UnsupportedError('fileExists not supported on web');
}
