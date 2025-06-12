import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rahban/utils/encryption_service.dart';

/// Manages the permanent End-to-End Encryption (E2EE) key for the user.
/// This key is generated once and stored securely for all trips.
class E2EEController with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _e2eeKeyStorageKey = 'permanent_e2ee_key';

  String? _base64Key;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  bool get isKeySet => _base64Key != null;

  E2EEController() {
    loadKey();
  }

  /// Loads the E2EE key from secure storage when the controller is initialized.
  Future<void> loadKey() async {
    _isLoading = true;
    notifyListeners();
    _base64Key = await _secureStorage.read(key: _e2eeKeyStorageKey);
    _isLoading = false;
    notifyListeners();
  }

  /// Generates a key from the provided words, saves it in Base64 format,
  /// and updates the state.
  Future<void> generateAndSaveKey(List<String> words) async {
    final combinedWords = words.join('');
    final keyBytes = EncryptionService.generateKeyFromWords(combinedWords);
    final base64Key = base64.encode(keyBytes);

    await _secureStorage.write(key: _e2eeKeyStorageKey, value: base64Key);
    _base64Key = base64Key;
    notifyListeners();
  }

  /// Retrieves the raw key bytes for encryption operations.
  /// Throws an exception if the key is not set.
  Future<Uint8List> getKeyBytes() async {
    if (_base64Key == null) {
      await loadKey();
    }
    if (_base64Key == null) {
      throw Exception("E2EE key is not set. Cannot perform encryption.");
    }
    return base64.decode(_base64Key!);
  }
}
