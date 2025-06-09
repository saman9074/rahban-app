import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/api/trip_repository.dart';

class TripController with ChangeNotifier {
  final TripRepository _tripRepository;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  TripController(this._tripRepository) {
    loadActiveTrip();
  }

  // --- State Variables ---
  bool _isInTrip = false;
  String? _activeTripId;
  LatLng? _currentPosition;
  String _locationError = '';
  bool _isLocationLoading = true;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _backendUpdateTimer;

  // --- Getters ---
  bool get isInTrip => _isInTrip;
  String? get activeTripId => _activeTripId;
  LatLng? get currentPosition => _currentPosition;
  String get locationError => _locationError;
  bool get isLocationLoading => _isLocationLoading;

  // --- Location Service Management ---
  Future<void> initializeLocationService() async {
    // برای جلوگیری از فراخوانی مجدد، اگر در حال لود شدن نیست یا موقعیت از قبل وجود دارد، خارج شو
    if (!_isLocationLoading || _currentPosition != null) return;

    try {
      final initialPosition = await _determinePosition();
      _currentPosition = LatLng(initialPosition.latitude, initialPosition.longitude);
      _locationError = '';
      _isLocationLoading = false;
      _startLocationStream();
      notifyListeners();
    } catch (e) {
      _locationError = e.toString();
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('سرویس موقعیت مکانی غیرفعال است.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('دسترسی به موقعیت مکانی رد شد.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('دسترسی به موقعیت مکانی برای همیشه رد شده است.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _startLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();
    });
  }

  void _stopLocationStream() {
    _positionStreamSubscription?.cancel();
  }

  // --- Trip State Management ---
  Future<void> loadActiveTrip() async {
    final tripId = await _secureStorage.read(key: 'active_trip_id');
    if (tripId != null) {
      _activeTripId = tripId;
      _isInTrip = true;
      _startBackendUpdates();
      notifyListeners();
    }
  }

  Future<void> startNewTrip(String tripId) async {
    await _secureStorage.write(key: 'active_trip_id', value: tripId);
    _activeTripId = tripId;
    _isInTrip = true;
    _startBackendUpdates();
    notifyListeners();
  }

  Future<void> completeActiveTrip() async {
    if (_activeTripId == null) return;
    try {
      await _tripRepository.completeTrip(tripId: _activeTripId!);
    } catch (e) {
      print("Error completing trip on server, but ending locally anyway: $e");
    } finally {
      // **تغییر:** این بخش همیشه اجرا می‌شود تا وضعیت اپلیکیشن ریست شود
      _stopBackendUpdates();
      await _secureStorage.delete(key: 'active_trip_id');
      _activeTripId = null;
      _isInTrip = false;
      notifyListeners();
    }
  }

  Future<void> triggerSOS() async {
    if (_activeTripId == null) return;
    try {
      if (_currentPosition != null) {
        await _tripRepository.updateLocation(
          tripId: _activeTripId!,
          location: _currentPosition!,
        );
        print("SOS: Location updated immediately before sending alert.");
      }
      await _tripRepository.triggerSOS(tripId: _activeTripId!);
    } catch (e) {
      print("Error triggering SOS with location update: $e");
    }
  }

  // --- Backend Sync ---
  void _startBackendUpdates() {
    _backendUpdateTimer?.cancel();
    _backendUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isInTrip || _activeTripId == null || _currentPosition == null) {
        timer.cancel();
        return;
      }
      try {
        _tripRepository.updateLocation(tripId: _activeTripId!, location: _currentPosition!);
        print("Backend Location updated for trip $_activeTripId at ${DateTime.now()}");
      } catch (e) {
        print("Failed to send location update to backend: $e");
      }
    });
  }

  void _stopBackendUpdates() {
    _backendUpdateTimer?.cancel();
    _backendUpdateTimer = null;
  }

  @override
  void dispose() {
    _stopLocationStream();
    _stopBackendUpdates();
    super.dispose();
  }
}