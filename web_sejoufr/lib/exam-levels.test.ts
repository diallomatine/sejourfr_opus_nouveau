// Assertions courtes sur les règles PURES du bilan d'un examen à plusieurs
// épreuves (aucun composant monté) : pas de rouge sur un palier, pas de niveau
// sur une épreuve verrouillée, pas de spinner sur une évaluation morte, pas de
// décompte affirmé sans le champ backend.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    EXAM_STALE_THRESHOLD_MS,
    epreuveLevelTone,
    examIsStale,
    floorMarks,
    floorRuleSentence,
    floorScope,
    isCompleteExamResult,
    subAttemptView,
} from "./exam-levels.ts";
import type {EpreuveType, FullTcfExamSubAttempt, NiveauCecrl} from "./types.ts";

function sub(over: Partial<FullTcfExamSubAttempt> = {}): FullTcfExamSubAttempt {
    return {
        attemptId: "a1",
        epreuve: "TCF_EE" as EpreuveType,
        finishedAt: "2026-08-05T10:00:00Z",
        cecrlLevel: null,
        score: null,
        maxScore: null,
        calibratedScore: null,
        submissionsCount: null,
        failedSubmissionIds: [],
        locked: false,
        timeLimitSeconds: null,
        timerStartedAt: null,
        deadlineAt: null,
        ...over,
    };
}

describe("teinte d'un palier", () => {
    it("ne produit jamais de rouge, et un B2 partout reste vert partout", () => {
        const niveaux: NiveauCecrl[] = ["A1_NON_ATTEINT", "A1", "A2", "B1", "B2", "C1", "C2"];
        for (const n of niveaux) {
            assert.ok(["amber", "blue", "green"].includes(epreuveLevelTone(n)), n);
        }
        const b2: NiveauCecrl[] = ["B2", "B2", "B2", "B2"];
        assert.deepEqual(b2.map(epreuveLevelTone), [
            "green",
            "green",
            "green",
            "green",
        ]);
        assert.equal(epreuveLevelTone(null), "neutral");
    });
});

describe("mention du niveau retenu", () => {
    it("ne marque rien à égalité, marque le point faible sinon", () => {
        assert.deepEqual(floorMarks(["B2", "B2", "B2"], "B2"), [false, false, false]);
        assert.deepEqual(floorMarks(["B2", "B1", "A2"], "A2"), [false, false, true]);
        assert.deepEqual(floorMarks([null, "B2", "B1"], "B1"), [false, false, true]);
        assert.deepEqual(floorMarks(["B1", "B2"], null), [false, false]);
    });
});

describe("phrase de la règle du plancher", () => {
    it("n'affirme aucun chiffre quand le backend ne publie pas le périmètre", () => {
        const scope = floorScope({});
        assert.deepEqual(scope, {counted: null, expected: null, partial: false});
        assert.ok(!/\d/.test(floorRuleSentence(scope)));
    });

    it("dit le décompte réel sur un bilan complet", () => {
        const phrase = floorRuleSentence(
            floorScope({
                epreuvesCountedInFinalLevel: 4,
                epreuvesExpected: 4,
                finalLevelPartial: false,
            }),
        );
        assert.ok(phrase.includes("tes 4 épreuves"));
        assert.ok(!phrase.includes("partiel"));
    });

    it("annonce le bilan partiel avec « N sur 4 » au lieu des 4 épreuves", () => {
        const phrase = floorRuleSentence(
            floorScope({
                epreuvesCountedInFinalLevel: 3,
                epreuvesExpected: 4,
                finalLevelPartial: true,
            }),
        );
        assert.ok(phrase.startsWith("Bilan partiel"));
        assert.ok(phrase.includes("3 épreuves sur 4"));
        assert.ok(!phrase.includes("tes 4 épreuves"));
    });

    it("écarte un bilan partiel des résultats d'examen complet", () => {
        assert.equal(
            isCompleteExamResult({status: "COMPLETED", finalLevelPartial: false}),
            true,
        );
        assert.equal(
            isCompleteExamResult({status: "COMPLETED", finalLevelPartial: true}),
            false,
        );
        assert.equal(
            isCompleteExamResult({status: "PENDING_EVALUATIONS", finalLevelPartial: false}),
            false,
        );
    });
});

describe("état d'une épreuve", () => {
    it("verrouillée : aucun niveau, aucun spinner", () => {
        const v = subAttemptView(sub({locked: true, cecrlLevel: "A1_NON_ATTEINT"}));
        assert.equal(v.state, "locked");
        assert.equal(v.level, null);
        assert.equal(v.showSpinner, false);
    });

    it("en échec : relance au lieu du spinner", () => {
        const v = subAttemptView(sub({submissionsCount: 1, failedSubmissionIds: ["s1", "s2"]}));
        assert.equal(v.state, "failed");
        assert.equal(v.showSpinner, false);
        assert.equal(v.subtitle, "1/3 réussies · 2 à relancer");
        const total = subAttemptView(sub({submissionsCount: 0, failedSubmissionIds: ["a", "b", "c"]}));
        assert.equal(total.subtitle, "3 évaluations en échec");
    });

    it("stale : le spinner s'arrête, le sous-titre ne dit plus « en cours »", () => {
        const running = subAttemptView(sub({submissionsCount: 1}));
        assert.equal(running.showSpinner, true);
        const dead = subAttemptView(sub({submissionsCount: 1}), {stale: true});
        assert.equal(dead.state, "stalled");
        assert.equal(dead.showSpinner, false);
        assert.ok(!dead.subtitle.includes("en cours"));
    });

    it("évaluée : niveau + teinte de son palier", () => {
        const v = subAttemptView(sub({cecrlLevel: "B2", submissionsCount: 3}));
        assert.equal(v.state, "evaluated");
        assert.equal(v.tone, "green");
    });
});

describe("examen mort (stale)", () => {
    it("laisse deux minutes à l'IA, puis coupe", () => {
        const finishedAt = "2026-08-05T10:00:00Z";
        const t0 = new Date(finishedAt).getTime();
        assert.equal(examIsStale({status: "COMPLETED", finishedAt}, t0 + 10 * 60_000), false);
        assert.equal(
            examIsStale({status: "PENDING_EVALUATIONS", finishedAt: null}, t0 + 10 * 60_000),
            false,
        );
        assert.equal(examIsStale({status: "PENDING_EVALUATIONS", finishedAt}, t0 + 60_000), false);
        assert.equal(
            examIsStale(
                {status: "PENDING_EVALUATIONS", finishedAt},
                t0 + EXAM_STALE_THRESHOLD_MS + 1,
            ),
            true,
        );
    });
});
