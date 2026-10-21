import 'auth_user.dart';

class AuthResult {
  final bool ok;
  final bool unlocked;
  final AuthUser? user;
  final bool isPremium;
  final String? nonce;
  final String? message;

  const AuthResult({
    required this.ok,
    required this.unlocked,
    required this.user,
    required this.isPremium,
    required this.nonce,
    required this.message,
  });

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        ok: j['ok'] == true,
        unlocked: j['unlocked'] == true,
        user: j['user'] is Map
            ? AuthUser.fromJson(Map<String, dynamic>.from(j['user'] as Map))
            : null,
        isPremium: j['is_premium'] == true,
        nonce: j['nonce'] as String?,
        message: j['message'] as String?,
      );
}