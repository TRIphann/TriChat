// Platform-specific file operations for chat uploads
// This file exports the appropriate implementation based on platform

export 'file_ops_stub.dart' if (dart.library.io) 'file_ops_io.dart';
