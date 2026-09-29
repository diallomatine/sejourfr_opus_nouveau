import 'api_client.dart';

/// Endpoint public POST `/api/contact` — pas d'auth nécessaire (un visiteur
/// non connecté doit pouvoir nous écrire). Le backend relaye le message
/// vers `support@sejourfr.fr` via `MailService`.
class ContactRepository {
  ContactRepository(this._client);

  final ApiClient _client;

  Future<void> submit({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    await _client.dio.post<void>(
      '/api/contact',
      data: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      },
    );
  }
}
