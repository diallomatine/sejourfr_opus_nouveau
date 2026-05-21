import 'package:sejourfr_mobile/core/models/attempt_summary.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';

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

  /// Récupère l'historique des sessions de l'utilisateur courant.
  ///
  /// Paramètres :
  ///  - [type]   : filtrer par TRAINING / MOCK_EXAM (null = toutes)
  ///  - [module] : filtrer par module CIVIQUE / TCF (null = tous)
  ///  - [moduleExamQuestionType] : isole les examens module TCF (CO ou CE),
  ///    null pour ne pas filtrer sur ce critère
  ///  - [limit]  : nombre max de résultats (par défaut 20)
  ///
  /// Backend : GET /api/me/attempts?type=...&module=...&moduleExamQuestionType=...&limit=...
  Future<List<AttemptSummary>> listMine({
    AttemptType? type,
    AppModule? module,
    QuestionType? moduleExamQuestionType,
    int limit = 20,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/me/attempts',
      queryParameters: {
        if (type != null) 'type': type.wire,
        if (module != null) 'module': module.wire,
        if (moduleExamQuestionType != null)
          'moduleExamQuestionType': moduleExamQuestionType.wire,
        'limit': limit,
      },
    );
    return (res.data ?? []).map((e) => AttemptSummary.fromJson(e as Map<String, dynamic>)).toList();
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
