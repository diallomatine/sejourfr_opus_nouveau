import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';
import '../plan/learning_plan_provider.dart';

/// Provider centralisé du détail d'un examen blanc TCF complet.
///
/// Extrait du fichier d'écran pour pouvoir être invalidé depuis les autres
/// surfaces (runner CO/CE, bilan EE/EO) avant de revenir au hub de
/// progression. Sans cette invalidation, `context.go` réutilise le widget
/// existant et l'état du provider reste périmé — les épreuves récemment
/// terminées n'apparaîtraient pas comme Done.
final fullTcfExamProvider =
    FutureProvider.autoDispose.family<FullTcfExamResponse, String>(
        (ref, parentId) async {
  return ref.watch(fullTcfExamRepositoryProvider).get(parentId);
});

/// **Clôt une épreuve de production (EE/EO) d'un examen complet** — le point
/// UNIQUE des six gestes qui le font (dernière tâche, chrono écoulé, sortie
/// confirmée, en EE comme en EO). Pendant web : `fullTcfExamApi.markSubDone`,
/// qui purge par `afterMeasureWrite`.
///
/// 🛑 **Clore une épreuve est une MESURE écrite** : son niveau se fige sur ce
/// qui a été rendu, donc le Plan, le parcours et l'Accueil sont à relire. Le
/// signal suit la réponse, jamais la soumission d'avant : la relecture qu'elle
/// déclenchait partait avant la clôture. Best-effort : un échec est avalé
/// (le hook backend finira par poser `finishedAt`), la sortie n'est jamais
/// bloquée.
///
/// ⚠️ Le notifier est lu AVANT l'attente : l'écran appelant peut être démonté
/// pendant l'appel, et un `WidgetRef` démonté ne se lit plus.
Future<void> cloreEpreuveDuComplet(
  WidgetRef ref, {
  required String fullExamId,
  required EpreuveType epreuve,
}) async {
  final repo = ref.read(fullTcfExamRepositoryProvider);
  final revision = ref.read(learningPlanRevisionProvider.notifier);
  try {
    await repo.markSubDone(
      parentAttemptId: fullExamId,
      epreuveWire: epreuve.wire,
    );
    revision.state++;
  } catch (_) {
    /* hook auto backend fallback */
  }
}
