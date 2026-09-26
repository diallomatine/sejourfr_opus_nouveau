import {withPlanStep} from "./plan-step.ts";
import {productionTaskHref} from "./production-catalog.ts";
import type {
  DiagnosticCommunicationStatus,
  DiagnosticExerciseDto,
  DiagnosticFormatDto,
  DiagnosticResponse,
  DiagnosticTaskCompletion,
  LearningPlanSkillStatus,
  LearningPlanSourceType,
  NiveauCecrl,
  PlanMilestoneExerciseDto,
  PlanSkillExerciseDto,
  ProductionTaskDto,
  SkillSection,
} from "./types";
import {SKILL_SECTION_LABEL} from "./types.ts";

export type DiagnosticDashboardState = "NOT_STARTED" | "IN_PROGRESS" | "COMPLETED";

/** Le diagnostic est un agrégat piloté par un pipeline asynchrone : même sans
 *  écriture dans cet onglet, NOT_STARTED peut devenir IN_PROGRESS et ANALYZING
 *  peut devenir terminal. On mutualise donc seulement une requête déjà en vol ;
 *  aucun snapshot résolu ne doit survivre au prochain lecteur. */
export function requiresDiagnosticRevalidation(
  diagnostic: Pick<DiagnosticResponse, "status">,
): boolean {
  switch (diagnostic.status) {
    case "NOT_STARTED":
    case "IN_PROGRESS":
    case "ANALYZING":
    case "COMPLETED":
    case "FAILED":
      return true;
  }
}

export function diagnosticDashboardState(
  diagnostic: DiagnosticResponse | null | undefined,
): DiagnosticDashboardState {
  if (!diagnostic || diagnostic.status === "NOT_STARTED") return "NOT_STARTED";
  if (diagnostic.status === "COMPLETED") return "COMPLETED";
  return "IN_PROGRESS";
}

export function diagnosticCompletedExerciseCount(
  diagnostic: DiagnosticResponse | null | undefined,
): number {
  if (!diagnostic) return 0;
  return [diagnostic.written, diagnostic.oral].filter(
    (exercise) => exercise?.submissionId != null,
  ).length;
}

/**
 * Sujet de diagnostic, dans la seule forme qui sert à **produire** : ce que
 * la version publique (visiteur) et la version de session (connecté) ont en
 * commun. Les identifiants de session (`attemptId`, `submissionId`) n'existent
 * qu'après le compte et ne servent qu'à soumettre, jamais à afficher.
 */
export type DiagnosticExerciseContent = Omit<
  DiagnosticExerciseDto,
  "attemptId" | "submissionId" | "submissionStatus"
>;

/**
 * Ce que l'écran de présentation a besoin de savoir d'un sujet pour annoncer
 * son coût en temps. Volontairement réduit aux quatre mesures : la présentation
 * ne montre ni consigne ni titre — elle annonce un effort, pas un exercice.
 */
export type DiagnosticExerciseMeasure = Pick<
  DiagnosticExerciseContent,
  "wordsMin" | "wordsMax" | "durationMinSeconds" | "durationMaxSeconds"
>;

/**
 * Vitesse de rédaction retenue pour convertir une fourchette de mots en
 * minutes sur l'écran de présentation, et **seulement là**. C'est un ordre de
 * grandeur assumé (toujours précédé de « environ »), pas un engagement : rien
 * dans le parcours ne chronomètre le candidat sur cette valeur.
 *
 * ⚠️ À ne pas confondre avec les 12 mots/minute de `ExerciseDuration` côté
 * serveur, qui estime le temps d'un **exercice du Plan** rédaction comprise.
 */
export const DIAGNOSTIC_WRITING_WORDS_PER_MINUTE = 40;

function midpoint(min: number | null, max: number | null): number | null {
  if (min != null && max != null) return (min + max) / 2;
  return min ?? max;
}

/** Minutes annoncées pour l'écrit, dérivées de la fourchette de mots servie. */
export function diagnosticWrittenMinutes(
  exercise: DiagnosticExerciseMeasure | null | undefined,
): number | null {
  const words = midpoint(exercise?.wordsMin ?? null, exercise?.wordsMax ?? null);
  if (words == null || words <= 0) return null;
  return Math.max(1, Math.round(words / DIAGNOSTIC_WRITING_WORDS_PER_MINUTE));
}

/** Minutes annoncées pour l'oral, dérivées du temps de parole servi. */
export function diagnosticOralMinutes(
  exercise: DiagnosticExerciseMeasure | null | undefined,
): number | null {
  const seconds = midpoint(
    exercise?.durationMinSeconds ?? null,
    exercise?.durationMaxSeconds ?? null,
  );
  if (seconds == null || seconds <= 0) return null;
  return Math.max(1, Math.round(seconds / 60));
}

/**
 * **Combien d'exercices ce diagnostic comporte** — servi, jamais écrit.
 *
 * 🛑 Le repli ne vaut que pour un backend antérieur au champ : il compte ce
 * qu'il voit, ce qui donne `1` sur un parcours non commencé (les sujets n'y
 * sont pas attachés). C'est encore la bonne réponse pour le diagnostic actif,
 * et c'est le sens de l'erreur qui ne promet rien de trop.
 */
export function diagnosticExerciseCount(d: DiagnosticResponse): number {
    if (d.format) return d.format.exerciseCount;
    const vus = (d.written ? 1 : 0) + (d.oral ? 1 : 0);
    return vus === 0 ? 1 : vus;
}

/** Ce diagnostic comporte-t-il une étape orale ? */
export function diagnosticHasOral(format: DiagnosticFormatDto | null): boolean {
    return (format?.exerciseCount ?? 1) > 1;
}

/**
 * « 1 exercice · ≈ 5 min » — l'effort annoncé, **dérivé du format servi**.
 *
 * 🛑 **Rien n'est écrit en dur** (correctif du 2026-09-14). La carte annonçait
 * « 2 exercices · ≈ 8 à 10 min » alors que le diagnostic actif (`QUICK_TCF`)
 * n'en comporte qu'**un** — une production écrite, sans étape orale depuis
 * V050. Un candidat qui n'avait jamais rien fait lisait donc une promesse
 * fausse dès sa première carte.
 *
 * Sans mesure exploitable, on annonce le **compte** et rien d'autre.
 * Miroir mot pour mot de `homeDiagStartSubtitle` côté mobile.
 */
export function diagnosticStartSubtitle(format: DiagnosticFormatDto | null): string {
    const n = format?.exerciseCount ?? 1;
    const exercices = `${n} exercice${n > 1 ? "s" : ""}`;
    const minutes = diagnosticFormatMinutes(format);
    return minutes == null ? exercices : `${exercices} · ≈ ${minutes} min`;
}

/** « On analyse votre écrit… » — l'oral n'est nommé que s'il existe. */
export function diagnosticStartObjective(format: DiagnosticFormatDto | null): string {
    const quoi = diagnosticHasOral(format) ? "votre écrit et votre oral" : "votre écrit";
    return `On analyse ${quoi} pour construire votre premier plan.`;
}

/** L'attente d'analyse : « vos deux réponses » seulement s'il y en a deux. */
export function diagnosticAnalyzingObjective(
    format: DiagnosticFormatDto | null,
): string {
    return diagnosticHasOral(format)
        ? "Vos deux réponses sont enregistrées ; vous pouvez revenir voir le résultat."
        : "Votre réponse est enregistrée ; vous pouvez revenir voir le résultat.";
}

/** « 1 / 2 terminé ». Les **deux** nombres sont servis. */
export function diagnosticCountLabel(done: number, total: number): string {
    return `${done} / ${total} terminé${done > 1 ? "s" : ""}`;
}

/** Somme des minutes annoncées, écrit + oral. `null` sans borne exploitable. */
function diagnosticFormatMinutes(format: DiagnosticFormatDto | null): number | null {
    if (!format) return null;
    // Les deux règles lisent la même forme de mesure : on la leur donne
    // entière, le format portant les quatre bornes.
    const mesure: DiagnosticExerciseMeasure = {
        wordsMin: format.writtenWordsMin,
        wordsMax: format.writtenWordsMax,
        durationMinSeconds: format.oralDurationMinSeconds,
        durationMaxSeconds: format.oralDurationMaxSeconds,
    };
    return diagnosticExpressionMinutes(mesure, mesure);
}

/**
 * Le temps annoncé pour les productions du diagnostic : l'écrit, plus l'oral
 * s'il existe. `null` quand aucune borne n'est servie — on n'invente pas une
 * durée. Seule règle du web pour ce total (présentation, choix d'examen,
 * Accueil). Miroir : `diagnosticExpressionMinutes` côté mobile.
 */
export function diagnosticExpressionMinutes(
    written: DiagnosticExerciseMeasure | null | undefined,
    oral: DiagnosticExerciseMeasure | null | undefined,
): number | null {
    const total = (diagnosticWrittenMinutes(written) ?? 0) + (diagnosticOralMinutes(oral) ?? 0);
    return total > 0 ? total : null;
}

/**
 * La mesure de l'écrit : la fourchette de mots servie, puis le temps estimé.
 * `null` quand la base ne porte aucune borne — on n'invente pas un chiffre que
 * le sujet contredirait à l'écran suivant.
 */
export function diagnosticWrittenMeasureLabel(
  exercise: DiagnosticExerciseMeasure | null | undefined,
): string | null {
  const words = diagnosticWordRangeLabel(exercise);
  const minutes = diagnosticWrittenMinutes(exercise);
  const time = minutes == null ? null : `environ ${minutes} min`;
  const parts = [words, time].filter((part): part is string => part != null);
  return parts.length === 0 ? null : parts.join(" · ");
}

/**
 * « 80 à 300 mots » — la fourchette de l'écrit, **telle que le sujet la sert**
 * (`wordsMin` / `wordsMax`, les bornes mêmes qui acceptent ou refusent la copie
 * côté serveur). Seule mise en mots de la fourchette du diagnostic : la
 * présentation et l'éditeur de l'écrit la lisent ici. `null` sans borne — on
 * n'invente pas un chiffre. Miroir : `diagnosticWordRangeLabel` (mobile,
 * `diagnostic_intro_labels.dart`).
 */
export function diagnosticWordRangeLabel(
  exercise: Pick<DiagnosticExerciseMeasure, "wordsMin" | "wordsMax"> | null | undefined,
): string | null {
  const min = exercise?.wordsMin ?? null;
  const max = exercise?.wordsMax ?? null;
  if (min != null && max != null) return `${min} à ${max} mots`;
  if (min != null) return `${min} mots minimum`;
  if (max != null) return `${max} mots maximum`;
  return null;
}

/** La mesure de l'oral : son temps de parole, en clair. */
export function diagnosticOralMeasureLabel(
  exercise: DiagnosticExerciseMeasure | null | undefined,
): string | null {
  const minutes = diagnosticOralMinutes(exercise);
  if (minutes == null) return null;
  return `environ ${minutes} minute${minutes > 1 ? "s" : ""}`;
}

/** Adapte le sujet diagnostic au composant de production existant, sans lui
 *  inventer de tâche officielle ni de niveau cible. */
export function diagnosticExerciseAsProductionTask(
  exercise: DiagnosticExerciseContent,
): ProductionTaskDto {
  return {
    id: exercise.productionTaskId,
    epreuve: exercise.epreuve,
    tacheNumero: 1,
    niveauCible: "Diagnostic",
    titre: exercise.title,
    consigne: exercise.instruction,
    contexte: exercise.helperText,
    dureeMaxSec: exercise.durationMaxSeconds,
    dureeMinSec: exercise.durationMinSeconds,
    motsMin: exercise.wordsMin,
    motsMax: exercise.wordsMax,
  };
}

/** Numéro de tâche porté par un code de compétence canonique (`EE1-C1` → 1).
 *  `null` quand le code ne suit pas la convention : l'appelant retombe alors sur
 *  une route générique plutôt que d'en fabriquer une fausse. */
export function skillTaskNumber(skillCode: string): number | null {
  const task = skillCode.match(/^(?:EE|EO)([1-3])(?:-|$)/)?.[1];
  return task ? Number(task) : null;
}

/**
 * Où mène l'exercice recommandé par le Plan. **Deux natures, deux écrans** : un
 * micro-sujet du module Compétences, ou une **vérification en situation** sur
 * une vraie tâche TCF. On lit `kind`, on ne le devine jamais d'un identifiant
 * nul — et une vérification sans `productionTaskId` retombe sur la liste des
 * sujets de sa tâche plutôt que sur une adresse fabriquée.
 *
 * Les URLs Compétences portent le numéro de tâche : le contrat Plan fournit le
 * code canonique (EE1-C1, EO2-C3...), on n'en déduit ici que le segment de
 * route, jamais une décision pédagogique.
 */
export function recommendedExerciseHref(
  exercise: PlanSkillExerciseDto | null | undefined,
  options: {planStep?: boolean} = {},
): string {
  if (!exercise) return "/entrainement?module=TCF";
  if (exercise.kind === "TARGETED_QCM_SERIES") {
    // Une série ciblée se **démarre** (`attemptApi.startTargetedSeries`, le seul
    // `skillId` suffit) : la compréhension n'a ni tâche ni petit sujet, donc
    // aucune page de sujets à ouvrir. Tant qu'aucun écran ne la lance, on renvoie
    // sur l'entrée d'entraînement TCF plutôt que sur une adresse fabriquée.
    return "/entrainement?module=TCF";
  }
  const base = `/entrainement/tcf/${exercise.section.toLowerCase()}`;
  if (exercise.kind === "REASSESSMENT") {
    /* Le marqueur d'étape suit aussi la vérification : sans lui, un verrou
       rencontré sur la tâche désignée par le Plan n'était plus le CTA du Plan
       (contrôle F, 2026-09-25). */
    if (exercise.productionTaskId) {
      return withPlanStep(
        productionTaskHref(exercise.section, exercise.productionTaskId),
        options.planStep === true,
      );
    }
    return withPlanStep(`${base}/tache/${exercise.tacheNumero ?? 1}`, options.planStep === true);
  }
  const task = skillTaskNumber(exercise.skillCode);
  /* 🛑 **Le marqueur d'étape voyage jusqu'au SUJET**, pas seulement jusqu'à la
     fiche. Sans lui, le CTA du Plan ouvrait un sujet qui s'annonçait « 1/15 » :
     le périmètre de l'étape était perdu à la navigation, et l'enchaînement
     débordait sur le 6ᵉ sujet de la compétence. Le repli (aucune tâche
     dérivable du code) le porte aussi — on ne sort pas de l'étape par un
     chemin de secours. */
  if (!task) return withPlanStep(`${base}/tache/1/competences`, options.planStep === true);
  return withPlanStep(
    `${base}/tache/${task}/competences/${exercise.skillId}/${exercise.skillPromptId}`,
    options.planStep === true,
  );
}

/**
 * Fiche d'une compétence observée dans le module Compétences — le Plan et
 * « Réviser → Compétences » ouvrent le **même** écran.
 *
 * `planStep` y ajoute le marqueur `?etape=1` : arrivé **depuis le Plan**,
 * l'écran se limite aux sujets de l'étape et compte « 2/5 » au lieu de
 * « 1/15 » (cf. `lib/plan-step.ts`). Sans le marqueur, comportement
 * strictement inchangé.
 */
export function competenceHref(
  skill: {
    skillId: string;
    skillCode: string;
    section: SkillSection;
  },
  options: {planStep?: boolean} = {},
): string {
  const base = `/entrainement/tcf/${skill.section.toLowerCase()}`;
  const task = skillTaskNumber(skill.skillCode);
  if (!task) return `${base}/tache/1/competences`;
  return withPlanStep(
    `${base}/tache/${task}/competences/${skill.skillId}`,
    options.planStep === true,
  );
}

/** Nom complet d'un domaine, écrit une seule fois pour le diagnostic et pour le
 *  Plan. Délègue à `SKILL_SECTION_LABEL` (miroir de l'enum serveur) : depuis que
 *  `SkillSection` porte aussi la compréhension, un `else` sur `"EE"` aurait
 *  affiché « Expression orale » sur un domaine CO/CE. */
export function productionSectionLabel(section: SkillSection): string {
  return SKILL_SECTION_LABEL[section];
}

/* ------------------------------------------------------------------ jalons */

/**
 * Ce qu'on dit d'un **jalon** du Plan. Le serveur n'en fournit **aucun**
 * libellé : il expose des faits (quelle épreuve, quel slot, verrouillé ou non),
 * la phrase appartient aux fronts — même partage que `PlanChangeDto`.
 *
 * ⚠️ **Contrat gelé, miroir mot pour mot du mobile**
 * (`lib/screens/plan/plan_milestone_labels.dart`). Ces chaînes ne transitent pas
 * par le réseau : chaque front en tient sa copie, un libellé qui bouge, ce sont
 * **deux** fichiers à changer dans la même passe.
 *
 * **Ton** : un jalon est une étape de progression, pas une sanction. Le candidat
 * vient prouver ce qu'il a acquis, on ne le met pas en garde.
 */
export const PLAN_MILESTONE_SECTION_TITLE = "Votre prochain jalon";
export const PLAN_MILESTONE_SECTION_TEXT =
  "Un cran au-dessus des étapes : venez prouver ce que vous avez déjà acquis.";
export const PLAN_MILESTONE_PILL = "Jalon";
export const PLAN_MILESTONE_CTA = "Passer l'examen blanc";
export const PLAN_MILESTONE_LOCKED_CTA = "Débloquer cet examen blanc";
export const PLAN_MILESTONE_LOCK_NOTE =
  "Cet examen blanc fait partie du pass Intégral. Votre plan, lui, reste entier.";
export const PLAN_MILESTONE_FULL_TITLE = "Examen blanc TCF complet";
export const PLAN_MILESTONE_FULL_TEXT =
  "L'écrit et l'oral ont chacun franchi leur jalon. Il reste à les tenir ensemble, sur les 4 épreuves du TCF.";

/** Titre d'un jalon : « Examen blanc — Expression écrite / orale », ou l'examen
 *  complet. C'est `epreuve` qui tranche, jamais `section` (toujours nulle ici). */
export function planMilestoneTitle(milestone: PlanMilestoneExerciseDto): string {
  if (milestone.kind === "FULL_TCF_MOCK_EXAM") return PLAN_MILESTONE_FULL_TITLE;
  const section: SkillSection = milestone.epreuve === "TCF_EO" ? "EO" : "EE";
  return `Examen blanc — ${productionSectionLabel(section)}`;
}

/** Pourquoi ce jalon est proposé maintenant — une phrase, pas un avertissement. */
export function planMilestoneText(milestone: PlanMilestoneExerciseDto): string {
  if (milestone.kind === "FULL_TCF_MOCK_EXAM") return PLAN_MILESTONE_FULL_TEXT;
  const section: SkillSection = milestone.epreuve === "TCF_EO" ? "EO" : "EE";
  return `Vos compétences en ${productionSectionLabel(section).toLowerCase()} tiennent en exercice ciblé. Enchaînez les 3 tâches en conditions d'examen pour le confirmer.`;
}

/** Le repère factuel sous le titre : quel examen de la grille, quelle durée.
 *  La durée vient du DTO (`estimatedMinutes`), jamais d'un nombre écrit ici. */
export function planMilestoneMeta(milestone: PlanMilestoneExerciseDto): string {
  return `Examen blanc n°${milestone.slotNumber} · ≈ ${milestone.estimatedMinutes} min`;
}

export function niveauEstimateLabel(level: NiveauCecrl | null | undefined): string {
  if (!level) return "Non estimé";
  return level === "A1_NON_ATTEINT" ? "A1 non atteint" : level;
}

/**
 * Libellés FR de l'état d'une compétence dans le Plan.
 *
 * ⚠️ **Contrat gelé** (`diagnostic.test.ts`) : ces chaînes ne transitent pas par
 * le réseau, chaque front en tient sa propre copie écrite à la main — et les
 * deux avaient déjà divergé (`NOT_OBSERVED` : « Non observée » ici, « À
 * évaluer » sur mobile). **Le web fait référence** : un libellé qui bouge, ce
 * sont deux fichiers et deux tests à changer dans la même passe.
 */
export const LEARNING_PLAN_SKILL_STATUS_LABEL: Record<LearningPlanSkillStatus, string> = {
  NOT_OBSERVED: "Non observée",
  PRIORITY: "Prioritaire",
  TO_REINFORCE: "À renforcer",
  SOLID: "Solide",
};

/**
 * D'où vient une observation, dit au candidat.
 *
 * ⚠️ **Contrat gelé**, recopié au caractère près côté mobile. Écrit et oral
 * partagent volontairement le même mot : sur la frise d'une compétence, la
 * section est déjà celle de la compétence — répéter « écrit » à chaque ligne
 * n'apprendrait rien. `TCF_CO` / `TCF_CE` sont **réservés** : le serveur ne les
 * sert pas encore, ils sont prévus pour ne pas laisser un libellé vide le jour
 * où la compréhension entrera dans le Plan.
 */
export const LEARNING_PLAN_SOURCE_LABEL: Record<LearningPlanSourceType, string> = {
  DIAGNOSTIC_EE: "Diagnostic",
  DIAGNOSTIC_EO: "Diagnostic",
  PRODUCTION_EE: "Production complète",
  PRODUCTION_EO: "Production complète",
  MOCK_EXAM_EE: "Examen blanc",
  MOCK_EXAM_EO: "Examen blanc",
  SKILL_TRAINING: "Entraînement ciblé",
  TCF_CO: "Compréhension",
  TCF_CE: "Compréhension",
};

/**
 * Teinte d'un signal de diagnostic : vert = acquis, ambre = à consolider,
 * rouge = prioritaire, neutre = rien d'observé.
 *
 * Une seule échelle pour les trois signaux servis par le diagnostic (état d'une
 * compétence, accomplissement de la consigne, efficacité de la communication) :
 * sans elle, le même « partiel » se serait retrouvé vert d'un côté et rouge de
 * l'autre.
 */
export type DiagnosticSignalTone = "good" | "mid" | "weak" | "none";

export const LEARNING_PLAN_SKILL_STATUS_TONE: Record<LearningPlanSkillStatus, DiagnosticSignalTone> = {
  NOT_OBSERVED: "none",
  PRIORITY: "weak",
  TO_REINFORCE: "mid",
  SOLID: "good",
};

/** Accomplissement de la consigne, tel que le diagnostic le juge. Formulé en
 *  constat, jamais en reproche (règle de ton du dépôt). */
export const DIAGNOSTIC_TASK_COMPLETION_LABEL: Record<DiagnosticTaskCompletion, string> = {
  COMPLETED: "Consigne accomplie",
  PARTIAL: "Consigne partiellement accomplie",
  NOT_COMPLETED: "Consigne non accomplie",
};

export const DIAGNOSTIC_TASK_COMPLETION_TONE: Record<DiagnosticTaskCompletion, DiagnosticSignalTone> = {
  COMPLETED: "good",
  PARTIAL: "mid",
  NOT_COMPLETED: "weak",
};

/** Efficacité de la communication — ce que le lecteur ou l'auditeur a compris,
 *  indépendamment de la correction de la langue. */
export const DIAGNOSTIC_COMMUNICATION_LABEL: Record<DiagnosticCommunicationStatus, string> = {
  EFFECTIVE: "Message clair",
  PARTIAL: "Message compris avec effort",
  INEFFECTIVE: "Message difficile à suivre",
};

export const DIAGNOSTIC_COMMUNICATION_TONE: Record<DiagnosticCommunicationStatus, DiagnosticSignalTone> = {
  EFFECTIVE: "good",
  PARTIAL: "mid",
  INEFFECTIVE: "weak",
};

// ---------------------------------------------------------------------------
// Revenir à son écrit depuis l'écran de compte (diagnostic invité)
// ---------------------------------------------------------------------------
// Miroir mot pour mot de `mobile_sejourfr/lib/screens/diagnostic/widgets/
// diagnostic_common.dart` (`kDiagnosticEdit*`, `diagnosticEditNote`).

/** Le retour de l'écran de compte vers l'écrit, pré-rempli. */
export const DIAGNOSTIC_EDIT_WRITTEN_CTA = "Modifier mon texte";
/** Quitter la modification sans rien changer à la production enregistrée. */
export const DIAGNOSTIC_EDIT_CANCEL = "Revenir sans modifier";
/** Le bouton de l'écrit rouvert : il remplace la production, puis ramène au compte. */
export const DIAGNOSTIC_EDIT_SUBMIT = "Enregistrer mes modifications";

/** Ce qui ne bouge pas tant que la modification n'est pas enregistrée. */
export function diagnosticEditNote(hasOral: boolean): string {
  return hasOral
    ? "Votre texte et votre enregistrement restent conservés tant que vous n'enregistrez pas vos modifications."
    : "Votre texte reste conservé tant que vous n'enregistrez pas vos modifications.";
}

// ---------------------------------------------------------------------------
// L'écran d'un exercice du diagnostic (écrit, oral)
// ---------------------------------------------------------------------------
// Miroir mot pour mot de `mobile_sejourfr/lib/screens/diagnostic/widgets/
// diagnostic_common.dart` (`kDiagnosticExercise*`, `diagnosticExerciseSub`,
// `diagnosticWrittenSubmitLabel`, `diagnosticConsigneBlocks`).

export type DiagnosticExerciseKind = "written" | "oral";

/** Sur-titre mono de l'écran d'exercice. */
export const DIAGNOSTIC_EXERCISE_KICKER: Record<DiagnosticExerciseKind, string> = {
  written: "Diagnostic TCF · Expression écrite",
  oral: "Diagnostic TCF · Expression orale",
};

/** Titre Fraunces : `lead` puis `em` (rouge), puis `tail` collé. */
export const DIAGNOSTIC_EXERCISE_TITLE: Record<
  DiagnosticExerciseKind,
  {lead: string; em: string; tail: string}
> = {
  written: {lead: "Votre texte,", em: "votre niveau", tail: "."},
  oral: {lead: "Votre voix,", em: "votre niveau", tail: "."},
};

/**
 * La ligne sous le titre. 🛑 **Le rang se lit sur la FORME servie** (oral
 * `null` ⇒ exercice unique) : le diagnostic rapide n'a qu'un écrit, l'écran
 * annonçait « Premier exercice sur deux ».
 */
export function diagnosticExerciseSub(kind: DiagnosticExerciseKind, hasOral: boolean): string {
  const rang =
    kind === "oral"
      ? "Deuxième et dernier exercice"
      : hasOral
        ? "Premier exercice sur deux"
        : "Un seul exercice";
  return `${rang} · aucune note sur 20.`;
}

/** Tête de la zone de saisie de l'écrit. */
export const DIAGNOSTIC_WRITTEN_EDITOR_TITLE = "Votre texte";
/** Sur-titre de la carte du sujet. */
export const DIAGNOSTIC_SUBJECT_TAG = "Votre sujet";

/**
 * Le bouton de l'écrit : il dit ce qui se passe **ensuite**, selon la forme
 * servie et le régime. Avec un oral, on continue ; sans, un visiteur valide
 * son texte (le compte vient après), un compte lance l'analyse.
 */
export function diagnosticWrittenSubmitLabel(options: {guest: boolean; hasOral: boolean}): string {
  if (options.hasOral) return "Continuer vers l'oral";
  return options.guest ? "Valider mon texte" : "Lancer mon analyse";
}

/** Un bloc de consigne : un paragraphe, ou une liste précédée de son amorce. */
export type DiagnosticConsigneBlock =
  | {kind: "paragraph"; text: string}
  | {kind: "list"; lead: string | null; ordered: boolean; items: string[]};

const BULLET = /^\s*(?:[-•*]|\d+[.)])\s+/;
const NUMBERED = /^\s*\d+[.)]\s+/;

/**
 * **Met en forme** la consigne servie, sans en réécrire un mot : les
 * paragraphes sont séparés par une ligne vide ; un paragraphe dont les lignes
 * suivantes commencent par « - », « • », « * » ou « 1. » devient une liste,
 * sa première ligne (« Dans un seul texte : ») en devient l'amorce. Une liste
 * numérotée le reste (`ordered`). Le texte des puces est rendu tel quel,
 * ponctuation comprise.
 */
export function diagnosticConsigneBlocks(text: string): DiagnosticConsigneBlock[] {
  return text
    .replace(/\r\n/g, "\n")
    .trim()
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.trim())
    .filter((paragraph) => paragraph.length > 0)
    .map((paragraph): DiagnosticConsigneBlock => {
      const lines = paragraph.split("\n").map((line) => line.trim()).filter(Boolean);
      const firstBullet = lines.findIndex((line) => BULLET.test(line));
      const bulletsOnly = firstBullet >= 0 && lines.slice(firstBullet).every((line) => BULLET.test(line));
      if (!bulletsOnly || firstBullet > 1 || lines.length - firstBullet < 2) {
        return {kind: "paragraph", text: paragraph};
      }
      return {
        kind: "list",
        lead: firstBullet === 1 ? lines[0] : null,
        ordered: lines.slice(firstBullet).every((line) => NUMBERED.test(line)),
        items: lines.slice(firstBullet).map((line) => line.replace(BULLET, "")),
      };
    });
}
