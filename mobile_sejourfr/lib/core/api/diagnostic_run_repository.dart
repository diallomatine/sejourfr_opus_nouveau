import 'package:dio/dio.dart';

import '../models/diagnostic_run_models.dart';
import 'api_client.dart';

/// La trace du tunnel diagnostic — routes **publiques**.
///
/// Le jeton d'accès part s'il existe (le serveur fait alors de l'appelant le
/// porteur de la run), mais `skipRefresh` est armé : une mesure ne déclenche
/// jamais la déconnexion globale.
class DiagnosticRunRepository {
  DiagnosticRunRepository(this._client);

  final ApiClient _client;

  static final Options _options = Options(extra: const {'skipRefresh': true});

  /// `POST /api/public/diagnostic-runs` — à l'affichage de la **première
  /// question**. Idempotent par `(X-Sejourfr-Anonymous-Id, clientKey)` et par
  /// session.
  Future<DiagnosticRunCreated?> create({
    required DiagnosticRunType type,
    required String clientKey,
    String? sessionId,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/public/diagnostic-runs',
      data: {
        'diagnosticType': type.wire,
        'clientKey': clientKey,
        if (sessionId != null) 'sessionId': sessionId,
      },
      options: _options,
    );
    final data = res.data;
    return data == null ? null : DiagnosticRunCreated.fromJson(data);
  }

  /// `POST /api/public/diagnostic-runs/{id}/submit` — **`QUICK_TCF` seulement**,
  /// à « Analyser mes réponses ». Le civique et le TCF complet sont posés
  /// « soumis » par le serveur (409 si on l'appelait).
  Future<void> submit({
    required String diagnosticRunId,
    String? claimToken,
  }) async {
    await _client.dio.post<void>(
      '/api/public/diagnostic-runs/$diagnosticRunId/submit',
      data: {if (claimToken != null) 'claimToken': claimToken},
      options: _options,
    );
  }
}
