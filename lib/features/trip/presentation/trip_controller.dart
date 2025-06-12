import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:rahban/utils/encryption_service.dart';

class TripController with ChangeNotifier {
  final TripRepository _tripRepository;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Constructor: Initialize services when the controller is created.
  TripController(this._tripRepository) {
    _checkInitialLocationStatus();
    loadActiveTrip();
    _listenToLocationService();
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
    final tripId = await _secureStorage.read(key: 'active_trip_id');
    if (tripId != null) {
      // Also check if the E2EE key exists for this trip.
      final key = await _secureStorage.read(key: 'e2ee_key_$tripId');
      if (key != null) {
        // If both tripId and key exist, restore the trip state.
        _activeTripId = tripId;
        _isInTrip = true;
        _startBackendUpdates();
        notifyListeners();
      } else {
        // If tripId exists but the key doesn't, it indicates a corrupted state. Clean up.
        await _secureStorage.delete(key: 'active_trip_id');
      }
    }
  }

  /// Starts a new trip, storing the trip ID and its corresponding E2EE key in secure storage.
  Future<void> startNewTrip(String tripId, String base64Key) async {
    await _secureStorage.write(key: 'active_trip_id', value: tripId);
    // Store the key with a trip-specific identifier.
    await _secureStorage.write(key: 'e2ee_key_$tripId', value: base64Key);

    _activeTripId = tripId;
    _isInTrip = true;
    _startBackendUpdates();
    notifyListeners();
  }

  /// Completes the active trip on the server and clears local state.
  Future<void> completeActiveTrip() async {
    if (_activeTripId == null) return;
    final tripIdToComplete = _activeTripId!;

    try {
      await _tripRepository.completeTrip(tripId: tripIdToComplete);
    } catch (e) {
      print("Error completing trip on server, but ending locally anyway: $e");
    } finally {
      _stopBackendUpdates();
      // Clean up all data related to the completed trip.
      await _secureStorage.delete(key: 'active_trip_id');
      await _secureStorage.delete(key: 'e2ee_key_$tripIdToComplete');
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
        timer.cancel(); // Stop if there's no active trip or location.
        return;
      }
      try {
        // --- E2EE Encryption for Periodic Updates ---
        // 1. Retrieve the session's E2EE key from secure storage.
        final base64Key = await _secureStorage.read(key: 'e2ee_key_$_activeTripId');
        if (base64Key == null) {
          print("Error: E2EE key not found for active trip $_activeTripId. Stopping updates.");
          completeActiveTrip(); // End the trip as it's in a bad state.
          return;
        }

        // 2. Decode the key and encrypt the current location.
        final keyBytes = base64.decode(base64Key);
        final locationJson = jsonEncode({'lat': _currentPosition!.latitude, 'lon': _currentPosition!.longitude});
        final encryptedData = EncryptionService.encrypt(locationJson, keyBytes);

        // 3. Send the encrypted data to the repository.
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

  // All other methods related to location service handling remain the same.
  // (_checkInitialLocationStatus, _listenToLocationService, initializeLocationService, etc.)

  // ... [The rest of the unchanged location service methods from the original file] ...

  /// Checks location permission and service status on app start.
  Future<void> _checkInitialLocationStatus() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
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

  /// Listens for changes in the location service status (e.g., user turns GPS on/off).
  void _listenToLocationService() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _locationServiceEnabled = (status == ServiceStatus.enabled);
      if (_locationServiceEnabled) {
        _locationError = '';
        initializeLocationService(); // Re-initialize if service is turned back on
      } else {
        _locationError = "سرویس موقعیت مکانی غیرفعال شد.";
        _currentPosition = null; // Clear position if service is off
      }
      notifyListeners();
    });
  }

  /// Main function to get location permissions and start the stream.
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

  /// Checks for permissions and requests them if necessary.
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

  /// Starts listening to the continuous location stream.
  void _startLocationStream() {
    _positionStreamSubscription?.cancel(); // Cancel any existing stream
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
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
      if (_currentPosition != null) {
        final base64Key = await _secureStorage.read(key: 'e2ee_key_$_activeTripId');
        if (base64Key != null) {
          final keyBytes = base64.decode(base64Key);
          final locationJson = jsonEncode({'lat': _currentPosition!.latitude, 'lon': _currentPosition!.longitude});
          final encryptedData = EncryptionService.encrypt(locationJson, keyBytes);
          await _tripRepository.updateLocation(tripId: _activeTripId!, encryptedData: encryptedData);
          print("SOS: Encrypted location updated immediately before sending alert.");
        }
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
