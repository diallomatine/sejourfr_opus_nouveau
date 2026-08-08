// Fige la **mention de périmètre** du niveau TCF estimé, côté web.
//
// La chaîne ne transite pas par le réseau : le web et le mobile en tiennent
// chacun une copie écrite à la main (`estimatedTcfLevelScopeLabel`, ici et dans
// `mobile_sejourfr/lib/core/models/dashboard_models.dart`). Rien n'empêcherait
// une couche de dériver — c'est exactement comme ça que les libellés du module
// Compétences avaient décroché. Même technique que `skill-labels.test.ts` :
// deux couches, une seule table, deux tests qui refusent de diverger. Le miroir
// mobile est `test/estimated_tcf_level_test.dart`, sur **exactement** les mêmes
// chaînes.
//
// Un échec ici veut dire que la mention a bougé et que l'autre copie doit bouger
// dans la même passe — jamais qu'il faut « mettre à jour le test ».
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {estimatedTcfLevelScopeLabel} from "./types.ts";

const scope = (counted: number, expected: number, partial: boolean) => ({
    estimatedTcfLevelEpreuvesCounted: counted,
    estimatedTcfLevelEpreuvesExpected: expected,
    estimatedTcfLevelPartial: partial,
});

describe("mention de périmètre du niveau TCF estimé", () => {
    it("les deux formes sont gelées, au caractère près", () => {
        assert.equal(estimatedTcfLevelScopeLabel(scope(1, 4, true)), "D'après 1 épreuve sur 4");
        assert.equal(estimatedTcfLevelScopeLabel(scope(3, 4, true)), "D'après 3 épreuves sur 4");
    });

    it("accorde le pluriel à partir de deux épreuves", () => {
        assert.equal(estimatedTcfLevelScopeLabel(scope(2, 4, true)), "D'après 2 épreuves sur 4");
    });

    // LE DÉFAUT D'ORIGINE : quatre épreuves sur quatre, le niveau porte sur
    // tout — annoter là serait inventer une réserve.
    it("un niveau complet n'est pas annoté", () => {
        assert.equal(estimatedTcfLevelScopeLabel(scope(4, 4, false)), null);
    });

    it("aucune épreuve : le niveau vaut déjà « — », rien à annoter", () => {
        assert.equal(estimatedTcfLevelScopeLabel(scope(0, 4, false)), null);
    });

    // Le drapeau vient du serveur et c'est LUI qui décide : un front ne
    // recompte pas le périmètre, il l'affiche.
    it("le drapeau serveur fait foi, jamais un décompte refait côté front", () => {
        assert.equal(estimatedTcfLevelScopeLabel(scope(1, 4, false)), null);
    });

    it("des compteurs absurdes ou un résumé manquant n'affichent rien", () => {
        assert.equal(estimatedTcfLevelScopeLabel(scope(0, 0, true)), null);
        assert.equal(estimatedTcfLevelScopeLabel(null), null);
        assert.equal(estimatedTcfLevelScopeLabel(undefined), null);
    });

    // Aucun chiffre de barème ne doit se glisser dans cette mention : c'est un
    // décompte d'épreuves, pas une note.
    it("ne parle jamais d'une note", () => {
        for (const counted of [1, 2, 3]) {
            const label = estimatedTcfLevelScopeLabel(scope(counted, 4, true)) ?? "";
            assert.ok(!label.includes("/20"), label);
            assert.ok(!/\bnote\b/i.test(label), label);
        }
    });
});
