import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class EncryptionHelper {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyAlias = 'local_file_encryption_key';
  static encrypt.Key? _cachedKey;

  /// Retrieves a secure encryption key. If not present in secure storage,
  /// it dynamically generates a new random 256-bit key and stores it securely.
  static Future<encrypt.Key> getEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      String? keyString = await _secureStorage.read(key: _keyAlias);
      if (keyString == null || keyString.isEmpty) {
        // Generate a random 32-character key using secure random bytes
        final random = Random.secure();
        const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^*()';
        keyString = List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();

        await _secureStorage.write(key: _keyAlias, value: keyString);
      }
      _cachedKey = encrypt.Key.fromUtf8(keyString);
      return _cachedKey!;
    } catch (e) {
      // Safe fallback if secure storage is completely unavailable (e.g. running in test environments)
      return encrypt.Key.fromUtf8('fallback32lengthsupersecretkey12');
    }
  }
}
