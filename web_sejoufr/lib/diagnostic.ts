import {withPlanStep} from "./plan-step.ts";
import {productionTaskHref} from "./production-catalog.ts";
import type {
  DiagnosticCommunicationStatus,
  DiagnosticExerciseDto,
  DiagnosticResponse,
  DiagnosticTaskCompletion,
  LearningPlanSkillStatus,
  LearningPlanSourceType,
  NiveauCecrl,
  PlanMilestoneExerciseDto,
  PlanStepExerciseDto,
  ProductionTaskDto,
  SkillSection,
} from "./types";

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
 * La mesure de l'écrit : la fourchette de mots servie, puis le temps estimé.
 * `null` quand la base ne porte aucune borne — on n'invente pas un chiffre que
 * le sujet contredirait à l'écran suivant.
 */
export function diagnosticWrittenMeasureLabel(
  exercise: DiagnosticExerciseMeasure | null | undefined,
): string | null {
  const min = exercise?.wordsMin ?? null;
  const max = exercise?.wordsMax ?? null;
  const words =
    min != null && max != null
      ? `${min} à ${max} mots`
      : min != null
        ? `${min} mots minimum`
        : max != null
          ? `${max} mots maximum`
          : null;
  const minutes = diagnosticWrittenMinutes(exercise);
  const time = minutes == null ? null : `environ ${minutes} min`;
  const parts = [words, time].filter((part): part is string => part != null);
  return parts.length === 0 ? null : parts.join(" · ");
}

/** La mesure de l'oral : son temps de parole, en clair. */
export function diagnosticOralMeasureLabel(
  exercise: DiagnosticExerciseMeasure | null | undefined,
): string | null {
  const minutes = diagnosticOralMinutes(exercise);
  if (minutes == null) return null;
  return `environ ${minutes} minute${minutes > 1 ? "s" : ""}`;
}

/**
 * Le budget annoncé en tête de la présentation. Somme des deux exercices, donc
 * il suit les sujets : si la base raccourcit l'écrit, la promesse raccourcit
 * avec lui. Sans mesure exploitable, on annonce le nombre d'exercices plutôt
 * qu'une durée inventée.
 */
export function diagnosticBudgetLabel(
  written: DiagnosticExerciseMeasure | null | undefined,
  oral: DiagnosticExerciseMeasure | null | undefined,
): string {
  const total = (diagnosticWrittenMinutes(written) ?? 0) + (diagnosticOralMinutes(oral) ?? 0);
  return total > 0 ? `Diagnostic express · ~${total} min` : "Diagnostic express · 2 exercices";
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
  exercise: PlanStepExerciseDto | null | undefined,
): string {
  if (!exercise) return "/entrainement?module=TCF";
  const base = `/entrainement/tcf/${exercise.section.toLowerCase()}`;
  if (exercise.kind === "REASSESSMENT") {
    if (exercise.productionTaskId) {
      return productionTaskHref(exercise.section, exercise.productionTaskId);
    }
    return `${base}/tache/${exercise.tacheNumero ?? 1}`;
  }
  const task = skillTaskNumber(exercise.skillCode);
  if (!task) return `${base}/tache/1/competences`;
  return `${base}/tache/${task}/competences/${exercise.skillId}/${exercise.skillPromptId}`;
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

/** Nom complet d'une épreuve de production, écrit une seule fois pour le
 *  diagnostic et pour le Plan. */
export function productionSectionLabel(section: SkillSection): string {
  return section === "EE" ? "Expression écrite" : "Expression orale";
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
  "Cet examen blanc fait partie de l'abonnement Intégral. Votre plan, lui, reste entier.";
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
