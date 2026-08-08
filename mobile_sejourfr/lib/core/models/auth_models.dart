import 'enums.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.targetProcedure,
    this.targetLevel,
    this.isPremium = false,
    this.hasCivique = false,
    this.hasTcf = false,
    this.premiumEndsAt,
    this.authProvider = AuthProvider.local,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final TargetProcedure? targetProcedure;

  /// Palier VISÉ, **dérivé serveur** : `max(exigé par la démarche, niveau
  /// déclaré)` (cf. `TargetProcedure.niveauVise`). Le backend applique déjà le
  /// plancher, donc ce champ ne contredit jamais [targetProcedure] — null
  /// seulement quand ni l'un ni l'autre n'est connu.
  final TargetLevel? targetLevel;

  /// Vrai si l'utilisateur a au moins un plan payant actif (CIVIQUE ou INTÉGRAL).
  final bool isPremium;

  /// Accès au module Civique (plan CIVIQUE_3MOIS ou INTEGRAL_3MOIS actif).
  final bool hasCivique;

  /// Accès au module TCF (uniquement plan INTEGRAL_3MOIS actif).
  final bool hasTcf;

  /// Date d'expiration de l'accès payant, null si pas de plan actif.
  final DateTime? premiumEndsAt;

  /// Moyen par lequel le compte a ete cree (mot de passe local vs social).
  final AuthProvider authProvider;

  /// L'utilisateur a-t-il choisi son parcours administratif ?
  /// Les comptes ADMIN n'ont pas besoin de cette étape : on les considère
  /// toujours comme onboardés.
  bool get hasCompletedOnboarding =>
      role == UserRole.admin || targetProcedure != null;

  /// L'utilisateur a-t-il accès complet au module donné ?
  /// - CIVIQUE : nécessite plan Civique 3 mois OU Intégral 3 mois.
  /// - TCF     : nécessite plan Intégral 3 mois (les comptes Civique n'y ont pas accès).
  bool canAccessModule(AppModule module) {
    if (role == UserRole.admin) return true;
    return switch (module) {
      AppModule.civique => hasCivique,
      AppModule.tcf => hasTcf,
    };
  }

  String get displayName {
    final fn = firstName?.trim();
    final ln = lastName?.trim();
    if (fn != null && fn.isNotEmpty) {
      return ln != null && ln.isNotEmpty ? '$fn $ln' : fn;
    }
    return email;
  }

  AuthUser copyWith({
    TargetProcedure? targetProcedure,
    TargetLevel? targetLevel,
    bool? isPremium,
    bool? hasCivique,
    bool? hasTcf,
    DateTime? premiumEndsAt,
    AuthProvider? authProvider,
  }) =>
      AuthUser(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        targetProcedure: targetProcedure ?? this.targetProcedure,
        targetLevel: targetLevel ?? this.targetLevel,
        isPremium: isPremium ?? this.isPremium,
        hasCivique: hasCivique ?? this.hasCivique,
        hasTcf: hasTcf ?? this.hasTcf,
        premiumEndsAt: premiumEndsAt ?? this.premiumEndsAt,
        authProvider: authProvider ?? this.authProvider,
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
        targetLevel:
            TargetLevel.fromWireNullable(json['targetLevel'] as String?),
        isPremium: json['isPremium'] as bool? ?? false,
        hasCivique: json['hasCivique'] as bool? ?? false,
        hasTcf: json['hasTcf'] as bool? ?? false,
        premiumEndsAt: json['premiumEndsAt'] != null
            ? DateTime.tryParse(json['premiumEndsAt'] as String)
            : null,
        authProvider: json['authProvider'] == null
            ? AuthProvider.local
            : AuthProvider.fromWire(json['authProvider'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.wire,
        if (targetProcedure != null) 'targetProcedure': targetProcedure!.wire,
        if (targetLevel != null) 'targetLevel': targetLevel!.wire,
        'isPremium': isPremium,
        'hasCivique': hasCivique,
        'hasTcf': hasTcf,
        if (premiumEndsAt != null)
          'premiumEndsAt': premiumEndsAt!.toIso8601String(),
        'authProvider': authProvider.wire,
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
