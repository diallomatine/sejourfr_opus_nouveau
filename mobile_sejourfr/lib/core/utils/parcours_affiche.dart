import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// **Le parcours affiché** — TCF ou Examen civique — partagé par l'Accueil et
/// le Plan.
///
/// 🛑 **Une seule mécanique, pas deux.** C'est la règle que le web tient avec
/// son `?module=` : « deux mécaniques auraient fini par afficher deux parcours
/// différents sur deux écrans du même compte ». L'app n'a pas d'URL, donc elle
/// a ce provider — et aucun écran ne garde de `setState` de module à côté.
///
/// 🛑 **`null` = pas encore décidé**, et c'est un état normal : le défaut est
/// **servi** (`moduleCiviqueParDefaut(prep)`), il n'est pas écrit ici. Un écran
/// qui le pose le fait avec `??=`, pour ne jamais écraser un choix déjà fait
/// par le candidat sur l'autre écran.
///
/// ⚠️ Volontairement **distinct de `selectedModuleProvider`**, qui mémorise le
/// dernier module *touché* (il alimente l'écran Réviser → erreurs/favoris) et
/// qu'un lancement d'entraînement écrit au passage. Celui-ci ne décrit qu'un
/// affichage.
final parcoursCiviqueProvider = StateProvider<bool?>((ref) {
  // 🛑 Le parcours choisi appartient au compte : changer de compte le remet à
  // « pas encore décidé », et le défaut **servi** du nouveau compte s'applique.
  ref.watch(compteIdProvider);
  return null;
});
