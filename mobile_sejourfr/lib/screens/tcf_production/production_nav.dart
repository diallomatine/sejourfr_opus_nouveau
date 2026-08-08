import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import 'tcf_production_module.dart';

/// Chemins du parcours de production, construits en **un seul endroit**.
///
/// Depuis que les trois modes vivent dans un même écran, une bascule ne navigue
/// plus : il ne reste ici que les chemins réellement empruntés — l'entrée du
/// parcours (mode Compétences, dont `AppRoutes.tcf{Ee,Eo}Entry` est la forme
/// littérale) et les modèles corrigés, qui sont un écran à part.

String productionCompetencesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/competences';

String productionExamplesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/exemples';

/// « Retour » depuis l'un des **trois modes** du parcours (Compétences, Sujets,
/// Examens).
///
/// Les trois sont des frères rendus par un même écran, et il n'existe plus
/// d'écran au-dessus d'eux depuis la suppression du hub d'épreuve. Quitter un
/// mode, c'est donc quitter le parcours : on dépile si on peut (retour à
/// l'écran qui a ouvert le parcours), sinon on rejoint Réviser. Surtout pas un
/// autre mode : « retour » ne doit pas se traduire par un déplacement latéral.
void leaveProductionParcours(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppRoutes.reviser);
}
