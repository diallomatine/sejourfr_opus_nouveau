import assert from "node:assert/strict";
import test from "node:test";
import {
  competenceHref,
  DIAGNOSTIC_COMMUNICATION_LABEL,
  DIAGNOSTIC_TASK_COMPLETION_LABEL,
  diagnosticCompletedExerciseCount,
  diagnosticDashboardState,
  LEARNING_PLAN_SKILL_STATUS_LABEL,
  productionSectionLabel,
  requiresDiagnosticRevalidation,
  recommendedExerciseHref,
} from "./diagnostic.ts";
import type {DiagnosticResponse, PlanRecommendedExerciseDto} from "./types.ts";

function response(
  status: DiagnosticResponse["status"],
  written = false,
  oral = false,
): DiagnosticResponse {
  const exercise = (id: string) => ({submissionId: id}) as DiagnosticResponse["written"];
  return {
    sessionId: status === "NOT_STARTED" ? null : "session-1",
    diagnosticCode: status === "NOT_STARTED" ? null : "TCF_INITIAL",
    diagnosticVersion: status === "NOT_STARTED" ? null : 1,
    status,
    nextStep: status === "NOT_STARTED" ? "PRESENTATION" : "WRITTEN",
    written: written ? exercise("written") : null,
    oral: oral ? exercise("oral") : null,
    result: null,
    startedAt: null,
    completedAt: null,
    errorMessage: null,
    canRetry: false,
  };
}

test("les états dashboard restent limités aux trois variantes produit", () => {
  assert.equal(diagnosticDashboardState(response("NOT_STARTED")), "NOT_STARTED");
  assert.equal(diagnosticDashboardState(response("ANALYZING", true, true)), "IN_PROGRESS");
  assert.equal(diagnosticDashboardState(response("FAILED", true, true)), "IN_PROGRESS");
  assert.equal(diagnosticDashboardState(response("COMPLETED", true, true)), "COMPLETED");
});

test("la progression compte uniquement les productions déjà persistées", () => {
  assert.equal(diagnosticCompletedExerciseCount(response("IN_PROGRESS")), 0);
  assert.equal(diagnosticCompletedExerciseCount(response("IN_PROGRESS", true)), 1);
  assert.equal(diagnosticCompletedExerciseCount(response("ANALYZING", true, true)), 2);
});

test("aucun snapshot diagnostic mutable ne reste servi après sa résolution", () => {
  for (const status of [
    "NOT_STARTED",
    "IN_PROGRESS",
    "ANALYZING",
    "COMPLETED",
    "FAILED",
  ] satisfies DiagnosticResponse["status"][]) {
    assert.equal(requiresDiagnosticRevalidation(response(status)), true);
  }
});

test("la recommandation ouvre le micro-exercice exact à partir du code canonique", () => {
  const exercise: PlanRecommendedExerciseDto = {
    skillPromptId: "prompt-7",
    skillId: "skill-3",
    skillCode: "EO2-C3",
    title: "Structurer une réponse",
    section: "EO",
    estimatedMinutes: 6,
  };
  assert.equal(
    recommendedExerciseHref(exercise),
    "/entrainement/tcf/eo/tache/2/competences/skill-3/prompt-7",
  );
  assert.equal(recommendedExerciseHref(null), "/entrainement?module=TCF");
});

test("le Plan et « Réviser → Compétences » ouvrent la même fiche de compétence", () => {
  assert.equal(
    competenceHref({skillId: "skill-3", skillCode: "EE1-C4", section: "EE"}),
    "/entrainement/tcf/ee/tache/1/competences/skill-3",
  );
  // Code hors convention : route générique, jamais une tâche inventée.
  assert.equal(
    competenceHref({skillId: "skill-9", skillCode: "INCONNU", section: "EO"}),
    "/entrainement/tcf/eo/tache/1/competences",
  );
});

// ---------------------------------------------------------------------------
// Libellés gelés.
//
// Ces chaînes ne viennent PAS du backend : le web et le mobile en tiennent
// chacun une copie écrite à la main, donc rien n'empêche une couche de dériver —
// et c'est arrivé (`NOT_OBSERVED` : « Non observée » ici, « À évaluer » sur
// mobile ; `PRIORITY` : « Prioritaire » ici, « Priorité » là-bas). **Le web fait
// référence** : un échec ici veut dire qu'un libellé a bougé et que la copie
// mobile (`diagnostic_models.dart`) doit bouger dans la même passe — pas qu'il
// faut mettre le test à jour tout seul.
// Même technique que `skill-labels.test.ts` pour le module Compétences.
// ---------------------------------------------------------------------------

test("l'état d'une compétence du Plan : les quatre libellés sont gelés", () => {
  assert.deepEqual(LEARNING_PLAN_SKILL_STATUS_LABEL, {
    NOT_OBSERVED: "Non observée",
    PRIORITY: "Prioritaire",
    TO_REINFORCE: "À renforcer",
    SOLID: "Solide",
  });
});

test("les deux verdicts de production du diagnostic sont gelés", () => {
  assert.deepEqual(DIAGNOSTIC_TASK_COMPLETION_LABEL, {
    COMPLETED: "Consigne accomplie",
    PARTIAL: "Consigne partiellement accomplie",
    NOT_COMPLETED: "Consigne non accomplie",
  });
  assert.deepEqual(DIAGNOSTIC_COMMUNICATION_LABEL, {
    EFFECTIVE: "Message clair",
    PARTIAL: "Message compris avec effort",
    INEFFECTIVE: "Message difficile à suivre",
  });
});

test("le nom d'une épreuve de production s'écrit à un seul endroit", () => {
  assert.equal(productionSectionLabel("EE"), "Expression écrite");
  assert.equal(productionSectionLabel("EO"), "Expression orale");
});
