import 'package:dio/dio.dart';

import '../models/civic_diagnostic_models.dart';
import '../models/enums.dart';
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

  /// Ouvre un diagnostic **sans compte** (`V053`).
  Future<CivicDiagnosticDto> openGuest(TargetProcedure procedure);

  /// L'avancement d'une session de visiteur. **404 dès qu'un compte l'a
  /// adoptée** : elle n'est plus lisible que par son porteur.
  Future<CivicDiagnosticDto> guest(String sessionId);

  /// **Adopte** la session passée en visiteur : elle devient celle du compte.
  Future<CivicDiagnosticDto> adopt(String sessionId);
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

  /// Ouvre le diagnostic d'un **visiteur** (`V053`).
  ///
  /// 🛑 **La démarche pilote le tirage** : mesurer un candidat naturalisation
  /// sur le programme d'une carte de séjour lui rendrait un diagnostic flatteur
  /// et un plan incomplet.
  ///
  /// 🛑 **Il n'existe AUCUNE route de résultat publique**, et c'est délibéré :
  /// le résultat est ce qu'on échange contre le compte.
  @override
  Future<CivicDiagnosticDto> openGuest(TargetProcedure procedure) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/public/civic-diagnostics',
      queryParameters: {'procedure': procedure.wire},
      options: _publicOptions,
    );
    return CivicDiagnosticDto.fromJson(res.data!);
  }

  @override
  Future<CivicDiagnosticDto> guest(String sessionId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/public/civic-diagnostics/$sessionId',
      options: _publicOptions,
    );
    return CivicDiagnosticDto.fromJson(res.data!);
  }

  /// L'adoption. **Idempotent** : un second appel sur une session déjà adoptée
  /// par ce compte la rend telle quelle. 🛑 Rien n'est rejoué — mêmes
  /// questions, mêmes réponses, déjà corrigées.
  @override
  Future<CivicDiagnosticDto> adopt(String sessionId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/civic-diagnostics/$sessionId/adopt',
    );
    return CivicDiagnosticDto.fromJson(res.data!);
  }

  /// Route publique : aucun jeton, et un 401 ne doit pas déclencher la
  /// déconnexion globale de l'intercepteur.
  static final Options _publicOptions =
      Options(extra: const {'skipAuth': true, 'skipRefresh': true});
}
