import 'dart:async';

import '../../core/api/production_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import 'production_result_polling.dart' show kProductionPollInterval;

/// Borne du suivi : au-delà, une correction bloquée côté serveur ne fait plus
/// tirer l'app sur le réseau.
const Duration kExamCorrectionsMaxDuration = Duration(minutes: 3);

/// Sursis entre « toutes les corrections sont finies » et la relecture : le
/// parcours range les priorités de l'examen **après le commit** de la dernière
/// correction (`ApresCommit`), donc quelques dizaines de millisecondes après
/// que la soumission se lit `EVALUATED`. Relire dans cette fenêtre rendrait
/// encore le compte d'avant.
const Duration kParcoursApresCorrections = Duration(seconds: 2);

final Set<String> _examensSuivis = <String>{};

/// **Relire le compte quand les corrections d'un examen EE/EO ont atterri**
/// (bug du 2026-10-05).
///
/// L'étape d'examen du Plan se clôt **à la soumission**, mais les priorités que
/// l'examen dépose dans le cycle suivant n'arrivent qu'avec ses corrections,
/// en arrière-plan, des secondes plus tard. La relecture émise au `finish`
/// rendait donc le Plan d'avant l'analyse (« 5 priorités identifiées »), et
/// rien ne le relisait ensuite : le bilan peut être quitté avant la fin, et son
/// polling meurt avec lui. Ce suivi n'appartient à **aucun écran** : il tourne
/// jusqu'à la dernière correction, puis émet le signal des sources du compte.
///
/// Un seul suivi par examen ; aucun signal si rien n'était en cours au départ
/// (la relecture du `finish` était alors déjà juste).
///
/// Pendant web : `relireApresLesCorrections` (`web_sejoufr/lib/api.ts`).
Future<void> relireApresLesCorrections({
  required ProductionRepository repo,
  required String attemptId,
  required EpreuveType epreuve,
  required void Function() onPlanChanged,
}) async {
  if (!_examensSuivis.add(attemptId)) return;
  try {
    final debut = DateTime.now();
    var correctionEnCours = false;
    while (DateTime.now().difference(debut) < kExamCorrectionsMaxDuration) {
      List<ProductionSubmissionDto>? session;
      try {
        session = (await repo.listMine(epreuve: epreuve))
            .where((s) => s.attemptId == attemptId)
            .toList();
      } catch (_) {
        session = null;
      }
      if (session != null && session.every((s) => s.statut.isFinal)) {
        if (!correctionEnCours) return;
        await Future<void>.delayed(kParcoursApresCorrections);
        try {
          onPlanChanged();
        } catch (_) {
          /* compte quitté entre-temps : plus rien à relire */
        }
        return;
      }
      if (session != null) correctionEnCours = true;
      await Future<void>.delayed(kProductionPollInterval);
    }
  } finally {
    _examensSuivis.remove(attemptId);
  }
}
