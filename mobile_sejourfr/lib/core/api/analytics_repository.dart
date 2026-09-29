import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Rapport de `POST /api/public/analytics/events/batch` (202).
class AnalyticsBatchReport {
  const AnalyticsBatchReport({
    required this.received,
    required this.accepted,
    required this.duplicates,
    required this.rejected,
  });

  final int received;
  final int accepted;
  final int duplicates;

  /// Les événements refusés **un par un** (nom, propriété, run inconnue…). Le
  /// client les purge comme les autres : renvoyés, ils seraient refusés encore.
  final List<({String? eventId, String reason})> rejected;

  factory AnalyticsBatchReport.fromJson(Map<String, dynamic> json) =>
      AnalyticsBatchReport(
        received: (json['received'] as num?)?.toInt() ?? 0,
        accepted: (json['accepted'] as num?)?.toInt() ?? 0,
        duplicates: (json['duplicates'] as num?)?.toInt() ?? 0,
        rejected: [
          for (final item in json['rejected'] as List<dynamic>? ?? const [])
            if (item is Map<String, dynamic>)
              (
                eventId: item['eventId'] as String?,
                reason: item['reason'] as String? ?? '',
              ),
        ],
      );
}

/// Ingestion analytics **en lot** — `POST /api/public/analytics/events/batch`.
///
/// 🛑 L'unitaire (`POST /api/public/analytics/events`) est supprimé côté serveur :
/// tout passe par la file persistante (`AnalyticsQueue`).
///
/// **Public**, mais on laisse l'intercepteur poser le jeton quand il y en a
/// un : le serveur rattache alors l'événement au compte. `skipRefresh` est
/// armé — un jeton périmé sur une mesure ne déclenche **jamais** la
/// déconnexion globale ; et un 401 est rejoué **une fois** sans jeton.
class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final ApiClient _client;

  Future<AnalyticsBatchReport> sendBatch(Map<String, Object?> envelope) async {
    try {
      return await _post(envelope, skipAuth: false);
    } catch (error) {
      if (ApiClient.toApiException(error).statusCode != 401) rethrow;
      return _post(envelope, skipAuth: true);
    }
  }

  Future<AnalyticsBatchReport> _post(
    Map<String, Object?> envelope, {
    required bool skipAuth,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/public/analytics/events/batch',
      data: envelope,
      options: Options(extra: {'skipRefresh': true, 'skipAuth': skipAuth}),
    );
    final data = res.data;
    if (data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: 'Réponse vide');
    }
    return AnalyticsBatchReport.fromJson(data);
  }
}
