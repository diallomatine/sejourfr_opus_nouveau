import '../models/enums.dart';
import '../models/tcf_diagnostic_models.dart';
import 'api_client.dart';

/// Le diagnostic TCF **4 épreuves** (L4).
///
/// 🛑 Distinct de `DiagnosticRepository`, qui porte le diagnostic **initial**
/// (une production écrite + une orale). Deux objets produit différents.
///
/// La **passation** n'est pas ici : les sections QCM répondent par
/// `AttemptsRepository` et les productions par `ProductionRepository`,
/// exactement comme l'examen complet. Aucun pipeline n'est dupliqué.
abstract interface class TcfDiagnosticGateway {
  Future<TcfDiagnosticDto> open();
  Future<TcfDiagnosticDto?> current();
  Future<TcfDiagnosticDto> detail(String sessionId);
  Future<TcfDiagnosticDto> startSection(String sessionId, EpreuveType epreuve);
  Future<TcfDiagnosticResultDto> result(String sessionId);
  Future<TcfDiagnosticResultDto> readResult(String sessionId);
  Future<TcfReassessmentEligibilityDto> eligibility();
}

class TcfDiagnosticRepository implements TcfDiagnosticGateway {
  TcfDiagnosticRepository(this._client);

  final ApiClient _client;

  /// Ouvre le diagnostic, ou rend celui en cours.
  ///
  /// **Idempotent côté serveur** : un double appui ne crée pas deux
  /// diagnostics — ce qui compte, le premier étant le seul gratuit.
  @override
  Future<TcfDiagnosticDto> open() async {
    final res = await _client.dio.post<Map<String, dynamic>>('/api/tcf-diagnostics');
    return TcfDiagnosticDto.fromJson(res.data!);
  }

  /// Le diagnostic courant, ou `null` si le candidat n'en a jamais ouvert
  /// (**204** côté serveur).
  ///
  /// 🛑 Une lecture n'ouvre jamais de diagnostic par effet de bord : ne pas
  /// remplacer cet appel par [open] pour « simplifier » un écran.
  @override
  Future<TcfDiagnosticDto?> current() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/tcf-diagnostics/current',
    );
    final data = res.data;
    if (data == null || data.isEmpty) return null;
    return TcfDiagnosticDto.fromJson(data);
  }

  @override
  Future<TcfDiagnosticDto> detail(String sessionId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/tcf-diagnostics/$sessionId',
    );
    return TcfDiagnosticDto.fromJson(res.data!);
  }

  /// Pose l'ancre du chrono d'une section. À appeler **avant** d'ouvrir le
  /// runner : sans elle la section n'a aucune échéance. Idempotent — reprendre
  /// ne rend pas de temps au candidat.
  @override
  Future<TcfDiagnosticDto> startSection(String sessionId, EpreuveType epreuve) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/tcf-diagnostics/$sessionId/sections/${epreuve.wire}/start',
    );
    return TcfDiagnosticDto.fromJson(res.data!);
  }

  /// Calcule le résultat et clôture. N'exige pas les 4 sections.
  @override
  Future<TcfDiagnosticResultDto> result(String sessionId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/tcf-diagnostics/$sessionId/result',
    );
    return TcfDiagnosticResultDto.fromJson(res.data!);
  }

  /// Relit un résultat sans rien reclôturer.
  @override
  Future<TcfDiagnosticResultDto> readResult(String sessionId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/tcf-diagnostics/$sessionId/result',
    );
    return TcfDiagnosticResultDto.fromJson(res.data!);
  }

  /// **Peut-il relancer, et sinon pourquoi ?** (L7)
  ///
  /// 🛑 C'est la seule façon correcte de le savoir. Ne jamais le déduire d'un
  /// `completedAt` ni recompter les 14 jours ici : la règle a une seule
  /// autorité, et elle est serveur — elle connaît aussi la dérogation du Plan,
  /// que le mobile ne voit pas.
  ///
  /// Jamais 204 — un candidat sans aucun diagnostic reçoit
  /// `first: true, canStart: true`.
  @override
  Future<TcfReassessmentEligibilityDto> eligibility() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/tcf-diagnostics/eligibility',
    );
    return TcfReassessmentEligibilityDto.fromJson(res.data!);
  }
}
