import 'package:flutter/material.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:rahban/features/history/models/trip_model.dart';

class HistoryController with ChangeNotifier {
  final TripRepository _tripRepository;
  HistoryController(this._tripRepository);

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _trips = await _tripRepository.getTrips();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}