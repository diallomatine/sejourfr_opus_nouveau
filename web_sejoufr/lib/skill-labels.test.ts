// Fige les libellés FR du module « Compétences TCF ».
//
// Ces chaînes ne viennent PAS du backend : chaque front en tient sa propre copie
// à la main (ici, `mobile/lib/core/models/skill_models.dart`,
// `admin/src/features/skills/skillHelpers.ts`), et l'enum Java n'en est que la
// référence écrite. Rien n'empêchait donc une couche de dériver — et c'est
// arrivé : `NOT_VALIDATED` s'affichait « Critère à retravailler » sur le web,
// « Critère non atteint » sur mobile et « Critère non validé » côté serveur.
// Trois formulations pour un même état, alors que la parité web ⇄ mobile est une
// règle non négociable du projet.
//
// Ce test tient le côté web ; `SkillLabelsTest` (backend) et
// `skill_models_test.dart` (mobile) tiennent les leurs, sur les mêmes chaînes.
// Un échec ici veut dire qu'un libellé a bougé et que les autres copies doivent
// bouger dans la même passe — pas qu'il faut mettre le test à jour tout seul.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    SKILL_CRITERION_STATUS_LABEL,
    SKILL_DIFFICULTY_LABEL,
    SKILL_PROMPT_STATUS_LABEL,
    SKILL_REFERENCE_LEVELS,
    SKILL_REFERENCE_LEVEL_LABEL,
    SKILL_SELF_EVALUATION_LABEL,
} from "./types.ts";

describe("libellés du module Compétences", () => {
    it("verdict du critère : les trois libellés sont gelés", () => {
        assert.deepEqual(SKILL_CRITERION_STATUS_LABEL, {
            VALIDATED: "Critère validé",
            PARTIAL: "Critère partiellement atteint",
            NOT_VALIDATED: "Critère non atteint",
        });
    });

    it("« à retravailler » ne revient pas : c'est le vocabulaire d'un statut de sujet", () => {
        // « Critère à retravailler » était quasi synonyme de « À renforcer »
        // (TO_REINFORCE) et confondait le verdict d'UNE tentative avec l'état
        // d'UN sujet.
        for (const label of Object.values(SKILL_CRITERION_STATUS_LABEL)) {
            assert.ok(
                !label.toLowerCase().includes("retravailler"),
                `verdict « ${label} » : formulation réservée aux statuts de sujet`,
            );
        }
    });

    it("statut d'un sujet : les quatre libellés sont gelés", () => {
        assert.deepEqual(SKILL_PROMPT_STATUS_LABEL, {
            TODO: "À faire",
            TREATED: "Fait",
            VALIDATED: "Validé",
            TO_REINFORCE: "À renforcer",
        });
    });

    it("auto-évaluation : trois libellés à la première personne, gelés", () => {
        assert.deepEqual(SKILL_SELF_EVALUATION_LABEL, {
            REUSSI: "Je pense avoir réussi",
            INCERTAIN: "Je ne suis pas sûr",
            DIFFICILE: "J'ai eu du mal",
        });
    });

    it("difficulté : « Accessible » décrit le sujet, il ne juge pas le candidat", () => {
        assert.deepEqual(SKILL_DIFFICULTY_LABEL, {
            EASY: "Accessible",
            MEDIUM: "Intermédiaire",
            HARD: "Exigeant",
        });
    });

    it("niveaux de référence : libellés gelés et ordre d'affichage imposé", () => {
        assert.deepEqual(SKILL_REFERENCE_LEVEL_LABEL, {
            INSUFFICIENT: "Insuffisant",
            EXPECTED: "Attendu",
            EXCELLENT: "Très réussi",
        });
        // On montre d'abord ce qui ne suffit pas, puis ce qui suffit.
        assert.deepEqual([...SKILL_REFERENCE_LEVELS], [
            "INSUFFICIENT",
            "EXPECTED",
            "EXCELLENT",
        ]);
    });

    it("aucun libellé vide, aucun doublon dans une même famille", () => {
        for (const famille of [
            SKILL_CRITERION_STATUS_LABEL,
            SKILL_PROMPT_STATUS_LABEL,
            SKILL_SELF_EVALUATION_LABEL,
            SKILL_DIFFICULTY_LABEL,
            SKILL_REFERENCE_LEVEL_LABEL,
        ]) {
            const labels = Object.values(famille);
            assert.ok(
                labels.every((l) => l.trim().length > 0),
                "un libellé vide serait rendu tel quel au candidat",
            );
            assert.equal(new Set(labels).size, labels.length);
        }
    });
});
