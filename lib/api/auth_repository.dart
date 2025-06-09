import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rahban/api/api_service.dart';

class AuthRepository {
  final Dio _dio = ApiService().dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> get token async => await _secureStorage.read(key: 'auth_token');

  Future<void> _persistToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<Response> login(String phoneNumber, String password) async {
    final response = await _dio.post('/login', data: {
      'phone_number': phoneNumber,
      'password': password,
    });

    if (response.statusCode == 200 && response.data['access_token'] != null) {
      await _persistToken(response.data['access_token']);
    }
    return response;
  }

  Future<Response> register({
    required String name,
    required String email, // ایمیل اضافه شد
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _dio.post('/register', data: {
      'name': name,
      'email': email, // ایمیل به درخواست اضافه شد
      'phone_number': phoneNumber,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch(e) {
      // حتی اگر درخواست به سرور ناموفق بود، توکن را از حافظه پاک می‌کنیم
      print('Logout failed on server, but deleting token locally: $e');
    }
    await deleteToken();
  }
}