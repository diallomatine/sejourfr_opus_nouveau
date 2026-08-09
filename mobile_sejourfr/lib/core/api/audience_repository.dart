import 'package:dio/dio.dart';

import 'api_client.dart';

enum AudienceEvent {
  diagnosticViewed('DIAGNOSTIC_VIEWED'),
  diagnosticStarted('DIAGNOSTIC_STARTED'),
  diagnosticWrittenCompleted('DIAGNOSTIC_WRITTEN_COMPLETED'),
  diagnosticOralCompleted('DIAGNOSTIC_ORAL_COMPLETED'),
  diagnosticCompleted('DIAGNOSTIC_COMPLETED'),
  diagnosticResultViewed('DIAGNOSTIC_RESULT_VIEWED'),
  planOpened('PLAN_OPENED'),
  planRecommendedExerciseStarted('PLAN_RECOMMENDED_EXERCISE_STARTED');

  const AudienceEvent(this.wire);

  final String wire;
}

class AudienceRepository {
  AudienceRepository(this._client);

  final ApiClient _client;

  /// Mesure agrégée sans identifiant, token, cookie ni donnée personnelle.
  /// Le backend ne connaît pas de source « mobile » : `direct` est la valeur
  /// autorisée qui décrit correctement une ouverture native sans campagne.
  Future<void> track({
    required String path,
    required AudienceEvent event,
  }) async {
    await _client.dio.post<void>(
      '/api/public/page-views',
      data: {'path': path, 'source': 'direct', 'event': event.wire},
      options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
    );
  }
}
