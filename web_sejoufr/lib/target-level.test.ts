// Fige la correspondance **démarche → palier de français** et la règle du
// plancher, côté web.
//
// Ce n'est pas un réglage produit : ce sont les seuils légaux en vigueur au
// 1ᵉʳ janvier 2026 (CSP → A2, CR → B1, NAT → B2). La table vit dans l'enum
// `TargetProcedure` côté backend ; ce fichier tient le miroir web, comme
// `TargetProcedureTest` tient le backend et `target_level_test.dart` le mobile.
// Même technique que `skill-labels.test.ts` : trois couches, une seule table,
// trois tests qui refusent de diverger.
//
// Un échec ici veut dire que la correspondance a bougé et que les deux autres
// copies doivent bouger dans la même passe — jamais qu'il faut « mettre à jour
// le test ».
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    TCF_LEVEL_BY_PROCEDURE,
    niveauViseTcf,
    resolveTcfLevel,
    tcfLevelFromProcedure,
    type TargetLevel,
    type TargetProcedure,
} from "./types.ts";

const user = (
    targetProcedure: TargetProcedure | null,
    targetLevel: TargetLevel | null,
) => ({targetProcedure, targetLevel});

describe("démarche → palier de français", () => {
    it("la table est gelée : CSP → A2, CR → B1, NAT → B2", () => {
        assert.deepEqual(TCF_LEVEL_BY_PROCEDURE, {CSP: "A2", CR: "B1", NAT: "B2"});
    });

    it("la naturalisation exige le B2", () => {
        assert.equal(tcfLevelFromProcedure("NAT"), "B2");
    });

    it("sans démarche, aucun palier n'est deviné", () => {
        assert.equal(tcfLevelFromProcedure(null), null);
        assert.equal(tcfLevelFromProcedure(undefined), null);
    });
});

describe("niveau visé : la démarche fait plancher", () => {
    // LE DÉFAUT D'ORIGINE. Un compte NAT portant un `targetLevel` hérité à B1
    // était réputé « au niveau visé » dès qu'il écrivait du B1 : plus aucun
    // texte modèle, et le candidat n'était jamais tiré vers le B2 dont sa
    // démarche a besoin.
    it("naturalisation + niveau déclaré plus bas ⇒ B2", () => {
        assert.equal(niveauViseTcf(user("NAT", "B1")), "B2");
        assert.equal(niveauViseTcf(user("NAT", "A2")), "B2");
    });

    it("viser plus haut que sa démarche est respecté", () => {
        assert.equal(niveauViseTcf(user("CSP", "B2")), "B2");
        assert.equal(niveauViseTcf(user("CSP", "B1")), "B1");
    });

    it("démarche seule ⇒ le palier qu'elle exige", () => {
        assert.equal(niveauViseTcf(user("CR", null)), "B1");
    });

    it("sans démarche ⇒ le niveau déclaré, seul", () => {
        assert.equal(niveauViseTcf(user(null, "B1")), "B1");
    });

    it("rien de connu ⇒ rien de deviné", () => {
        assert.equal(niveauViseTcf(user(null, null)), null);
        assert.equal(niveauViseTcf(null), null);
    });

    it("un couple cohérent est un point fixe", () => {
        for (const [proc, niveau] of Object.entries(TCF_LEVEL_BY_PROCEDURE)) {
            assert.equal(niveauViseTcf(user(proc as TargetProcedure, niveau)), niveau);
        }
    });
});

describe("resolveTcfLevel : le repli B1, et lui seul", () => {
    it("hérite du plancher de la démarche", () => {
        assert.equal(resolveTcfLevel(user("NAT", "B1")), "B2");
    });

    it("ne retombe sur B1 que quand rien n'est connu", () => {
        assert.equal(resolveTcfLevel(user(null, null)), "B1");
        assert.equal(resolveTcfLevel(null), "B1");
    });
});
