import '../../screens/plan/learning_plan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../auth/auth_controller.dart';
import '../models/progress_models.dart';

/// « Où vous en êtes » — `GET /api/me/progress`, lu par l'**Accueil** (les
/// 4 épreuves et les thèmes civiques). ⚠️ L'ancien écran Progrès, son autre
/// lecteur, est supprimé (2026-09-24) : les écrans de progression lisent
/// `/api/me/progression/*` (`screens/progression/progression_providers.dart`).
///
/// 🛑 **Gardé en vie pour la session**, comme les deux plans : il ne dépend pas
/// de l'onglet affiché, et l'Accueil le relisait à chaque ouverture. Il se
/// rafraîchit au tiré-pour-rafraîchir de l'Accueil.
///
/// L'échec n'est **pas** mis en cache.
final progressProvider = FutureProvider.autoDispose<Progress>((ref) async {
  // 🛑 **La donnée est liée au COMPTE ET À SON ACCÈS** : l'observer recrée le
  // cache dès que l'un des deux change. Sans l'identité, se reconnecter avec un
  // autre compte sans tuer l'app affichait les données du précédent ; sans
  // l'accès, un achat laissait cette lecture sur les `locked` d'avant.
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  // 🛑 **Le signal d'avancement**, partagé : sans lui, cette source gardée en
  // vie resterait figée après un diagnostic ou une production.
  ref.watch(learningPlanRevisionProvider);
  // 🛑 **Le signal « l'accès a changé »** : ce que cette lecture porte dépend du
  // pass du candidat (`locked` servi, quota, détail verrouillé). Sans lui, un
  // achat laissait cette source sur les verrous d'avant.
  ref.watch(accesRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.read(progressRepositoryProvider).progres();
  } catch (_) {
    link.close();
    rethrow;
  }
});
