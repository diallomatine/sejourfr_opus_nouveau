import assert from "node:assert/strict";
import test from "node:test";
import {
  diagnosticCompletedExerciseCount,
  diagnosticDashboardState,
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
