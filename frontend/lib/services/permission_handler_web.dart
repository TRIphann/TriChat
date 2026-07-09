// Stub for web - permission_handler not available
class Permission {
  static const microphone = Permission._('microphone');
  static const camera = Permission._('camera');
  static const location = Permission._('location');
  static const storage = Permission._('storage');

  final String _value;
  const Permission._(this._value);

  Future<PermissionStatus> request() async {
    return PermissionStatus.denied;
  }
}

enum PermissionStatus {
  denied,
  granted,
  permanentlyDenied,
  restricted,
  limited,
}
