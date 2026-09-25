import '../models/email_preferences.dart';
import 'api_client.dart';

/// Endpoints du compte utilisateur (édition profil, mot de passe, email).
/// Distinct de `UserContentRepository` qui sert les données pédagogiques
/// (stats, progression, favoris). Tous nécessitent l'auth.
///
/// Backend correspondant :
///  - `PATCH  /api/me/profile`              { firstName, lastName }
///  - `POST   /api/me/change-password`      { currentPassword, newPassword }
///  - `POST   /api/me/change-email-request` { newEmail, currentPassword }
///  - `GET    /api/me/email-preferences`
///  - `PATCH  /api/me/email-preferences`    { engagementEnabled?, marketingEnabled? }
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

  Future<EmailPreferences> getEmailPreferences() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/email-preferences',
    );
    return EmailPreferences.fromJson(res.data ?? const {});
  }

  /// Un champ `null` n'est pas envoyé : le serveur le laisse inchangé.
  Future<EmailPreferences> updateEmailPreferences({
    bool? engagementEnabled,
    bool? marketingEnabled,
  }) async {
    final res = await _client.dio.patch<Map<String, dynamic>>(
      '/api/me/email-preferences',
      data: {
        if (engagementEnabled != null) 'engagementEnabled': engagementEnabled,
        if (marketingEnabled != null) 'marketingEnabled': marketingEnabled,
      },
    );
    return EmailPreferences.fromJson(res.data ?? const {});
  }
}
