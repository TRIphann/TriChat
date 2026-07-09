/// Web stub for call service
/// Camera và permissions không khả dụng trên web

class CallService {
  dynamic cameraController;

  Future<bool> requestPermissions() async {
    return true;
  }

  Future<dynamic> initCamera() async {
    return null;
  }

  void dispose() {}
}
