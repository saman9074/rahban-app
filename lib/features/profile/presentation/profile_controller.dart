import 'package:flutter/material.dart';
import 'package:rahban/api/user_repository.dart';
import 'package:rahban/features/profile/models/user_model.dart';

class ProfileController with ChangeNotifier {
  final UserRepository _userRepository;
  ProfileController(this._userRepository);

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _userRepository.getUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // **تغییر:** متد جدید برای تغییر رمز عبور
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _userRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      return "رمز عبور با موفقیت تغییر کرد.";
    } catch (e) {
      // You can parse the DioError for more specific messages
      return "خطا در تغییر رمز عبور: $e";
    }
  }
}