// TODO: Implement this file.
class AuthUser {
  final int id;
  final String name;
  final String email;
  final String phone;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };
}