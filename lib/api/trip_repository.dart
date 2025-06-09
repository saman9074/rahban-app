import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahban/api/api_service.dart';
import 'package:rahban/features/history/models/trip_model.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';
import 'package:latlong2/latlong.dart';

class TripRepository {
  final Dio _dio = ApiService().dio;

  Future<Response> startTrip({
    Map<String, String>? vehicleInfo,
    required List<Guardian> guardians,
    required LatLng location,
    XFile? platePhoto,
  }) async {

    // **تغییر:** موقعیت مکانی به داخل آبجکت اصلی منتقل شد
    final tripData = {
      'vehicle_info': vehicleInfo,
      'guardians': guardians.map((g) => g.toJson()).toList(),
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    };

    final formData = FormData.fromMap({
      'data': jsonEncode(tripData),
    });

    if (platePhoto != null) {
      formData.files.add(MapEntry(
        'plate_photo',
        MultipartFile.fromBytes(
          await platePhoto.readAsBytes(),
          filename: platePhoto.name,
        ),
      ));
    }

    return await _dio.post(
      '/trips/start',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<List<Trip>> getTrips() async {
    final response = await _dio.get('/trips');
    final data = response.data['data'] as List;
    return data.map((tripJson) => Trip.fromJson(tripJson)).toList();
  }
  Future<Response> updateLocation({required String tripId, required LatLng location}) async {
    return await _dio.post('/trips/$tripId/location', data: {'latitude': location.latitude,'longitude': location.longitude,});
  }
  Future<Response> completeTrip({required String tripId}) async {
    return await _dio.post('/trips/$tripId/complete');
  }
  Future<Response> triggerSOS({required String tripId}) async {
    return await _dio.post('/trips/$tripId/sos');
  }
}