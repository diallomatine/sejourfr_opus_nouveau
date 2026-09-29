// Fige le compteur de mots et le blocage de la zone de rédaction EE.
//
// Les bornes du TCF IRN sont STRICTES : 30–60 mots en tâche 1, **40–90** en
// tâches 2 et 3. Elles vivent en base (`production_tasks.mots_min/mots_max`) et
// arrivent au front dans la tâche ; ce test vérifie que le front bloque
// exactement là où le serveur bloque (`ProductionEvaluationServiceTest`) et là
// où le mobile bloque (`production_models_test.dart`). Un front qui refuse une
// copie que le serveur accepte, c'est un candidat bloqué pour rien : les 59
// mots en T2/T3 sont précisément la régression corrigée.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";

import {countEeWords, isEeWordCountWithinBounds} from "./ee-word-bounds.ts";

/** Bornes officielles par tâche, telles que la base les sert. */
const BORNES: Record<number, {motsMin: number; motsMax: number}> = {
    1: {motsMin: 30, motsMax: 60},
    2: {motsMin: 40, motsMax: 90},
    3: {motsMin: 40, motsMax: 90},
};

/** Texte de `n` mots — même matière que ce que taperait le candidat. */
function texte(n: number): string {
    return Array.from({length: n}, () => "mot").join(" ");
}

describe("compteur de mots EE", () => {
    it("ne compte rien sur un texte vide ou blanc", () => {
        assert.equal(countEeWords(""), 0);
        assert.equal(countEeWords("   \n  "), 0);
    });

    it("compte les mots séparés par n'importe quel blanc", () => {
        assert.equal(countEeWords("  un   deux\ntrois\t quatre "), 4);
        assert.equal(countEeWords(texte(59)), 59);
    });
});

describe("bornes strictes EE du TCF IRN", () => {
    it("tâche 1 : refuse 29, accepte 30 et 60, refuse 61", () => {
        const t1 = BORNES[1];
        assert.equal(isEeWordCountWithinBounds(t1, 29), false);
        assert.equal(isEeWordCountWithinBounds(t1, 30), true);
        assert.equal(isEeWordCountWithinBounds(t1, 60), true);
        assert.equal(isEeWordCountWithinBounds(t1, 61), false);
    });

    for (const tache of [2, 3]) {
        it(`tâche ${tache} : refuse 39, accepte 40, 59 et 90, refuse 91`, () => {
            const bornes = BORNES[tache];
            assert.equal(isEeWordCountWithinBounds(bornes, 39), false);
            assert.equal(isEeWordCountWithinBounds(bornes, 40), true);
            // Le cœur de la régression : 59 mots valait 60 minimum avant V724.
            assert.equal(isEeWordCountWithinBounds(bornes, 59), true);
            assert.equal(isEeWordCountWithinBounds(bornes, 90), true);
            assert.equal(isEeWordCountWithinBounds(bornes, 91), false);
        });
    }

    it("le blocage se lit sur le texte saisi, pas sur un nombre à part", () => {
        assert.equal(isEeWordCountWithinBounds(BORNES[2], countEeWords(texte(59))), true);
        assert.equal(isEeWordCountWithinBounds(BORNES[2], countEeWords(texte(39))), false);
    });

    it("une borne absente ne bloque pas de son côté", () => {
        assert.equal(isEeWordCountWithinBounds({motsMin: null, motsMax: 90}, 1), true);
        assert.equal(isEeWordCountWithinBounds({motsMin: 40, motsMax: null}, 5000), true);
    });
});
