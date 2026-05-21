import '../models/enums.dart';
import '../models/lot_models.dart';
import 'api_client.dart';

/// Accès à `/api/lots` côté mobile.
///
/// Côté backend : `LotService` calcule les lots à la volée depuis le pool de
/// questions filtré (module + questionType + difficulty), trié par
/// `created_at, id`. Seuls les lots complets sont renvoyés.
class LotsRepository {
  LotsRepository(this._client);

  final ApiClient _client;

  /// Liste les lots disponibles pour un module / épreuve / niveau.
  /// `questionType` est optionnel (TCF QCM : passe `CO` ou `CE` ; pour le
  /// civique sans découpage par épreuve, laisser null — le backend gère).
  Future<List<LotDto>> list({
    required AppModule module,
    QuestionType? questionType,
    required Difficulty difficulty,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/lots',
      queryParameters: {
        'module': module.wire,
        if (questionType != null) 'questionType': questionType.wire,
        'difficulty': difficulty.wire,
      },
    );
    return (res.data ?? [])
        .map((e) => LotDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
