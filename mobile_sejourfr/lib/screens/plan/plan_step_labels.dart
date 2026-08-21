import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';

/// **Une compétence ouverte depuis le Plan reste dans son étape.**
///
/// Une étape du Plan, ce sont les 5 premiers sujets actifs d'une compétence
/// (`stepPromptIds`, servis par le serveur). La carte d'étape affiche déjà
/// « 2/5 » ; sans marqueur, ouvrir la compétence retombait sur la fiche
/// générique et son « 1/15 », donc le candidat perdait de vue ce qu'il lui
/// reste à faire pour finir son étape.
///
/// Deux vues d'une même compétence selon la porte d'entrée, c'est **assumé** :
/// par « Réviser → épreuve → Compétences », la fiche complète (les 15 sujets,
/// « x/15 ») ne bouge pas d'un pixel.
///
/// 🛑 **Rien n'est recalculé ici** : ni « les 5 premiers par ordre
/// d'affichage », ni un statut de sujet, ni un compteur. Le serveur sert le
/// périmètre et les compteurs, ce fichier ne fait que les retrouver.
///
/// ⚠️ **Aucun identifiant ne voyage dans la route** : on passe un simple
/// marqueur (`?etape=1`) et on relit le Plan **déjà chargé** par l'écran d'où
/// l'on vient. Aucun appel réseau supplémentaire.

/// Marqueur de route. Sa valeur ne porte aucune information : seule sa présence
/// dit « on arrive du Plan ».
const String kPlanStepParam = 'etape';
const String kPlanStepValue = '1';

/// Vrai quand l'écran a été ouvert depuis le Plan.
bool isPlanStepQuery(Map<String, String> query) =>
    query[kPlanStepParam] == kPlanStepValue;

/// Le **périmètre** d'une étape, quelle que soit sa nature — priorité en cours,
/// priorité à venir ou étape **franchie**. C'est le seul contrat dont l'écran
/// d'étape a besoin : les identifiants de ses sujets et ses compteurs servis.
///
/// ⚠️ Une étape **franchie** n'a **ni exercice recommandé ni cadenas** (le
/// serveur n'en sert aucun), et son [stepCompleted] vaut `false` : le serveur ne
/// publie ce dérivé que sur une priorité, et le recalculer ici serait
/// réimplémenter une règle serveur. L'écran retombe alors sur son comportement
/// historique — c'est le repli voulu, pas un manque.
class PlanStepScope {
  const PlanStepScope({
    required this.skillId,
    required this.stepPromptCount,
    required this.stepAttemptedCount,
    required this.stepValidatedCount,
    required this.stepPromptIds,
    required this.stepCompleted,
    required this.recommendedExercise,
  });

  PlanStepScope.ofPriority(LearningPlanPriority priority)
      : skillId = priority.skillId,
        stepPromptCount = priority.stepPromptCount,
        stepAttemptedCount = priority.stepAttemptedCount,
        stepValidatedCount = priority.stepValidatedCount,
        stepPromptIds = priority.stepPromptIds,
        stepCompleted = priority.stepCompleted,
        recommendedExercise = priority.recommendedExercise;

  PlanStepScope.ofCompleted(LearningPlanCompletedStep step)
      : skillId = step.skillId,
        stepPromptCount = step.stepPromptCount,
        stepAttemptedCount = step.stepAttemptedCount,
        stepValidatedCount = step.stepValidatedCount,
        stepPromptIds = step.stepPromptIds,
        stepCompleted = false,
        recommendedExercise = null;

  final String skillId;
  final int stepPromptCount;
  final int stepAttemptedCount;
  final int stepValidatedCount;
  final List<String> stepPromptIds;
  final bool stepCompleted;
  final PlanRecommendedExercise? recommendedExercise;
}

/// L'étape du Plan qui porte cette compétence — priorité n°1 et **étape
/// franchie** comprises. Une étape franchie garde son périmètre : ouvrir une
/// carte cochée doit mener aux mêmes 5 sujets, pas à la fiche des 15.
///
/// `null` est un cas **normal et fréquent** : le Plan n'est pas chargé, ou la
/// compétence n'apparaît plus dans le parcours (une étape franchie en sort quand
/// la borne serveur est atteinte). L'appelant retombe alors silencieusement sur
/// la fiche complète.
PlanStepScope? planStepFor(LearningPlan? plan, String skillId) {
  if (plan == null || skillId.isEmpty) return null;
  final priorities = <LearningPlanPriority>[
    if (plan.currentPriority != null) plan.currentPriority!,
    ...plan.nextPriorities,
  ];
  for (final priority in priorities) {
    if (priority.skillId == skillId) {
      return priority.stepPromptIds.isEmpty
          ? null
          : PlanStepScope.ofPriority(priority);
    }
  }
  for (final step in plan.completedSteps) {
    if (step.skillId == skillId) {
      return step.stepPromptIds.isEmpty
          ? null
          : PlanStepScope.ofCompleted(step);
    }
  }
  return null;
}

/// **Le sujet que l'écran d'étape propose de faire — désigné par le SERVEUR.**
///
/// 🛑 Aucune règle de choix n'est écrite ici. `RecommendedExerciseSelector`
/// (premier sujet jamais tenté, sinon le `TO_REINFORCE` le plus ancien, sinon
/// le plus anciennement tenté) tourne côté serveur, son périmètre est **déjà
/// borné aux sujets de l'étape**, et son résultat est servi sur la priorité. On
/// ne fait que retrouver le sujet correspondant : un « premier sujet non
/// validé » recodé ici désignerait un autre sujet que le Plan, et les deux
/// écrans se contrediraient.
///
/// `null` est un cas **normal** : pas d'exercice recommandé, exercice qui n'est
/// pas un micro-sujet (une **vérification** se lance depuis le Plan, jamais
/// d'ici), ou sujet absent du périmètre servi. L'appelant garde alors son
/// comportement habituel.
SkillPromptSummary? planStepRecommendedPrompt(
  PlanStepScope? step,
  List<SkillPromptSummary> prompts,
) {
  final exercise = step?.recommendedExercise;
  final promptId = exercise?.skillPromptId;
  if (exercise == null ||
      exercise.kind != PlanExerciseKind.microTraining ||
      promptId == null) {
    return null;
  }
  for (final prompt in prompts) {
    if (prompt.id == promptId) return prompt;
  }
  return null;
}

/* ------------------------------------------------------------------ libellés
 *
 * ⚠️ **Contrat gelé, miroir mot pour mot du web** (`web_sejoufr/lib/plan-step.ts`).
 * Ces chaînes ne transitent pas par le réseau : chaque front en tient sa copie,
 * un libellé qui bouge, ce sont **deux** fichiers à changer dans la même passe.
 *
 * **Tutoiement** : on est dans le module « Compétences », qui tutoie son chrome.
 */

const String kPlanStepPill = 'Étape de ton plan';
const String kPlanStepBackLabel = 'Mon plan';
const String kPlanStepSectionTitle = 'Les sujets de cette étape';
const String kPlanStepLink = 'Voir mon plan';
const String kPlanStepDoneTitle = 'Étape terminée';
const String kPlanStepDoneCta = 'Revenir à mon plan';

/// Les deux libellés du bouton d'action de l'écran d'étape. Commencer un sujet
/// neuf et revenir sur un sujet déjà rendu ne se disent pas pareil : c'est le
/// **statut servi** du sujet désigné qui tranche (`TODO` ou non), jamais une
/// règle de choix recodée côté front.
const String kPlanStepStartCta = 'Commencer le prochain sujet';
const String kPlanStepRetryCta = 'Retravailler ce sujet';

/// « Cette étape, ce sont les 5 premiers sujets de cette compétence. » — le
/// nombre vient du serveur, il n'est jamais écrit en dur (une compétence qui
/// publie moins de sujets a une étape plus courte).
String planStepSectionText(int total) => total > 1
    ? 'Cette étape, ce sont les $total premiers sujets de cette compétence.'
    : 'Cette étape, c\'est le premier sujet de cette compétence.';

/// Ce qu'on dit quand les sujets de l'étape ont tous été traités. On ne promet
/// aucune suite : c'est le Plan qui décide de ce qui vient après.
String planStepDoneText(int total) => total > 1
    ? 'Tu as traité les $total sujets de cette étape. La suite se décide dans '
        'ton plan.'
    : 'Tu as traité le sujet de cette étape. La suite se décide dans ton plan.';

/* ------------------------------------------- étapes franchies (écran « Plan »)
 *
 * ⚠️ **Vouvoiement** : ces chaînes-ci vivent sur le Plan, qui vouvoie — à la
 * différence des libellés ci-dessus, qui appartiennent au module « Compétences ».
 * Miroir mot pour mot de `web_sejoufr/lib/plan-step.ts`.
 */

/// Badge d'état d'une étape **franchie**, dans la même famille que « EN COURS »
/// et « À VENIR » de l'étape courante et des suivantes (les tags de cet écran
/// sont en capitales : c'est l'idiome de `AppTag`, pas un libellé différent).
const String kPlanStepBadgeDone = 'TERMINÉE';

/// Libellé de la coche qui remplace le numéro d'une étape franchie — lu par les
/// lecteurs d'écran, jamais affiché.
const String kPlanStepDoneMarkLabel = 'Étape terminée';

/// Le bouton qui déplie les étapes franchies, sous le parcours.
String planDoneSectionCta(int count, bool open) {
  final s = count > 1 ? 's' : '';
  return open
      ? 'Masquer les étapes franchies'
      : 'Voir les $count étape$s franchie$s';
}
