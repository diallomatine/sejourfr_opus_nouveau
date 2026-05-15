import 'enums.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.targetProcedure,
    this.isPremium = false,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final TargetProcedure? targetProcedure;
  final bool isPremium;

  /// L'utilisateur a-t-il choisi son parcours administratif ?
  /// Les comptes ADMIN n'ont pas besoin de cette étape : on les considère
  /// toujours comme onboardés.
  bool get hasCompletedOnboarding =>
      role == UserRole.admin || targetProcedure != null;

  String get displayName {
    final fn = firstName?.trim();
    final ln = lastName?.trim();
    if (fn != null && fn.isNotEmpty) {
      return ln != null && ln.isNotEmpty ? '$fn $ln' : fn;
    }
    return email;
  }

  AuthUser copyWith({TargetProcedure? targetProcedure, bool? isPremium}) =>
      AuthUser(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        targetProcedure: targetProcedure ?? this.targetProcedure,
        isPremium: isPremium ?? this.isPremium,
      );

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        role: UserRole.fromWire(json['role'] as String),
        targetProcedure: json['targetProcedure'] == null
            ? null
            : TargetProcedure.fromWire(json['targetProcedure'] as String),
        isPremium: json['isPremium'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.wire,
        if (targetProcedure != null) 'targetProcedure': targetProcedure!.wire,
        'isPremium': isPremium,
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
