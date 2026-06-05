import 'package:dio/dio.dart';

import '../models/account_models.dart';
import '../models/auth_models.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<TokenResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
      options: _publicOptions(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<TokenResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
      options: _publicOptions(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  /// Echange un ID token Google (obtenu via `google_sign_in`) contre une
  /// session SejourFR. Cree le compte automatiquement s'il n'existe pas.
  Future<TokenResponse> loginWithGoogle({required String idToken}) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/google',
      data: {'idToken': idToken},
      options: _publicOptions(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  /// Echange un identityToken Apple (obtenu via `sign_in_with_apple`) contre
  /// une session SejourFR. Le nom n'est renvoye par Apple qu'au premier
  /// consent — on le passe au backend pour peupler le profil a la creation.
  Future<TokenResponse> loginWithApple({
    required String identityToken,
    String? firstName,
    String? lastName,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/apple',
      data: {
        'identityToken': identityToken,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      },
      options: _publicOptions(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<AuthUser> me() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/auth/me');
    return AuthUser.fromJson(res.data!);
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.dio.post(
      '/api/auth/forgot-password',
      data: {'email': email},
      options: _publicOptions(),
    );
  }

  /// Révoque le refresh token côté serveur. Best-effort : on absorbe toutes
  /// les erreurs (timeout, 4xx, 5xx) — le logout côté client doit toujours
  /// aboutir en clearant le storage, peu importe si le serveur a confirmé.
  /// `skipAuth=true` car le token d'accès peut être expiré au moment du
  /// logout (sinon l'intercepteur essaie de refresh, ce qu'on ne veut pas).
  Future<void> logout({required String refreshToken}) async {
    try {
      await _client.dio.post(
        '/api/auth/logout',
        data: {'refreshToken': refreshToken},
        options: _publicOptions(),
      );
    } catch (_) {
      // Silencieux. Le clear local est garanti par AuthController.logout().
    }
  }

  /// Supprime le compte de l'utilisateur courant (App Store 5.1.1(v)).
  /// Authentifié : le backend identifie le user via le Bearer, jamais via un
  /// paramètre. Renvoie le détail abonnement pour informer l'utilisateur.
  Future<AccountDeletionResult> deleteAccount() async {
    final res = await _client.dio.delete<Map<String, dynamic>>('/api/account');
    return AccountDeletionResult.fromJson(res.data ?? const {});
  }

  Options _publicOptions() =>
      Options(extra: const {'skipAuth': true, 'skipRefresh': true});
}
