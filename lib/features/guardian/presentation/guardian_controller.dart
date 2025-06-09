import 'package:flutter/material.dart';
import 'package:rahban/api/guardian_repository.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';

class GuardianController with ChangeNotifier {
  final GuardianRepository _guardianRepository;
  GuardianController(this._guardianRepository);

  List<Guardian> _guardians = [];
  List<Guardian> get guardians => _guardians;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGuardians() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _guardians = await _guardianRepository.getGuardians();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGuardian({required String name, required String phoneNumber}) async {
    try {
      final newGuardian = await _guardianRepository.addGuardian(name: name, phoneNumber: phoneNumber);
      _guardians.add(newGuardian);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteGuardian(int guardianId) async {
    try {
      await _guardianRepository.deleteGuardian(guardianId);
      _guardians.removeWhere((g) => g.id == guardianId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> setDefault(int guardianId) async {
    try {
      await _guardianRepository.setDefaultGuardian(guardianId);
      // Refresh list to show the new default
      fetchGuardians();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}