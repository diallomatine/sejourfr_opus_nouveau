import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import 'tcf_production_module.dart';
import 'widgets/production_module_bar.dart';

/// Chemins des trois modes du parcours de production. Un seul endroit les
/// construit — les écrans qui portent la barre du module recollaient sinon la
/// même chaîne chacun de leur côté.

String productionSubjectsPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache';

String productionExamplesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/exemples';

String productionCompetencesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/competences';

/// La page des examens blancs est **portée par l'épreuve**, pas par la tâche :
/// on garde le numéro de tâche en query pour savoir vers quelle tâche revenir
/// quand l'utilisateur repart sur « Sujets » ou « Compétences ».
String productionExamsPath(TcfProductionModule module, int tache) {
  final base = module.isEo
      ? '/tcf/expression-orale/examens'
      : '/tcf/expression-ecrite/examens';
  return '$base?tache=$tache';
}

/// Navigation latérale de la barre du module. `pushReplacement` : passer de
/// Sujets à Examens n'empile pas un écran de plus à dépiler ensuite.
void goProductionTab(
  BuildContext context,
  TcfProductionModule module,
  int tache,
  ProductionModuleTab tab, {
  required ProductionModuleTab current,
}) {
  if (tab == current) return;
  final path = switch (tab) {
    ProductionModuleTab.competences =>
      productionCompetencesPath(module, tache),
    ProductionModuleTab.sujets => productionSubjectsPath(module, tache),
    ProductionModuleTab.examens => productionExamsPath(module, tache),
  };
  context.pushReplacement(path);
}

/// « Retour » depuis l'un des **trois modes** du parcours (Compétences, Sujets,
/// Examens).
///
/// Les trois sont des frères — on passe de l'un à l'autre en
/// `pushReplacement` — et il n'existe plus d'écran au-dessus d'eux depuis la
/// suppression du hub d'épreuve. Quitter un mode, c'est donc quitter le
/// parcours : on dépile si on peut (retour à l'écran qui a ouvert le
/// parcours), sinon on rejoint Réviser. Surtout pas un autre mode : « retour »
/// ne doit pas se traduire par un déplacement latéral.
void leaveProductionParcours(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppRoutes.reviser);
}
