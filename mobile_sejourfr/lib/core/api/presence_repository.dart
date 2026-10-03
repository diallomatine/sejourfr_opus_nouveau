import 'api_client.dart';

/// Battement de présence (chantier « Activité ») : `POST /api/me/presence`,
/// sans corps, 204. N'importe quelle requête authentifiée compte déjà comme
/// activité ; le battement couvre seulement les phases sans requête. Appelé
/// par `PresenceHeartbeat`, et par lui seul.
///
/// Requête ordinaire : jeton, en-têtes `X-Sejourfr-*` (dont la plateforme) et
/// rafraîchissement sur 401 comme tout appel — jamais déclenché exprès.
class PresenceRepository {
  PresenceRepository(this._client);

  final ApiClient _client;

  Future<void> beat() async {
    await _client.dio.post<void>('/api/me/presence');
  }
}
