import 'package:dio/dio.dart';
import 'package:rahban/api/api_service.dart';
import 'package:rahban/features/profile/models/user_model.dart';

class UserRepository {
  final Dio _dio = ApiService().dio;

  Future<User> getUser() async {
    final response = await _dio.get('/user');
    return User.fromJson(response.data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _dio.post('/user/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }
}