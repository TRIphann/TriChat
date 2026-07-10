// IO implementation for mobile/desktop
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> getTempDirectory() async {
  final tempDir = await getTemporaryDirectory();
  return tempDir.path;
}

class FileWrapper {
  final String path;
  FileWrapper(this.path);
  File get _file => File(path);
  Future<Uint8List> readAsBytes() => _file.readAsBytes();
}

dynamic createFile(String path) => FileWrapper(path);

Future<bool> exists(dynamic file) async {
  if (file == null) return false;
  if (file is FileWrapper) return File(file.path).exists();
  return await File(file.path).exists();
}

Future<void> deleteFile(dynamic file) async {
  if (file == null) return;
  final p = file is FileWrapper ? file.path : file.path;
  await File(p).delete();
}
