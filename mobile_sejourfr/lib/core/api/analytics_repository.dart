import 'package:dio/dio.dart';

import 'api_client.dart';

/// Ingestion analytics — `POST /api/public/analytics/events`, réponse 204.
///
/// **Public**, mais on laisse l'intercepteur poser le jeton quand il y en a
/// un : le serveur rattache alors l'événement au compte au moment de
/// l'écriture. En revanche `skipRefresh` est armé — un jeton périmé sur une
/// mesure d'audience ne doit **jamais** déclencher la déconnexion globale.
class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final ApiClient _client;

  Future<void> send({
    required String anonymousId,
    required String sessionId,
    required String event,
    String? path,
    Map<String, String>? properties,
    Map<String, String>? firstTouch,
  }) async {
    await _client.dio.post<void>(
      '/api/public/analytics/events',
      data: {
        'anonymousId': anonymousId,
        'sessionId': sessionId,
        'event': event,
        if (path != null) 'path': path,
        if (properties != null && properties.isNotEmpty)
          'properties': properties,
        if (firstTouch != null && firstTouch.isNotEmpty)
          'firstTouch': firstTouch,
      },
      options: Options(extra: const {'skipRefresh': true}),
    );
  }
}
