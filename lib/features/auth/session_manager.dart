import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'data/models/auth_user.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kUserKey = 'cio.auth.user';
  static const _kPremiumKey = 'cio.auth.premium';
  static const _kNonceKey = 'cio.auth.nonce';

  AuthUser? _user;
  bool _isPremium = false;
  String? _nonce;

  AuthUser? get currentUser => _user;
  bool get isSignedIn => _user != null;
  bool get isPremium => _isPremium;
  String? get nonce => _nonce;

  void setSession({
    required AuthUser user,
    required bool isPremium,
    String? nonce,
  }) {
    _user = user;
    _isPremium = isPremium;
    _nonce = nonce;
  }

  Future<void> persist() async {
    final user = _user;
    if (user == null) {
      debugPrint('[session] persist: no user, clearing storage');
      await _clearStorage();
      return;
    }
    try {
      final encoded = jsonEncode(user.toJson());
      debugPrint('[session] persist: writing user key, bytes=${encoded.length}');
      await _storage.write(key: _kUserKey, value: encoded);
      await _storage.write(key: _kPremiumKey, value: _isPremium ? '1' : '0');
      if (_nonce != null && _nonce!.isNotEmpty) {
        await _storage.write(key: _kNonceKey, value: _nonce);
      } else {
        await _storage.delete(key: _kNonceKey);
      }
      debugPrint('[session] persist: complete');
    } catch (e) {
      debugPrint('[session] persist FAILED: $e');
    }
  }

  Future<void> restore() async {
    try {
      final rawUser = await _storage.read(key: _kUserKey);
      debugPrint('[session] restore: rawUser isNull=${rawUser == null} '
          'length=${rawUser?.length ?? 0}');
      if (rawUser == null || rawUser.isEmpty) {
        _user = null;
        _isPremium = false;
        _nonce = null;
        return;
      }
      final map = jsonDecode(rawUser);
      if (map is! Map) {
        debugPrint('[session] restore: stored value is not a JSON object');
        await _clearStorage();
        return;
      }
      _user = AuthUser.fromJson(Map<String, dynamic>.from(map));
      _isPremium = (await _storage.read(key: _kPremiumKey)) == '1';
      _nonce = await _storage.read(key: _kNonceKey);
      debugPrint('[session] restore: user=${_user?.email} premium=$_isPremium');
    } catch (e, st) {
      debugPrint('[session] restore FAILED: $e');
      debugPrint('[session] stack: $st');
      await _clearStorage();
    }
  }

  Future<void> clear() async {
    _user = null;
    _isPremium = false;
    _nonce = null;
    await _clearStorage();
  }

  Future<void> _clearStorage() async {
    try {
      await _storage.delete(key: _kUserKey);
      await _storage.delete(key: _kPremiumKey);
      await _storage.delete(key: _kNonceKey);
    } catch (_) {}
  }
}