import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahban/api/api_service.dart';
import 'package:rahban/features/history/models/trip_model.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';

class TripRepository {
  final Dio _dio = ApiService().dio;

  /// Starts a new trip on the server.
  ///
  /// The payload sent to the backend is a multipart form. The main trip data
  /// is JSON encoded and passed in a field named 'data'.
  Future<Response> startTrip({
    Map<String, String>? vehicleInfo,
    required List<Guardian> guardians,
    required String encryptedInitialLocation,
    XFile? platePhoto,
  }) async {
    // The main data payload is JSON encoded.
    final tripData = {
      'vehicle_info': vehicleInfo,
      'guardians': guardians.map((g) => g.toJson()).toList(),
      // FIXED: The key for the initial location has been changed to match the backend validation rule.
      'initial_encrypted_data': encryptedInitialLocation,
    };

    final formData = FormData.fromMap({
      'data': jsonEncode(tripData),
    });

    // If a plate photo is provided, it's added to the multipart form data.
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

  /// Updates the location for an ongoing trip in NORMAL mode.
  ///
  /// The backend route expects a JSON body like: `{"data": "encrypted_string"}`
  Future<Response> updateLocation({required String tripId, required String encryptedData}) async {
    return await _dio.post('/trips/$tripId/location', data: {'data': encryptedData});
  }

  /// [NEW] Sends an environmental data packet for a trip in EMERGENCY mode.
  ///
  /// The backend route expects a JSON body like: `{"data": "encrypted_string"}`
  Future<Response> sendSosData({required String tripId, required String encryptedData}) async {
    return await _dio.post('/trips/$tripId/sos-data', data: {'data': encryptedData});
  }

  Future<Response> completeTrip({required String tripId}) async {
    return await _dio.post('/trips/$tripId/complete');
  }

  /// This sends an initial alert to backend that trip is now in SOS.
  Future<Response> triggerSOS({required String tripId}) async {
    return await _dio.post('/trips/$tripId/sos');
  }
}