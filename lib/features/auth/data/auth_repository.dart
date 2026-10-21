import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/nonce_store.dart';
import 'models/auth_result.dart';
import 'models/reader_status.dart';

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<AuthResult> submitCredentials({
    required String action,
    required String email,
    required String password,
    String? name,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    };
    final json = await _client.postJson('/access/free-subscribe', body: body);
    final result = AuthResult.fromJson(json);
    if (!result.ok) {
      throw WordPressApiException(
        'auth_failed',
        result.message ?? 'Sign-in failed. Please try again.',
      );
    }
    NonceStore.set(result.nonce);
    return result;
  }

  Future<AuthResult> submitGoogleCredential(String idToken) async {
    final json = await _client.postJson(
      '/access/google',
      body: {'credential': idToken},
    );
    final result = AuthResult.fromJson(json);
    if (!result.ok) {
      throw WordPressApiException(
        'google_auth_failed',
        result.message ?? 'Google sign-in failed.',
      );
    }
    NonceStore.set(result.nonce);
    return result;
  }

  Future<ReaderStatus> status() async {
    final json = await _client.getJson('/access/status');
    final s = ReaderStatus.fromJson(json);
    NonceStore.set(s.nonce);
    return s;
  }

  Future<String?> refreshNonce() async {
    final json = await _client.getJson('/access/nonce');
    final nonce = json['nonce'] as String?;
    NonceStore.set(nonce);
    return nonce;
  }
}