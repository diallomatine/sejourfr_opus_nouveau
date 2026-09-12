import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';

/// Signal émis par les activités susceptibles de modifier le Plan : une
/// production évaluée, un micro-exercice, une mutation du diagnostic.
///
/// ⚠️ **Depuis que le Plan est gardé en vie** (2026-09-12), incrémenter ce
/// signal **déclenche bien un appel**, même si aucun écran n'est monté — la
/// remarque inverse qui vivait ici n'est plus vraie. C'est le prix, et il est
/// bas : un appel par changement réel, au lieu d'un appel par ouverture
/// d'écran.
final learningPlanRevisionProvider = StateProvider<int>((ref) => 0);

/// Le Plan TCF, **gardé en vie pour la session**.
///
/// 🛑 Il était `autoDispose` sans garde : quitter l'onglet Plan ou l'Accueil le
/// jetait, et y revenir rappelait `/api/me/plan` — pour une réponse identique.
/// Le remède est celui que le dépôt emploie déjà pour le catalogue d'une
/// épreuve (`production_catalog.dart`) : `ref.keepAlive()`, **plus des points
/// d'invalidation explicites** — on ne cache jamais ce qui mesure la
/// progression sans dire où ça se rafraîchit.
///
/// **Ses points de fraîcheur** : [learningPlanRevisionProvider] (toute activité
/// qui peut le changer), le tiré-pour-rafraîchir de l'Accueil et du Plan, et le
/// retour d'un flux poussé au-dessus du Plan (`didPopNext`).
///
/// L'échec n'est **pas** mis en cache : un « Réessayer » repart sur un appel
/// neuf.
final learningPlanProvider = FutureProvider.autoDispose<LearningPlan>((ref) async {
  ref.watch(learningPlanRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.watch(learningPlanRepositoryProvider).get();
  } catch (_) {
    link.close();
    rethrow;
  }
});
