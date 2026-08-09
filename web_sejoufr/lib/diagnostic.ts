import type {
  DiagnosticExerciseDto,
  DiagnosticResponse,
  LearningPlanSkillStatus,
  NiveauCecrl,
  PlanRecommendedExerciseDto,
  ProductionTaskDto,
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

/** Adapte le sujet diagnostic au composant de production existant, sans lui
 *  inventer de tâche officielle ni de niveau cible. */
export function diagnosticExerciseAsProductionTask(
  exercise: DiagnosticExerciseDto,
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

/** Les URLs Compétences portent le numéro de tâche. Le contrat Plan fournit le
 *  code canonique (EE1-C1, EO2-C3...) : on n'en déduit ici que le segment de
 *  route, jamais une décision pédagogique. */
export function recommendedExerciseHref(
  exercise: PlanRecommendedExerciseDto | null | undefined,
): string {
  if (!exercise) return "/entrainement?module=TCF";
  const base = `/entrainement/tcf/${exercise.section.toLowerCase()}`;
  const task = exercise.skillCode.match(/^(?:EE|EO)([1-3])(?:-|$)/)?.[1];
  if (!task) return `${base}/tache/1/competences`;
  return `${base}/tache/${task}/competences/${exercise.skillId}/${exercise.skillPromptId}`;
}

export function niveauEstimateLabel(level: NiveauCecrl | null | undefined): string {
  if (!level) return "Non estimé";
  return level === "A1_NON_ATTEINT" ? "A1 non atteint" : level;
}

export const LEARNING_PLAN_SKILL_STATUS_LABEL: Record<LearningPlanSkillStatus, string> = {
  NOT_OBSERVED: "Non observée",
  PRIORITY: "Prioritaire",
  TO_REINFORCE: "À renforcer",
  SOLID: "Solide",
};
