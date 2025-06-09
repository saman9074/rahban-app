import 'package:dio/dio.dart';
import 'package:rahban/api/api_service.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';

class GuardianRepository {
  final Dio _dio = ApiService().dio;

  Future<List<Guardian>> getGuardians() async {
    final response = await _dio.get('/guardians');
    final data = response.data as List;
    return data.map((json) => Guardian.fromJson(json)).toList();
  }

  Future<Guardian> addGuardian({required String name, required String phoneNumber}) async {
    final response = await _dio.post('/guardians', data: {
      'name': name,
      'phone_number': phoneNumber,
    });
    return Guardian.fromJson(response.data);
  }

  Future<void> deleteGuardian(int guardianId) async {
    await _dio.delete('/guardians/$guardianId');
  }

  Future<void> setDefaultGuardian(int guardianId) async {
    await _dio.post('/guardians/$guardianId/set-default');
  }
}