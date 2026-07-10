// IO implementation for mobile/desktop - uses dart:io
import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readFileBytes(String path) async {
  return await File(path).readAsBytes();
}

Future<int> getFileSize(String path) async {
  final file = File(path);
  return await file.length();
}

Future<bool> fileExists(String path) async {
  return await File(path).exists();
}
