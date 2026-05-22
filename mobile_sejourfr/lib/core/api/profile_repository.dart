import 'api_client.dart';

/// Endpoints du compte utilisateur (édition profil, mot de passe, email).
/// Distinct de `UserContentRepository` qui sert les données pédagogiques
/// (stats, progression, favoris). Tous nécessitent l'auth.
///
/// Backend correspondant :
///  - `PATCH  /api/me/profile`              { firstName, lastName }
///  - `POST   /api/me/change-password`      { currentPassword, newPassword }
///  - `POST   /api/me/change-email-request` { newEmail, currentPassword }
///
/// Le confirm email se fait via lien dans le mail → endpoint backend
/// `GET /api/auth/confirm-email-change?token=...` qui rend une page HTML
/// directement (pas appelé par le mobile).
class ProfileRepository {
  ProfileRepository(this._client);

  final ApiClient _client;

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    await _client.dio.patch<void>(
      '/api/me/profile',
      data: {'firstName': firstName, 'lastName': lastName},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.post<void>(
      '/api/me/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Déclenche l'envoi d'un mail de vérification au [newEmail]. L'email du
  /// compte ne change qu'au moment où l'utilisateur clique sur le lien.
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    await _client.dio.post<void>(
      '/api/me/change-email-request',
      data: {
        'newEmail': newEmail,
        'currentPassword': currentPassword,
      },
    );
  }
}
