import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/api_config.dart';

/// Separate Dio client for public endpoints (no Firebase auth required).
/// Uses shorter timeouts so users don't wait 120s on cold-start failures.
class PublicDioClient {
  PublicDioClient._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}

/// Interceptor tự động gắn Firebase ID Token vào Header Authorization
/// của mọi request. Token được refresh tự động khi hết hạn.
class _AuthInterceptor extends Interceptor {
  // Tránh retry loop: chỉ retry 1 lần duy nhất
  static const _retryKey = 'retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // forceRefresh: false → dùng cache, tự refresh khi sắp hết hạn
      final idToken = await user.getIdToken(false);
      options.headers['Authorization'] = 'Bearer $idToken';
    }

    handler.next(options); // tiếp tục gửi request
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Nếu backend trả 401 và chưa retry lần nào → thử force refresh rồi retry
    final alreadyRetried = err.requestOptions.extra[_retryKey] == true;
    if (err.response?.statusCode == 401 && !alreadyRetried) {
      _retryWithFreshToken(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _retryWithFreshToken(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        handler.next(err);
        return;
      }

      // Force refresh token mới
      final newToken = await user.getIdToken(true);

      // Tạo lại request với token mới, đánh dấu đã retry
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      opts.extra[_retryKey] = true; // ngăn retry lần 2

      final dio = DioClient.instance;
      final response = await dio.fetch(opts);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }
}

/// Singleton Dio client dùng chung toàn app.
/// Mọi request qua client này đều tự động đính kèm token.
class DioClient {
  DioClient._();

  static final Dio instance = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        // Render free-tier service cold-start (~30-60s sau khi idle) + thời gian
        // SMTP connect đến Gmail có thể mất 10-20s. Timeout 120s cho cả 3 pha
        // để cover worst-case trên cả mobile và web.
        connectTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          // Không đặt Content-Type mặc định để Dio tự động chọn đúng:
          // - multipart/form-data khi body là FormData (upload file)
          // - application/json khi body là Map/JSON
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    // Chỉ log request/response khi debug mode để tránh lộ sensitive data trong production
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[Dio] $o'),
        // Filter out sensitive headers
        requestHeaderFilter: (key, value) {
          if (key.toLowerCase() == 'authorization') return 'Bearer ***';
          return value;
        },
        responseHeaderFilter: (key, value) => value,
      ));
    }

    return dio;
  }
}
