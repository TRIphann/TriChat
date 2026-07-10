// Platform-specific file operations for chat uploads
// This file exports the appropriate implementation based on platform

import 'dart:typed_data';

export 'file_ops_stub.dart' if (dart.library.io) 'file_ops_io.dart';

/// Read bytes from a file path
Future<Uint8List> readFileBytes(String path);

/// Get file size from path
Future<int> getFileSize(String path);

/// Check if file exists
Future<bool> fileExists(String path);
