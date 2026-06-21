import '../models/full_tcf_exam.dart';
import 'api_client.dart';

/// Accès aux endpoints `/api/full-tcf-exams` (examen blanc TCF complet).
///
/// Backend : `FullTcfExamService.start` crée parent `TCF_COMPLET` + 4
/// sous-attempts (CO/CE/EE/EO) en une transaction. Le mobile pilote ensuite
/// l'enchaînement en utilisant les `attemptId` des sous-attempts renvoyés.
class FullTcfExamRepository {
  FullTcfExamRepository(this._client);

  final ApiClient _client;

  /// Démarre un nouvel examen blanc complet. Réservé aux abonnés TCF — un
  /// non-premium reçoit 403 (le mobile affiche le paywall avant cet appel).
  /// [slotNumber] permet à la grille « 20 examens TCF complets » de
  /// stabiliser la numérotation (refaire le slot N met à jour le slot N
  /// au lieu de glisser les essais d'un cran). Cf. V110.
  Future<FullTcfExamResponse> start({int? slotNumber}) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/full-tcf-exams',
      queryParameters: {
        if (slotNumber != null) 'slotNumber': slotNumber,
      },
    );
    return FullTcfExamResponse.fromJson(res.data!);
  }

  /// État courant d'un examen blanc complet (parent + sous-attempts +
  /// agrégation CECRL plancher si toutes les évals IA sont prêtes).
  Future<FullTcfExamResponse> get(String parentAttemptId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/full-tcf-exams/$parentAttemptId',
    );
    return FullTcfExamResponse.fromJson(res.data!);
  }

  /// Démarre le chrono d'une épreuve (CO/CE) au moment où le candidat la
  /// lance, AVANT d'ouvrir le runner. Le backend pose l'ancre globale 90 min
  /// au premier appel et recale le `startedAt` de l'épreuve sur l'instant réel
  /// pour que son chrono propre (CO 20 min / CE 30 min) reparte à neuf — sinon
  /// la CE héritait du temps écoulé sur la CO. Idempotent : une reprise ne
  /// remet pas le compteur à zéro.
  Future<FullTcfExamResponse> beginEpreuve({
    required String parentAttemptId,
    required String epreuveWire,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/full-tcf-exams/$parentAttemptId/begin',
      queryParameters: {'epreuve': epreuveWire},
    );
    return FullTcfExamResponse.fromJson(res.data!);
  }

  /// Marque l'examen comme terminé. Le CECRL plancher est persisté à condition
  /// que toutes les évaluations IA EE/EO soient EVALUATED ; sinon il sera
  /// posé au prochain `get` une fois les évals prêtes.
  Future<FullTcfExamResponse> finish(String parentAttemptId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/full-tcf-exams/$parentAttemptId/finish',
    );
    return FullTcfExamResponse.fromJson(res.data!);
  }

  /// Marque explicitement un sous-attempt EE ou EO comme terminé. Appelé
  /// après la dernière tâche d'une épreuve productive pour débloquer
  /// l'étape suivante sans attendre que l'évaluation IA (fire-and-forget)
  /// se termine côté serveur.
  Future<FullTcfExamResponse> markSubDone({
    required String parentAttemptId,
    required String epreuveWire,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/full-tcf-exams/$parentAttemptId/sub-done',
      queryParameters: {'epreuve': epreuveWire},
    );
    return FullTcfExamResponse.fromJson(res.data!);
  }

  /// Historique des examens blancs complets du user (tri descendant).
  Future<List<FullTcfExamSummary>> listMine({int limit = 20}) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/me/full-tcf-exams',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => FullTcfExamSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
