import {productionTaskHref} from "./production-catalog.ts";
import type {
  DiagnosticCommunicationStatus,
  DiagnosticExerciseDto,
  DiagnosticResponse,
  DiagnosticTaskCompletion,
  LearningPlanSkillStatus,
  LearningPlanSourceType,
  NiveauCecrl,
  PlanRecommendedExerciseDto,
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
  exercise: PlanRecommendedExerciseDto | null | undefined,
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

/** Fiche d'une compétence observée dans le module Compétences — le Plan et
 *  « Réviser → Compétences » ouvrent le **même** écran. */
export function competenceHref(skill: {
  skillId: string;
  skillCode: string;
  section: SkillSection;
}): string {
  const base = `/entrainement/tcf/${skill.section.toLowerCase()}`;
  const task = skillTaskNumber(skill.skillCode);
  if (!task) return `${base}/tache/1/competences`;
  return `${base}/tache/${task}/competences/${skill.skillId}`;
}

/** Nom complet d'une épreuve de production, écrit une seule fois pour le
 *  diagnostic et pour le Plan. */
export function productionSectionLabel(section: SkillSection): string {
  return section === "EE" ? "Expression écrite" : "Expression orale";
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
