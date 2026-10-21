import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistent holder for the WordPress REST nonce.
///
/// The plugin returns a fresh nonce on every authenticated response. We
/// keep the latest one both in memory (fast path) and in secure storage
/// (survives app restarts). The Dio nonce interceptor reads from here
/// before each request.
class NonceStore {
  NonceStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kNonceKey = 'cio.wp.nonce';

  static String? _value;

  static String? get current => _value;

  /// Save a nonce. Passing null or empty clears it.
  static Future<void> set(String? nonce) async {
    if (nonce == null || nonce.isEmpty) {
      _value = null;
      try {
        await _storage.delete(key: _kNonceKey);
      } catch (_) {}
      return;
    }
    _value = nonce;
    try {
      await _storage.write(key: _kNonceKey, value: nonce);
    } catch (e) {
      debugPrint('[nonce] persist failed: $e');
    }
  }

  /// Read the current nonce. Loads from storage on first access after a
  /// cold start.
  static Future<String?> get() async {
    if (_value != null) return _value;
    try {
      _value = await _storage.read(key: _kNonceKey);
    } catch (_) {
      _value = null;
    }
    return _value;
  }

  /// Clear the nonce from memory and storage.
  static Future<void> clear() async {
    _value = null;
    try {
      await _storage.delete(key: _kNonceKey);
    } catch (_) {}
  }
}