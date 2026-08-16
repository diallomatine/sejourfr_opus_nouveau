import '../models/realtime_models.dart';
import 'api_client.dart';

/// Accès aux endpoints du mode EO temps réel (examinateur vocal) :
///   GET  /api/realtime/eo/quota
///   POST /api/realtime/eo/sessions                    (démarre, mint token)
///   POST /api/realtime/eo/sessions/{id}/resume        (reprise après coupure)
///   POST /api/realtime/eo/sessions/{id}/transcript    (relais dialogue)
///   POST /api/realtime/eo/sessions/{id}/finish        (clôture)
class RealtimeRepository {
  RealtimeRepository(this._client);

  final ApiClient _client;

  Future<RealtimeQuota> getQuota() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/realtime/eo/quota',
    );
    return RealtimeQuota.fromJson(res.data!);
  }

  Future<RealtimeSessionDescriptor> startSession({
    required String productionTaskId,
    String? attemptId,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/realtime/eo/sessions',
      data: {
        'productionTaskId': productionTaskId,
        if (attemptId != null) 'attemptId': attemptId,
      },
    );
    return RealtimeSessionDescriptor.fromJson(res.data!);
  }

  /// Reprend une session dont le WebSocket est tombé : NOUVEAU token, MÊME
  /// conversation, MÊME transcript, et surtout AUCUN slot de simulation
  /// re-débité. Ne JAMAIS rappeler [startSession] après une coupure : cela
  /// créerait une seconde session et débiterait un second slot.
  ///
  /// Peut répondre `ASYNC_FALLBACK` (mint impossible côté serveur) ; lève une
  /// `ApiException` 422 si la session est terminée, si le plafond de reprises
  /// est atteint ou si la reprise est désactivée.
  Future<RealtimeSessionDescriptor> resumeSession(
    String sessionId, {
    String? resumptionHandle,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/realtime/eo/sessions/$sessionId/resume',
      data: {'resumptionHandle': resumptionHandle},
    );
    return RealtimeSessionDescriptor.fromJson(res.data!);
  }

  /// Relaie un fragment de transcript (candidat OU examinateur). Le backend
  /// répond 204 ; rien à parser.
  ///
  /// [turnIndex] rend l'appel IDEMPOTENT : le serveur ignore un index déjà
  /// appliqué, donc un réessai après coupure réseau ne duplique plus un tour.
  /// Il doit être strictement croissant sur la session et CONSERVÉ d'un essai à
  /// l'autre. [resumptionHandle] voyage ici plutôt que dans un appel dédié : le
  /// client POSTe déjà toutes les 1,2 s, le serveur reste à jour gratuitement.
  Future<void> appendTranscript({
    required String sessionId,
    required RealtimeSpeaker speaker,
    required String text,
    int? turnIndex,
    String? resumptionHandle,
  }) async {
    await _client.dio.post<void>(
      '/api/realtime/eo/sessions/$sessionId/transcript',
      data: {
        'speaker': speaker.wire,
        'text': text,
        if (turnIndex != null) 'turnIndex': turnIndex,
        if (resumptionHandle != null) 'resumptionHandle': resumptionHandle,
      },
    );
  }

  Future<RealtimeSessionStateResponse> finishSession(String sessionId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/realtime/eo/sessions/$sessionId/finish',
    );
    return RealtimeSessionStateResponse.fromJson(res.data!);
  }
}
