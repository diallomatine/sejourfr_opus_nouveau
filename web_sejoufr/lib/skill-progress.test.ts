// Agrégats de progression du module « Compétences TCF ».
//
// Ces calculs alimentent deux affichages que le client regarde en premier : la
// barre du hero (« Progression … N % ») et la barre « Progression de la
// compétence · X/5 ». Aucun endpoint ne les sert : ils sont dérivés côté client
// des compteurs déjà exposés. Un écran qui refait la division dans son JSX est
// un écran qui finira par diverger de l'autre.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {findSkillProgress, progressPercent, sumProgress} from "./skill-progress.ts";

describe("progressPercent", () => {
    it("arrondit à l'entier", () => {
        assert.equal(progressPercent(1, 3), 33);
        assert.equal(progressPercent(2, 3), 67);
    });

    it("une tâche vierge vaut 0 %, jamais NaN", () => {
        assert.equal(progressPercent(0, 40), 0);
        assert.equal(progressPercent(0, 0), 0);
        assert.equal(progressPercent(3, 0), 0);
    });

    it("reste borné à 100 même si le backend sur-compte", () => {
        assert.equal(progressPercent(9, 5), 100);
        assert.equal(progressPercent(-2, 5), 0);
    });
});

describe("sumProgress", () => {
    it("additionne les 8 compétences d'une tâche", () => {
        const skills = [
            {promptCount: 5, attemptedCount: 5},
            {promptCount: 5, attemptedCount: 2},
            {promptCount: 5, attemptedCount: 0},
            {promptCount: 5, attemptedCount: 1},
        ];
        assert.deepEqual(sumProgress(skills), {attempted: 8, total: 20, percent: 40});
    });

    it("liste vide → 0/0 à 0 %", () => {
        assert.deepEqual(sumProgress([]), {attempted: 0, total: 0, percent: 0});
    });

    it("ne rend jamais « 6/5 » : le nombre de tentés est plafonné par le total", () => {
        assert.deepEqual(sumProgress([{promptCount: 5, attemptedCount: 6}]), {
            attempted: 5,
            total: 5,
            percent: 100,
        });
    });
});

describe("findSkillProgress", () => {
    const skills = [
        {id: "a", promptCount: 5, attemptedCount: 3},
        {id: "b", promptCount: 5, attemptedCount: 0},
    ];

    it("retrouve la compétence par son id", () => {
        assert.deepEqual(findSkillProgress(skills, "a"), {attempted: 3, total: 5, percent: 60});
    });

    it("null quand la liste n'est pas chargée ou ne la contient pas — on n'affiche pas une barre fausse", () => {
        assert.equal(findSkillProgress(null, "a"), null);
        assert.equal(findSkillProgress(undefined, "a"), null);
        assert.equal(findSkillProgress(skills, "zzz"), null);
    });
});
