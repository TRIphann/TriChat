// IO implementation for mobile/desktop
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getTempDirectory() async {
  final tempDir = await getTemporaryDirectory();
  return tempDir.path;
}

dynamic createFile(String path) => File(path);

Future<bool> exists(dynamic file) async {
  if (file == null) return false;
  return await File(file.path).exists();
}

Future<void> deleteFile(dynamic file) async {
  if (file == null) return;
  await File(file.path).delete();
}
