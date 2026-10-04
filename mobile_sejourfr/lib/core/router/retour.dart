import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// **Le geste « retour » d'un écran poussé** : on dépile si on peut, sinon on
/// rejoint un écran sûr.
///
/// 🛑 **`context.pop()` seul ne suffit pas.** Sur une pile vide il ne fait
/// **rien** — la flèche reste à l'écran et ne répond pas. Et la pile est vide
/// plus souvent qu'on ne croit : un écran atteint par `context.go` (une
/// redirection du router, un retour de flux qui remplace la page, un lien
/// profond, un démarrage à froid) n'a personne en dessous de lui.
///
/// C'était le défaut de la flèche du diagnostic civique, constaté à l'écran le
/// 2026-09-12 : arrivé là par une navigation qui remplace, le candidat était
/// **enfermé**, sans autre issue que la bottom nav.
///
/// ⚠️ Le repli n'est pas un détail : il doit mener là où le candidat aurait
/// atterri en dépilant. Un écran de diagnostic revient au Plan, un écran de
/// profil au Profil — d'où le paramètre, jamais une valeur unique codée ici.
///
/// C'est le motif de [leaveProductionEpreuve] (`production_nav.dart`), extrait
/// à sa deuxième surface.
void retourOuRepli(BuildContext context, {String repli = AppRoutes.home}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(repli);
}

/// Le paramètre qui porte **l'écran d'où un examen blanc a été lancé**.
/// Miroir web : `RETOUR_PARAM` (`web_sejoufr/lib/retour.ts`).
const String kRetourParam = 'retour';

/// Les écrans d'un examen blanc : runner, résultat, session EE/EO, hub et
/// bilan de l'examen complet. Un `retour` qui en désigne un est refusé — le
/// « Retour » d'un bilan ne doit jamais rouvrir l'examen qu'il vient de clore.
final List<RegExp> _ecransDExamen = [
  RegExp(r'^/runner/'),
  RegExp(r'^/exam-result/'),
  RegExp(r'^/exam-report/'),
  RegExp(r'^/tcf/examen-blanc/'),
  RegExp(
      r'^/tcf/expression-(ecrite|orale)/(t|sessions|resultats|realtime)(/|$)'),
];

/// **L'écran d'où un examen blanc a été lancé**, lu et validé, ou `null`.
///
/// Seul un chemin interne passe (`/…`, jamais `//` ni `/\`), et jamais un
/// écran d'examen. `null` (lien profond, ancien lien, valeur trafiquée) ⇒
/// l'écran garde sa destination historique. Miroir web : `retourExamenDe`.
String? retourExamenDe(Map<String, String> query) {
  final brut = query[kRetourParam];
  if (brut == null || brut.isEmpty) return null;
  if (!brut.startsWith('/') ||
      brut.startsWith('//') ||
      brut.startsWith(r'/\')) {
    return null;
  }
  final chemin = brut.split(RegExp(r'[?#]')).first;
  if (_ecransDExamen.any((motif) => motif.hasMatch(chemin))) return null;
  return brut;
}

/// Pose `retour` sur une adresse ; `null` ⇒ l'adresse telle quelle.
String avecRetour(String location, String? retour) {
  if (retour == null || retour.isEmpty) return location;
  final sep = location.contains('?') ? '&' : '?';
  return '$location$sep$kRetourParam=${Uri.encodeComponent(retour)}';
}

/// L'adresse de l'écran affiché (la page go_router du dessus — une feuille
/// ouverte par-dessus n'en est pas une), pour la reposer en `retour`.
String adresseCourante(BuildContext context) =>
    GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

/// Le hub d'un examen complet, avec l'écran de lancement que porte la route
/// courante — c'est ainsi qu'il suit le candidat d'une épreuve à l'autre.
String fullExamHubLocation(BuildContext context, String fullExamId) =>
    AppRoutes.tcfFullExamProgressPath(
      fullExamId,
      retour: retourExamenDe(GoRouterState.of(context).uri.queryParameters),
    );
