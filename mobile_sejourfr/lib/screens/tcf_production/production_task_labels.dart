/// **Les phrases du détail d'une tâche d'expression** (ses sujets
/// d'entraînement) **et de ses exemples corrigés**.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/production-task-labels.ts`.**
/// Un libellé qui bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Vouvoiement** partout : ces écrans tutoyaient côté mobile et
/// vouvoyaient côté web, les deux fronts vouvoient désormais. Le texte des
/// **sujets** (`production_tasks.consigne`) vient de la base et n'est jamais
/// réécrit ici.
///
/// 🛑 **Rien n'est classé ici.** Un sujet « traité » est un sujet qui a au
/// moins une production du candidat (`ProductionCatalog.lastByTaskId`, même
/// règle que le « N/M sujets » servi par `/api/me/dashboard`) ; le palier
/// affiché est celui que l'évaluation sert.
library;

/* ------------------------------------------------ tête d'une tâche */

/// La consigne générale d'une tâche, sous sa contrainte (durée ou fourchette
/// de mots, servie par `production_tasks`). Écrit et oral disent la même
/// chose : seule la façon de produire change.
String productionTaskIntro({required bool isOral, required int tache}) {
  if (isOral) {
    return switch (tache) {
      1 =>
        "Vous vous présentez et vous répondez aux questions de l'examinateur : votre parcours, vos goûts, vos projets.",
      2 =>
        "Vous jouez une situation de la vie courante et vous posez les questions qu'il faut pour obtenir ce que vous voulez.",
      _ =>
        'Vous donnez votre point de vue sur un sujet et vous le défendez avec des arguments et des exemples.',
    };
  }
  return switch (tache) {
    1 =>
      'Vous répondez à un message court — invitation, demande, annonce — en traitant chaque point demandé.',
    2 =>
      "Vous racontez une expérience personnelle au passé, dans l'ordre, avec ce que vous en avez retenu.",
    _ =>
      "Vous donnez votre avis sur une question et vous l'argumentez, en tenant compte de l'avis opposé.",
  };
}

const String kTaskBriefLabel = 'Consigne';

/* ------------------------------------------------ liste des sujets */

const String kSubjectsTitle = "Sujets d'entraînement";

String subjectsHint({required bool isOral}) => isOral
    ? 'Choisissez un sujet, enregistrez votre réponse, recevez votre correction.'
    : 'Choisissez un sujet, rédigez votre réponse, recevez votre correction.';

const String kSubjectFilterAll = 'Tous';
const String kSubjectFilterTodo = 'À faire';
const String kSubjectFilterDone = 'Traités';

/// « Tous · 3 » — le compteur fait partie du libellé de la pastille.
String subjectFilterLabel(String label, int count) => '$label · $count';

/// Lien vers les modèles. Le compteur n'est dit que s'il est connu et non nul.
String examplesLinkLabel(int count) {
  if (count <= 0) return 'Exemples corrigés';
  return count == 1 ? '1 exemple corrigé' : '$count exemples corrigés';
}

const String kSubjectsEmpty =
    'Les sujets de cette tâche ne sont pas encore prêts. Revenez vite !';
const String kSubjectsNoneDone = "Aucun sujet traité pour l'instant.";
const String kSubjectsAllDone = 'Tous les sujets sont traités. Bravo !';

/// Nombre de sujets montrés avant « Voir les N autres ».
const int kSubjectsPageSize = 6;

String showMoreLabel(int remaining) => 'Voir les $remaining autres';

/// Pastille d'un sujet jamais produit.
const String kSubjectTodo = 'À faire';

/* ------------------------------------------- feuille d'un sujet traité */

String lastEvaluationLabel(String etat) => 'Dernière évaluation : $etat';

const String kSubjectDetailCta = 'Voir le détail';
const String kSubjectRedoCta = 'Refaire';

/* ------------------------------------------------ exemples corrigés */

const String kExamplesTitle = 'Exemples corrigés';

String examplesMeta(int tache, String taskTitle) => 'Tâche $tache · $taskTitle';

const String kExamplesSectionTitle = 'Des modèles à imiter';

String examplesHint({required bool isOral}) => isOral
    ? 'Écoutez comment un candidat traite le sujet, puis reprenez la structure dans vos propres réponses.'
    : 'Lisez comment un candidat traite le sujet, puis reprenez la structure dans vos propres réponses.';

String examplesEmpty({required bool isOral}) => isOral
    ? 'Les exemples audio arriveront bientôt pour cette tâche.'
    : 'Les exemples rédigés arriveront bientôt pour cette tâche.';

const String kExampleEyebrow = 'EXEMPLE CORRIGÉ';
const String kExampleOpenCta = 'Voir le corrigé';

String exampleLockedLabel({required bool isOral}) => isOral
    ? 'Écoute incluse dans le pass Intégral'
    : 'Corrigé inclus dans le pass Intégral';

const String kExampleListen = 'Écouter le modèle';
const String kExamplePause = 'Pause';
const String kExampleTextLabel = 'TEXTE DU MODÈLE';
const String kExampleWhyTitle = 'Ce qui fait la différence';
const String kExamplePlanTitle = 'Plan rapide';

const String kMethodTitle = 'Méthode & formules-clés';
const String kMethodText =
    'Le plan en 3 points, à réutiliser sur tous les sujets.';
const String kPreparationLabel = 'POUR RÉUSSIR, PENSEZ À';

const String kExamplesNoticeTitle = 'À quoi servent ces modèles';
const String kExamplesNoticeBody =
    'Ils montrent une façon de faire, pas la seule bonne réponse. Repérez la structure et les formules, puis écrivez ou parlez avec vos propres mots.';
