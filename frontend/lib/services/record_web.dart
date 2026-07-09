// Stub for web - record package not available
class AudioRecorder {
  Future<bool> hasPermission() async => true;

  Future<void> start(RecordConfig config, {required String path}) async {
    // Stub - no recording on web
  }

  Future<String?> stop() async => null;

  void dispose() {}
}

class RecordConfig {
  final AudioEncoder encoder;

  const RecordConfig({this.encoder = AudioEncoder.aacLc});
}

enum AudioEncoder {
  aacLc,
  opus,
  vorbis,
}
