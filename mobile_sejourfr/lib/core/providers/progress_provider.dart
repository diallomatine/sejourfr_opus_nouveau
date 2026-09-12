import '../../screens/plan/learning_plan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../auth/auth_controller.dart';
import '../models/progress_models.dart';

/// « Ce qui a bougé » — `GET /api/me/progress`, partagé par l'écran **Progrès**
/// et par le bloc « Votre progression » de l'**Accueil**.
///
/// 🛑 **C'est la seule source des compteurs de compétences** (`travaillees` /
/// `maitrisees`, servis pour les deux parcours, et **servis même verrouillés** :
/// c'est le *détail* qui est premium, pas le fait d'avoir progressé). Deux
/// écrans qui compteraient chacun de leur côté auraient fini par afficher deux
/// chiffres pour le même candidat.
/// 🛑 **Gardé en vie pour la session**, comme les deux plans : il ne dépend pas
/// de l'onglet affiché, et l'Accueil le relisait à chaque ouverture. Il se
/// rafraîchit au tiré-pour-rafraîchir de l'Accueil.
///
/// L'échec n'est **pas** mis en cache.
final progressProvider = FutureProvider.autoDispose<Progress>((ref) async {
  // 🛑 **La donnée est liée au COMPTE** : l'observer recrée le cache dès que
  // l'identité change. Sans ça, se reconnecter avec un autre compte sans tuer
  // l'app affichait les données du précédent.
  ref.watch(compteIdProvider);
  // 🛑 **Le signal d'avancement**, partagé : sans lui, cette source gardée en
  // vie resterait figée après un diagnostic ou une production.
  ref.watch(learningPlanRevisionProvider);
  final link = ref.keepAlive();
  try {
    return await ref.read(progressRepositoryProvider).progres();
  } catch (_) {
    link.close();
    rethrow;
  }
});
