import '../models/attempt_models.dart';
import 'api_client.dart';

/// Endpoints utilisateur côté backend :
///   POST   /api/attempts                     (StartAttemptRequest)
///   GET    /api/attempts/{id}
///   POST   /api/attempts/{id}/answers        ({attemptQuestionId, choiceIds[]})
///   POST   /api/attempts/{id}/finish
///
/// Le backend renvoie l'Attempt avec la liste complète des AttemptQuestion +
/// la Question imbriquée pour le runner.
class AttemptsRepository {
  AttemptsRepository(this._client);

  final ApiClient _client;

  Future<Attempt> start(StartAttemptRequest req) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/attempts',
      data: req.toJson(),
    );
    return Attempt.fromJson(res.data!);
  }

  Future<Attempt> getById(String id) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/attempts/$id',
    );
    return Attempt.fromJson(res.data!);
  }

  /// Soumet une réponse. En mode entraînement, le backend renvoie immédiatement
  /// la correction (correct/incorrect + explication). En examen blanc,
  /// le backend renvoie une AnswerResult vide jusqu'à la fin.
  Future<AnswerResult> submitAnswer({
    required String attemptId,
    required String attemptQuestionId,
    required List<String> choiceIds,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/attempts/$attemptId/answers',
      data: {
        'attemptQuestionId': attemptQuestionId,
        'choiceIds': choiceIds,
      },
    );
    return AnswerResult.fromJson(res.data!);
  }

  Future<Attempt> finish(String attemptId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/attempts/$attemptId/finish',
    );
    return Attempt.fromJson(res.data!);
  }
}
