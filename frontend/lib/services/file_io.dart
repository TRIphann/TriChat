// Stub for web - dart:io not available
import 'dart:typed_data';

class File {
  final String path;
  File(this.path);

  Future<bool> exists() async => false;
  Future<void> delete() async {}
}

class Directory {
  final String path;
  Directory(this.path);
}
