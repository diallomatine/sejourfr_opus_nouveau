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

  /// Démarre un nouvel examen blanc complet. Accessible aux comptes gratuits
  /// (slot 1 offert, EE/EO évaluées une seule fois à vie) et illimité pour
  /// les abonnés TCF — le backend n'exige plus `hasTcf` ici, le verrou porte
  /// sur le slot (le mobile affiche le paywall avant l'appel pour slot > 1
  /// non-premium, cf. `TcfFullExamsView.startNew`). [slotNumber] permet à la
  /// grille « 20 examens TCF complets » de stabiliser la numérotation
  /// (refaire le slot N met à jour le slot N au lieu de glisser les essais
  /// d'un cran). Cf. V110.
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
  ///
  /// ⚠️ Cet appel **clôture automatiquement** une épreuve dont l'échéance est
  /// passée, avec ce qui avait été enregistré : un retour dans l'app peut donc
  /// rendre une épreuve déjà `finishedAt` — c'est normal, pas une erreur.
  Future<FullTcfExamResponse> get(String parentAttemptId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/full-tcf-exams/$parentAttemptId',
    );
    return FullTcfExamResponse.fromJson(res.data!);
  }

  /// Démarre le chrono d'une épreuve **au moment où le candidat la lance**,
  /// AVANT d'ouvrir l'écran de l'épreuve. À appeler pour les **4** épreuves :
  /// tant qu'il n'est pas appelé, l'épreuve n'a **pas d'échéance** (les 4
  /// sous-attempts sont créés d'un bloc au démarrage de l'examen, leur
  /// `startedAt` ne dit rien du moment où le candidat les ouvre). Le backend
  /// pose `timerStartedAt` et recale `startedAt` sur l'instant réel, puis expose
  /// `deadlineAt` — la seule source du compte à rebours.
  ///
  /// Il n'y a **plus d'enveloppe globale de 90 min** : chaque épreuve porte sa
  /// durée (CO 20 min, CE 35 min **partout**, EE 30 min ; l'EO se chronomètre
  /// par tâche) et rien ne se transfère de l'une à l'autre.
  ///
  /// Idempotent : une reprise ne remet pas le compteur à zéro — **et le temps a
  /// continué de courir pendant l'absence**. Il n'existe volontairement aucun
  /// flux « recommencer une épreuve interrompue ».
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
