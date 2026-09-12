import '../../screens/plan/learning_plan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../auth/auth_controller.dart';
import '../models/preparation_models.dart';

/// **L'état UNIQUE des deux préparations**, lu une seule fois par écran.
///
/// 🛑 **Trois portes, un seul état** (arbitrage du 2026-09-10). Sur l'Accueil,
/// deux blocs le lisent — « Ma préparation » et « Continuez votre diagnostic
/// complet ». Deux appels séparés auraient pu répondre deux états différents
/// dans la même seconde, donc proposer deux prochaines actions : ce provider
/// garantit qu'ils lisent la **même** réponse.
///
/// ⚠️ L'écran Plan garde sa propre lecture (`PlanScreen._chargerPreparation`) :
/// elle décide de l'onglet ouvert **avant** le premier rendu et ne peut pas
/// s'exprimer en `AsyncValue` sans faire clignoter la bascule de parcours.
/// 🛑 **Gardé en vie pour la session** (2026-09-12) : trois écrans le lisent
/// (Accueil, Plan, Examens) et il ne dépend d'aucun onglet — chaque ouverture
/// rappelait `/api/me/preparation` pour la même réponse. Il se rafraîchit au
/// tiré-pour-rafraîchir et au retour d'un diagnostic joué au-dessus.
///
/// L'échec n'est **pas** mis en cache : la porte d'un diagnostic inachevé doit
/// pouvoir réapparaître au rafraîchissement suivant.
final preparationProvider = FutureProvider.autoDispose<PreparationDto>((ref) async {
  // 🛑 **La donnée est liée au COMPTE** : l'observer recrée le cache dès que
  // l'identité change. Sans ça, se reconnecter avec un autre compte sans tuer
  // l'app affichait les données du précédent.
  ref.watch(compteIdProvider);
  // 🛑 **Le signal d'avancement**, partagé : sans lui, cette source gardée en
  // vie resterait figée après un diagnostic ou une production.
  ref.watch(learningPlanRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.watch(userContentRepositoryProvider).preparation();
  } catch (_) {
    link.close();
    rethrow;
  }
});
