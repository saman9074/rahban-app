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
    _listenToLocationService();
  }

  bool _isInTrip = false;
  String? _activeTripId;
  LatLng? _currentPosition;
  String _locationError = '';
  bool _isLocationLoading = true;
  bool _locationServiceEnabled = false;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _backendUpdateTimer;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  bool get isInTrip => _isInTrip;
  String? get activeTripId => _activeTripId;
  LatLng? get currentPosition => _currentPosition;
  String get locationError => _locationError;
  bool get isLocationLoading => _isLocationLoading;
  bool get locationServiceEnabled => _locationServiceEnabled;

  void _listenToLocationService() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      final wasEnabled = _locationServiceEnabled;
      _locationServiceEnabled = status == ServiceStatus.enabled;

      if (_locationServiceEnabled && !wasEnabled) {
        initializeLocationService();
      }

      notifyListeners();
    }, onError: (error) {
      // اگر خطایی در استریم رخ داد می‌توانید اینجا مدیریت کنید
      print("Error in location service status stream: $error");
    });
  }

  Future<void> initializeLocationService() async {
    if (!_isLocationLoading && _currentPosition != null) return;
    _isLocationLoading = true;
    notifyListeners();

    try {
      final initialPosition = await _determinePosition();
      _currentPosition = LatLng(initialPosition.latitude, initialPosition.longitude);
      _locationError = '';
      _startLocationStream();
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
    _positionStreamSubscription = Geolocator.getPositionStream().listen(
          (Position position) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        notifyListeners();
      },
      onError: (error) {
        _locationError = error.toString();
        notifyListeners();
      },
    );
  }

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

  void _startBackendUpdates() {
    _backendUpdateTimer?.cancel();
    _backendUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isInTrip || _activeTripId == null || _currentPosition == null) {
        timer.cancel();
        return;
      }
      try {
        await _tripRepository.updateLocation(tripId: _activeTripId!, location: _currentPosition!);
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
    _positionStreamSubscription?.cancel();
    _backendUpdateTimer?.cancel();
    _serviceStatusStream?.cancel();
    super.dispose();
  }
}
