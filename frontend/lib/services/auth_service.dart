import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/dio_client.dart';
import 'package:image_picker/image_picker.dart';

class UserModel {
  final String email;
  final String fullName;
  final String dateOfBirth;
  final String? avatar;
  final String? bio;

  UserModel({
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    this.avatar,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
    );
  }
}

class LoginResult {
  final String? token;
  final String? errorCode;
  final String? errorMessage;

  const LoginResult({this.token, this.errorCode, this.errorMessage});

  bool get isSuccess => token != null;
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? bio;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.bio,
  });
}

class AuthService {
  static Future<LoginResult> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final idToken = await user.getIdToken();
        return LoginResult(token: idToken);
      }

      return const LoginResult(errorMessage: 'Không lấy được thông tin user');
    } on FirebaseAuthException catch (e) {
      final msg = _mapFirebaseError(e.code);
      return LoginResult(errorCode: e.code, errorMessage: msg);
    } catch (e) {
      return LoginResult(errorMessage: 'Lỗi không xác định: $e');
    }
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> register(RegisterRequest req) async {
    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: req.email,
        password: req.password,
      );

      final user = credential.user!;

      // Backend is configured with JsonNamingPolicy.SnakeCaseLower, so all
      // payload keys must be snake_case (e.g. `first_name`, `date_of_birth`)
      // — PascalCase keys are silently ignored and the validator then fails
      // because required fields are empty.
      await DioClient.instance.post(
        '/api/user',
        data: {
          'id': user.uid,
          'first_name': req.firstName,
          'last_name': req.lastName,
          'email': req.email,
          'password': req.password,
          'date_of_birth': req.dateOfBirth,
          'bio': req.bio ?? '',
        },
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      if (credential != null) {
        await credential.user?.delete();
      }
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  static Future<void> deleteAccountAndData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final documentId = querySnapshot.docs.first.id;
        try {
          await DioClient.instance.delete('/api/user/$documentId');
        } catch (_) {}
      }
    } catch (_) {}

    try {
      await user.delete();
    } catch (_) {}
  }

  static Future<void> sendOtp(String email) async {
    try {
      final response = await PublicDioClient.instance.post(
        '/api/otp/generate',
        data: {'email': email.trim()},
      );
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception(_extractErrorMessage(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'OTP send failed',
          ),
          'Không thể gửi OTP',
        ));
      }
      // Return OTP if email failed (it's in the result field)
      // This OTP will be sent back during verify if email delivery fails
      final data = response.data;
      if (data is Map) {
        final result = data['result'] as Map?;
        if (result != null && result['otp'] != null) {
          _lastFallbackOtp = result['otp'] as String;
        } else {
          _lastFallbackOtp = null;
        }
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể gửi OTP'));
    } catch (e) {
      throw Exception('Lỗi kết nối hệ thống');
    }
  }

  /// Stores the most recent fallback OTP so verifyOtp can pass it to the
  /// backend as a hint when Redis/email is unavailable.
  static String? _lastFallbackOtp;

  static String? get lastFallbackOtp => _lastFallbackOtp;

  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final body = <String, dynamic>{
        'email': email.trim(),
        'otp': otp.trim(),
      };
      // If we have a fallback OTP from the generate call (i.e. email
      // delivery failed), forward it so the backend can verify even when
      // Redis was unable to cache it.
      if (_lastFallbackOtp != null && _lastFallbackOtp == otp.trim()) {
        body['cached_otp'] = _lastFallbackOtp;
      }

      final response = await PublicDioClient.instance.post(
        '/api/otp/verify',
        data: body,
      );
      if (response.statusCode == 200) {
        // Clear cached OTP after successful verification
        _lastFallbackOtp = null;
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Mã OTP không đúng hoặc đã hết hạn');
      }
      throw Exception(_extractErrorMessage(e, 'Mã OTP không hợp lệ'));
    } catch (e) {
      throw Exception('Lỗi xác thực: $e');
    }
  }

  /// Trích xuất thông báo lỗi từ DioException một cách an toàn.
  ///
  /// Backend có thể trả về body không phải JSON (ví dụ 404 với body rỗng hoặc
/// text/plain), khi đó `e.response?.data` là `String` chứ không phải `Map`.
/// Việc truy cập trực tiếp `data['message']` sẽ ném TypeError trên Flutter
/// web vì `String[]` yêu cầu tham số `int`. Hàm này kiểm tra kiểu trước khi
/// truy cập và fallback về thông báo mặc định nếu body không hợp lệ.
  static String _extractErrorMessage(DioException e, String fallback) {
    // Trường hợp lỗi mạng / timeout — không có response từ server.
    if (e.response == null) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '$fallback: máy chủ phản hồi chậm, vui lòng thử lại.';
        case DioExceptionType.connectionError:
          return '$fallback: không kết nối được tới máy chủ.';
        default:
          return '$fallback: ${e.message ?? "lỗi mạng"}';
      }
    }

    final dynamic data = e.response?.data;
    if (data is Map) {
      final dynamic raw = data['message'];
      if (raw is String && raw.isNotEmpty) return raw;
      if (raw != null) return raw.toString();
    }
    final status = e.response?.statusCode;
    if (status != null) return '$fallback (mã $status)';
    return fallback;
  }

  static Future<UserModel> getUserById(String userId) async {
    final response = await DioClient.instance.get('/api/User/$userId');
    return UserModel.fromJson(response.data['result']);
  }

  static Future<void> updateUserInfo({
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? bio,
  }) async {
    try {
      final fullName = '$firstName $lastName'.trim();

      // Backend expects PascalCase field names (UpdateUserRequest)
      final response = await DioClient.instance.put(
        '/api/user/me',
        data: {
          'FirstName': firstName,
          'LastName': lastName,
          'Bio': bio ?? '',
          if (dateOfBirth != null) 'DateOfBirth': dateOfBirth,
        },
      );

      if (response.statusCode == 200) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
      }
    } on DioException catch (e) {
      final dynamic data = e.response?.data;
      String errorMsg = 'Lỗi cập nhật';
      if (data is Map) {
        errorMsg = data['message']?.toString() ?? errorMsg;
      } else {
        errorMsg = data?.toString() ?? errorMsg;
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  static Future<bool> checkEmailExists(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String> updateAvatar(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      return _uploadAvatarBytes(bytes, image.name);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  static Future<String> updateAvatarFromBytes(
    Uint8List bytes, {
    String filename = 'avatar.jpg',
  }) async {
    try {
      return await _uploadAvatarBytes(bytes, filename);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  static Future<String> _uploadAvatarBytes(
    Uint8List bytes,
    String filename,
  ) async {
    final safeName = filename.isNotEmpty ? filename : 'avatar.jpg';
    final formData = FormData.fromMap({
      'File': MultipartFile.fromBytes(bytes, filename: safeName),
    });

    final response = await DioClient.instance.patch(
      '/api/user/avatar',
      data: formData,
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final avatarUrl = result?['avatar'] as String?;

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(avatarUrl);
        return avatarUrl;
      }
    }

    throw Exception('Cập nhật avatar thất bại');
  }

  static String _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Chưa đăng nhập hoặc token hết hạn';
    if (status == 403) return 'Không có quyền cập nhật avatar';
    if (status == 404) return 'Không tìm thấy tài khoản';
    if (status != null) return 'Lỗi server $status';
    return 'Lỗi kết nối: ${e.message}';
  }

  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng dùng email khác.';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ thường và chữ hoa.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      default:
        return 'Lỗi: $code';
    }
  }
}
