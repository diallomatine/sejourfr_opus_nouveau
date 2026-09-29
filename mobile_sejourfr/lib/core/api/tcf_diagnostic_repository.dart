import '../models/tcf_diagnostic_models.dart';
import 'api_client.dart';

/// Le diagnostic TCF **4 épreuves** (L4) — **en LECTURE seule** côté mobile.
///
/// 🛑 Le parcours (ouvrir, lancer / clore une section, calculer le résultat)
/// est **retiré des fronts le 2026-09-26** (décision du propriétaire) : les
/// épreuves que le diagnostic rapide ne mesure pas se mesurent par l'examen
/// blanc que propose le Plan. Les endpoints backend restent en place, non
/// appelés. Seule la relecture d'un résultat DÉJÀ obtenu subsiste, parce qu'il
/// est toujours lu (`plan_unlock_screen.dart`). Miroir de `tcfDiagnosticApi`
/// (`web_sejoufr/lib/api.ts`).
///
/// 🛑 Distinct de `DiagnosticRepository`, qui porte le diagnostic **rapide**.
class TcfDiagnosticRepository {
  TcfDiagnosticRepository(this._client);

  final ApiClient _client;

  /// Le diagnostic courant, ou `null` si le candidat n'en a jamais ouvert
  /// (**204** côté serveur). Une lecture n'ouvre jamais de diagnostic.
  Future<TcfDiagnosticDto?> current() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/tcf-diagnostics/current',
    );
    final data = res.data;
    if (data == null || data.isEmpty) return null;
    return TcfDiagnosticDto.fromJson(data);
  }

  /// Relit un résultat sans rien reclôturer.
  Future<TcfDiagnosticResultDto> readResult(String sessionId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/tcf-diagnostics/$sessionId/result',
    );
    return TcfDiagnosticResultDto.fromJson(res.data!);
  }
}
