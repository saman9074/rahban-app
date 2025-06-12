import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  /// Generates a cryptographic key from a given string (e.g., concatenated words) using SHA-256.
  /// The output is a 32-byte (256-bit) key suitable for AES-256.
  static Uint8List generateKeyFromWords(String words) {
    // 1. Combine the words into a single string without spaces.
    final String combined = words.replaceAll(RegExp(r'[\s-]'), '');

    // 2. Convert the combined string to bytes using UTF-8 encoding.
    final bytes = utf8.encode(combined);

    // 3. Hash the bytes using the SHA-256 algorithm.
    final digest = sha256.convert(bytes);

    // 4. Return the resulting hash as a Uint8List.
    return Uint8List.fromList(digest.bytes);
  }

  /// Encrypts a plaintext string using AES-256-GCM mode.
  /// GCM (Galois/Counter Mode) is an authenticated encryption mode that provides confidentiality
  /// and authenticity.
  ///
  /// The process is as follows:
  /// 1. A secure random 12-byte Initialization Vector (IV) is generated for each encryption.
  ///    Using a unique IV for each encryption with the same key is critical for security.
  /// 2. The plaintext is encrypted using the provided key and the generated IV.
  /// 3. The IV is prepended to the ciphertext. This is necessary because the IV is required for decryption.
  /// 4. The combined result (IV + ciphertext) is encoded into a Base64 string for safe network transport.
  static String encrypt(String plainText, Uint8List keyBytes) {
    final key = Key(keyBytes);

    // Use a secure random IV for each encryption operation.
    // AES-GCM typically uses a 12-byte (96-bit) IV for best performance and security.
    final iv = IV.fromSecureRandom(12);

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Prepend the IV to the ciphertext. The receiver will need the IV to decrypt.
    // The structure will be: [IV (12 bytes)] + [Ciphertext]
    final payload = iv.bytes + encrypted.bytes;

    // Return the combined payload as a Base64 string.
    return base64.encode(payload);
  }
}
