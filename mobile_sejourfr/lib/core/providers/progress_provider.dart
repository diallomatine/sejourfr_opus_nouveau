import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
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
  final link = ref.keepAlive();
  try {
    return await ref.read(progressRepositoryProvider).progres();
  } catch (_) {
    link.close();
    rethrow;
  }
});
