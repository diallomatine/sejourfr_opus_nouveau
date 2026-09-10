import 'package:dio/dio.dart';

import '../models/diagnostic_models.dart';
import 'api_client.dart';

abstract interface class DiagnosticGateway {
  /// Les deux sujets, servis **sans compte**. Aucune session n'est créée.
  Future<PublicDiagnostic> publicCurrent();

  Future<DiagnosticJourney> current();
  /// Ouvre la session, ou rend celle déjà commencée. **Idempotent.**
  ///
  /// [writtenTaskId] est le sujet que le candidat a réellement lu et traité
  /// (L3). **Facultatif** et **vérifié serveur** : un identifiant inconnu
  /// retombe sur un tirage plutôt que de bloquer un candidat dont le sujet a
  /// été désactivé entre-temps.
  Future<DiagnosticJourney> startOrResume({String? writtenTaskId});
  Future<DiagnosticJourney> detail(String sessionId);
  Future<DiagnosticJourney> retryAnalysis(String sessionId);
}

class DiagnosticRepository implements DiagnosticGateway {
  DiagnosticRepository(this._client);

  final ApiClient _client;

  @override
  Future<PublicDiagnostic> publicCurrent() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/public/diagnostics/current',
      // Route publique : on n'envoie aucun jeton et un 401 ne doit surtout pas
      // déclencher la déconnexion globale de l'intercepteur.
      options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
    );
    return PublicDiagnostic.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> current() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/diagnostics/current',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> startOrResume({String? writtenTaskId}) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/diagnostics',
      queryParameters: writtenTaskId == null
          ? null
          : {'writtenTaskId': writtenTaskId},
    );
    return DiagnosticJourney.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> detail(String sessionId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/diagnostics/$sessionId',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> retryAnalysis(String sessionId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/diagnostics/$sessionId/retry-analysis',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }
}
