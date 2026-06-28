import '../models/realtime_models.dart';
import 'api_client.dart';

/// Accès aux endpoints du mode EO temps réel (examinateur vocal) :
///   GET  /api/realtime/eo/quota
///   POST /api/realtime/eo/sessions                    (démarre, mint token)
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

  /// Relaie un fragment de transcript (candidat OU examinateur). Le backend
  /// répond 204 ; rien à parser.
  Future<void> appendTranscript({
    required String sessionId,
    required RealtimeSpeaker speaker,
    required String text,
  }) async {
    await _client.dio.post<void>(
      '/api/realtime/eo/sessions/$sessionId/transcript',
      data: {'speaker': speaker.wire, 'text': text},
    );
  }

  Future<RealtimeSessionStateResponse> finishSession(String sessionId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/realtime/eo/sessions/$sessionId/finish',
    );
    return RealtimeSessionStateResponse.fromJson(res.data!);
  }
}
