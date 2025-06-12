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
  /// MODIFIED to accept `encryptedInitialLocation` instead of raw LatLng.
  /// The backend API has been updated to expect a single `encrypted_data` field for the location.
  Future<Response> startTrip({
    Map<String, String>? vehicleInfo,
    required List<Guardian> guardians,
    required String encryptedInitialLocation, // CHANGED from LatLng
    XFile? platePhoto,
  }) async {
    // The main data payload is JSON encoded and sent as a string field.
    // This simplifies handling on the backend, especially with multipart forms.
    final tripData = {
      'vehicle_info': vehicleInfo,
      'guardians': guardians.map((g) => g.toJson()).toList(),
      // The backend expects the first encrypted location point here.
      'encrypted_location': encryptedInitialLocation,
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

  /// Updates the location for an ongoing trip.
  ///
  /// MODIFIED to send a single encrypted string. The backend route
  /// `trips/{trip_id}/location` now expects a JSON body like: `{"data": "encrypted_string"}`
  Future<Response> updateLocation({required String tripId, required String encryptedData}) async {
    return await _dio.post('/trips/$tripId/location', data: {'data': encryptedData});
  }

  Future<Response> completeTrip({required String tripId}) async {
    return await _dio.post('/trips/$tripId/complete');
  }

  Future<Response> triggerSOS({required String tripId}) async {
    return await _dio.post('/trips/$tripId/sos');
  }
}
