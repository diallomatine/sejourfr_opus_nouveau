// Écran de résultat d'un petit sujet : ce qui est déplié, ce qui est replié.
//
// Le client a inversé les deux blocs — l'analyse IA était derrière un bouton
// « Voir » et les références étaient dépliées. Ces tests figent l'inversion,
// pour qu'un futur passage sur cet écran ne la remette pas silencieusement à
// l'endroit.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    ANALYSIS_OPEN_BY_DEFAULT,
    REFERENCES_OPEN_BY_DEFAULT,
    referencesOpenByDefault,
    skillResultAnalysisView,
    skillResultBannerAction,
    skillResultHasBanner,
    type SkillResultAnalysisView,
} from "./skill-result-view.ts";

const NOMINAL = {pending: false, hasAnalysis: true, failed: false, analysisAllowed: true};

describe("l'analyse IA est dépliée par défaut", () => {
    it("s'ouvre dépliée, sans clic", () => {
        assert.equal(ANALYSIS_OPEN_BY_DEFAULT, true);
    });

    it("dès qu'une analyse existe, l'écran la rend elle, pas un bandeau", () => {
        assert.equal(skillResultAnalysisView(NOMINAL), "ANALYSIS");
        assert.equal(skillResultHasBanner("ANALYSIS"), false);
    });

    it("aucun bouton à actionner dans le cas nominal", () => {
        // C'est tout le point du changement : le retour vient d'être mérité,
        // il n'y a rien à déverrouiller.
        assert.equal(skillResultBannerAction("ANALYSIS"), null);
    });

    it("une analyse présente l'emporte sur un quota épuisé", () => {
        // Le quota se lit après coup : il ne doit jamais masquer un retour
        // déjà obtenu et déjà payé par un des essais offerts.
        assert.equal(
            skillResultAnalysisView({...NOMINAL, analysisAllowed: false}),
            "ANALYSIS",
        );
    });

    it("une analyse présente l'emporte sur un statut en échec", () => {
        assert.equal(skillResultAnalysisView({...NOMINAL, failed: true}), "ANALYSIS");
    });
});

describe("les références comparatives sont repliées par défaut", () => {
    it("s'ouvrent repliées", () => {
        assert.equal(REFERENCES_OPEN_BY_DEFAULT, false);
    });

    it("le repli est un état, pas une suppression : les deux sens existent", () => {
        // Garde-fou de rédaction : si la constante devenait autre chose qu'un
        // booléen, le dépliant n'aurait plus d'état à inverser.
        assert.equal(typeof REFERENCES_OPEN_BY_DEFAULT, "boolean");
        assert.equal(!REFERENCES_OPEN_BY_DEFAULT, true);
    });

    it("repliées seulement quand il y a une analyse à lire au-dessus", () => {
        assert.equal(referencesOpenByDefault("ANALYSIS"), false);
    });

    it("ouvertes quand elles sont le seul retour de l'écran", () => {
        // Sans analyse, les replier laisserait le candidat devant une page qui
        // ne lui apprend rien. Parité mot pour mot avec le mobile.
        for (const view of ["LOCKED", "MISSING", "FAILED", "PENDING"] as const) {
            assert.equal(referencesOpenByDefault(view), true, view);
        }
    });
});

describe("le bandeau ne subsiste que quand il n'y a rien à déplier", () => {
    it("analyse en vol : ni bandeau ni retour, un indicateur d'attente", () => {
        assert.equal(
            skillResultAnalysisView({...NOMINAL, pending: true, hasAnalysis: false}),
            "PENDING",
        );
        assert.equal(skillResultHasBanner("PENDING"), false);
        assert.equal(skillResultBannerAction("PENDING"), null);
    });

    it("analyse en échec : bandeau qui relance", () => {
        const view = skillResultAnalysisView({
            pending: false,
            hasAnalysis: false,
            failed: true,
            analysisAllowed: true,
        });
        assert.equal(view, "FAILED");
        assert.equal(skillResultHasBanner(view), true);
        assert.equal(skillResultBannerAction(view), "RETRY");
    });

    it("un échec relance même quand les analyses offertes sont épuisées", () => {
        // `retryAnalysis` ne re-consomme pas le quota : proposer l'offre ici
        // ferait payer une panne de notre côté.
        const view = skillResultAnalysisView({
            pending: false,
            hasAnalysis: false,
            failed: true,
            analysisAllowed: false,
        });
        assert.equal(view, "FAILED");
        assert.equal(skillResultBannerAction(view), "RETRY");
    });

    it("quota épuisé : bandeau qui ouvre l'offre", () => {
        const view = skillResultAnalysisView({
            pending: false,
            hasAnalysis: false,
            failed: false,
            analysisAllowed: false,
        });
        assert.equal(view, "LOCKED");
        assert.equal(skillResultHasBanner(view), true);
        assert.equal(skillResultBannerAction(view), "PAYWALL");
    });

    it("production sans analyse alors qu'il en restait : bandeau qui propose de refaire", () => {
        const view = skillResultAnalysisView({
            pending: false,
            hasAnalysis: false,
            failed: false,
            analysisAllowed: true,
        });
        assert.equal(view, "MISSING");
        assert.equal(skillResultHasBanner(view), true);
        assert.equal(skillResultBannerAction(view), "REQUEST");
    });

    it("chaque état de bandeau porte une action, et une seule", () => {
        const views: SkillResultAnalysisView[] = [
            "PENDING",
            "ANALYSIS",
            "FAILED",
            "LOCKED",
            "MISSING",
        ];
        for (const view of views) {
            assert.equal(
                skillResultHasBanner(view),
                skillResultBannerAction(view) !== null,
                `incohérence bandeau/action sur ${view}`,
            );
        }
    });
});
