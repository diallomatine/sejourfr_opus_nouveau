import 'package:flutter/widgets.dart';

import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import 'tcf_production_module.dart';

/// Chemins du parcours de production, construits en **un seul endroit**.
///
/// Le parcours a deux niveaux depuis la refonte 2026-08-21 : l'épreuve et ses
/// trois tâches (`AppRoutes.tcf{Ee,Eo}Entry`, littéral — il n'a pas de
/// paramètre), puis **une** tâche et ses deux onglets ([productionTaskPath]).
/// Les examens blancs sont un écran à part ([productionExamsPath]), atteint
/// par la barre fixe du niveau 1 — leur chemin n'a pas changé.

/// Niveau 2 : une tâche, ouverte sur son onglet « Compétences ».
String productionTaskPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache';

/// Niveau 2, forme explicite de l'onglet « Compétences ». Conservée parce que
/// le Plan y renvoie (`plan_task_row`, `recommended_exercise_launcher`) : elle
/// dit ce qu'elle ouvre, là où [productionTaskPath] dépend d'un défaut.
String productionCompetencesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/competences';

/// Les 10 examens blancs de l'épreuve. Porté par l'épreuve, jamais par une
/// tâche — un examen, c'est les 3 tâches enchaînées.
String productionExamsPath(TcfProductionModule module) =>
    '/tcf/${module.isEo ? 'expression-orale' : 'expression-ecrite'}/examens';

String productionExamplesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/exemples';

/// Écran de production de la tâche **déjà chargée en session** (`t/0`).
///
/// ⚠️ Le sujet ne voyage **jamais** dans l'URL : l'écran lit la session Riverpod
/// (`startSingle` / `startExam`), qui doit donc avoir été démarrée avant le
/// push. C'est ce qui distingue cette adresse d'un lien profond.
String productionSessionPath(TcfProductionModule module) =>
    '/tcf/${module.isEo ? 'expression-orale' : 'expression-ecrite'}/t/0';

/// « Retour » depuis le **niveau 1** d'une épreuve, qui n'a aucun écran de
/// production au-dessus de lui : on dépile si on peut (retour à l'écran qui a
/// ouvert l'épreuve), sinon on rejoint Réviser.
void leaveProductionEpreuve(BuildContext context) =>
    retourOuRepli(context, repli: AppRoutes.reviser);
