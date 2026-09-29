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
