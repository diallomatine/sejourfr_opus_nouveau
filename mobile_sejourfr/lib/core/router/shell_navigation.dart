import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// **Les quatre branches du shell** (Navigation v2, 2026-10-03) — dans l'ordre
/// de la barre d'onglets : Accueil · TCF · Civique · Profil.
///
/// Chaque branche a SA pile ([StatefulShellRoute.indexedStack]) : changer
/// d'onglet conserve l'écran ouvert, le segment choisi et le défilement.
enum ShellBranch { accueil, tcf, civique, profil }

/// Le navigateur de chaque branche, déclaré une fois : le router les pose sur
/// ses `StatefulShellBranch`, et [pousserOuAller] les relit pour savoir dans
/// quelle pile vit une adresse.
final Map<ShellBranch, GlobalKey<NavigatorState>> shellBranchKeys = {
  for (final branche in ShellBranch.values)
    branche: GlobalKey<NavigatorState>(debugLabel: 'branche-${branche.name}'),
};

/// **Les trois segments d'un écran de module** — « Plan | Entraînement |
/// Examens », pour le TCF comme pour le civique (D1-A).
///
/// Chaque segment est une sous-route (`/tcf/plan`, `/civique/examens`…) : il
/// survit au changement d'onglet et reste adressable.
enum ModuleSegment {
  plan('plan'),
  entrainement('entrainement'),
  examens('examens');

  const ModuleSegment(this.slug);

  /// Le dernier segment de l'adresse.
  final String slug;

  /// L'adresse du segment dans le module.
  String path({required bool civique}) =>
      '${civique ? '/civique' : '/tcf'}/$slug';
}

/// **Le dernier segment affiché par module** (`true` = civique) — la mémoire
/// du « segment d'origine ». Une Progression atteinte par `go` (depuis
/// l'Accueil, le Profil…) remplace la pile de sa branche : son lien retour et
/// le retour Android y ramènent le candidat. Écrit par l'écran de module.
final dernierSegmentProvider = StateProvider.family<ModuleSegment, bool>(
    (ref, civique) => ModuleSegment.plan);

/// La racine d'un module, sur son dernier segment affiché.
String racineDuModule(WidgetRef ref, {required bool civique}) =>
    ref.read(dernierSegmentProvider(civique)).path(civique: civique);

/// La branche qui porte [location], ou `null` si l'adresse vit sur le
/// navigateur racine (plein écran). Lue sur la **configuration du router**,
/// jamais sur une table recopiée.
ShellBranch? brancheDe(GoRouter router, String location) {
  final match = router.configuration.findMatch(Uri.parse(location));
  if (match.isError || match.matches.isEmpty) return null;
  final premier = match.matches.first;
  if (premier is! ShellRouteMatch) return null;
  for (final entry in shellBranchKeys.entries) {
    if (entry.value == premier.navigatorKey) return entry.key;
  }
  return null;
}

/// **Ouvre [location] sans casser les piles.**
///
/// 🛑 `context.push` d'une adresse **d'une branche** n'est sûr que depuis un
/// écran de **cette même branche**. Depuis un écran plein écran (navigateur
/// racine), go_router empilerait un second shell portant la même clé de page —
/// la collision qui interdisait jusqu'ici de déclarer ces écrans dans le shell.
/// Depuis une autre branche, la page atterrirait sous le mauvais onglet.
///
/// D'où la règle : même branche ⇒ `push` (le retour dépile) ; écran plein
/// écran ⇒ `push` ; sinon ⇒ `go` (l'onglet de la cible devient actif, son
/// lien retour et le retour Android ramènent à l'écran du module).
///
/// Pendant de `retourOuRepli` pour l'aller.
void pousserOuAller(BuildContext context, String location) {
  final router = GoRouter.of(context);
  final match = router.configuration.findMatch(Uri.parse(location));
  // Une ancienne adresse redirigée : sa cible réelle n'est connue qu'après la
  // redirection — `go` est toujours sûr.
  if (!match.isError &&
      match.matches.isNotEmpty &&
      match.last.route.redirect != null) {
    context.go(location);
    return;
  }
  final cible = brancheDe(router, location);
  if (cible == null) {
    context.push(location);
    return;
  }
  final courante = StatefulNavigationShell.maybeOf(context)?.currentIndex;
  if (courante == cible.index) {
    context.push(location);
  } else {
    context.go(location);
  }
}
