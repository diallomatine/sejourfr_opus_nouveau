import 'enums.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final UserRole role;

  String get displayName {
    final fn = firstName?.trim();
    final ln = lastName?.trim();
    if (fn != null && fn.isNotEmpty) {
      return ln != null && ln.isNotEmpty ? '$fn $ln' : fn;
    }
    return email;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        role: UserRole.fromWire(json['role'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.wire,
      };
}

class TokenResponse {
  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final AuthUser user;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
