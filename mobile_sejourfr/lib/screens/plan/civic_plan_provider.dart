import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/civic_plan_models.dart';

/// Le plan **civique** servi par `GET /api/me/civic-plan`, pour les écrans qui
/// n'en lisent qu'un extrait — aujourd'hui l'Accueil, dont l'action du jour
/// civique est la cible de rang 1 **désignée par le serveur**.
///
/// 🛑 **Rien n'est dérivé de ce plan hors du serveur** : l'ordre des cibles,
/// leur maîtrise, leur échéance et leur verrou arrivent servis.
///
/// ⚠️ `CivicPlanView` garde sa propre lecture : elle pilote un écran entier avec
/// ses états de chargement et d'erreur, et elle est montée sous un onglet, pas
/// sous ce provider.
/// 🛑 **Gardé en vie pour la session**, comme le Plan TCF : il était
/// `autoDispose` sans garde, donc chaque ouverture d'écran rappelait
/// `/api/me/civic-plan` pour une réponse identique. Ses points de fraîcheur :
/// le tiré-pour-rafraîchir de l'Accueil et du Plan, le retour d'un flux poussé
/// (`PlanScreen.didPopNext`) et le lancement d'une série ciblée, qui fait
/// bouger la boîte Leitner.
///
/// L'échec n'est **pas** mis en cache.
final civicPlanProvider = FutureProvider.autoDispose<CivicPlan>((ref) async {
  final link = ref.keepAlive();
  try {
    return await ref.read(civicPlanRepositoryProvider).plan();
  } catch (_) {
    link.close();
    rethrow;
  }
});
