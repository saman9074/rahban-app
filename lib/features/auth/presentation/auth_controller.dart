import 'package:flutter/material.dart';
import 'package:rahban/api/auth_repository.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthController with ChangeNotifier {
  final AuthRepository _authRepository;
  AuthState _authState = AuthState.unknown;

  AuthController(this._authRepository);

  AuthState get authState => _authState;

  Future<void> checkAuthenticationStatus() async {
    final token = await _authRepository.token;
    if (token != null) {
      _authState = AuthState.authenticated;
    } else {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    try {
      await _authRepository.login(phoneNumber, password);
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }
}