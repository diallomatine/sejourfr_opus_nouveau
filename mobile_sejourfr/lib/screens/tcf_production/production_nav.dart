import 'package:flutter/widgets.dart';

import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../plan/plan_step_labels.dart' show kPlanStepParam, kPlanStepValue;
import 'tcf_production_module.dart';

/// Chemins du parcours de production, construits en **un seul endroit**.
///
/// Le parcours a deux niveaux depuis la refonte 2026-08-21 : l'épreuve et ses
/// trois tâches (`AppRoutes.tcf{Ee,Eo}Entry`, littéral — il n'a pas de
/// paramètre), puis **une** tâche et ses sujets complets ([productionTaskPath]).
/// Les examens blancs sont un écran à part ([productionExamsPath]), atteint
/// par la barre fixe du niveau 1 — leur chemin n'a pas changé.

/// Niveau 2 : une tâche et ses **sujets complets**.
///
/// [planStep] ajoute le marqueur `?etape=1` : la liste est ouverte **depuis le
/// Plan** (repli d'une vérification sans sujet), et l'offre ouverte sur un 403
/// y part en `LOCKED_PLAN` (contrôle F). Sans lui, comportement inchangé.
String productionTaskPath(
  TcfProductionModule module,
  int tache, {
  bool planStep = false,
}) {
  final path = '/tcf/${module.routeKey}/tache/$tache';
  return planStep ? '$path?$kPlanStepParam=$kPlanStepValue' : path;
}

/// Les **8 compétences** d'une tâche. 🛑 **Depuis le Plan, et de là seulement**
/// (2026-09-20) : l'écran d'une tâche n'a plus d'onglet « Compétences ».
String productionCompetencesPath(TcfProductionModule module, int tache) =>
    '/tcf/${module.routeKey}/tache/$tache/competences';

/// Les 10 examens blancs de l'épreuve. Porté par l'épreuve, jamais par une
/// tâche — un examen, c'est les 3 tâches enchaînées.
String productionExamsPath(TcfProductionModule module) =>
    '/tcf/${module.isEo ? 'expression-orale' : 'expression-ecrite'}/examens';

/// Le **bilan d'une session** (examen ou entraînement à 3 tâches) — la page
/// que « Voir → » d'un écran de progression ouvre sur un `rapport.kind`
/// `PRODUCTION` servi.
String productionSessionReportPath(
        TcfProductionModule module, String attemptId) =>
    '/tcf/${module.isEo ? 'expression-orale' : 'expression-ecrite'}/sessions/$attemptId';

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
