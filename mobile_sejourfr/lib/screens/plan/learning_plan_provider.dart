import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/diagnostic_models.dart';

/// **Le signal « l'avancement du candidat a changé »** : une production
/// évaluée, un micro-exercice, une mutation d'un diagnostic (TCF ou civique),
/// une série ciblée.
///
/// 🛑 **Il ne concerne PAS que le Plan**, malgré son nom — hérité de l'époque
/// où il était son seul lecteur. Depuis que les sources de l'Accueil et du Plan
/// sont **gardées en vie** (2026-09-12), c'est lui qui les rafraîchit toutes :
/// `learningPlanProvider`, `civicPlanProvider`, `preparationProvider`,
/// `progressProvider` et `diagnosticCourantProvider`. Une source de compte qui
/// ne l'écouterait pas resterait figée jusqu'au prochain redémarrage.
///
/// ⚠️ C'est exactement ce qui s'est produit : au retour du diagnostic rapide,
/// le Plan réclamait encore « Faire mon diagnostic », parce que sa **porte**
/// vient de `preparationProvider` — qui, lui, n'écoutait rien.
///
/// ⚠️ **Incrémenter déclenche un appel**, même sans écran monté. C'est le prix,
/// et il est bas : un appel par changement réel, au lieu d'un par ouverture
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
  // 🛑 **La donnée est liée au COMPTE** : l'observer recrée le cache dès que
  // l'identité change. Sans ça, se reconnecter avec un autre compte sans tuer
  // l'app affichait les données du précédent.
  ref.watch(compteIdProvider);
  ref.watch(learningPlanRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.watch(learningPlanRepositoryProvider).get();
  } catch (_) {
    link.close();
    rethrow;
  }
});
