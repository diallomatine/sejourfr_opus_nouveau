import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';

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

/// **Émettre le signal depuis un écran** : une mesure vient d'être écrite côté
/// serveur — examen blanc QCM terminé, section de diagnostic close, diagnostic
/// clos, épreuve d'un examen complet fermée.
///
/// 🛑 **Une émission par MESURE, jamais une par requête.** Le signal recharge
/// cinq sources gardées en vie ; l'émettre deux fois pour un même geste les
/// rechargerait deux fois pour rien. Les parcours de production émettent déjà
/// par leur contrôleur (`onPlanChanged` sur `ee/eoSessionProvider`,
/// `skillSubmissionProvider`, `diagnosticControllerProvider`) : ne pas
/// ré-émettre sur la clôture qui suit immédiatement une soumission.
///
/// C'est le pendant mobile d'`invalidateDiagnosticAndPlan()`
/// (`web_sejoufr/lib/api.ts`) — à ceci près que le web **purge** un cache là où
/// le mobile **relance** les lectures vivantes, d'où la règle ci-dessus.
void signalerMesureEcrite(WidgetRef ref) {
  ref.read(learningPlanRevisionProvider.notifier).state++;
}

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
/// qui peut le changer), [accesRevisionProvider] (un pass acheté ou restauré —
/// le Plan porte des `locked` servis), [compteObjectifProvider] (une démarche
/// changée depuis le Profil ou le Plan), le tiré-pour-rafraîchir de l'Accueil et
/// du Plan, et le retour d'un flux poussé au-dessus du Plan (`didPopNext`).
///
/// L'échec n'est **pas** mis en cache : un « Réessayer » repart sur un appel
/// neuf.
final learningPlanProvider = FutureProvider.autoDispose<LearningPlan>((ref) async {
  // 🛑 **La donnée est liée au COMPTE ET À SON ACCÈS** : l'observer recrée le
  // cache dès que l'un des deux change. Sans l'identité, se reconnecter avec un
  // autre compte sans tuer l'app affichait les données du précédent ; sans
  // l'accès, un achat laissait cette lecture sur les `locked` d'avant.
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.watch(learningPlanRepositoryProvider).get();
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// **Le parcours TCF**, gardé en vie aux mêmes conditions que le Plan.
///
/// 🛑 **Mêmes points de fraîcheur, exactement** : sans ça, une évaluation
/// rechargerait le Plan et laisserait le parcours sur son état d'avant — deux
/// lectures du même candidat, au même instant, qui se contrediraient à l'écran.
/// C'est précisément la contradiction que le 2026-09-16 a corrigée sur la carte
/// « À faire maintenant ».
///
/// L'échec n'est **pas** mis en cache.
final journeyProvider = FutureProvider.autoDispose<Journey>((ref) async {
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.watch(learningPlanRepositoryProvider).journey();
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// **Le cycle CIVIQUE**, gardé en vie aux mêmes conditions que le parcours TCF.
///
/// 🛑 **Un provider PAR MODULE, jamais un `family` sur le module** : les deux
/// cycles sont deux réponses différentes, et les servir sous la même clé aurait
/// montré le cycle TCF sur l'onglet civique — au premier changement d'onglet.
/// C'est le pendant Dart des clés de cache par module du web
/// (`journeyApi.cacheKeyFor`).
///
/// 🛑 **Mêmes points de fraîcheur que le plan civique** : une série sur unité,
/// un examen de thème ou une fin de cycle bougent les deux, et deux lectures du
/// même candidat qui se contrediraient à l'écran est exactement le défaut que
/// le 2026-09-16 a corrigé côté TCF.
final journeyCiviqueProvider = FutureProvider.autoDispose<Journey>((ref) async {
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref
        .watch(learningPlanRepositoryProvider)
        .journey(module: AppModule.civique);
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// **L'historique des cycles**, derriere « Voir ma progression ».
///
/// 🛑 **`autoDispose` et NON garde en vie** : c'est une archive qu'on ouvre,
/// pas une source d'ecran d'accueil. La garder retiendrait une liste d'avant
/// le cycle qu'« Actualiser mon plan » vient de fermer.
///
/// Il ecoute quand meme [learningPlanRevisionProvider] : historiser un cycle
/// passe par ce signal, et l'ecran peut etre ouvert au moment ou il tombe.
///
/// 🛑 **Un `family` sur le module, ici, et PAS deux providers** (P8.9) — la
/// raison d'A88 ne s'applique pas : le cycle est `keepAlive` et **observe en
/// permanence par deux ecrans**, donc une cle partagee y aurait fait voir le
/// cycle TCF sur l'onglet civique. L'archive, elle, est `autoDispose` et
/// s'ouvre **une a la fois** ; Riverpod cle par l'argument, et il n'y a rien a
/// garder en vie entre deux ouvertures.
final journeyHistoryProvider =
    FutureProvider.autoDispose.family<JourneyHistory, AppModule>(
        (ref, module) async {
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
  return ref.watch(learningPlanRepositoryProvider).history(module: module);
});

/// **Le détail d'une étape de séries**, derrière une ligne du cycle.
///
/// 🛑 **`autoDispose` et NON gardé en vie** : c'est un écran qu'on ouvre, pas
/// une source d'accueil. Le garder retiendrait des séries d'avant la passation
/// qu'on vient de faire.
///
/// Il écoute [learningPlanRevisionProvider] : une série terminée passe par ce
/// signal, et l'écran est encore monté sous le runner quand il tombe — c'est ce
/// qui repeint les cartes au retour, sans tiré-pour-rafraîchir.
final journeyStepProvider =
    FutureProvider.autoDispose.family<JourneyStepDetail, String>(
        (ref, stepId) async {
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
  return ref.watch(learningPlanRepositoryProvider).stepDetail(stepId);
});

/// **Le parcours affiché, pour l'origine d'un achat parti du Plan** (Q12, D32) :
/// avec `LOCKED_PLAN`, c'est ce qui rattache l'achat au tunnel. Lu dans le
/// cache — jamais un appel de plus ; `null` s'il n'est pas chargé.
String? planJourneyId(WidgetRef ref, {bool civique = false}) => ref
    .read(civique ? journeyCiviqueProvider : journeyProvider)
    .valueOrNull
    ?.journeyId;
