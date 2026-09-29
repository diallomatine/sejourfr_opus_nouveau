/**
 * **Les phrases du détail d'une tâche d'expression** (ses sujets
 * d'entraînement) **et de ses exemples corrigés**.
 *
 * 🛑 **Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/tcf_production/production_task_labels.dart`.**
 * Un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 **Vouvoiement** partout : l'écran était tutoyé côté mobile et vouvoyé
 * côté web, les deux fronts vouvoient désormais. Le texte des **sujets**
 * (`production_tasks.consigne`) vient de la base et n'est jamais réécrit ici.
 *
 * 🛑 **Rien n'est classé ici.** Un sujet « traité » est un sujet qui a au moins
 * une production du candidat (`latestSubmissionByTask`, même règle que le
 * « N/M sujets » servi par `/api/me/dashboard`) ; le palier affiché est celui
 * que l'évaluation sert. Ce fichier ne pose que des mots sur ces faits.
 */

/* ------------------------------------------------ tête d'une tâche */

/**
 * La consigne générale d'une tâche, sous sa contrainte (durée ou fourchette de
 * mots, servie par `production_tasks`). Écrit et oral disent la même chose :
 * seule la façon de produire change.
 */
export function productionTaskIntro(isOral: boolean, tache: number): string {
  if (isOral) {
    switch (tache) {
      case 1:
        return "Vous vous présentez et vous répondez aux questions de l'examinateur : votre parcours, vos goûts, vos projets.";
      case 2:
        return "Vous jouez une situation de la vie courante et vous posez les questions qu'il faut pour obtenir ce que vous voulez.";
      default:
        return "Vous donnez votre point de vue sur un sujet et vous le défendez avec des arguments et des exemples.";
    }
  }
  switch (tache) {
    case 1:
      return "Vous répondez à un message court — invitation, demande, annonce — en traitant chaque point demandé.";
    case 2:
      return "Vous racontez une expérience personnelle au passé, dans l'ordre, avec ce que vous en avez retenu.";
    default:
      return "Vous donnez votre avis sur une question et vous l'argumentez, en tenant compte de l'avis opposé.";
  }
}

export const TASK_BRIEF_LABEL = "Consigne";

/* ------------------------------------------------ liste des sujets */

export const SUBJECTS_TITLE = "Sujets d'entraînement";

export function subjectsHint(isOral: boolean): string {
  return isOral
    ? "Choisissez un sujet, enregistrez votre réponse, recevez votre correction."
    : "Choisissez un sujet, rédigez votre réponse, recevez votre correction.";
}

export const SUBJECT_FILTER_ALL = "Tous";
export const SUBJECT_FILTER_TODO = "À faire";
export const SUBJECT_FILTER_DONE = "Traités";

/** « Tous · 3 » — le compteur fait partie du libellé, comme sur la pastille mobile. */
export function subjectFilterLabel(label: string, count: number): string {
  return `${label} · ${count}`;
}

/** Lien vers les modèles. Le compteur n'est dit que s'il est connu et non nul. */
export function examplesLinkLabel(count: number): string {
  if (count <= 0) return "Exemples corrigés";
  return count === 1 ? "1 exemple corrigé" : `${count} exemples corrigés`;
}

export const SUBJECTS_EMPTY =
  "Les sujets de cette tâche ne sont pas encore prêts. Revenez vite !";
export const SUBJECTS_NONE_DONE = "Aucun sujet traité pour l'instant.";
export const SUBJECTS_ALL_DONE = "Tous les sujets sont traités. Bravo !";

/** Nombre de sujets montrés avant « Voir les N autres ». */
export const SUBJECTS_PAGE_SIZE = 6;

export function showMoreLabel(remaining: number): string {
  return `Voir les ${remaining} autres`;
}

/** Pastille d'un sujet jamais produit. */
export const SUBJECT_TODO = "À faire";

/* ------------------------------------------- feuille d'un sujet traité */

export function lastEvaluationLabel(etat: string): string {
  return `Dernière évaluation : ${etat}`;
}

export const SUBJECT_DETAIL_CTA = "Voir le détail";
export const SUBJECT_REDO_CTA = "Refaire";

/* ------------------------------------------------ exemples corrigés */

export const EXAMPLES_TITLE = "Exemples corrigés";

export function examplesMeta(tache: number, taskTitle: string): string {
  return `Tâche ${tache} · ${taskTitle}`;
}

export const EXAMPLES_SECTION_TITLE = "Des modèles à imiter";

export function examplesHint(isOral: boolean): string {
  return isOral
    ? "Écoutez comment un candidat traite le sujet, puis reprenez la structure dans vos propres réponses."
    : "Lisez comment un candidat traite le sujet, puis reprenez la structure dans vos propres réponses.";
}

export function examplesEmpty(isOral: boolean): string {
  return isOral
    ? "Les exemples audio arriveront bientôt pour cette tâche."
    : "Les exemples rédigés arriveront bientôt pour cette tâche.";
}

export const EXAMPLE_EYEBROW = "EXEMPLE CORRIGÉ";
export const EXAMPLE_OPEN_CTA = "Voir le corrigé";

export function exampleLockedLabel(isOral: boolean): string {
  return isOral
    ? "Écoute incluse dans le pass Intégral"
    : "Corrigé inclus dans le pass Intégral";
}

export const EXAMPLE_LISTEN = "Écouter le modèle";
export const EXAMPLE_PAUSE = "Pause";
export const EXAMPLE_TEXT_LABEL = "TEXTE DU MODÈLE";
export const EXAMPLE_WHY_TITLE = "Ce qui fait la différence";
export const EXAMPLE_PLAN_TITLE = "Plan rapide";

export const METHOD_TITLE = "Méthode & formules-clés";
export const METHOD_TEXT = "Le plan en 3 points, à réutiliser sur tous les sujets.";
export const PREPARATION_LABEL = "POUR RÉUSSIR, PENSEZ À";

export const EXAMPLES_NOTICE_TITLE = "À quoi servent ces modèles";
export const EXAMPLES_NOTICE_BODY =
  "Ils montrent une façon de faire, pas la seule bonne réponse. Repérez la structure et les formules, puis écrivez ou parlez avec vos propres mots.";

/**
 * Les trois points « Pour réussir, pensez à » d'une tâche — la fiche de
 * méthode ouverte depuis les exemples.
 *
 * 🛑 Miroir mot pour mot de `productionPreparationPoints`
 * (`mobile_sejourfr/lib/screens/tcf_production/widgets/preparation_points.dart`),
 * qui reste l'autorité côté mobile (le briefing la lit aussi).
 */
export function productionPreparationPoints(
  isOral: boolean,
  tache: number,
): ReadonlyArray<readonly [titre: string, aide: string]> {
  if (isOral) {
    switch (tache) {
      case 1:
        return [
          ["Présentez-vous", "Prénom, origine, ville et situation actuelle."],
          ["Parlez de votre quotidien", "Travail ou études, famille, activités."],
          ["Terminez par votre projet", "Pourquoi vous passez le TCF, vos objectifs."],
        ];
      case 2:
        return [
          ["Posez des questions claires", "Au moins 4 questions sur des aspects différents."],
          ["Réagissez à l'interlocuteur", "« D'accord », « Très bien », « C'est possible quand ? »"],
          ["Terminez l'échange", "Proposez une suite, puis remerciez."],
        ];
      default:
        return [
          ["Annoncez votre position", "« À mon avis… », « Je pense que… »"],
          ["Donnez deux arguments", "« D'abord… ensuite… » avec un exemple pour chacun."],
          ["Concluez en nuançant", "« Cependant… », « Pour finir… »"],
        ];
    }
  }
  switch (tache) {
    case 1:
      return [
        ["Répondez au message reçu", "Acceptez ou refusez, réagissez au déclencheur."],
        ["Donnez les informations utiles", "Jour, heure, lieu, détails demandés."],
        ["Posez une question et concluez", "Avec une formule de fin adaptée à un ami."],
      ];
    case 2:
      return [
        ["Plantez le décor", "Quand, où, avec qui."],
        ["Racontez le déroulement", "Au passé composé / imparfait, avec une anecdote."],
        ["Terminez par un bilan", "Ce que vous en avez retenu."],
      ];
    default:
      return [
        ["Annoncez votre thèse", "« Selon moi… », « Je pense que… »"],
        ["Donnez deux arguments illustrés", "Un exemple concret pour chacun."],
        ["Traitez une objection", "« Certes… toutefois… » puis concluez."],
      ];
  }
}
