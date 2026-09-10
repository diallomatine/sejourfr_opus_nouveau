import '../models/civic_diagnostic_models.dart';
import 'api_client.dart';

/// Le diagnostic **civique** (L9, `20_` §4).
///
/// 🛑 **Distinct de l'examen blanc civique** : couverture équilibrée contre
/// représentative, il CRÉE le plan là où l'examen blanc VÉRIFIE la préparation.
///
/// 🛑 **La passation n'est pas ici** : les réponses passent par
/// `AttemptsRepository`, exactement comme n'importe quelle série. Aucun runner
/// n'est dupliqué.
///
/// 🛑 **Aucun appel LLM** : le civique est du QCM déterministe.
abstract interface class CivicDiagnosticGateway {
  Future<CivicDiagnosticDto> open();
  Future<CivicDiagnosticDto?> current();
  Future<CivicDiagnosticResultDto> result(String sessionId);
  Future<CivicDiagnosticResultDto> readResult(String sessionId);
}

class CivicDiagnosticRepository implements CivicDiagnosticGateway {
  CivicDiagnosticRepository(this._client);

  final ApiClient _client;

  /// Ouvre, ou rend celui en cours. **Idempotent** : deux appuis ne font pas
  /// deux tirages, donc pas deux mesures incomparables.
  @override
  Future<CivicDiagnosticDto> open() async {
    final res = await _client.dio.post<Map<String, dynamic>>('/api/civic-diagnostics');
    return CivicDiagnosticDto.fromJson(res.data!);
  }

  /// Le diagnostic courant, ou `null` (**204**).
  ///
  /// 🛑 Une lecture n'ouvre jamais de diagnostic par effet de bord : ne pas
  /// remplacer cet appel par [open] pour « simplifier » un écran — l'ouvrir
  /// consomme l'unique diagnostic gratuit.
  @override
  Future<CivicDiagnosticDto?> current() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/civic-diagnostics/current',
    );
    final data = res.data;
    if (data == null || data.isEmpty) return null;
    return CivicDiagnosticDto.fromJson(data);
  }

  /// Calcule le résultat et clôture.
  @override
  Future<CivicDiagnosticResultDto> result(String sessionId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/civic-diagnostics/$sessionId/result',
    );
    return CivicDiagnosticResultDto.fromJson(res.data!);
  }

  /// Relit un résultat sans rien reclôturer.
  @override
  Future<CivicDiagnosticResultDto> readResult(String sessionId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/civic-diagnostics/$sessionId/result',
    );
    return CivicDiagnosticResultDto.fromJson(res.data!);
  }
}
