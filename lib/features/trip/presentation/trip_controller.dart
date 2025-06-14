import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:rahban/features/security/e2ee_controller.dart';

enum TripStatus { none, active, emergency }

class TripController with ChangeNotifier {
  final TripRepository _tripRepository;
  final E2EEController _e2eeController;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _backgroundService = FlutterBackgroundService();

  TripController(this._tripRepository, this._e2eeController) {
    loadActiveTrip();
    if (!kIsWeb) {
      // متدهای جا افتاده در اینجا فراخوانی می شوند
      _checkInitialLocationStatus();
      _listenToLocationService();
      _listenToNetworkChanges();
    }
  }

  // State variables
  TripStatus _tripStatus = TripStatus.none;
  String? _activeTripId;
  LatLng? _currentPosition;
  String _locationError = '';
  bool _isLocationLoading = true;
  bool _locationServiceEnabled = false;
  bool _isOnline = true;

  // For GPS Path Smoothing
  final List<LatLng> _recentPositions = [];
  final int _smoothingWindow = 5;

  // Stream Subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters for UI
  TripStatus get tripStatus => _tripStatus;
  bool get isInTrip => _tripStatus != TripStatus.none;
  String? get activeTripId => _activeTripId;
  LatLng? get currentPosition => _currentPosition;
  String get locationError => _locationError;
  bool get isLocationLoading => _isLocationLoading;
  bool get locationServiceEnabled => _locationServiceEnabled;
  bool get isOnline => _isOnline;

  Future<void> loadActiveTrip() async {
    final tripId = await _secureStorage.read(key: 'active_trip_id');
    final tripStatusStr = await _secureStorage.read(key: 'active_trip_status');

    if (tripId != null) {
      _activeTripId = tripId;
      _tripStatus = _stringToTripStatus(tripStatusStr);
      final isRunning = await _backgroundService.isRunning();
      if (isRunning) {
        _configureAndStartService();
      }
      notifyListeners();
    }
  }

  void _configureAndStartService() {
    _backgroundService.startService();
    _backgroundService.invoke('configure', {
      'tripId': _activeTripId,
      'tripStatusValue': _tripStatus.index,
    });
    _updateNotification();
  }

  Future<void> startNewTrip(String tripId) async {
    _tripStatus = TripStatus.active;
    _activeTripId = tripId;

    await _secureStorage.write(key: 'active_trip_id', value: tripId);
    await _secureStorage.write(key: 'active_trip_status', value: 'active');

    _configureAndStartService();
    notifyListeners();
  }

  Future<void> completeActiveTrip() async {
    if (_activeTripId == null) return;
    try {
      await _tripRepository.completeTrip(tripId: _activeTripId!);
    } catch (e) {
      print("Error completing trip on server, but ending locally anyway: $e");
    } finally {
      _backgroundService.invoke('stop');
      await _secureStorage.delete(key: 'active_trip_id');
      await _secureStorage.delete(key: 'active_trip_status');
      _activeTripId = null;
      _tripStatus = TripStatus.none;
      _recentPositions.clear();
      _positionStreamSubscription?.cancel();
      notifyListeners();
    }
  }

  Future<void> activateEmergencyMode() async {
    if (!isInTrip || _tripStatus == TripStatus.emergency) return;
    try {
      await _tripRepository.triggerSOS(tripId: _activeTripId!);
      _tripStatus = TripStatus.emergency;
      await _secureStorage.write(key: 'active_trip_status', value: 'emergency');
      _backgroundService.invoke('updateTripStatus', {'tripStatusValue': _tripStatus.index});
      _updateNotification();
      print("Trip status changed to EMERGENCY.");
      notifyListeners();
    } catch (e) {
      print("Error activating emergency mode: $e");
    }
  }

  void _updateNotification() {
    FlutterBackgroundService().invoke('update_notification', {
      'title': 'رهبان در حال محافظت از شماست',
      'content': _tripStatus == TripStatus.emergency
          ? 'وضعیت اضطراری فعال است. در حال ضبط شواهد.'
          : 'سفر شما در حالت عادی فعال است.',
    });
  }

  // --- متدهای جا افتاده که اضافه شدند ---

  TripStatus _stringToTripStatus(String? statusStr) {
    switch (statusStr) {
      case 'active':
        return TripStatus.active;
      case 'emergency':
        return TripStatus.emergency;
      default:
        return TripStatus.none;
    }
  }

  void _checkInitialLocationStatus() async {
    if (kIsWeb) return;
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();
  }

  void _listenToLocationService() {
    if (kIsWeb) return;
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _locationServiceEnabled = status == ServiceStatus.enabled;
      if (!_locationServiceEnabled) {
        _locationError = 'GPS خاموش است. لطفا برای ادامه، آن را روشن کنید.';
      } else {
        if (_locationError.isNotEmpty) {
          initializeLocationService();
        }
      }
      notifyListeners();
    });
  }

  void _listenToNetworkChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final currentlyOnline = !results.contains(ConnectivityResult.none);
      if (_isOnline != currentlyOnline) {
        _isOnline = currentlyOnline;
        print("Network status changed: ${isOnline ? 'Online' : 'Offline'}");
        notifyListeners();
      }
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
      distanceFilter: 5,
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);
        _applySmoothing(newPosition);
        _locationError = '';
        _isLocationLoading = false;

        // موقعیت جدید را برای سرویس پس‌زمینه ارسال می‌کنیم
        if (isInTrip) {
          _backgroundService.invoke('updatePosition', {
            'lat': _currentPosition!.latitude,
            'lon': _currentPosition!.longitude
          });
        }

        notifyListeners();
      },
      onError: (error) {
        _locationError = "خطا در دریافت موقعیت: $error";
        _isLocationLoading = false;
        notifyListeners();
      },
    );
  }

  void _applySmoothing(LatLng newPosition) {
    if (_recentPositions.length >= _smoothingWindow) {
      _recentPositions.removeAt(0);
    }
    _recentPositions.add(newPosition);

    if (_recentPositions.isEmpty) return;

    double avgLat = 0;
    double avgLon = 0;
    for (var pos in _recentPositions) {
      avgLat += pos.latitude;
      avgLon += pos.longitude;
    }
    _currentPosition = LatLng(avgLat / _recentPositions.length, avgLon / _recentPositions.length);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusStream?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}