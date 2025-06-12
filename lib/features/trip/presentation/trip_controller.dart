import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:rahban/features/security/e2ee_controller.dart'; // NEW
import 'package:rahban/utils/encryption_service.dart';

class TripController with ChangeNotifier {
  final TripRepository _tripRepository;
  final E2EEController _e2eeController; // NEW: Injected E2EE controller
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // The E2EE controller is now injected via the constructor
  TripController(this._tripRepository, this._e2eeController) {
    _checkInitialLocationStatus();
    loadActiveTrip();
    if (!kIsWeb) {
      _listenToLocationService();
    }
  }

  // State variables
  bool _isInTrip = false;
  String? _activeTripId;
  LatLng? _currentPosition;
  String _locationError = '';
  bool _isLocationLoading = true;
  bool _locationServiceEnabled = false;

  // Timers and Stream Subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _backendUpdateTimer;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  // Getters for UI
  bool get isInTrip => _isInTrip;
  String? get activeTripId => _activeTripId;
  LatLng? get currentPosition => _currentPosition;
  String get locationError => _locationError;
  bool get isLocationLoading => _isLocationLoading;
  bool get locationServiceEnabled => _locationServiceEnabled;

  /// Loads an active trip's state from secure storage upon app start.
  Future<void> loadActiveTrip() async {
    // The key is now managed by E2EEController, so we only need to check for the trip ID.
    final tripId = await _secureStorage.read(key: 'active_trip_id');
    if (tripId != null) {
      _activeTripId = tripId;
      _isInTrip = true;
      _startBackendUpdates();
      notifyListeners();
    }
  }

  // MODIFIED: No longer needs the key as a parameter.
  Future<void> startNewTrip(String tripId) async {
    await _secureStorage.write(key: 'active_trip_id', value: tripId);
    _activeTripId = tripId;
    _isInTrip = true;
    _startBackendUpdates();
    notifyListeners();
  }

  /// Completes the active trip on the server and clears local state.
  Future<void> completeActiveTrip() async {
    if (_activeTripId == null) return;
    try {
      await _tripRepository.completeTrip(tripId: _activeTripId!);
    } catch (e) {
      print("Error completing trip on server, but ending locally anyway: $e");
    } finally {
      _stopBackendUpdates();
      // Only the trip ID needs to be cleared now.
      await _secureStorage.delete(key: 'active_trip_id');
      _activeTripId = null;
      _isInTrip = false;
      notifyListeners();
    }
  }

  /// Starts a periodic timer to send encrypted location updates to the backend.
  void _startBackendUpdates() {
    _backendUpdateTimer?.cancel();
    _backendUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isInTrip || _activeTripId == null || _currentPosition == null) {
        timer.cancel();
        return;
      }
      try {
        // --- E2EE Encryption with Permanent Key ---
        if (!_e2eeController.isKeySet) {
          print("Error: Permanent E2EE key not available. Stopping updates.");
          completeActiveTrip();
          return;
        }

        final keyBytes = await _e2eeController.getKeyBytes();
        final locationJson = jsonEncode({'lat': _currentPosition!.latitude, 'lon': _currentPosition!.longitude});
        final encryptedData = EncryptionService.encrypt(locationJson, keyBytes);

        await _tripRepository.updateLocation(tripId: _activeTripId!, encryptedData: encryptedData);
        print("Backend Location encrypted and updated for trip $_activeTripId at ${DateTime.now()}");
        // --- END E2EE ---
      } catch (e) {
        print("Failed to send encrypted location update to backend: $e");
      }
    });
  }

  /// Stops the periodic location updates.
  void _stopBackendUpdates() {
    _backendUpdateTimer?.cancel();
    _backendUpdateTimer = null;
  }

  // The rest of the location service handling methods remain the same.
  // ...

  Future<void> _checkInitialLocationStatus() async {
    if (kIsWeb) {
      _locationServiceEnabled = true;
    } else {
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    if (!_locationServiceEnabled) {
      _locationError = "سرویس موقعیت مکانی غیرفعال است. لطفا آن را روشن کنید.";
      _isLocationLoading = false;
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _locationError = "دسترسی به موقعیت مکانی رد شده است. لطفا از تنظیمات دسترسی دهید.";
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  void _listenToLocationService() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _locationServiceEnabled = (status == ServiceStatus.enabled);
      if (_locationServiceEnabled) {
        _locationError = '';
        initializeLocationService();
      } else {
        _locationError = "سرویس موقعیت مکانی غیرفعال شد.";
        _currentPosition = null;
      }
      notifyListeners();
    });
  }

  Future<void> initializeLocationService() async {
    _isLocationLoading = true;
    _locationError = '';
    notifyListeners();

    try {
      await _determinePosition();
      _startLocationStream();
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'دسترسی به موقعیت مکانی رد شد.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'دسترسی به موقعیت مکانی برای همیشه رد شده است. لطفا از تنظیمات برنامه دسترسی را فعال کنید.';
    }
  }

  void _startLocationStream() {
    _positionStreamSubscription?.cancel();
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationError = '';
        _isLocationLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _locationError = "خطا در دریافت موقعیت: $error";
        _isLocationLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> triggerSOS() async {
    if (_activeTripId == null) return;
    try {
      if (_currentPosition != null && _e2eeController.isKeySet) {
        final keyBytes = await _e2eeController.getKeyBytes();
        final locationJson = jsonEncode({'lat': _currentPosition!.latitude, 'lon': _currentPosition!.longitude});
        final encryptedData = EncryptionService.encrypt(locationJson, keyBytes);
        await _tripRepository.updateLocation(tripId: _activeTripId!, encryptedData: encryptedData);
        print("SOS: Encrypted location updated immediately before sending alert.");
      }
      await _tripRepository.triggerSOS(tripId: _activeTripId!);
    } catch (e) {
      print("Error triggering SOS with location update: $e");
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _backendUpdateTimer?.cancel();
    _serviceStatusStream?.cancel();
    super.dispose();
  }
}
