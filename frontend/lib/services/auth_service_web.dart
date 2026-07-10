// Stub for auth_service - minimal implementations
// Real implementations are in auth_service_io.dart

class AuthService {
  static Future<void> register(dynamic req) async {
    throw UnsupportedError('Use platform-specific auth_service');
  }
}
