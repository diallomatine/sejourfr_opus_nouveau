import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/diagnostic_models.dart';
import '../plan/learning_plan_provider.dart';

/// **Le diagnostic courant, en LECTURE seule**, pour les écrans qui ne font que
/// l'afficher — aujourd'hui l'Accueil, dont « À faire maintenant » a besoin de
/// savoir s'il est à faire, en cours ou terminé.
///
/// 🛑 **Il ne remplace pas `diagnosticControllerProvider`**, et il ne faut pas
/// l'y fondre : le contrôleur porte le **parcours** (brouillons, soumissions,
/// polling, marqueur « déjà démarré ») et son `autoDispose` est un invariant
/// écrit — « tout chemin d'abandon emporte le marqueur ». Le garder en vie pour
/// éviter un appel aurait cassé une garantie bien plus chère que cet appel.
///
/// 🛑 **Gardé en vie pour la session** : l'Accueil instanciait le contrôleur
/// juste pour lire un statut, et le contrôleur appelle
/// `GET /api/diagnostics/current` à sa création — donc un appel à **chaque**
/// ouverture de l'onglet Accueil, pour une réponse identique.
///
/// **Son point de fraîcheur** : [learningPlanRevisionProvider], que le
/// contrôleur incrémente à **chaque** mutation du parcours (démarrage,
/// soumission, analyse, relance, fin de polling). Les deux lectures ne peuvent
/// donc pas diverger.
///
/// `null` pour un visiteur : la route publique du diagnostic sert les sujets,
/// pas un parcours, et l'Accueil n'est pas atteignable sans compte.
final diagnosticCourantProvider =
    FutureProvider.autoDispose<DiagnosticJourney?>((ref) async {
  final authentifie = ref.watch(
    authControllerProvider.select((state) => state is AuthAuthenticated),
  );
  if (!authentifie) return null;
  ref.watch(learningPlanRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.read(diagnosticRepositoryProvider).current();
  } catch (_) {
    // L'échec n'est pas mis en cache : la carte disparaît, le rafraîchissement
    // suivant repart sur un appel neuf.
    link.close();
    rethrow;
  }
});
